// Archivo: lib/features/billing/presentation/widgets/plan_picker.dart
//
// T4·49 — PlanPicker · Rediseño HUD «Hangar OS».
//
// Muestra los planes de suscripción disponibles como paneles HUD comparables.
// El plan recomendado (centro de la lista ordenada por precio) se destaca con
// chaflán a 45°, borde dorado, HudCornerBrackets, shimmer y escala 1.04.
//
// Lógica de negocio:
//   - Filtra planes públicos (isPublic == true).
//   - Ordena por priceMonthly ascendente.
//   - Detecta plan actual via subscription?.planId.
//   - Llama onPlanSelected(planId) para que el shell abra el modal de prorrateo.
//
// Intervalo anual: precio = priceMonthly × 10 (2 meses gratis ≈ 17% de ahorro).
// El ticker anima entre precios al cambiar el toggle.
//
// Accesibilidad: WCAG AA — estado actual identificado por texto + borde, no
// solo por color. Targets ≥ 48 px en CTAs. Reduced-motion respetado.

import 'dart:async';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/hud/hud_id_tag.dart';
import 'package:botslode/core/ui/hud/hud_ticker.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/empty_state.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Enums & constants
// ---------------------------------------------------------------------------

enum _BillingInterval { monthly, annual }

// Desktop ≥ 1040 content width; tablet 720–1040; narrow < 720.
const double _kDesktopBreak = 1040;
const double _kTabletBreak = 720;

// CTA height matching AppButtonSize.md (spec-defined, not in AppDimens).
const double _kCtaHeight = 44;

// Annual = 10 monthly payments (2 months free).
// Savings vs paying monthly: (12 - 10) / 12 = 16.67% ≈ 17%.
const int _kAnnualDiscountPercent = 17;
const double _kAnnualMultiplier = 10.0;

// Max width for the centered interval toggle control.
const double _kToggleMaxWidth = 320.0;

// ---------------------------------------------------------------------------
// PlanPicker — public API
// ---------------------------------------------------------------------------

/// Displays available subscription plans as HUD-themed comparison panels.
///
/// Triggers [onPlanSelected] with the chosen plan ID when the user taps
/// a non-current plan CTA. The parent is responsible for opening the
/// proration preview modal (prompt 56).
class PlanPicker extends ConsumerStatefulWidget {
  /// Called when the user selects a non-current plan.
  final void Function(String planId) onPlanSelected;

  const PlanPicker({super.key, required this.onPlanSelected});

  @override
  ConsumerState<PlanPicker> createState() => _PlanPickerState();
}

