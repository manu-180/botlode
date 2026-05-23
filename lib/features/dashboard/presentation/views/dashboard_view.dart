// lib/features/dashboard/presentation/views/dashboard_view.dart
// Dashboard «Bahía de Carga» — Hangar OS. Grilla de unidades + HUD de crédito.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/buttons/app_button.dart';
import 'package:botslode/core/ui/hud/hud.dart';
import 'package:botslode/core/ui/responsive/breakpoints.dart';
import 'package:botslode/core/ui/states/error_state.dart';
import 'package:botslode/core/ui/widgets/page_title.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/payment_checkout_modal.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:botslode/features/dashboard/presentation/providers/dashboard_controller.dart';
import 'package:botslode/features/dashboard/presentation/widgets/bot_card.dart';
import 'package:botslode/features/dashboard/presentation/widgets/credit_hud_panel.dart';
import 'package:botslode/features/dashboard/presentation/widgets/create_bot_modal.dart';
import 'package:botslode/features/dashboard/presentation/widgets/dashboard_empty_states.dart';
import 'package:botslode/features/dashboard/presentation/widgets/dashboard_grid_skeleton.dart';
import 'package:botslode/features/dashboard/presentation/widgets/dashboard_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

// ─── DASHBOARD VIEW ───────────────────────────────────────────────────────────

class DashboardView extends ConsumerStatefulWidget {
  static const String routeName = 'dashboard';

  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView>
    with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final AnimationController _toolbarCtrl;
  late final AnimationController _gridCtrl;
  late final AnimationController _contentEnterCtrl;

  late final Animation<double> _headerAnim;
  late final Animation<double> _toolbarAnim;
  late final Animation<double> _gridAnim;
  late final Animation<double> _contentEnterAnim;

