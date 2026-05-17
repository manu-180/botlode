// Archivo: lib/features/billing/presentation/widgets/proration_preview_modal.dart
//
// T4·56 — ProrationPreviewModal · Rediseño HUD «Hangar OS»
//
// Panel de cómputo de prorrateo: hoja de cálculo HUD con crédito, cargo y total
// animado (HudTicker). Banda «antes → después» de plan. Variante modal de HoloPanel.
//
// Lógica conservada: previewProration, changePlan, idempotencyKey, BillingException.

import 'dart:ui';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_chamfer.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/hud/hud_ticker.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

Future<void> showProrationPreviewModal(
  BuildContext context,
  WidgetRef ref,
  String targetPlanId,
) async {
  final isDesktop = MediaQuery.of(context).size.width >= 600;
  final container = ProviderScope.containerOf(context);

  final modal = UncontrolledProviderScope(
    container: container,
    child: _ProrationPreviewModal(targetPlanId: targetPlanId),
  );

  if (isDesktop) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.scrim,
      builder: (_) => modal,
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => modal,
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widget
// ---------------------------------------------------------------------------

class _ProrationPreviewModal extends ConsumerStatefulWidget {
  const _ProrationPreviewModal({required this.targetPlanId});

  final String targetPlanId;

  @override
  ConsumerState<_ProrationPreviewModal> createState() =>
      _ProrationPreviewModalState();
}

class _ProrationPreviewModalState extends ConsumerState<_ProrationPreviewModal>
    with SingleTickerProviderStateMixin {
  // ── Preview state ──────────────────────────────────────────────────────────
  bool _loadingPreview = true;
  ProrationOutput? _preview;
  String? _previewError;

  // ── Confirm state ──────────────────────────────────────────────────────────
  bool _confirming = false;
  String? _mutationError;

  // ── Entry animation ────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  static const _kDisclaimer =
      'El cálculo final lo confirma la pasarela; pueden existir diferencias mínimas.';

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: AppMotion.durBase);
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: AppMotion.easeEntrance);
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: AppMotion.easeEntrance));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _entryCtrl.duration = AppMotion.durCrossfadeReduced;
      }
      _entryCtrl.forward();
    });

    _loadPreview();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  Future<void> _loadPreview() async {
    setState(() {
      _loadingPreview = true;
      _previewError = null;
      _preview = null;
    });

    try {
      final output = await ref
          .read(billingV2Provider.notifier)
          .previewProration(widget.targetPlanId);
      if (!mounted) return;
      setState(() {
        _preview = output;
        _loadingPreview = false;
      });
    } on BillingException catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.message;
        _loadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.toString();
        _loadingPreview = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_preview == null) return;

    final idempotencyKey = const Uuid().v4();

    setState(() {
      _confirming = true;
      _mutationError = null;
    });

    try {
      await ref
          .read(billingV2Provider.notifier)
          .changePlan(widget.targetPlanId, idempotencyKey);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.billingProrationSuccess)),
      );
    } on BillingException catch (e) {
      if (!mounted) return;
      if (e.code == 'not_implemented') {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.billingProrationComingSoon)),
        );
      } else {
        setState(() {
          _mutationError = e.message;
          _confirming = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mutationError = e.toString();
        _confirming = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final reduced = AppMotion.reduced(context);

    Widget panel = _buildAnimatedPanel(reduced);

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: panel,
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: panel,
      ),
    );
  }

  Widget _buildAnimatedPanel(bool reduced) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) {
        final t = _fadeAnim.value;
        final scale = reduced ? 1.0 : _scaleAnim.value;
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: _buildGlassPanel(),
    );
  }

  Widget _buildGlassPanel() {
    return HudCornerBrackets(
      color: AppColors.borderGold,
      armLength: 18,
      thickness: 1.0,
      child: ClipRRect(
        borderRadius: AppDimens.brXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassSurfaceStrong,
              borderRadius: AppDimens.brXL,
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: AppDimens.elev3,
            ),
            child: Stack(
              children: [
                // Top highlight hairline
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.glassHighlightTop,
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDimens.radiusXL),
                        topRight: Radius.circular(AppDimens.radiusXL),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppDimens.space24),
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: AppDimens.space20),
        _buildBeforeAfterBand(),
        const SizedBox(height: AppDimens.space20),
        AnimatedSwitcher(
          duration: AppMotion.durBase,
          switchInCurve: AppMotion.easeStandard,
          switchOutCurve: AppMotion.easeStandard,
          child: _loadingPreview
              ? _buildSkeleton()
              : _previewError != null
                  ? _buildPreviewError()
                  : _buildHudSpreadsheet(_preview!),
        ),
        if (_mutationError != null) ...[
          const SizedBox(height: AppDimens.space12),
          _buildMutationError(_mutationError!),
        ],
        const SizedBox(height: AppDimens.space16),
        _buildDisclaimer(),
        const SizedBox(height: AppDimens.space24),
        _buildActions(),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        // Chip biselado 40×40 con ícono swap
        Container(
          width: 40,
          height: 40,
          decoration: const ShapeDecoration(
            shape: ChamferBorder(
              chamfer: AppDimens.chamferM,
              side: BorderSide(
                color: AppColors.borderGold,
                width: 1,
              ),
            ),
            color: AppColors.goldGlow,
          ),
          child: const Center(
            child: Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'CAMBIO DE PLAN',
                  style: AppTextStyles.titleL,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Revisá el detalle antes de confirmar',
                style: AppTextStyles.bodyS,
              ),
            ],
          ),
        ),
        AppIconButton(
          icon: Icons.close_rounded,
          onPressed: _confirming ? null : () => Navigator.of(context).pop(),
          tooltip: 'Cerrar',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
        ),
      ],
    );
  }

  // ── Before → After band ────────────────────────────────────────────────────

  Widget _buildBeforeAfterBand() {
    final billingState = ref.watch(billingV2Provider).valueOrNull;
    final currentPlan = billingState?.availablePlans
        .where((p) => p.id == (billingState.subscription?.planId ?? ''))
        .firstOrNull;
    final targetPlan = billingState?.availablePlans
        .where((p) => p.id == widget.targetPlanId)
        .firstOrNull;

    Widget band;
    if (_loadingPreview) {
      band = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonBase(width: 100, height: 32, radius: AppDimens.radiusPill),
          SizedBox(width: AppDimens.space12),
          SkeletonBase(width: 24, height: 24, shape: BoxShape.circle),
          SizedBox(width: AppDimens.space12),
          SkeletonBase(width: 100, height: 32, radius: AppDimens.radiusPill),
        ],
      );
    } else {
      band = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PlanCapsule(
            name: currentPlan?.name ?? '—',
            energized: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
            child: _buildArrow(),
          ),
          _PlanCapsule(
            name: targetPlan?.name ?? widget.targetPlanId,
            energized: true,
          ),
        ],
      );
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brM,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
      child: band,
    );
  }

  Widget _buildArrow() {
    final reduced = AppMotion.reduced(context);

    Widget arrow = const Icon(
      Icons.arrow_forward_rounded,
      color: AppColors.cyan,
      size: 18,
    );

    if (!reduced && !_loadingPreview) {
      arrow = arrow
          .animate()
          .moveX(
            begin: -4,
            end: 0,
            duration: AppMotion.durFast,
            curve: AppMotion.easeStandard,
          );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.cyanGlow,
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: arrow,
    );
  }

  // ── HUD Spreadsheet ────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Column(
      key: const ValueKey('skeleton'),
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.surfaceHud,
            borderRadius: AppDimens.brM,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              _buildSkeletonRow(),
              const SizedBox(height: AppDimens.space8),
              const HudDivider(),
              const SizedBox(height: AppDimens.space8),
              _buildSkeletonRow(),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        const HudDivider(),
        const SizedBox(height: AppDimens.space12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBase(width: 140, height: 14),
            SkeletonBase(width: 80, height: 28),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonRow() {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBase(height: 14),
              SizedBox(height: 4),
              SkeletonBase(height: 11, width: 120),
            ],
          ),
        ),
        SizedBox(width: AppDimens.space16),
        SkeletonBase(width: 70, height: 14),
      ],
    );
  }

  Widget _buildPreviewError() {
    return ErrorFeedbackCard(
      key: const ValueKey('preview-error'),
      title: 'Error al calcular el prorrateo',
      message: _previewError!,
      onRetry: () async => _loadPreview(),
      retryLabel: 'Reintentar',
      variant: ErrorVariant.inline,
    );
  }

  Widget _buildHudSpreadsheet(ProrationOutput output) {
    final billingState = ref.watch(billingV2Provider).valueOrNull;
    final subscription = billingState?.subscription;
    final periodEnd = subscription?.currentPeriodEnd;
    final reduced = AppMotion.reduced(context);

    // Build accessibility description
    final creditStr =
        '\$${output.creditAmount.toStringAsFixed(2)} de crédito por días no usados del plan actual';
    final chargeStr =
        '\$${output.chargeAmount.toStringAsFixed(2)} de cargo por el nuevo plan';
    final netStr =
        'Total a cobrar hoy: \$${output.netAmount.abs().toStringAsFixed(2)}';
    final prorationDescription =
        'Ajuste de precio: $creditStr, $chargeStr. $netStr';

    final now = DateTime.now();
    final creditEnd = periodEnd ?? now.add(Duration(days: output.daysRemaining));
    final chargeEnd = creditEnd;

    return Semantics(
      label: prorationDescription,
      child: Column(
        key: const ValueKey('spreadsheet'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spreadsheet container
          Container(
            padding: const EdgeInsets.all(AppDimens.space16),
            decoration: BoxDecoration(
              color: AppColors.surfaceHud,
              borderRadius: AppDimens.brM,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _buildLineRow(
                  index: 0,
                  description: 'Crédito plan actual',
                  dateFrom: now,
                  dateTo: creditEnd,
                  amount: output.creditAmount,
                  isCredit: true,
                  reduced: reduced,
                ),
                const SizedBox(height: AppDimens.space4),
                const HudDivider(),
                const SizedBox(height: AppDimens.space4),
                _buildLineRow(
                  index: 1,
                  description: 'Cargo nuevo plan',
                  dateFrom: now,
                  dateTo: chargeEnd,
                  amount: output.chargeAmount,
                  isCredit: false,
                  reduced: reduced,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.space12),

          // Total divider with node
          const HudDivider(),

          const SizedBox(height: AppDimens.space12),

          // Total row
          _buildTotalRow(output, reduced: reduced),

          // Next period
          if (periodEnd != null) ...[
            const SizedBox(height: AppDimens.space8),
            _buildNextPeriodRow(periodEnd),
          ],
        ],
      ),
    );
  }

  Widget _buildLineRow({
    required int index,
    required String description,
    required DateTime dateFrom,
    required DateTime dateTo,
    required double amount,
    required bool isCredit,
    required bool reduced,
  }) {
    final color = isCredit ? AppColors.success : AppColors.warning;
    final prefix = isCredit ? '−' : '+';
    final prefixIcon = isCredit ? Icons.remove_rounded : Icons.add_rounded;
    final formatted =
        '\$${amount.toStringAsFixed(2)}';

    Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: AppTextStyles.bodyM,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateRange(dateFrom, dateTo),
                  style: AppTextStyles.mono.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(prefixIcon, color: color, size: 12),
              const SizedBox(width: 2),
              Text(
                '$prefix$formatted',
                style: AppTextStyles.hudReadout.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );

    if (!reduced) {
      row = row
          .animate(delay: AppMotion.staggerDelay(index))
          .fadeIn(
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          )
          .moveY(
            begin: 12,
            end: 0,
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          );
    }

    return row;
  }

  Widget _buildTotalRow(ProrationOutput output, {required bool reduced}) {
    final isCharge = output.netAmount >= 0;
    final color = isCharge ? AppColors.gold : AppColors.success;
    final glowColor = isCharge ? AppColors.goldGlow : AppColors.successGlow;

    return Semantics(
      label: 'Total a cobrar hoy: \$${output.netAmount.abs().toStringAsFixed(2)}',
      child: Row(
        children: [
          Expanded(
            child: Text(
              'TOTAL A COBRAR HOY',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: HudTicker(
              value: output.netAmount.abs(),
              prefix: '\$',
              decimals: 2,
              style: AppTextStyles.numericTicker.copyWith(color: color),
              animate: !reduced,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPeriodRow(DateTime periodEnd) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          color: AppColors.textTertiary,
          size: 13,
        ),
        const SizedBox(width: AppDimens.space8),
        Expanded(
          child: Text(
            'Próximo cobro completo: ${fmt.format(periodEnd)}',
            style: AppTextStyles.bodyS,
          ),
        ),
      ],
    );
  }

  // ── Mutation error ─────────────────────────────────────────────────────────

  Widget _buildMutationError(String message) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space12,
          vertical: AppDimens.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.dangerGlow.withValues(alpha: 0.3),
          borderRadius: AppDimens.brS,
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: AppDimens.iconS,
            ),
            const SizedBox(width: AppDimens.space8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Disclaimer ─────────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brS,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textTertiary,
            size: 15,
          ),
          const SizedBox(width: AppDimens.space8),
          Expanded(
            child: Text(
              _kDisclaimer,
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Widget _buildActions() {
    final canConfirm = !_loadingPreview &&
        _previewError == null &&
        _preview != null &&
        !_confirming;

    final billingState = ref.watch(billingV2Provider).valueOrNull;
    final targetPlan = billingState?.availablePlans
        .where((p) => p.id == widget.targetPlanId)
        .firstOrNull;
    final targetPlanName = targetPlan?.name ?? widget.targetPlanId;
    final targetPlanPrice = targetPlan != null
        ? '\$${targetPlan.priceMonthly.toStringAsFixed(2)}/mes'
        : '';
    final confirmLabel = _confirming
        ? 'Procesando cambio de plan, por favor espere'
        : 'Confirmar cambio de plan a $targetPlanName'
            '${targetPlanPrice.isNotEmpty ? ' por $targetPlanPrice' : ''}';

    return Row(
      children: [
        Expanded(
          child: AppButton.ghost(
            label: AppStrings.billingProrationCancel,
            onPressed: _confirming ? null : () => Navigator.of(context).pop(),
            size: AppButtonSize.md,
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Semantics(
            label: confirmLabel,
            liveRegion: _confirming,
            child: AppButton.primary(
              label: 'CONFIRMAR CAMBIO',
              onPressed: canConfirm ? _confirm : null,
              size: AppButtonSize.md,
              loading: _confirming,
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('dd/MM/yyyy');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}

// ---------------------------------------------------------------------------
// Plan capsule (before/after band)
// ---------------------------------------------------------------------------

class _PlanCapsule extends StatelessWidget {
  const _PlanCapsule({
    required this.name,
    required this.energized,
  });

  final String name;
  final bool energized;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    Widget capsule = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: energized
            ? AppColors.goldGlow.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: AppDimens.brPill,
        border: Border.all(
          color: energized ? AppColors.borderGold : AppColors.borderDefault,
          width: 1,
        ),
        boxShadow: energized
            ? const [
                BoxShadow(
                  color: AppColors.goldGlow,
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Text(
        name.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: energized ? AppColors.gold : AppColors.textTertiary,
          fontSize: 11,
        ),
      ),
    );

    // Glow pulse on reveal for destination capsule
    if (energized && !reduced) {
      capsule = capsule
          .animate()
          .custom(
            duration: AppMotion.durBase,
            curve: Curves.easeOut,
            builder: (context, value, child) => child,
          )
          .fadeIn(
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          );
    }

    return capsule;
  }
}
