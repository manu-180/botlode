// Archivo: lib/features/billing/presentation/services/billing_error_mapper.dart
//
// Traduce códigos crudos de Stripe / Mercado Pago a mensajes en español
// rioplatense listos para mostrar en la UI.
//
// Uso:
//   final msg = BillingErrorMapper.mapBillingError(caughtError);
//
// Los códigos crudos nunca llegan al usuario; los logs pueden registrarlos
// por separado antes de llamar a este servicio.

import 'dart:async';
import 'dart:io';

import 'package:botslode/l10n/app_strings.dart';

// ---------------------------------------------------------------------------
// Enum de códigos normalizados
// ---------------------------------------------------------------------------

enum BillingErrorCode {
  cardDeclined,
  insufficientFunds,
  expiredCard,
  incorrectCvc,
  processingError,
  authenticationRequired,
  networkError,
  gatewayTimeout,
  unknown,
}

// ---------------------------------------------------------------------------
// Mapper principal (funciones puras estáticas)
// ---------------------------------------------------------------------------

class BillingErrorMapper {
  const BillingErrorMapper._();

  /// Convierte un código de error de Stripe al enum normalizado.
  ///
  /// Cubre los decline_codes más comunes; cualquier otro devuelve [unknown].
  static BillingErrorCode parseStripeError(String code) {
    switch (code) {
      case 'card_declined':
        return BillingErrorCode.cardDeclined;
      case 'insufficient_funds':
        return BillingErrorCode.insufficientFunds;
      case 'expired_card':
        return BillingErrorCode.expiredCard;
      case 'incorrect_cvc':
      case 'incorrect_cvc_or_exp_date':
        return BillingErrorCode.incorrectCvc;
      case 'processing_error':
        return BillingErrorCode.processingError;
      case 'authentication_required':
        return BillingErrorCode.authenticationRequired;
      case 'network_error':
        return BillingErrorCode.networkError;
      case 'gateway_timeout':
        return BillingErrorCode.gatewayTimeout;
      default:
        return BillingErrorCode.unknown;
    }
  }

  /// Convierte un `status_detail` de Mercado Pago al enum normalizado.
  static BillingErrorCode parseMpError(String code) {
    switch (code) {
      case 'cc_rejected_insufficient_amount':
        return BillingErrorCode.insufficientFunds;
      case 'cc_rejected_bad_filled_date':
        return BillingErrorCode.expiredCard;
      case 'cc_rejected_bad_filled_security_code':
        return BillingErrorCode.incorrectCvc;
      case 'cc_rejected_call_for_authorize':
        return BillingErrorCode.authenticationRequired;
      case 'cc_rejected_other_reason':
      case 'cc_rejected_card_disabled':
        return BillingErrorCode.processingError;
      case 'cc_rejected_bad_filled_card_number':
      case 'cc_rejected_high_risk':
        return BillingErrorCode.cardDeclined;
      default:
        return BillingErrorCode.unknown;
    }
  }

  /// Devuelve el mensaje localizado para un [BillingErrorCode].
  static String describe(BillingErrorCode code) {
    switch (code) {
      case BillingErrorCode.cardDeclined:
        return AppStrings.billingErrCardDeclined;
      case BillingErrorCode.insufficientFunds:
        return AppStrings.billingErrInsufficientFunds;
      case BillingErrorCode.expiredCard:
        return AppStrings.billingErrExpiredCard;
      case BillingErrorCode.incorrectCvc:
        return AppStrings.billingErrIncorrectCvc;
      case BillingErrorCode.processingError:
        return AppStrings.billingErrProcessingError;
      case BillingErrorCode.authenticationRequired:
        return AppStrings.billingErrAuthenticationRequired;
      case BillingErrorCode.networkError:
        return AppStrings.billingErrNetworkError;
      case BillingErrorCode.gatewayTimeout:
        return AppStrings.billingErrGatewayTimeout;
      case BillingErrorCode.unknown:
        return AppStrings.billingErrUnknown;
    }
  }

  /// Punto de entrada principal: acepta cualquier error capturado y devuelve
  /// el string listo para mostrar al usuario.
  ///
  /// Orden de detección:
  ///   1. [SocketException] → networkError
  ///   2. [TimeoutException] → gatewayTimeout
  ///   3. Código MP exacto (empieza con `cc_rejected_`)
  ///   4. Código Stripe exacto
  ///   5. Heurísticas por contenido de texto
  ///   6. Fallback → unknown
  static String mapBillingError(Object error) {
    if (error is SocketException) {
      return describe(BillingErrorCode.networkError);
    }
    if (error is TimeoutException) {
      return describe(BillingErrorCode.gatewayTimeout);
    }

    final raw = error is Exception
        ? error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')
        : error.toString();

    // Mercado Pago: status_detail siempre empieza con cc_rejected_
    if (raw.startsWith('cc_rejected_')) {
      return describe(parseMpError(raw.trim()));
    }

    // Stripe: intento con código exacto
    final stripeCode = parseStripeError(raw.trim());
    if (stripeCode != BillingErrorCode.unknown) {
      return describe(stripeCode);
    }

    // Heurísticas sobre el contenido del mensaje de error
    final lower = raw.toLowerCase();
    if (lower.contains('insufficient') || lower.contains('fondos')) {
      return describe(BillingErrorCode.insufficientFunds);
    }
    if (lower.contains('network') ||
        lower.contains('conexión') ||
        lower.contains('connection')) {
      return describe(BillingErrorCode.networkError);
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return describe(BillingErrorCode.gatewayTimeout);
    }
    if (lower.contains('expired') ||
        lower.contains('vencida') ||
        lower.contains('vencido')) {
      return describe(BillingErrorCode.expiredCard);
    }
    if (lower.contains('cvc') ||
        lower.contains('cvv') ||
        lower.contains('security code')) {
      return describe(BillingErrorCode.incorrectCvc);
    }
    if (lower.contains('authentication') || lower.contains('autenticación')) {
      return describe(BillingErrorCode.authenticationRequired);
    }
    if (lower.contains('declined') ||
        lower.contains('rechazada') ||
        lower.contains('rechazado')) {
      return describe(BillingErrorCode.cardDeclined);
    }

    return describe(BillingErrorCode.unknown);
  }
}
