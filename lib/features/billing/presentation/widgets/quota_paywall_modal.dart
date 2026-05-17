// Archivo: lib/features/billing/presentation/widgets/quota_paywall_modal.dart
//
// T4·55 — QuotaPaywallModal (Hangar OS redesign)
//
// Modal que se muestra cuando el usuario intenta crear un recurso pero su plan
// actual no lo permite. Presenta un resumen claro del límite alcanzado y una
// comparación entre el plan actual y el siguiente disponible.
//
// Diseño: Dialog en desktop (ancho ≥ 600) con blur de scrim, o
// ModalBottomSheet en pantallas angostas. Sin Consumer: todos los datos se
// pasan como parámetros (no necesita Riverpod).

import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/buttons/app_button.dart';
import 'package:botslode/core/ui/hud/hud_chamfer.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/quota/quota_result.dart';
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
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: AppColors.scrim,
      transitionDuration: AppMotion.durBase,
      transitionBuilder: (ctx, animation, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4 * animation.value,
            sigmaY: 4 * animation.value,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  ),
                ),
              ),
              modal,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget interno (StatefulWidget para animación de entrada)
// ---------------------------------------------------------------------------

class _QuotaPaywallModal extends StatefulWidget {
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

  @override
  State<_QuotaPaywallModal> createState() => _QuotaPaywallModalState();
}