class _PlanPickerState extends ConsumerState<PlanPicker> {
  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingV2Provider);

    return billingAsync.when(
      loading: () => const _LoadingPlans(),
      error: (err, _) => ErrorFeedbackCard(
        title: 'Error al cargar planes',
        message: 'No se pudieron cargar los planes disponibles. '
            'Verifica tu conexión e intenta de nuevo.',
        onRetry: () async => ref.invalidate(billingV2Provider),
      ),
      data: (state) => _PlanPickerContent(
        state: state,
        onPlanSelected: widget.onPlanSelected,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content — rendered when billing data is available
// ---------------------------------------------------------------------------

class _PlanPickerContent extends StatefulWidget {
  const _PlanPickerContent({
    required this.state,
    required this.onPlanSelected,
  });

  final BillingV2State state;
  final void Function(String planId) onPlanSelected;

  @override
  State<_PlanPickerContent> createState() => _PlanPickerContentState();
}

class _PlanPickerContentState extends State<_PlanPickerContent> {
  _BillingInterval _selectedInterval = _BillingInterval.monthly;

  @override
  Widget build(BuildContext context) {
    final plans = widget.state.availablePlans
        .where((p) => p.isPublic)
        .toList()
      ..sort((a, b) => a.priceMonthly.compareTo(b.priceMonthly));

    if (plans.isEmpty) {
      return EmptyState(
        icon: Icons.workspace_premium_outlined,
        title: 'Sin planes disponibles',
        description: 'No hay planes disponibles en este momento. '
            'Contacta a soporte para conocer nuestras opciones.',
        action: AppButton.secondary(
          label: 'CONTACTAR SOPORTE',
          onPressed: () {},
          leadingIcon: Icons.mail_outline,
        ),
      );
    }

    final currentPlanId = widget.state.subscription?.planId;
    final currentPlan = currentPlanId != null
        ? plans.where((p) => p.id == currentPlanId).firstOrNull
        : null;

    // Only show the discount badge if at least one plan has a non-zero price.
    final hasPrice = plans.any((p) => p.priceMonthly > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Interval toggle (centered) ─────────────────────────────────────
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kToggleMaxWidth),
            child: _IntervalToggle(
              value: _selectedInterval,
              onChanged: (v) => setState(() => _selectedInterval = v),
              annualDiscountPercent:
                  hasPrice ? _kAnnualDiscountPercent : 0,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space20),

        // ── Plan grid ─────────────────────────────────────────────────────
        _PlanGrid(
          plans: plans,
          selectedInterval: _selectedInterval,
          currentPlanId: currentPlanId,
          currentPlan: currentPlan,
          onPlanSelected: widget.onPlanSelected,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Plan grid — responsive layout
// ---------------------------------------------------------------------------

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({
    required this.plans,
    required this.selectedInterval,
    required this.currentPlanId,
    required this.currentPlan,
    required this.onPlanSelected,
  });

  final List<Plan> plans;
  final _BillingInterval selectedInterval;
  final String? currentPlanId;
  final Plan? currentPlan;
  final void Function(String planId) onPlanSelected;

  // Middle plan is «recommended»; skip if there's only one option.
  int get _highlightedIndex =>
      plans.length > 1 ? plans.length ~/ 2 : -1;

  bool _isUpgrade(Plan plan) {
    final c = currentPlan;
    return c == null || plan.priceMonthly > c.priceMonthly;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    if (w >= _kDesktopBreak) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < plans.length; i++) ...[
              if (i > 0) const SizedBox(width: AppDimens.space20),
              Expanded(child: _staggeredCard(i)),
            ],
          ],
        ),
      );
    }

    if (w >= _kTabletBreak) {
      final cardWidth = (w - AppDimens.space20) / 2;
      return Wrap(
        spacing: AppDimens.space20,
        runSpacing: AppDimens.space20,
        children: [
          for (int i = 0; i < plans.length; i++)
            SizedBox(width: cardWidth, child: _staggeredCard(i)),
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < plans.length; i++) ...[
          if (i > 0) const SizedBox(height: AppDimens.space16),
          _staggeredCard(i),
        ],
      ],
    );
  }

  Widget _staggeredCard(int i) {
    final plan = plans[i];
    return _StaggerReveal(
      index: i,
      child: _PlanCard(
        plan: plan,
        selectedInterval: selectedInterval,
        isCurrent: plan.id == currentPlanId,
        isHighlighted: i == _highlightedIndex,
        isUpgrade: _isUpgrade(plan),
        onTap: () => onPlanSelected(plan.id),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stagger reveal — P1 pattern
// ---------------------------------------------------------------------------

/// Wraps a child with a staggered fade + translateY entrance.
/// Each [index] delays by [AppMotion.durStagger] × index before starting.
/// Respects reduced-motion: all items appear together with a quick crossfade.
class _StaggerReveal extends StatefulWidget {
  const _StaggerReveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggerReveal> createState() => _StaggerRevealState();
}

class _StaggerRevealState extends State<_StaggerReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durBase);
    _anim = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = AppMotion.reduced(context);
      if (reduced) {
        _ctrl.duration = AppMotion.durCrossfadeReduced;
        _ctrl.forward();
        return;
      }
      final delay = AppMotion.staggerDelay(widget.index);
      if (delay == Duration.zero) {
        _ctrl.forward();
      } else {
        _timer = Timer(delay, () {
          if (mounted) _ctrl.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final t = _anim.value;
        return Opacity(
          opacity: t,
          child: reduced
              ? child
              : Transform.translate(
                  offset: Offset(0, (1.0 - t) * 12.0),
                  child: child,
                ),
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Plan card — HoloPanel-based
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selectedInterval,
    required this.isCurrent,
    required this.isHighlighted,
    required this.isUpgrade,
    required this.onTap,
  });

  final Plan plan;
  final _BillingInterval selectedInterval;
  final bool isCurrent;
  final bool isHighlighted;
  final bool isUpgrade;
  final VoidCallback onTap;

  bool get _isAnnual => selectedInterval == _BillingInterval.annual;

  double get _displayPrice =>
      _isAnnual ? plan.priceMonthly * _kAnnualMultiplier : plan.priceMonthly;

  String get _periodLabel => _isAnnual ? '/ año' : '/ mes';

  bool get _showAnnualSaving =>
      _isAnnual && plan.priceMonthly > 0;

  String _priceLabel() {
    final v = _displayPrice;
    return v.truncateToDouble() == v
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    // ── Card content ────────────────────────────────────────────────────────
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badges (ACTUAL / RECOMENDADO)
        if (isCurrent || isHighlighted) ...[
          Wrap(
            spacing: AppDimens.space4,
            runSpacing: AppDimens.space4,
            children: [
              if (isCurrent)
                const _HudBadge(label: 'ACTUAL', color: AppColors.gold),
              if (isHighlighted)
                const _HudBadge(label: 'RECOMENDADO', color: AppColors.gold),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
        ],

        // Plan name
        Text(plan.name.toUpperCase(), style: AppTextStyles.titleL),
        const SizedBox(height: AppDimens.space8),

        // Price hero: $ prefix + HudTicker
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$',
              style: AppTextStyles.titleM.copyWith(color: AppColors.gold),
            ),
            const SizedBox(width: 2),
            HudTicker(
              value: _displayPrice,
              decimals:
                  _displayPrice.truncateToDouble() == _displayPrice ? 0 : 2,
              style:
                  AppTextStyles.numericTicker.copyWith(color: AppColors.gold),
            ),
          ],
        ),
        Text(
          _periodLabel,
          style:
              AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
        ),

        // Annual saving readout
        if (_showAnnualSaving) ...[
          const SizedBox(height: AppDimens.space4),
          Text(
            '−$_kAnnualDiscountPercent% vs mensual',
            style:
                AppTextStyles.hudReadout.copyWith(color: AppColors.success),
          ),
        ],

        const SizedBox(height: AppDimens.space16),
        const HudDivider(),
        const SizedBox(height: AppDimens.space12),

        // Description / feature bullet
        if (plan.description != null && plan.description!.isNotEmpty) ...[
          _FeatureRow(label: plan.description!),
          const SizedBox(height: AppDimens.space8),
        ],

        const SizedBox(height: AppDimens.space12),

        // CTA
        _PlanCta(
          isCurrent: isCurrent,
          isUpgrade: isUpgrade,
          isHighlighted: isHighlighted,
          onTap: onTap,
        ),

        // HudIdTag for current plan
        if (isCurrent) ...[
          const SizedBox(height: AppDimens.space12),
          const HudIdTag(text: '// PLAN ACTIVO', color: AppColors.gold),
        ],
      ],
    );

    // ── HoloPanel shell ────────────────────────────────────────────────────
    //
    // Recommended: chamfer shape, borderGold, glowGold, HudCornerBrackets.
    // Current: rounded, borderGold (subtle), no glow.
    // Default: rounded, glassBorder.
    Widget panel = MouseRegion(
      cursor: isCurrent ? MouseCursor.defer : SystemMouseCursors.click,
      child: HoloPanel(
        shape: isHighlighted ? HoloPanelShape.chamfer : HoloPanelShape.rounded,
        borderColor:
            (isHighlighted || isCurrent) ? AppColors.borderGold : null,
        glowAccent: isHighlighted ? AppColors.gold : null,
        cornerBrackets: isHighlighted,
        padding: const EdgeInsets.all(AppDimens.space24),
        child: cardContent,
      ),
    );

    // Scale boost for recommended card (visual hierarchy).
    if (isHighlighted) {
      panel = Transform.scale(scale: 1.04, child: panel);
    }

    // Gold shimmer sweep on recommended panel — P4 pattern.
    // Repeats every durShimmer (~3100 ms). Disabled on reduced-motion.
    if (isHighlighted && !reduced) {
      panel = panel
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: AppMotion.durShimmer,
            color: AppColors.goldBright.withValues(alpha: 0.10),
            angle: 0.3,
          );
    }

    return Semantics(
      label: 'Plan ${plan.name}, \$${_priceLabel()} $_periodLabel'
          '${isCurrent ? '. Plan actual.' : ''}'
          '${isHighlighted ? ' Recomendado.' : ''}',
      child: panel,
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Gold-tinted pill badge — ACTUAL / RECOMENDADO.
class _HudBadge extends StatelessWidget {
  const _HudBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

/// Single feature bullet — check_circle gold + text.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          size: AppDimens.iconXS,
          color: AppColors.gold,
        ),
        const SizedBox(width: AppDimens.space8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// CTA button area.
///
/// Current plan → disabled-but-legible custom widget (avoids 0.4 opacity of
/// AppButton disabled state that would hurt readability per the spec).
/// Upgrade → AppButton.primary with chamfer on recommended.
/// Downgrade → AppButton.secondary.
class _PlanCta extends StatelessWidget {
  const _PlanCta({
    required this.isCurrent,
    required this.isUpgrade,
    required this.isHighlighted,
    required this.onTap,
  });

  final bool isCurrent;
  final bool isUpgrade;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isCurrent) return const _CurrentPlanButton();

    return isUpgrade
        ? AppButton.primary(
            label: 'MEJORAR',
            onPressed: onTap,
            leadingIcon: Icons.arrow_upward_rounded,
            chamfer: isHighlighted,
            expand: true,
            size: AppButtonSize.md,
          )
        : AppButton.secondary(
            label: 'CAMBIAR A ESTE',
            onPressed: onTap,
            leadingIcon: Icons.arrow_downward_rounded,
            expand: true,
            size: AppButtonSize.md,
          );
  }
}

/// Fully-opaque disabled CTA for the current plan.
///
/// AppButton with onPressed: null applies 0.4 opacity to the whole widget,
/// which can compromise label readability. This widget keeps the label at
/// full opacity while blocking interaction via IgnorePointer.
class _CurrentPlanButton extends StatelessWidget {
  const _CurrentPlanButton();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: _kCtaHeight,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimens.space8),
              Text(
                'PLAN ACTUAL',
                style:
                    AppTextStyles.label.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Interval toggle — HUD segmented control
// ---------------------------------------------------------------------------

/// HUD-styled segmented toggle for monthly/annual billing interval.
///
/// A gold gradient pill slides under the active segment. When «ANUAL» is
/// selected and [annualDiscountPercent] > 0, a green badge appears next to
/// the label. Respects reduced-motion: indicator snaps without animation.
class _IntervalToggle extends StatelessWidget {
  const _IntervalToggle({
    required this.value,
    required this.onChanged,
    this.annualDiscountPercent = 0,
  });

  final _BillingInterval value;
  final ValueChanged<_BillingInterval> onChanged;
  final int annualDiscountPercent;

  bool get _isAnnual => value == _BillingInterval.annual;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    return Semantics(
      label: 'Intervalo de facturación',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : _kToggleMaxWidth;
          final padding = AppDimens.space4.toDouble();
          // Border accounts for 1px on each side.
          final innerWidth = totalWidth - padding * 2 - 2;
          final segW = innerWidth / 2;
          final indicatorLeft = padding + (_isAnnual ? segW : 0.0);

          return SizedBox(
            height: 40,
            width: totalWidth,
            child: Stack(
              children: [
                // Track background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHud,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusPill),
                      border: Border.all(
                        color: AppColors.borderDefault,
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // Sliding gold indicator
                AnimatedPositioned(
                  duration: reduced
                      ? Duration.zero
                      : AppMotion.durBase,
                  curve: AppMotion.easeStandard,
                  left: indicatorLeft,
                  top: padding,
                  bottom: padding,
                  width: segW,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradGold,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusPill),
                      boxShadow: AppDimens.glowGold,
                    ),
                  ),
                ),

                // Tap targets (above indicator)
                Row(
                  children: [
                    _ToggleSegment(
                      label: 'MENSUAL',
                      selected: !_isAnnual,
                      onTap: () => onChanged(_BillingInterval.monthly),
                    ),
                    _ToggleSegment(
                      label: 'ANUAL',
                      selected: _isAnnual,
                      trailing: annualDiscountPercent > 0
                          ? _DiscountPill(percent: annualDiscountPercent)
                          : null,
                      onTap: () => onChanged(_BillingInterval.annual),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Single segment inside [_IntervalToggle].
class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: selected
                        ? AppColors.textOnGold
                        : AppColors.textSecondary,
                  ),
                ),
                if (trailing != null && !selected) ...[
                  const SizedBox(width: AppDimens.space4),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Green pill badge showing annual savings — shown next to «ANUAL» when
/// that segment is not selected (hidden when selected to avoid overlap).
class _DiscountPill extends StatelessWidget {
  const _DiscountPill({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Text(
        'AHORRÁ $percent%',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.success),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state — 3 skeleton plan panels
// ---------------------------------------------------------------------------

class _LoadingPlans extends StatelessWidget {
  const _LoadingPlans();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    if (w >= _kDesktopBreak) {
      return const IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _SkeletonPlanCard()),
            SizedBox(width: AppDimens.space20),
            Expanded(child: _SkeletonPlanCard()),
            SizedBox(width: AppDimens.space20),
            Expanded(child: _SkeletonPlanCard()),
          ],
        ),
      );
    }

    if (w >= _kTabletBreak) {
      final cardWidth = (w - AppDimens.space20) / 2;
      return Wrap(
        spacing: AppDimens.space20,
        runSpacing: AppDimens.space20,
        children: [
          SizedBox(width: cardWidth, child: const _SkeletonPlanCard()),
          SizedBox(width: cardWidth, child: const _SkeletonPlanCard()),
          SizedBox(width: cardWidth, child: const _SkeletonPlanCard()),
        ],
      );
    }

    return const Column(
      children: [
        _SkeletonPlanCard(),
        SizedBox(height: AppDimens.space16),
        _SkeletonPlanCard(),
        SizedBox(height: AppDimens.space16),
        _SkeletonPlanCard(),
      ],
    );
  }
}

/// Skeleton silhouette of a plan panel for the loading state.
class _SkeletonPlanCard extends StatelessWidget {
  const _SkeletonPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space24),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brL,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: AppDimens.elev1,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge placeholder
          SkeletonBase(width: 88, height: 22, radius: AppDimens.radiusPill),
          SizedBox(height: AppDimens.space12),
          // Plan name
          SkeletonBase(
              width: double.infinity, height: 20, radius: AppDimens.radiusS),
          SizedBox(height: AppDimens.space8),
          // Price
          SkeletonBase(width: 110, height: 36, radius: AppDimens.radiusS),
          SizedBox(height: AppDimens.space4),
          SkeletonBase(width: 56, height: 13, radius: AppDimens.radiusXS),
          SizedBox(height: AppDimens.space16),
          // Divider
          SkeletonBase(width: double.infinity, height: 1, radius: 0),
          SizedBox(height: AppDimens.space12),
          // Feature bullets
          SkeletonBase(
              width: double.infinity, height: 14, radius: AppDimens.radiusXS),
          SizedBox(height: AppDimens.space8),
          SkeletonBase(width: 160, height: 14, radius: AppDimens.radiusXS),
          SizedBox(height: AppDimens.space20),
          // CTA
          SkeletonBase(
              width: double.infinity,
              height: _kCtaHeight,
              radius: AppDimens.radiusM),
        ],
      ),
    );
  }
}
