// Archivo: lib/features/billing/data/repositories/billing_repository_impl.dart
import 'dart:convert';
import 'package:botslode/core/config/app_config.dart';
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:botslode/features/billing/domain/models/transaction.dart';
import 'package:botslode/features/billing/domain/repositories/billing_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class BillingRepositoryImpl implements BillingRepository {
  final SupabaseClient _supabase;

  BillingRepositoryImpl(this._supabase);

  String get _mpPublicKey => dotenv.env['MP_PUBLIC_KEY'] ?? '';

  // --- GETTERS & FETCHING ---

  @override
  Future<List<BotTransaction>> getTransactions() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .order('created_at', ascending: true);
      return (response as List).map((data) => BotTransaction.fromMap(data)).toList();
    } catch (e) {
      debugPrint("🔴 Error fetching transactions: $e");
      throw Exception("Error de sincronización de transacciones");
    }
  }

  @override
  Future<List<CardInfo>> getCards() async {
    try {
      final response = await _supabase
          .from('user_billing')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((data) => CardInfo.fromMap(data)).toList();
    } catch (e) {
      debugPrint("🔴 Error fetching cards: $e");
      throw Exception("Error obteniendo métodos de pago");
    }
  }

  @override
  Future<double> getDolarBlueRate() async {
    try {
      final response = await http.get(Uri.parse("https://dolarapi.com/v1/dolares/blue"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['venta'] as num).toDouble();
      }
    } catch (e) {
      debugPrint("⚠️ API Dolar Error (Fallback): $e");
    }
    return 1240.0; // Fallback seguro
  }

  @override
  Future<int> getQualifiedBotCount() async {
    try {
      return await _supabase
          .from('bots')
          .count(CountOption.exact)
          .or('status.eq.active,status.eq.maintenance');
    } catch (e) {
      debugPrint("🔴 Error counting bots: $e");
      return 0;
    }
  }

  // --- ACTIONS ---

  @override
  Future<void> updateAutoPayThreshold(String cardId, double amount) async {
    try {
      await _supabase
          .from('user_billing')
          .update({'auto_pay_threshold': amount})
          .eq('id', cardId);
    } catch (e) {
      throw Exception("No se pudo actualizar el límite de autopago: $e");
    }
  }

  @override
  Future<void> processPayment({required double amountUSD, required String cardId}) async {
    final sessionToken = _supabase.auth.currentSession?.accessToken;
    if (sessionToken == null) throw Exception("Sesión inválida");

    final url = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/process-payment');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
          'apikey': AppConfig.supabaseAnonKey
        },
        body: jsonEncode({
          'amount_usd': amountUSD,
          'card_id': cardId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Rechazo del procesador: ${response.body}');
      }
    } catch (e) {
      debugPrint("🔴 Payment Process Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> setPrimaryCard(String cardId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    // Transacción manual simple (Batch update idealmente, pero secuencial funciona aquí)
    await _supabase.from('user_billing').update({'is_primary': false}).eq('user_id', userId);
    await _supabase.from('user_billing').update({'is_primary': true}).eq('id', cardId);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await _supabase.from('user_billing').delete().eq('id', cardId);
  }

  @override
  Future<void> linkCard({
    required String number,
    required String month,
    required String year,
    required String cvv,
    required String holder,
    required String brand,
    required String lastFour,
    required String email,
  }) async {
    // 1. Tokenización (Mercado Pago Directo)
    String token;
    try {
      final mpResponse = await http.post(
        Uri.parse('https://api.mercadopago.com/v1/card_tokens?public_key=$_mpPublicKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "card_number": number.replaceAll(' ', ''),
          "expiration_month": int.parse(month),
          "expiration_year": int.parse(year),
          "security_code": cvv,
          "cardholder": {"name": holder}
        }),
      );

      if (mpResponse.statusCode == 201 || mpResponse.statusCode == 200) {
        token = jsonDecode(mpResponse.body)['id'];
      } else {
        throw Exception('Error Tokenización: ${mpResponse.body}');
      }
    } catch (e) {
      throw Exception("Fallo al contactar proveedor de tarjetas: $e");
    }

    // 2. Sincronización Segura (Supabase Edge Function)
    final sessionToken = _supabase.auth.currentSession?.accessToken;
    if (sessionToken == null) throw Exception("Sesión expirada");

    final url = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/mp-payment-sync');
    
    final syncResponse = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $sessionToken',
        'apikey': AppConfig.supabaseAnonKey
      },
      body: jsonEncode({
        'token': token,
        'email': email,
        'brand': brand,
        'last_four': lastFour,
        'holder_name': holder,
        'expiry_date': "$month/${year.substring(2)}"
      }),
    );

    if (syncResponse.statusCode != 200) {
      throw Exception('Error en vinculación segura: ${syncResponse.body}');
    }
  }

  @override
  Future<String> createCheckoutLink(double amount) async {
    final sessionToken = _supabase.auth.currentSession?.accessToken;
    if (sessionToken == null) return "";

    final url = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/create-mp-preference');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
          'apikey': AppConfig.supabaseAnonKey
        },
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['init_point'] ?? '';
      }
      return "";
    } catch (e) {
      debugPrint("Checkout Link Error: $e");
      return "";
    }
  }

  @override
  Future<void> registerCycleCharge({
    required String botId,
    required String botName,
    required double amount,
    required String userId,
  }) async {
    try {
      await _supabase.from('transactions').insert({
        'user_id': userId,
        'bot_id': botId,
        'bot_name': botName,
        'amount': amount,
        'type': 'cycle_charge',
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("🔴 Critical Error logging charge: $e");
      // No re-lanzamos para no romper el flujo del bot, pero se loguea
    }
  }
}