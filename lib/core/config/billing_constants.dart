// Archivo: lib/core/config/billing_constants.dart
//
// Fuente única de verdad para los parámetros económicos del producto.
// Antes el precio del ciclo estaba duplicado en:
//   - features/dashboard/presentation/providers/bots_provider.dart (CYCLE_PRICE)
//   - features/dashboard/domain/models/bot.dart (_CYCLE_PRICE)
// Si se actualizaba uno y no el otro la deuda mostrada divergía del cargo real.

/// Precio en USD que se cobra por cada bot al cerrar un ciclo (30 días).
/// Cualquier cambio acá impacta cálculo de deuda, autopago y UI de billing.
const double kCyclePriceUsd = 20.00;

/// Crédito disponible por bot existente (cap suave para evitar deuda inmanejable).
/// Manejado por `billing_provider` al calcular `creditLimit`.
const double kCreditLimitPerBotUsd = 60.00;

/// Duración de un ciclo en días reales (no turbo).
const int kCycleDurationDays = 30;
