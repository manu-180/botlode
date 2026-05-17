// lib/features/dashboard/presentation/widgets/sidebar.dart
// Sidebar «Hangar OS» — columna HUD de navegación. Indicador dorado deslizante,
// ítems con estados hover/active/press/focus/keyboard, logo enmarcado con brackets.
//
// Nota: sidebarWidth = 72 px (AppDimens.sidebarWidth). El spec propone 84 px,
// pero el token existente es 72 y el resto del shell lo referencia directamente.
// Los micro-labels usan fontSize: 9 (en lugar del labelSmall de 11 px) para
// que 'PLANTILLAS' quepa en los 56 px útiles (72 - 8*2 padding).
import 'dart:async';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud.dart';
import 'package:botslode/core/ui/widgets/hud_tooltip.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:botslode/features/bots_library/presentation/views/bots_library_view.dart';
import 'package:botslode/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:botslode/features/settings/presentation/views/settings_view.dart';
import 'package:botslode/features/store/presentation/views/store_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

// ─── Sidebar ─────────────────────────────────────────────────────────────────

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // GlobalKeys para cada ítem de nav — usados para medir posición del indicador.
  final _botsKey = GlobalKey();
  final _plantillasKey = GlobalKey();
  final _pagosKey = GlobalKey();
  final _tiendaKey = GlobalKey();
  final _ajustesKey = GlobalKey();
  final _stackKey = GlobalKey();

  double _indicatorTop = 0;
  bool _indicatorVisible = false;

  // Bloquea actualizaciones del indicador durante la animación de entrada
  // escalonada para evitar posiciones erróneas por los transforms de translateY.
  bool _entryDone = false;
  Timer? _entryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = AppMotion.reduced(context);
      if (reduced) {
        // Sin animaciones de entrada: mostrar indicador en el primer frame.
        _finishEntry();
      } else {
        // Esperar a que terminen las animaciones escalonadas:
        // staggerDelay(5) + durBase + 50 ms buffer ≈ 470 ms
        _entryTimer = Timer(const Duration(milliseconds: 470), () {
          if (mounted) _finishEntry();
        });
      }
    });
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    super.dispose();
  }

  void _finishEntry() {
    final loc = GoRouterState.of(context).uri.path;
    _computeIndicatorPosition(loc);
    if (mounted) setState(() => _entryDone = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryDone) {
      final loc = GoRouterState.of(context).uri.path;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _computeIndicatorPosition(loc);
      });
    }
  }

  GlobalKey? _keyForLocation(String loc) {
    if (loc.startsWith('/dashboard') || loc == '/') return _botsKey;
    if (loc.startsWith('/bots')) return _plantillasKey;
    if (loc == '/billing') return _pagosKey;
    if (loc == '/store') return _tiendaKey;
    if (loc == '/settings') return _ajustesKey;
    return null;
  }

  void _computeIndicatorPosition(String loc) {
    if (!mounted) return;
    final key = _keyForLocation(loc);
    if (key == null) {
      setState(() => _indicatorVisible = false);
      return;
    }

    final stackRO = _stackKey.currentContext?.findRenderObject();
    final itemRO = key.currentContext?.findRenderObject();
    if (stackRO == null || itemRO == null) return;

    final stackBox = stackRO as RenderBox;
    final itemBox = itemRO as RenderBox;
    final itemOffset = itemBox.localToGlobal(Offset.zero, ancestor: stackBox);

    const indicH = 44.0;
    setState(() {
      _indicatorTop = itemOffset.dy + (itemBox.size.height - indicH) / 2;
      _indicatorVisible = true;
    });
  }

  bool _isActive(String loc, String key) => switch (key) {
        'bots' => loc.startsWith('/dashboard') || loc == '/',
        'plantillas' => loc.startsWith('/bots'),
        'pagos' => loc == '/billing',
        'tienda' => loc == '/store',
        'ajustes' => loc == '/settings',
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final reduced = AppMotion.reduced(context);

    Widget stagger(int index, Widget child) {
      if (reduced) return child;
      return child
          .animate(delay: AppMotion.staggerDelay(index))
          .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
          .moveY(
            begin: 12,
            end: 0,
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          );
    }

    return Container(
      width: AppDimens.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.voidBlack,
        border: Border(
          right: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Stack(
        key: _stackKey,
        children: [
          // ── Columna principal ────────────────────────────────────────────
          Column(
            children: [
              // ── Header: logo enmarcado con brackets HUD ────────────────
              const SizedBox(height: AppDimens.space24),
              Center(
                child: stagger(
                  0,
                  HudCornerBrackets(
                    color: AppColors.borderGold,
                    armLength: 8,
                    thickness: 1.5,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHud,
                        borderRadius: AppDimens.brM,
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icon/botlode_logo.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space24),

              // ── Ítems principales (zona central expandida) ─────────────
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    stagger(
                      1,
                      _SidebarItem(
                        key: _botsKey,
                        icon: AppIcons.bots,
                        label: 'BOTS',
                        tooltip: 'Bots',
                        isActive: _isActive(loc, 'bots'),
                        onTap: () => context.goNamed(DashboardView.routeName),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space12),
                    stagger(
                      2,
                      _SidebarItem(
                        key: _plantillasKey,
                        icon: AppIcons.library,
                        label: 'PLANTILLAS',
                        tooltip: 'Plantillas',
                        isActive: _isActive(loc, 'plantillas'),
                        onTap: () =>
                            context.goNamed(BotsLibraryView.routeName),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space12),
                    stagger(
                      3,
                      _SidebarItem(
                        key: _pagosKey,
                        icon: AppIcons.billing,
                        label: 'PAGOS',
                        tooltip: 'Pagos',
                        isActive: _isActive(loc, 'pagos'),
                        onTap: () => context.goNamed(BillingView.routeName),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space12),
                    stagger(
                      4,
                      _SidebarItem(
                        key: _tiendaKey,
                        icon: AppIcons.store,
                        label: 'TIENDA',
                        tooltip: 'Tienda',
                        isActive: _isActive(loc, 'tienda'),
                        onTap: () => context.goNamed(StoreView.routeName),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Footer: divisor HUD + AJUSTES ──────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.space8,
                  vertical: AppDimens.space12,
                ),
                child: HudDivider(),
              ),
              stagger(
                5,
                _SidebarItem(
                  key: _ajustesKey,
                  icon: AppIcons.settings,
                  label: 'AJUSTES',
                  tooltip: 'Ajustes',
                  isActive: _isActive(loc, 'ajustes'),
                  onTap: () => context.goNamed(SettingsView.routeName),
                ),
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),

          // ── Indicador deslizante (barra dorada vertical 3 px) ──────────
          // Se mueve entre ítems con AnimatedPositioned; su opacidad se controla
          // por _indicatorVisible (oculto durante la animación de entrada).
          AnimatedPositioned(
            duration:
                reduced ? AppMotion.durCrossfadeReduced : AppMotion.durBase,
            curve: reduced ? Curves.linear : AppMotion.easeEntrance,
            top: _indicatorTop,
            right: 0,
            width: 3,
            height: 44,
            child: AnimatedOpacity(
              duration:
                  reduced ? AppMotion.durCrossfadeReduced : AppMotion.durFast,
              opacity: _indicatorVisible ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradGold,
                  borderRadius: AppDimens.brPill,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ítem de navegación ──────────────────────────────────────────────────────

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;
  bool _pressed = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  BoxDecoration _cellDecoration({
    required bool active,
    required bool hov,
    required bool pressed,
  }) {
    if (active) {
      return BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppDimens.brM,
        border: Border.all(color: AppColors.borderGold, width: 1),
        boxShadow: const [...AppDimens.elev1, ...AppDimens.glowGold],
      );
    }
    if (pressed) {
      return BoxDecoration(
        color: AppColors.borderDefault,
        borderRadius: AppDimens.brM,
      );
    }
    if (hov) {
      return BoxDecoration(
        color: AppColors.borderSubtle,
        borderRadius: AppDimens.brM,
      );
    }
    return const BoxDecoration();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final hov = _hovered && !active;
    final focused = _focusNode.hasFocus;
    final reduced = AppMotion.reduced(context);

    final iconColor = active
        ? AppColors.gold
        : hov
            ? AppColors.textSecondary
            : AppColors.textTertiary;

    final labelColor = active
        ? AppColors.textPrimary
        : hov
            ? AppColors.textSecondary
            : AppColors.textTertiary;

    // Micro-label: 9 px en lugar de labelSmall (11 px) para que 'PLANTILLAS'
    // quepa en los 56 px útiles del sidebar de 72 px.
    final labelStyle = AppTextStyles.labelSmall.copyWith(
      fontSize: 9,
      letterSpacing: 1.2,
      color: labelColor,
    );

    return Semantics(
      selected: active,
      button: true,
      label: widget.label,
      child: HudTooltip(
        message: widget.tooltip,
        preferred: TooltipPosition.right,
        child: Focus(
          focusNode: _focusNode,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: AnimatedScale(
                duration: _pressed ? AppMotion.durInstant : AppMotion.durFast,
                curve: AppMotion.easeEntrance,
                scale: _pressed ? AppMotion.pressScale : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space8,
                  ),
                  child: Stack(
                    children: [
                      // Celda principal con fondo/borde animado
                      AnimatedContainer(
                        duration: reduced
                            ? AppMotion.durCrossfadeReduced
                            : AppMotion.durFast,
                        curve: AppMotion.easeStandard,
                        height: 64,
                        width: double.infinity,
                        decoration: _cellDecoration(
                          active: active,
                          hov: hov,
                          pressed: _pressed,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcons.icon(
                              widget.icon,
                              size: AppDimens.iconM,
                              color: iconColor,
                            ),
                            const SizedBox(height: AppDimens.space4),
                            AnimatedDefaultTextStyle(
                              duration: reduced
                                  ? AppMotion.durCrossfadeReduced
                                  : AppMotion.durFast,
                              curve: AppMotion.easeStandard,
                              style: labelStyle,
                              child: Text(
                                widget.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Anillo de foco cyan (visible siempre cuando focused,
                      // superpuesto al borde dorado cuando también está active).
                      if (focused)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: AppDimens.brM,
                                border: Border.all(
                                  color: AppColors.cyan,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
