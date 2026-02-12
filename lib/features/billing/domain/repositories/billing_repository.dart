// Archivo: lib/features/billing/domain/repositories/billing_repository.dart
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:botslode/features/billing/domain/models/transaction.dart';

abstract class BillingRepository {
  /// Obtiene el historial completo de transacciones.
  Future<List<BotTransaction>> getTransactions();

  /// Obtiene las tarjetas vinculadas del usuario.
  Future<List<CardInfo>> getCards();

  /// Obtiene la cotización del Dólar Blue (para referencia UI).
  Future<double> getDolarBlueRate();

  /// Cuenta todos los bots (activos y desactivados) para calcular el límite del pozo (total × 60).
  Future<int> getQualifiedBotCount();

  /// Actualiza el límite de autopago de una tarjeta específica.
  Future<void> updateAutoPayThreshold(String cardId, double amount);

  /// Procesa un pago real contra la pasarela (vía Edge Function).
  Future<void> processPayment({required double amountUSD, required String cardId});

  /// Establece una tarjeta como predeterminada.
  Future<void> setPrimaryCard(String cardId);

  /// Orquesta la tokenización (MercadoPago) y el guardado seguro (Supabase).
  Future<void> linkCard({
    required String number,
    required String month,
    required String year,
    required String cvv,
    required String holder,
    required String brand,
    required String lastFour,
    required String email,
  });

  /// Elimina una tarjeta del sistema.
  Future<void> deleteCard(String cardId);

  /// Genera un link de pago externo.
  Future<String> createCheckoutLink(double amount);

  /// Registra un cargo administrativo (ciclo de bot) en la DB.
  Future<void> registerCycleCharge({
    required String botId,
    required String botName,
    required double amount,
    required String userId,
  });
}