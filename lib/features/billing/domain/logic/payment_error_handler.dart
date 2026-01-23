// Archivo: lib/features/billing/domain/logic/payment_error_handler.dart

class PaymentErrorDetails {
  final String title;
  final String message;

  PaymentErrorDetails({required this.title, required this.message});
}

class PaymentErrorHandler {
  
  /// Traduce excepciones técnicas a mensajes tácticos para el usuario.
  static PaymentErrorDetails parseError(String rawError) {
    final cleanError = rawError.toLowerCase();
    
    String title = "TRANSACCIÓN RECHAZADA";
    String msg = "La entidad financiera denegó la operación. Por favor, contacte a su banco.";

    if (cleanError.contains('insufficient_funds') || cleanError.contains('fondos')) {
      title = "FONDOS INSUFICIENTES";
      msg = "La tarjeta no tiene saldo disponible para cubrir el monto total de la operación.";
    } else if (cleanError.contains('security_code') || cleanError.contains('cvv')) {
      title = "CÓDIGO DE SEGURIDAD INVÁLIDO";
      msg = "El CVV ingresado es incorrecto. Verifique el dorso de su tarjeta.";
    } else if (cleanError.contains('expiry') || cleanError.contains('expiration')) {
      title = "TARJETA VENCIDA";
      msg = "La fecha de expiración de la tarjeta no es válida.";
    } else if (cleanError.contains('call_for_authorize') || cleanError.contains('autorizar')) {
      title = "AUTORIZACIÓN REQUERIDA";
      msg = "El banco emisor requiere que usted autorice esta compra telefónicamente.";
    } else if (cleanError.contains('network') || cleanError.contains('connection')) {
      title = "ERROR DE ENLACE";
      msg = "No se pudo establecer conexión segura con la pasarela de pagos. Intente nuevamente.";
    }

    return PaymentErrorDetails(title: title, message: msg);
  }
}