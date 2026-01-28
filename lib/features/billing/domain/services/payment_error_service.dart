// Archivo: lib/features/billing/domain/services/payment_error_service.dart

/// Detalles de un error de pago formateado para el usuario
class PaymentErrorDetails {
  final String title;
  final String message;

  PaymentErrorDetails({required this.title, required this.message});
}

/// Servicio de dominio para manejo de errores de pago
/// 
/// Responsabilidad:
/// - Traducir excepciones técnicas de pagos a mensajes amigables
///   para el usuario final, manteniendo la claridad y profesionalismo.
class PaymentErrorService {
  
  /// Traduce excepciones técnicas a mensajes tácticos para el usuario.
  /// 
  /// Analiza el error crudo recibido de la pasarela de pagos y
  /// retorna un objeto PaymentErrorDetails con un título y mensaje
  /// apropiados para mostrar al usuario.
  static PaymentErrorDetails parseError(String rawError) {
    final cleanError = rawError.toLowerCase();
    
    String title = "TRANSACCIÓN RECHAZADA";
    String msg = "Tu banco rechazó la operación. Por favor, contacta a tu banco o intenta con otra tarjeta.";

    if (cleanError.contains('insufficient_funds') || cleanError.contains('fondos')) {
      title = "FONDOS INSUFICIENTES";
      msg = "Tu tarjeta no tiene saldo suficiente para completar esta operación.";
    } else if (cleanError.contains('security_code') || cleanError.contains('cvv')) {
      title = "CÓDIGO DE SEGURIDAD INVÁLIDO";
      msg = "El CVV ingresado es incorrecto. Verifique el dorso de su tarjeta.";
    } else if (cleanError.contains('expiry') || cleanError.contains('expiration')) {
      title = "TARJETA VENCIDA";
      msg = "La fecha de expiración de la tarjeta no es válida.";
    } else if (cleanError.contains('call_for_authorize') || cleanError.contains('autorizar')) {
      title = "AUTORIZACIÓN REQUERIDA";
      msg = "Tu banco requiere que autorices esta compra. Contacta al número de atención al cliente de tu banco.";
    } else if (cleanError.contains('network') || cleanError.contains('connection')) {
      title = "ERROR DE ENLACE";
      msg = "No se pudo establecer conexión segura con la pasarela de pagos. Intente nuevamente.";
    }

    return PaymentErrorDetails(title: title, message: msg);
  }
}
