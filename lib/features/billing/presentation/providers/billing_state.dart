// Archivo: lib/features/billing/presentation/providers/billing_state.dart
//
// BillingState para BillingV2Notifier (T4).
// Estado inmutable con freezed que agrega datos de todas las capas del dominio
// de facturación: suscripción activa, catálogo de planes, métodos de pago
// y facturas. Compatible con el AsyncNotifier de Riverpod.
//
// NOTA: No reemplaza a BillingState (definido en billing_provider.dart) que
// sigue siendo usado por el legacy Billing notifier.

import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_state.freezed.dart';

@freezed
class BillingV2State with _$BillingV2State {
  const factory BillingV2State({
    /// Suscripción activa del tenant (trialing, active o past_due).
    /// `null` si el tenant no tiene suscripción vigente.
    Subscription? subscription,

    /// Lista de planes públicos disponibles ordenados por precio ascendente.
    @Default(<Plan>[]) List<Plan> availablePlans,

    /// Métodos de pago activos del tenant (no eliminados).
    @Default(<PaymentMethod>[]) List<PaymentMethod> paymentMethods,

    /// ID del método de pago marcado como predeterminado.
    String? defaultPaymentMethodId,

    /// Página más reciente de facturas del tenant.
    @Default(<Invoice>[]) List<Invoice> invoices,

    /// Indica operación asíncrona optimista en curso (mutaciones).
    @Default(false) bool isLoading,

    /// Código de error estructurado de [BillingRepositoryException] o stub.
    String? errorCode,

    /// Mensaje legible del último error ocurrido.
    String? errorMessage,

    /// Preview de prorrateo generado localmente antes de confirmar cambio de plan.
    ProrationOutput? pendingProration,
  }) = _BillingV2State;
}
