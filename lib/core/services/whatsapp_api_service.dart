import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:botslode/core/providers/supabase_provider.dart';

// Resultado del intento de envío vía API Twilio.
enum WhatsAppSendResult {
  sent,      // Enviado correctamente
  disabled,  // Kill switch activo (_envioDeshabilitado = true)
  noSid,     // Content SID vacío (template no aprobado aún) → usar fallback
  error,     // Error de red o Twilio → usar fallback
}

class WhatsAppApiService {
  WhatsAppApiService(this._supabase, this._httpClient);

  final SupabaseClient _supabase;
  final http.Client _httpClient;

  bool _envLoaded = false;

  /// Poner en true para deshabilitar todos los envíos sin tocar credenciales.
  static const bool _envioDeshabilitado = false;

  /// Número sender ya registrado en Twilio/WhatsApp Business.
  static const String _fromNumber = 'whatsapp:+5491125303794';

  Future<void> _ensureEnvLoaded() async {
    if (_envLoaded) return;
    await dotenv.load(fileName: '.env');
    _envLoaded = true;
  }

  /// Devuelve el Content SID del template según el feature y el índice de rotación.
  ///
  /// [feature]: 'empresas' | 'assistify'
  /// [index]: 0-4 (se cicla con % 5)
  ///
  /// Devuelve null si el SID no está configurado aún (templates pendientes de aprobación).
  Future<String?> getContentSid(String feature, int index) async {
    await _ensureEnvLoaded();
    final key = 'WPP_${feature.toUpperCase()}_SID_${index % 5}';
    final sid = dotenv.maybeGet(key) ?? '';
    return sid.trim().isEmpty ? null : sid.trim();
  }

  /// Normaliza un teléfono argentino al formato Twilio: whatsapp:+549XXXXXXXXXX
  String _formatPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) return 'whatsapp:+549$clean';
    // 54 + 10 dígitos (sin el 9 móvil)
    if (clean.startsWith('54') && clean.length == 12) {
      return 'whatsapp:+549${clean.substring(2)}';
    }
    return 'whatsapp:+$clean';
  }

  /// Envía un mensaje de template de WhatsApp vía Twilio.
  ///
  /// [telefono]: número del destinatario (se normaliza internamente)
  /// [nombre]: nombre de la empresa/persona para la variable {{1}}
  /// [contentSid]: SID del template aprobado (HX...)
  /// [feature]: 'empresas' | 'assistify' (solo para el log de auditoría)
  ///
  /// Retorna [WhatsAppSendResult.noSid] si [contentSid] está vacío → el caller debe usar fallback.
  /// Retorna [WhatsAppSendResult.error] en caso de fallo de red/API → el caller debe usar fallback.
  Future<WhatsAppSendResult> sendToContact({
    required String telefono,
    required String nombre,
    required String contentSid,
    String feature = 'empresas',
  }) async {
    if (_envioDeshabilitado) return WhatsAppSendResult.disabled;

    if (contentSid.trim().isEmpty) return WhatsAppSendResult.noSid;

    try {
      await _ensureEnvLoaded();

      final apiKeySid = dotenv.env['API_KEY_SID'] ?? '';
      final apiKeySecret = dotenv.env['API_KEY_SECRET'] ?? '';
      final accountSid = dotenv.env['ACCOUNT_SID']?.trim() ?? '';

      if (apiKeySid.isEmpty || apiKeySecret.isEmpty || accountSid.isEmpty) {
        debugPrint('[WPP API] Faltan credenciales Twilio en .env');
        return WhatsAppSendResult.error;
      }

      final userId = _supabase.auth.currentUser?.id;
      final toFormatted = _formatPhone(telefono);

      // Registro de auditoría (si la tabla wpp_control no existe, se ignora el error).
      String? logId;
      try {
        final row = await _supabase.from('wpp_control').insert({
          'user_id': userId,
          'to_number': toFormatted,
          'content_sid': contentSid,
          'parameters': [nombre],
          'status': 'pending',
          'feature': feature,
        }).select('id').single();
        logId = row['id'] as String?;
      } catch (_) {
        // La tabla puede no existir en botslode. El envío continúa igual.
      }

      final uri = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
      );

      final contentVariables = jsonEncode({'1': nombre.trim().isNotEmpty ? nombre.trim() : 'su empresa'});

      final bodyFields = <String, String>{
        'From': _fromNumber,
        'To': toFormatted,
        'ContentSid': contentSid,
        'ContentVariables': contentVariables,
      };

      const maxRetries = 3;
      for (var attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final response = await _httpClient
              .post(
                uri,
                headers: {
                  'Authorization':
                      'Basic ${base64Encode(utf8.encode('$apiKeySid:$apiKeySecret'))}',
                  'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: bodyFields,
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 201) {
            final decoded = jsonDecode(response.body) as Map<String, dynamic>;
            final twilioSid = decoded['sid'] as String?;
            debugPrint('[WPP API] Enviado a $toFormatted. SID: $twilioSid');
            if (logId != null) {
              try {
                await _supabase.from('wpp_control').update({
                  'status': 'sent',
                  'twilio_sid': twilioSid,
                  'http_status': response.statusCode,
                }).eq('id', logId);
              } catch (_) {}
            }
            return WhatsAppSendResult.sent;
          } else if (response.statusCode >= 500 && attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          } else {
            debugPrint('[WPP API] Error Twilio ${response.statusCode}: ${response.body}');
            if (logId != null) {
              try {
                await _supabase.from('wpp_control').update({
                  'status': 'failed',
                  'error_message': response.body,
                  'http_status': response.statusCode,
                }).eq('id', logId);
              } catch (_) {}
            }
            return WhatsAppSendResult.error;
          }
        } on SocketException catch (e) {
          if (attempt >= maxRetries) {
            debugPrint('[WPP API] Sin conexión: ${e.message}');
            return WhatsAppSendResult.error;
          }
          await Future.delayed(Duration(seconds: attempt * 2));
        } on TimeoutException catch (_) {
          if (attempt >= maxRetries) {
            debugPrint('[WPP API] Timeout persistente');
            return WhatsAppSendResult.error;
          }
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
      return WhatsAppSendResult.error;
    } catch (e) {
      debugPrint('[WPP API] Excepción inesperada: $e');
      return WhatsAppSendResult.error;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final whatsAppApiServiceProvider = Provider<WhatsAppApiService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return WhatsAppApiService(supabase, http.Client());
});
