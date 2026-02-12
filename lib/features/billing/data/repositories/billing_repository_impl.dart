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

  // --- HELPERS PRIVADOS ---

  /// Analiza errores de vinculación de tarjetas y retorna mensaje amigable
  String _parseLinkCardError(dynamic error) {
    final String errorText = error.toString().toLowerCase();
    
    if (errorText.contains('customer not found') || errorText.contains('not found')) {
      return 'No pudimos validar tu tarjeta. Verifica que los datos sean correctos.';
    }
    if (errorText.contains('invalid') || errorText.contains('rejected')) {
      return 'La tarjeta fue rechazada. Verifica el número, CVV y fecha de vencimiento.';
    }
    if (errorText.contains('network') || errorText.contains('timeout') || errorText.contains('connection')) {
      return 'Error de conexión. Por favor, intenta nuevamente.';
    }
    if (errorText.contains('expired') || errorText.contains('expir')) {
      return 'La tarjeta está vencida. Por favor, usa una tarjeta vigente.';
    }
    if (errorText.contains('duplicate')) {
      return 'Esta tarjeta ya está registrada en tu cuenta.';
    }
    return 'No pudimos procesar tu tarjeta. Intenta con otra tarjeta o contacta a soporte.';
  }

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
      throw Exception("No pudimos cargar tu historial de transacciones. Verifica tu conexión a internet.");
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
      throw Exception("No pudimos cargar tus métodos de pago. Verifica tu conexión a internet.");
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
      // Error silenciado
    }
    return 1240.0; // Fallback seguro
  }

  @override
  Future<int> getQualifiedBotCount() async {
    try {
      // Límite = total de bots (activos + desactivados) × 60 — todos cuentan para el tope a pagar
      final response = await _supabase
          .from('bots')
          .select('id');
      return (response as List).length;
    } catch (e) {
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
      throw Exception("No pudimos actualizar tu configuración de autopago. Intenta nuevamente.");
    }
  }

  @override
  Future<void> processPayment({required double amountUSD, required String cardId}) async {
    // Validar monto mínimo (Mercado Pago requiere mínimo $2 ARS)
    if (amountUSD < 2.0) {
      amountUSD = 2.0;
    }
    
    try {
      // ✅ Usar el cliente de Supabase para Edge Functions
      // Esto maneja automáticamente los headers de autenticación
      final response = await _supabase.functions.invoke(
        'process-payment',
        body: {
          'amount_usd': amountUSD,
          'card_id': cardId,
        },
      );

      if (response.status != 200) {
        final errorMessage = response.data is Map 
            ? (response.data['error'] ?? 'No pudimos procesar el pago. Intenta nuevamente.')
            : response.data.toString();
        throw Exception(errorMessage);
      }
    } catch (e) {
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
        final errorData = jsonDecode(mpResponse.body);
        // debugPrint("🔴 MP Tokenization Error: $errorData");
        throw Exception('Los datos de tu tarjeta no son válidos. Verifica el número, CVV y fecha de vencimiento.');
      }
    } catch (e) {
      // debugPrint("🔴 Card provider error: $e");
      if (e.toString().contains('Los datos de tu tarjeta')) rethrow;
      throw Exception("Error de conexión con el procesador de pagos. Por favor, intenta nuevamente.");
    }

    // 2. Vincular tarjeta (Supabase Edge Function)
    
    try {
      final response = await _supabase.functions.invoke(
        'mp-payment-sync',
        body: {
          'token': token,
          'email': email,
          'brand': brand,
          'last_four': lastFour,
          'holder_name': holder,
          'expiry_date': "$month/${year.substring(2)}"
        },
      );

      // debugPrint("🔍 [LINK CARD] Response status: ${response.status}");

      if (response.status != 200) {
        final errorMessage = response.data is Map 
            ? (response.data['error'] ?? 'No pudimos vincular tu tarjeta. Intenta nuevamente.')
            : response.data.toString();
        
        // debugPrint("🔴 Card sync error: $errorMessage");
        final userMessage = _parseLinkCardError(errorMessage);
        throw Exception(userMessage);
      }
      
      // debugPrint("✅ [LINK CARD] Tarjeta vinculada exitosamente");
    } catch (e) {
      // debugPrint("🔴 Card Link Process Error: $e");
      rethrow;
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
      // debugPrint("Checkout Link Error: $e");
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
      // debugPrint("🔴 Critical Error logging charge: $e");
      // No re-lanzamos para no romper el flujo del bot, pero se loguea
    }
  }
}