class _QuotaPaywallModalState extends State<_QuotaPaywallModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final List<Plan> _sortedPlans;

  // Stagger para la columna derecha
  bool _showRightColumn = false;

  @override
  void initState() {
    super.initState();
    _sortedPlans = [...widget.plans]
      ..sort((a, b) => a.priceMonthly.compareTo(b.priceMonthly));
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durSlow,
    );

    final curved = CurvedAnimation(
      parent: _ctrl,
      curve: AppMotion.easeEntrance,
    );
    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(curved);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6),
      ),
    );

    _ctrl.forward();

    // Stagger: la columna derecha aparece después de durStagger.
    Future.delayed(AppMotion.durStagger, () {
      if (mounted) setState(() => _showRightColumn = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers de dominio
  // -------------------------------------------------------------------------

  /// Devuelve el siguiente plan al actual (ya ordenado en initState).
  /// Retorna null si el plan actual es el más caro (tier máximo).
  Plan? _nextPlan() {
    if (_sortedPlans.isEmpty) return null;
    if (widget.currentPlanId == null) {
      return _sortedPlans.first;
    }
    final currentIndex =
        _sortedPlans.indexWhere((p) => p.id == widget.currentPlanId);
    if (currentIndex < 0) return _sortedPlans.first;
    if (currentIndex >= _sortedPlans.length - 1) return null;
    return _sortedPlans[currentIndex + 1];
  }

  Plan? _currentPlan() {
    if (widget.currentPlanId == null) return null;
    try {
      return widget.plans.firstWhere((p) => p.id == widget.currentPlanId);
    } catch (_) {
      return null;
    }
  }


  // -------------------------------------------------------------------------
  // Build principal
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    final content = _buildContent(context);

    if (reduced) {
      // Reduced motion: sólo fade, sin escala ni stagger.
      return FadeTransition(
        opacity: _opacity,
        child: content,
      );
    }

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: content,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final current = _currentPlan();
    final next = _nextPlan();

    return _ModalContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ───────────────────────────────────────────────────
          _buildHeader(),
          const SizedBox(height: AppDimens.space16),
          const HudDivider(),
          const SizedBox(height: AppDimens.space16),

          // ── Cuerpo / copy ─────────────────────────────────────────────────
          _buildBodyCopy(),
          const SizedBox(height: AppDimens.space20),

          // ── Columnas de comparación ───────────────────────────────────────
          _buildComparison(
            context: context,
            current: current,
            next: next,
            reduced: reduced,
          ),
          const SizedBox(height: AppDimens.space24),

          // ── Acciones ──────────────────────────────────────────────────────
          _buildActions(context),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Encabezado
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withValues(alpha: 0.10),
              border: Border.all(color: AppColors.warning, width: 1.5),
              boxShadow: AppDimens.glowStatus(AppColors.warning),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.warning,
              size: AppDimens.iconM,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '// LÍMITE DE PLAN',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'LÍMITE ALCANZADO',
                  style: AppTextStyles.titleM.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Body copy con límite destacado
  // -------------------------------------------------------------------------

  Widget _buildBodyCopy() {
    final resourceLabel = widget.resource == 'bots' ? 'bots' : 'conversaciones';
    final quotaMessage =
        'Has alcanzado el límite de $resourceLabel de tu plan actual.';
    final planName = _currentPlan()?.name;
    final planLabel = planName != null ? '"$planName"' : 'actual';
    final limitStr = widget.quota.limit.toString();

    final List<TextSpan> spans;
    if (widget.resource == 'bots') {
      spans = [
        TextSpan(text: 'Tu plan $planLabel permite hasta '),
        TextSpan(
          text: limitStr,
          style: AppTextStyles.hudReadout.copyWith(color: AppColors.gold),
        ),
        const TextSpan(
            text: ' bot(s). Para crear más, pasate a un plan superior.'),
      ];
    } else {
      spans = [
        TextSpan(text: 'Tu plan $planLabel permite hasta '),
        TextSpan(
          text: limitStr,
          style: AppTextStyles.hudReadout.copyWith(color: AppColors.gold),
        ),
        const TextSpan(
            text:
                ' conversación(es) por período. Para continuar, pasate a un plan superior.'),
      ];
    }

    return Semantics(
      label: quotaMessage,
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodyM.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          children: spans,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Columnas de comparación
  // -------------------------------------------------------------------------

  Widget _buildComparison({
    required BuildContext context,
    required Plan? current,
    required Plan? next,
    required bool reduced,
  }) {
    if (current == null && next == null) return const SizedBox.shrink();

    final leftColumn = _CurrentPlanColumn(
      plan: current,
      quota: widget.quota,
      resource: widget.resource,
    );

    Widget rightColumn;
    if (next != null) {
      rightColumn = _NextPlanColumn(plan: next);
    } else {
      rightColumn = const _EnterpriseColumn();
    }

    // Stagger para la columna derecha (omitido en reduced motion)
    final animatedRight = reduced
        ? rightColumn
        : AnimatedOpacity(
            opacity: _showRightColumn ? 1.0 : 0.0,
            duration: AppMotion.durFast,
            child: AnimatedSlide(
              offset: _showRightColumn
                  ? Offset.zero
                  : const Offset(0, 0.04),
              duration: AppMotion.durFast,
              curve: AppMotion.easeEntrance,
              child: rightColumn,
            ),
          );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: leftColumn),
          Container(
            width: 1,
            color: AppColors.borderDefault,
          ),
          Expanded(child: animatedRight),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Acciones
  // -------------------------------------------------------------------------

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Mejorar plan para desbloquear esta función',
          button: true,
          child: AppButton(
            key: const Key('ver_planes_btn'),
            label: 'MEJORAR PLAN',
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.go('/billing');
            },
            variant: AppButtonVariant.primary,
            size: AppButtonSize.lg,
            leadingIcon: Icons.arrow_upward_rounded,
            expand: true,
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        Semantics(
          label: 'Cerrar aviso de límite de uso',
          button: true,
          child: AppButton(
            key: const Key('mas_tarde_btn'),
            label: 'MÁS TARDE',
            onPressed: () => Navigator.of(context).pop(),
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.md,
            expand: true,
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
    return HudCornerBrackets(
      color: AppColors.warning,
      child: HoloPanel(
        padding: const EdgeInsets.all(AppDimens.space24),
        cornerBrackets: false,
        glowAccent: AppColors.warning,
        borderColor: AppColors.warning.withValues(alpha: 0.30),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Columna izquierda: plan actual
// ---------------------------------------------------------------------------

class _CurrentPlanColumn extends StatelessWidget {
  const _CurrentPlanColumn({
    required this.plan,
    required this.quota,
    required this.resource,
  });

  final Plan? plan;
  final QuotaResult quota;
  final String resource;

  @override
  Widget build(BuildContext context) {
    final planName = plan?.name ?? 'SIN PLAN';
    final priceLabel = plan != null
        ? '\$${plan!.priceMonthly.toStringAsFixed(0)}/mes'
        : '\$0/mes';
    final limitLabel = resource == 'bots'
        ? '${quota.limit} bots máx.'
        : '${quota.limit} conv. máx.';

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAN ACTUAL',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            planName,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            priceLabel,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.space8),
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: AppDimens.iconXS,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppDimens.space4),
              Text(
                limitLabel,
                style: AppTextStyles.bodyS.copyWith(color: AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Columna derecha: plan sugerido (upgrade)
// ---------------------------------------------------------------------------

class _NextPlanColumn extends StatelessWidget {
  const _NextPlanColumn({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: AppDimens.glowGold,
      ),
      child: ChamferBox(
        chamfer: AppDimens.chamferM,
        fillColor: AppColors.gold.withValues(alpha: 0.05),
        border: const BorderSide(color: AppColors.borderGold, width: 1.5),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge "RECOMENDADO"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.borderGold),
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusPill),
                ),
                child: Text(
                  'RECOMENDADO',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gold,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space4),
              Text(
                'MEJORAR A',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.gold,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                plan.name,
                style:
                    AppTextStyles.label.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppDimens.space8),
              // Precio con flecha
              Row(
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    size: AppDimens.iconXS,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppDimens.space4),
                  Text(
                    '\$${plan.priceMonthly.toStringAsFixed(0)}/mes',
                    style: AppTextStyles.hudReadout
                        .copyWith(color: AppColors.gold),
                  ),
                ],
              ),
              if (plan.description != null) ...[
                const SizedBox(height: AppDimens.space8),
                Text(
                  plan.description!,
                  style: AppTextStyles.bodyS
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Columna derecha: caso enterprise (sin plan superior)
// ---------------------------------------------------------------------------

class _EnterpriseColumn extends StatelessWidget {
  const _EnterpriseColumn();

  @override
  Widget build(BuildContext context) {
    return ChamferBox(
      fillColor: AppColors.surfaceHud,
      border: const BorderSide(color: AppColors.borderDefault),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PLAN ENTERPRISE',
              style:
                  AppTextStyles.label.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Contactá a soporte para ampliar tus límites.',
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
