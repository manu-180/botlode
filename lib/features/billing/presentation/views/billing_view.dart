// Archivo: lib/features/billing/presentation/views/billing_view.dart
//
// T4·47 — «Centro de Crédito»: shell y tab bar de facturación rediseñados.
// Reemplaza la AppBar Material 3 plana por fondo ambiental + encabezado HUD
// + BillingTabBar deslizante + AnimatedSwitcher con transición direccional.
//
// Tab 0 — Plan            (stubs: SubscriptionSummaryCard, PlanPicker, AutoPaySettingsCard)
// Tab 1 — Métodos de pago (stubs: DigitalCard, GESTIONAR MÉTODOS)
// Tab 2 — Facturas        (stub: InvoiceList)
// Tab 3 — Historial       (EmptyState)

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/empty_state.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/core/ui/widgets/page_title.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/billing_tab_bar.dart';
import 'package:botslode/features/billing/presentation/widgets/dunning_warning_banner.dart';
import 'package:botslode/features/billing/presentation/widgets/manage_cards_modal.dart';
import 'package:botslode/features/billing/presentation/widgets/trial_countdown_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

// Maximum content width for desktop (wider than the old 960 to fit plan picker row).
const double _kMaxContentWidth = 1040;
// Horizontal padding breakpoint: narrow when width < 720.
const double _kNarrowBreak = 720;

// ─── View ─────────────────────────────────────────────────────────────────────

class BillingView extends ConsumerStatefulWidget {
  static const String routeName = 'billing';

  const BillingView({super.key});

