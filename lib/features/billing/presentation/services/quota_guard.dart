// Archivo: lib/features/billing/presentation/services/quota_guard.dart
//
// T4·20 — QuotaGuard
//
// Servicio de presentación que verifica cuotas antes de permitir una acción
// y muestra el QuotaPaywallModal cuando el límite está alcanzado.
//
// Uso:
//   final guard = ref.read(quotaGuardProvider);
//   final canProceed = await guard.canCreate(context, resource: 'bots');
//   if (!canProceed) return; // el modal ya se mostró

import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/features/billing/data/quota/quota_service_impl.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/quota/quota_action.dart';
import 'package:botslode/features/billing/domain/quota/quota_service.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_repository_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/quota_paywall_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Provider de [QuotaService] para inyección en [QuotaGuard] y en tests.
///
/// Usa [QuotaServiceImpl] con el cliente de Supabase y los repositorios T3.
/// Sin @riverpod: sigue el estilo de billing_repository_provider.dart.
final quotaServiceProvider = Provider<QuotaService>((ref) {
  return QuotaServiceImpl(
    client: Supabase.instance.client,
    subscriptionsRepo: ref.read(subscriptionsRepositoryProvider),
    plansRepo: ref.read(plansRepositoryProvider),
  );
});

/// Provider de [QuotaGuard] para inyección en widgets y tests.
final quotaGuardProvider = Provider<QuotaGuard>((ref) => QuotaGuard(ref));

// ---------------------------------------------------------------------------
// Mapeo resource → QuotaAction
// ---------------------------------------------------------------------------

QuotaAction? _actionForResource(String resource) {
  switch (resource) {
    case 'bots':
      return QuotaAction.createBot;
    case 'conversations':
      return QuotaAction.recordConversation;
    default:
      return null;
  }
}

// ---------------------------------------------------------------------------
// QuotaGuard
// ---------------------------------------------------------------------------

/// Servicio de presentación que verifica cuotas y muestra el paywall si es
/// necesario antes de que el usuario realice una acción limitada por el plan.
///
/// Almacena un [Ref] para leer providers sin necesidad de un [WidgetRef].
class QuotaGuard {
  QuotaGuard(this._ref);

  final Ref _ref;

  /// Verifica si el usuario actual puede realizar una acción sobre [resource].
  ///
  /// Valores aceptados para [resource]:
  ///   - `'bots'`          → [QuotaAction.createBot]
  ///   - `'conversations'` → [QuotaAction.recordConversation]
  ///
  /// Retorna `true` si la acción está permitida.
  /// Retorna `false` si el límite está alcanzado; en ese caso muestra
  /// [showQuotaPaywallModal] antes de retornar.
  ///
  /// Si [tenantId] es null (usuario no autenticado), retorna `true` sin bloquear.
  /// Si [resource] es desconocido, retorna `true` para no bloquear por error.
  Future<bool> canCreate(
    BuildContext context, {
    required String resource,
  }) async {
    final tenantId = _ref.read(currentUserIdProvider);
    if (tenantId == null) return true;

    final action = _actionForResource(resource);
    if (action == null) return true;

    final quotaService = _ref.read(quotaServiceProvider);
    final quotaResult = await quotaService.check(tenantId, action);

    if (quotaResult.allow) return true;

    // Cuota superada: intentar obtener datos del plan para la tabla comparativa.
    // Si falla, el modal igual se muestra pero sin la tabla de comparación.
    var plans = <Plan>[];
    String? currentPlanId;
    try {
      final billingState = await _ref.read(billingV2Provider.future);
      plans = billingState.availablePlans;
      currentPlanId = billingState.subscription?.planId;
    } catch (_) {
      // Continúa con tabla vacía; la cuota ya fue negada, no se permite la acción.
    }

    if (!context.mounted) return false;

    await showQuotaPaywallModal(
      context,
      quota: quotaResult,
      resource: resource,
      plans: plans,
      currentPlanId: currentPlanId,
    );

    return false;
  }
}
