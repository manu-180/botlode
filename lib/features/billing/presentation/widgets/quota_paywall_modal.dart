// Archivo: lib/features/billing/presentation/widgets/quota_paywall_modal.dart
//
// T4·20 — QuotaPaywallModal
//
// Modal que se muestra cuando el usuario intenta crear un recurso pero su plan
// actual no lo permite. Presenta un resumen claro del límite alcanzado y una
// tabla comparativa entre el plan actual y el siguiente disponible.
//
// Diseño: Dialog en desktop (ancho ≥ 600) o ModalBottomSheet en pantallas angostas.
// Sin Consumer: todos los datos se pasan como parámetros (no necesita Riverpod).

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/quota/quota_result.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Punto de entrada público
// ---------------------------------------------------------------------------

/// Muestra el modal de paywall cuando se supera la cuota de [resource].
///
/// [quota]         — resultado de la verificación de cuota (allow = false).
/// [resource]      — `'bots'` o `'conversations'`; determina el copy.
/// [plans]         — lista completa de planes públicos, ordenada por precio asc.
/// [currentPlanId] — ID del plan activo del tenant (puede ser null si no tiene suscripción).
Future<void> showQuotaPaywallModal(
  BuildContext context, {
  required QuotaResult quota,
  required String resource,
  required List<Plan> plans,
  String? currentPlanId,
}) async {
  final isDesktop = MediaQuery.of(context).size.width >= 600;

  final modal = _QuotaPaywallModal(
    quota: quota,
    resource: resource,
    plans: plans,
    currentPlanId: currentPlanId,
  );

  if (isDesktop) {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: modal,
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: modal,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget interno
// ---------------------------------------------------------------------------

class _QuotaPaywallModal extends StatelessWidget {
  const _QuotaPaywallModal({
    required this.quota,
    required this.resource,
    required this.plans,
    this.currentPlanId,
  });

  final QuotaResult quota;
  final String resource;
  final List<Plan> plans;
  final String? currentPlanId;

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Ordena los planes por precio y determina el "siguiente" al plan actual.
  ///
  /// Devuelve `null` si el plan actual es el más caro (usuario en el tier máximo).
  Plan? _nextPlan() {
    if (plans.isEmpty) return null;
    final sorted = [...plans]..sort((a, b) => a.priceCents.compareTo(b.priceCents));
    if (currentPlanId == null) {
      // Sin plan asignado → el primer plan de pago (o el único disponible).
      return sorted.isNotEmpty ? sorted.first : null;
    }
    final currentIndex = sorted.indexWhere((p) => p.id == currentPlanId);
    if (currentIndex < 0) return sorted.isNotEmpty ? sorted.first : null;
    if (currentIndex >= sorted.length - 1) return null; // ya está en el máximo
    return sorted[currentIndex + 1];
  }

  Plan? _currentPlan() {
    if (currentPlanId == null) return null;
    try {
      return plans.firstWhere((p) => p.id == currentPlanId);
    } catch (_) {
      return null;
    }
  }

  String _bodyCopy() {
    final planName = _currentPlan()?.name;
    final planLabel = planName != null ? '"$planName"' : 'actual';
    if (resource == 'bots') {
      return 'Tu plan $planLabel permite hasta ${quota.limit} bot(s). '
          'Para crear más, pasate a un plan superior.';
    }
    return 'Tu plan $planLabel permite hasta ${quota.limit} conversación(es) '
        'por período. Para continuar, pasate a un plan superior.';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _ModalContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, colorScheme),
          const SizedBox(height: 16),
          _buildBodyCopy(theme),
          const SizedBox(height: 20),
          _buildComparisonTable(context, colorScheme),
          const SizedBox(height: 28),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: colorScheme.error,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Límite alcanzado',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyCopy(ThemeData theme) {
    final resourceLabel = resource == 'bots' ? 'bots' : 'conversaciones';
    final quotaMessage =
        'Has alcanzado el límite de $resourceLabel. Actualiza tu plan para continuar.';
    return Semantics(
      label: quotaMessage,
      child: Text(
        _bodyCopy(),
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, ColorScheme colorScheme) {
    final current = _currentPlan();
    final next = _nextPlan();

    if (current == null && next == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
        },
        children: [
          _tableHeaderRow(colorScheme),
          if (current != null)
            _tablePlanRow(
              plan: current,
              isHighlighted: true,
              badge: null,
              colorScheme: colorScheme,
            ),
          if (next != null)
            _tablePlanRow(
              plan: next,
              isHighlighted: false,
              badge: 'Recomendado',
              colorScheme: colorScheme,
            ),
          if (next == null && current != null)
            _contactSupportRow(colorScheme),
        ],
      ),
    );
  }

  TableRow _tableHeaderRow(ColorScheme colorScheme) {
    return TableRow(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      children: [
        _tableHeaderCell('Plan', colorScheme),
        _tableHeaderCell('Bots', colorScheme),
        _tableHeaderCell('Convers.', colorScheme),
      ],
    );
  }

  Widget _tableHeaderCell(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TableRow _tablePlanRow({
    required Plan plan,
    required bool isHighlighted,
    required String? badge,
    required ColorScheme colorScheme,
  }) {
    final bgColor = isHighlighted
        ? colorScheme.surfaceContainerLow.withValues(alpha: 0.6)
        : colorScheme.primaryContainer.withValues(alpha: 0.15);

    return TableRow(
      decoration: BoxDecoration(color: bgColor),
      children: [
        _tablePlanNameCell(plan, badge, colorScheme),
        _tableCountCell('${plan.maxBots}', colorScheme),
        _tableCountCell('${plan.maxConversations}', colorScheme),
      ],
    );
  }

  Widget _tablePlanNameCell(Plan plan, String? badge, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            plan.name,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tableCountCell(String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        value,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 13,
        ),
      ),
    );
  }

  TableRow _contactSupportRow(ColorScheme colorScheme) {
    return TableRow(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.15),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            'Plan Enterprise',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            'Contactar soporte',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Actualizar plan para desbloquear esta función',
          button: true,
          child: FilledButton(
            key: const Key('ver_planes_btn'),
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.go('/billing');
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              AppStrings.billingPaywallViewPlans,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Cerrar aviso de límite de uso',
          button: true,
          child: TextButton(
            key: const Key('mas_tarde_btn'),
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(AppStrings.billingPaywallLater),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Contenedor decorativo del modal
// ---------------------------------------------------------------------------

class _ModalContainer extends StatelessWidget {
  const _ModalContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }
}
