// Archivo: lib/features/dashboard/domain/exceptions/credit_limit_reached_exception.dart

/// Excepción lanzada cuando el usuario intenta activar un bot
/// pero ha alcanzado su límite de crédito.
class CreditLimitReachedException implements Exception {
  const CreditLimitReachedException();

  @override
  String toString() =>
      'CreditLimitReachedException: Has alcanzado tu límite de crédito. Realiza un pago para poder activar más bots.';
}
