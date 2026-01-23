import 'dart:convert';
import 'package:botslode/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;
  String get _mpPublicKey => dotenv.env['MP_PUBLIC_KEY'] ?? '';

  // --- COTIZACIÓN REAL ---
  Future<double> getDolarBlueRate() async {
    try {
      final response = await http.get(Uri.parse("https://dolarapi.com/v1/dolares/blue"));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final venta = (data['venta'] as num).toDouble();
        debugPrint("💵 Dolar Blue Actualizado: \$$venta");
        return venta;
      }
    } catch (e) { 
      debugPrint("⚠️ API Dolar Error (Usando fallback): $e"); 
    }
    return 1240.0; 
  }

  // --- PROCESAMIENTO ---
  Future<void> processRealPayment({required double amountUSD, required String cardId}) async {
    final sessionToken = _supabase.auth.currentSession?.accessToken;
    if (sessionToken == null) throw Exception("No Auth Session");

    final url = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/process-payment');

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
      throw Exception('Error en Pago: ${response.body}');
    }
  }

  // --- GESTIÓN DE TARJETAS ---
  Future<String> tokenizeCard({required String cardNumber, required String expirationMonth, required String expirationYear, required String securityCode, required String cardholderName}) async {
    final response = await http.post(
      Uri.parse('https://api.mercadopago.com/v1/card_tokens?public_key=$_mpPublicKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "card_number": cardNumber.replaceAll(' ', ''), "expiration_month": int.parse(expirationMonth),
        "expiration_year": int.parse(expirationYear), "security_code": securityCode, "cardholder": {"name": cardholderName}
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) return jsonDecode(response.body)['id'];
    else throw Exception('Error Tokenización: ${response.body}');
  }

  Future<void> linkCardToUser({required String token, required String email, required String brand, required String lastFour, required String holderName, required String expiryDate}) async {
    final url = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/mp-payment-sync');
    final sessionToken = _supabase.auth.currentSession?.accessToken;
    if (sessionToken == null) throw Exception("No Auth Session");
    
    final response = await http.post(
      url,
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer $sessionToken', 'apikey': AppConfig.supabaseAnonKey },
      body: jsonEncode({ 'token': token, 'email': email, 'brand': brand, 'last_four': lastFour, 'holder_name': holderName, 'expiry_date': expiryDate }),
    );
    if (response.statusCode != 200) throw Exception('Error Sync: ${response.body}');
  }

  Future<void> deleteCard(String cardId) async { 
    await _supabase.from('user_billing').delete().eq('id', cardId); 
  }

  Future<void> setPrimaryCard(String cardId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('user_billing').update({'is_primary': false}).eq('user_id', userId);
    await _supabase.from('user_billing').update({'is_primary': true}).eq('id', cardId);
  }

  /// GENERA LINK DE PAGO (MERCADO PAGO) VÍA SUPABASE FUNCTION
  Future<String> createCheckoutLink(double amount) async {
    final sessionToken = _supabase.auth.currentSession?.accessToken;
    if (sessionToken == null) throw Exception("No Auth Session");

    // Asumimos que tienes (o tendrás) una función 'create-preference' en Supabase
    final url = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/create-mp-preference');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
          'apikey': AppConfig.supabaseAnonKey
        },
        body: jsonEncode({
          'amount': amount,
          // 'title': 'Recarga de Saldo BotLode', // Opcional
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['init_point'] ?? ''; 
      } else {
        debugPrint("Error generando link MP: ${response.body}");
        return "";
      }
    } catch (e) {
      debugPrint("Excepción en Checkout Link: $e");
      return "";
    }
  }
}