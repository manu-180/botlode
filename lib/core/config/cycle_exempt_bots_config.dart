/// Bots exentos del ciclo de cobro de $20 al pozo.
///
/// Estos bots no suman nada al ciclo, no generan transacciones cycle_charge
/// y su balance/deuda se mantiene siempre en 0.
class CycleExemptBotsConfig {
  CycleExemptBotsConfig._();

  /// IDs de bots que no contribuyen al pozo (no cargan $20 por ciclo).
  static const Set<String> exemptBotIds = {
    '0038971a-da75-4ddc-8663-d52a6b8f2936',
    '0b99e786-fa91-42ba-9578-5784f5049140',
  };

  static bool isExempt(String? botId) =>
      botId != null && exemptBotIds.contains(botId);
}
