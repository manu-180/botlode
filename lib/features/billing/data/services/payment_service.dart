// Archivo: lib/features/billing/data/services/payment_service.dart
import 'dart:convert';
import 'package:botslode/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;
  
  String get _mpPublicKey => dotenv.env['MP_PUBLIC_KEY'] ?? '';

  Future<double> getDolarBlueRate() async {
    try {
      final response = await http.get(Uri.parse("https://dolarapi.com/v1/dolares/blue"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['venta'] as num).toDouble();
      }
    } catch (e) {
      debugPrint("⚠️ API Dolar Error: $e");
    }
    return 1500.0; 
  }

  Future<String> createCheckoutLink(double amount) async {
    final url = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/create-mp-preference');
    final user = _supabase.auth.currentUser;
    
    final response = await http.post(
      url,
      headers: { 'Content-Type': 'application/json', 'apikey': AppConfig.supabaseAnonKey },
      body: jsonEncode({ 'amount': amount, 'email': user?.email ?? 'guest@botslode.com', 'userId': user?.id ?? 'GUEST' }),
    );

    if (response.statusCode == 200) return jsonDecode(response.body)['init_point']; 
    else throw Exception('Error Checkout: ${response.body}');
  }

  Future<String> tokenizeCard({
    required String cardNumber, required String expirationMonth, required String expirationYear,
    required String securityCode, required String cardholderName,
  }) async {
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

  Future<void> linkCardToUser({
    required String token, required String email, required String brand, required String lastFour,
    required String holderName, required String expiryDate,
  }) async {
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

  // --- NUEVA LÓGICA MULTI-TARJETA ---

  Future<void> deleteCard(String cardId) async {
    await _supabase.from('user_billing').delete().eq('id', cardId);
  }

  Future<void> setPrimaryCard(String cardId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Poner todas en false
    await _supabase.from('user_billing').update({'is_primary': false}).eq('user_id', userId);
    // 2. Poner la elegida en true
    await _supabase.from('user_billing').update({'is_primary': true}).eq('id', cardId);
  }
}