  @override
  ConsumerState<BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends ConsumerState<BillingView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // 1 = navigating right (index increases), −1 = navigating left.
  int _tabDirection = 1;
  int _prevTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabControllerChange);
  }

  void _onTabControllerChange() {
    final newIndex = _tabController.index;
    if (newIndex != _prevTabIndex) {
      setState(() {
        _tabDirection = newIndex > _prevTabIndex ? 1 : -1;
        _prevTabIndex = newIndex;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingV2Provider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < _kNarrowBreak
        ? AppDimens.space20
        : AppDimens.space32;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ambient background ────────────────────────────────────────────
          const _BillingBackground(),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    AppDimens.space24,
                    hPad,
                    0,
                  ),
                  child: _BillingHeader(billingAsync: billingAsync),
                ),

                const SizedBox(height: AppDimens.space24),

                // Tab bar HUD
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: BillingTabBar(
                    controller: _tabController,
                    enabled: !billingAsync.isLoading,
                  ),
                ),

                const SizedBox(height: AppDimens.space16),

                // Conditional banners — self-managed via their own providers.
                const DunningWarningBanner(),
                const TrialCountdownBanner(),

                // Content area
                Expanded(
                  child: billingAsync.when(
                    loading: () => _BillingLoadingSkeleton(hPad: hPad),
                    error: (err, _) => _BillingErrorState(
                      error: err,
                      onRetry: () async =>
                          ref.invalidate(billingV2Provider),
                    ),
                    data: (state) => _BillingTabContent(
                      tabController: _tabController,
                      tabDirection: _tabDirection,
                      billingState: state,
                      hPad: hPad,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ambient background ───────────────────────────────────────────────────────

class _BillingBackground extends StatelessWidget {
  const _BillingBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base colour
        const ColoredBox(color: AppColors.background),
        // Radial gold glow, tenue — centred slightly above mid-screen.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.65),
                radius: 0.85,
                colors: [
                  AppColors.gold.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Grid texture overlay
        IgnorePointer(
          child: CustomPaint(
            painter: _GridPainter(),
          ),
        ),
      ],
    );
  }
}

// Minimal inline grid painter (same as HudGridTexture internals).
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const cell = 32.0;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _BillingHeader extends StatelessWidget {
  const _BillingHeader({required this.billingAsync});

  final AsyncValue<BillingV2State> billingAsync;

  @override
  Widget build(BuildContext context) {
    final subscription = billingAsync.valueOrNull?.subscription;

    Widget? trailing;
    if (subscription != null) {
      final (label, color) = _statusInfo(subscription.status);
      trailing = HudIdTag(text: 'SUB · $label', color: color);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mono label above the title.
        ExcludeSemantics(
          child: Text(
            '// FACTURACIÓN',
            style: AppTextStyles.mono.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.6,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        PageTitle(
          title: 'CENTRO DE CRÉDITO',
          style: PageTitleStyle.techBar,
          trailing: trailing,
        ),
        const SizedBox(height: AppDimens.space16),
        const HudDivider(label: 'MÓDULOS'),
      ],
    );
  }

  (String, Color) _statusInfo(SubscriptionStatus status) =>
      switch (status) {
        SubscriptionStatus.active => ('ACTIVA', AppColors.success),
        SubscriptionStatus.trialing => ('TRIAL', AppColors.info),
        SubscriptionStatus.pastDue => ('PAGO PENDIENTE', AppColors.warning),
        SubscriptionStatus.canceled => ('CANCELADA', AppColors.danger),
        SubscriptionStatus.incomplete => ('INCOMPLETA', AppColors.textTertiary),
      };
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _BillingLoadingSkeleton extends StatelessWidget {
  const _BillingLoadingSkeleton({required this.hPad});

  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: AppDimens.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card skeleton (~180 px panel)
              const SkeletonBase(
                width: double.infinity,
                height: 180,
                radius: AppDimens.radiusL,
              ),
              const SizedBox(height: AppDimens.space24),
              // Three plan-card skeletons in a row-ish layout.
              for (int i = 0; i < 3; i++) ...[
                const SkeletonBase(
                  width: double.infinity,
                  height: 96,
                  radius: AppDimens.radiusM,
                ),
                const SizedBox(height: AppDimens.space16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _BillingErrorState extends StatelessWidget {
  const _BillingErrorState({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: ErrorFeedbackCard(
            title: 'Error al cargar facturación',
            message: 'No se pudo obtener la información de tu cuenta. '
                'Verificá tu conexión e intentá nuevamente.',
            onRetry: onRetry,
            retryLabel: 'REINTENTAR',
            variant: ErrorVariant.fullScreen,
          ),
        ),
      ),
    );
  }
}

// ─── Tab content area ─────────────────────────────────────────────────────────

class _BillingTabContent extends StatelessWidget {
  const _BillingTabContent({
    required this.tabController,
    required this.tabDirection,
    required this.billingState,
    required this.hPad,
  });

  final TabController tabController;
  final int tabDirection;
  final BillingV2State billingState;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
        child: AnimatedSwitcher(
          duration: AppMotion.durBase,
          switchInCurve: AppMotion.easeEntrance,
          switchOutCurve: AppMotion.easeStandard,
          transitionBuilder: (child, animation) => _BillingTabTransition(
            animation: animation,
            direction: tabDirection,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(tabController.index),
            child: _tabContent(tabController.index),
          ),
        ),
      ),
    );
  }

  Widget _tabContent(int index) {
    return switch (index) {
      0 => _PlanTab(billingState: billingState, hPad: hPad),
      1 => _PaymentMethodsTab(billingState: billingState, hPad: hPad),
      2 => _InvoicesTab(billingState: billingState, hPad: hPad),
      3 => _HistoryTab(hPad: hPad),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─── Directional tab transition ───────────────────────────────────────────────

class _BillingTabTransition extends StatelessWidget {
  const _BillingTabTransition({
    required this.animation,
    required this.direction,
    required this.child,
  });

  final Animation<double> animation;
  final int direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    // Outgoing widget: animation reverses from 1.0 → 0.0.
    final isOutgoing = animation.status == AnimationStatus.reverse;

    if (reduced || isOutgoing) {
      return FadeTransition(opacity: animation, child: child);
    }

    // Incoming: fade + directional slide of ~12 px (fractional offset).
    final slide = Tween<Offset>(
      begin: Offset(direction * 0.015, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animation, curve: AppMotion.easeEntrance),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

// ─── Shared tab section header ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.titleM),
        ),
        const SizedBox(height: AppDimens.space8),
        const HudDivider(),
      ],
    );
  }
}

// ─── Stub panel ───────────────────────────────────────────────────────────────
// Used as a visual placeholder until real components land in prompts 48–59.
// Wears HUD trim (corner brackets, dashed border, grid + mono code label)
// so it reads as "module in assembly" rather than "raw stub".

class _StubPanel extends StatelessWidget {
  const _StubPanel({required this.label, this.height = 96});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return HudCornerBrackets(
      color: AppColors.borderStrong,
      armLength: 14,
      thickness: 1.0,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceHud,
          border: Border.all(color: AppColors.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ExcludeSemantics(
              child: IgnorePointer(
                child: HudGridTexture(opacity: 0.03),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.precision_manufacturing_outlined,
                    color: AppColors.textTertiary.withValues(alpha: 0.6),
                    size: AppDimens.iconM,
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    '// MÓDULO EN PREPARACIÓN',
                    style: AppTextStyles.mono.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.4,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    label,
                    style: AppTextStyles.mono.copyWith(
                      color: AppColors.textTertiary.withValues(alpha: 0.55),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 0 — Plan ─────────────────────────────────────────────────────────────

class _PlanTab extends StatelessWidget {
  const _PlanTab({required this.billingState, required this.hPad});

  final BillingV2State billingState;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: AppDimens.space24,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('PLAN ACTUAL'),
          SizedBox(height: AppDimens.space24),

          // TODO(T4·50): replace with SubscriptionSummaryCard
          _StubPanel(
            label: 'SubscriptionSummaryCard — T4·50',
            height: 180,
          ),
          SizedBox(height: AppDimens.space24),

          // TODO(T4·49): replace with PlanPicker
          _StubPanel(label: 'PlanPicker — T4·49', height: 96),
          SizedBox(height: AppDimens.space24),

          // TODO(T4·58): replace with AutoPaySettingsCard
          _StubPanel(label: 'AutoPaySettingsCard — T4·58', height: 96),
        ],
      ),
    );
  }
}

// ─── Tab 1 — Métodos de pago ──────────────────────────────────────────────────

class _PaymentMethodsTab extends StatelessWidget {
  const _PaymentMethodsTab({
    required this.billingState,
    required this.hPad,
  });

  final BillingV2State billingState;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: AppDimens.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('MÉTODOS DE PAGO'),
          const SizedBox(height: AppDimens.space24),

          // TODO(T4·48): replace with DigitalCard
          const _StubPanel(label: 'DigitalCard — T4·48', height: 120),
          const SizedBox(height: AppDimens.space24),

          AppButton(
            label: 'GESTIONAR MÉTODOS',
            onPressed: () => ManageCardsModal.show(context),
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.md,
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2 — Facturas ─────────────────────────────────────────────────────────

class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab({required this.billingState, required this.hPad});

  final BillingV2State billingState;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: AppDimens.space24,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('FACTURAS'),
          SizedBox(height: AppDimens.space24),

          // TODO(T4·59): replace with InvoiceList
          _StubPanel(label: 'InvoiceList — T4·59', height: 180),
        ],
      ),
    );
  }
}

// ─── Tab 3 — Historial ────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.hPad});

  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimens.space24),
      child: const EmptyState(
        icon: Icons.history_outlined,
        title: 'Sin historial aún',
        description:
            'Los eventos de facturación aparecerán aquí una vez que realices tu primera transacción.',
        variant: EmptyStateVariant.neutral,
      ),
    );
  }
}