  @override
  void initState() {
    super.initState();
    _headerCtrl       = AnimationController(vsync: this, duration: AppMotion.durBase);
    _toolbarCtrl      = AnimationController(vsync: this, duration: AppMotion.durBase);
    _gridCtrl         = AnimationController(vsync: this, duration: AppMotion.durBase);
    _contentEnterCtrl = AnimationController(vsync: this, duration: AppMotion.durBase);

    _headerAnim       = CurvedAnimation(parent: _headerCtrl,       curve: AppMotion.easeEntrance);
    _toolbarAnim      = CurvedAnimation(parent: _toolbarCtrl,      curve: AppMotion.easeEntrance);
    _gridAnim         = CurvedAnimation(parent: _gridCtrl,         curve: AppMotion.easeEntrance);
    _contentEnterAnim = CurvedAnimation(parent: _contentEnterCtrl, curve: AppMotion.easeStandard);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = AppMotion.reduced(context);
      if (reduce) {
        for (final c in [_headerCtrl, _toolbarCtrl, _gridCtrl]) {
          c.animateTo(
            1.0,
            duration: AppMotion.durCrossfadeReduced,
            curve: Curves.linear,
          );
        }
      } else {
        _headerCtrl.forward();
        Future.delayed(AppMotion.durInstant, () {
          if (mounted) _toolbarCtrl.forward();
        });
        Future.delayed(AppMotion.durFast, () {
          if (mounted) _gridCtrl.forward();
        });
      }
      // If data is already available on mount (e.g. navigating back), skip fade-in.
      if (!ref.read(filteredBotsProvider).isLoading) {
        _contentEnterCtrl.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    (_headerAnim as CurvedAnimation).dispose();
    (_toolbarAnim as CurvedAnimation).dispose();
    (_gridAnim as CurvedAnimation).dispose();
    (_contentEnterAnim as CurvedAnimation).dispose();
    _headerCtrl.dispose();
    _toolbarCtrl.dispose();
    _gridCtrl.dispose();
    _contentEnterCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    ref.read(dashboardFilterProvider.notifier).setFilter(BotFilter.all);
    ref.read(dashboardSearchProvider.notifier).setSearch('');
  }

  void _confirmPayment(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (c) => Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent(),
        },
        child: Actions(
          actions: {
            _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(
              onInvoke: (_) {
                Navigator.pop(c);
                ref.read(billingProvider.notifier).processPayment(amount);
                return null;
              },
            ),
          },
          child: AlertDialog(
            backgroundColor: AppColors.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimens.brXL,
              side: const BorderSide(color: AppColors.success),
            ),
            title: Text(
              'CONFIRMAR PAGO RÁPIDO',
              style: AppTextStyles.titleL,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se debitará el total adeudado de su tarjeta principal.',
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.space20),
                HudTicker(
                  value: amount,
                  prefix: '\$ ',
                  suffix: ' USD',
                  decimals: 2,
                  style: AppTextStyles.numericTicker.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            actions: [
              AppButton.ghost(
                label: 'Cancelar',
                onPressed: () => Navigator.pop(c),
              ),
              AppButton.primary(
                label: 'Pagar ahora',
                onPressed: () {
                  Navigator.pop(c);
                  ref.read(billingProvider.notifier).processPayment(amount);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final botsAsync     = ref.watch(filteredBotsProvider);
    final allBotsAsync  = ref.watch(botsProvider);
    final billingAsync  = ref.watch(billingProvider);
    final filter        = ref.watch(dashboardFilterProvider);
    final search        = ref.watch(dashboardSearchProvider);

    final billingState      = billingAsync.valueOrNull;
    final totalDebt         = billingState?.totalDebt ?? 0.0;
    final dollarRate        = billingState?.dollarRate ?? 1200.0;
    final hasQueryOrFilter  = search.isNotEmpty || filter != BotFilter.all;
    final formFactor        = Breakpoints.of(context);
    final gridMaxExtent     = Breakpoints.gridTileExtent(formFactor);
    final hPadding          = Breakpoints.horizontalPadding(formFactor);
    final vPadding          = formFactor == FormFactor.mobile
        ? AppDimens.space16
        : AppDimens.space32;

    // Trigger content fade-in on loading → data/error transition.
    ref.listen<AsyncValue<List<Bot>>>(filteredBotsProvider, (prev, next) {
      if ((prev?.isLoading ?? true) && !next.isLoading && mounted) {
        if (_contentEnterCtrl.value < 1.0) {
          final reduce = AppMotion.reduced(context);
          _contentEnterCtrl.animateTo(
            1.0,
            duration: reduce ? AppMotion.durCrossfadeReduced : AppMotion.durBase,
            curve: reduce ? Curves.linear : AppMotion.easeStandard,
          );
        }
      }
    });

    // ── Sliver [3]: grid / skeleton / empty / error ──────────────────────────
    final Widget gridSliver = SliverPadding(
      padding: const EdgeInsets.only(top: AppDimens.space24),
      sliver: botsAsync.when(
        loading: () => SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: gridMaxExtent,
            childAspectRatio: formFactor == FormFactor.mobile ? 0.95 : 1.4,
            crossAxisSpacing: AppDimens.gapCard,
            mainAxisSpacing: AppDimens.gapCard,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, __) => const BotCardSkeleton(),
            childCount: 8,
          ),
        ),
        error: (err, _) => SliverFillRemaining(
          child: ErrorScreen(
            title: 'Error de enlace',
            message: err.toString(),
            retryLabel: 'Reintentar',
            onRetry: () => ref.invalidate(filteredBotsProvider),
          ),
        ),
        data: (bots) {
          final Widget contentSliver;

          if (bots.isEmpty) {
            final allBots = allBotsAsync.valueOrNull ?? [];
            if (allBots.isEmpty && !hasQueryOrFilter) {
              // Empty A — bahía vacía, ningún bot existe aún.
              contentSliver = SliverFillRemaining(
                hasScrollBody: false,
                child: DashboardEmptyBay(
                  onAssemble: () => showDialog(
                    context: context,
                    builder: (_) => const CreateBotModal(),
                  ),
                ),
              );
            } else {
              // Empty B — hay bots pero el filtro/búsqueda no los encuentra.
              contentSliver = SliverFillRemaining(
                hasScrollBody: false,
                child: DashboardEmptyNoResults(
                  query: search.trim().isEmpty ? null : search.trim(),
                  onClear: _clearSearch,
                ),
              );
            }
          } else {
            contentSliver = SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: gridMaxExtent,
                childAspectRatio:
                    formFactor == FormFactor.mobile ? 0.95 : 1.4,
                crossAxisSpacing: AppDimens.gapCard,
                mainAxisSpacing: AppDimens.gapCard,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => BotCard(
                  bot: bots[i],
                  staggerIndex: i,
                  onTap: () => ctx.goNamed(
                    'bot_detail',
                    pathParameters: {'botId': bots[i].id},
                  ),
                ),
                childCount: bots.length,
              ),
            );
          }

          // Crossfade: content fades in over durBase when loading → data.
          return SliverFadeTransition(
            opacity: _contentEnterAnim,
            sliver: contentSliver,
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: hPadding,
          vertical: vPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: CustomScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // ── [0] Header band ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _headerAnim,
                    builder: (_, __) {
                      final t = _headerAnim.value;
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 12),
                          child: _HeaderBand(
                            billingAsync: billingAsync,
                            onAssemble: () => showDialog(
                              context: context,
                              builder: (_) => const CreateBotModal(),
                            ),
                            onPayCard: () =>
                                _confirmPayment(context, totalDebt),
                            onPayLink: () => showDialog(
                              context: context,
                              builder: (_) => PaymentCheckoutModal(
                                amount: totalDebt,
                                exchangeRate: dollarRate,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── [1] Spacer ────────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimens.space24),
                ),

                // ── [2] Sticky toolbar ────────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ToolbarDelegate(
                    animation: _toolbarAnim,
                    height: formFactor == FormFactor.mobile ? 80 : 64,
                  ),
                ),

                // ── [3] Grid (animated with SliverOpacity) ────────────────
                AnimatedBuilder(
                  animation: _gridAnim,
                  builder: (_, __) => SliverOpacity(
                    opacity: _gridAnim.value,
                    sliver: gridSliver,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HEADER BAND ──────────────────────────────────────────────────────────────

class _HeaderBand extends StatelessWidget {
  final AsyncValue<BillingState> billingAsync;
  final VoidCallback onAssemble;
  final VoidCallback onPayCard;
  final VoidCallback onPayLink;

  const _HeaderBand({
    required this.billingAsync,
    required this.onAssemble,
    required this.onPayCard,
    required this.onPayLink,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);

    const pageTitle = PageTitle(
      title: 'BAHÍA DE CARGA',
      subtitle: 'Gestión operativa de unidades autónomas',
      style: PageTitleStyle.techBar,
    );

    final hudPanel = CreditHudPanel(
      billingAsync: billingAsync,
      onAssemble: onAssemble,
      onPayCard: onPayCard,
      onPayLink: onPayLink,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1180;

        final Widget content = isWide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  pageTitle,
                  SizedBox(
                    width: 420,
                    child: hudPanel,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  pageTitle,
                  const SizedBox(height: AppDimens.space20),
                  hudPanel,
                ],
              );

        if (reduce) {
          return content;
        }

        return AnimatedSize(
          duration: AppMotion.durBase,
          curve: AppMotion.easeStandard,
          child: AnimatedSwitcher(
            duration: AppMotion.durBase,
            child: KeyedSubtree(
              key: ValueKey(isWide),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

// ─── TOOLBAR DELEGATE ─────────────────────────────────────────────────────────

class _ToolbarDelegate extends SliverPersistentHeaderDelegate {
  final Animation<double> animation;
  final double height;

  const _ToolbarDelegate({required this.animation, this.height = 64});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(covariant _ToolbarDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.animation != animation;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: Stack(
              children: [
                const DashboardToolbar(),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: shrinkOffset > 0 ? 1.0 : 0.0,
                    duration: AppMotion.durFast,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

