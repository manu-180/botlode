// lib/core/ui/widgets/custom_title_bar.dart
// Barra de título «Hangar OS» — franja HUD de 36 px con marca, breadcrumb,
// indicador de estado y controles de ventana.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_icons.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import '../hud/hud_status_dot.dart';

// ─── SystemStatus ─────────────────────────────────────────────────────────────

enum SystemStatus { operational, offline, syncing }

// ─── CustomTitleBar ───────────────────────────────────────────────────────────

class CustomTitleBar extends StatelessWidget {
  final String? breadcrumb;
  final SystemStatus? systemStatus;

  const CustomTitleBar({super.key, this.breadcrumb, this.systemStatus});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.titleBarHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── DRAG AREA (left + center) ────────────────────────────────
            Expanded(
              child: DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppDimens.space12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Micro-logo 16×16
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Image.asset(
                          'assets/icon/botlode_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space8),
                      // Marca
                      Text(
                        'BOTSLODE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (breadcrumb != null) ...[
                        const SizedBox(width: AppDimens.space12),
                        // Divisor vertical hairline
                        Container(
                          width: 1,
                          height: 14,
                          color: AppColors.borderSubtle,
                        ),
                        const SizedBox(width: AppDimens.space12),
                        // Breadcrumb
                        Flexible(
                          child: Text(
                            '// ${breadcrumb!.toUpperCase()}',
                            style: AppTextStyles.mono.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                      // ─── CENTRO: indicador de estado ──────────────────
                      Expanded(
                        child: Center(
                          child: systemStatus != null
                              ? _SystemStatusIndicator(status: systemStatus!)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── CONTROLES DE VENTANA ────────────────────────────────────
            _WindowControl(
              icon: AppIcons.winMinimize,
              tooltip: 'Minimizar ventana',
              onTap: () => windowManager.minimize(),
            ),
            const _MaximizeControl(),
            _WindowControl(
              icon: AppIcons.winClose,
              tooltip: 'Cerrar aplicación',
              onTap: () => windowManager.close(),
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _SystemStatusIndicator ───────────────────────────────────────────────────

class _SystemStatusIndicator extends StatelessWidget {
  final SystemStatus status;

  const _SystemStatusIndicator({required this.status});

  HudStatus get _hudStatus => switch (status) {
        SystemStatus.operational => HudStatus.online,
        SystemStatus.offline => HudStatus.offline,
        SystemStatus.syncing => HudStatus.processing,
      };

  String get _label => switch (status) {
        SystemStatus.operational => 'SISTEMA OPERATIVO',
        SystemStatus.offline => 'SIN ENLACE',
        SystemStatus.syncing => 'SINCRONIZANDO',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HudStatusDot(status: _hudStatus, size: 6),
        const SizedBox(width: AppDimens.space8),
        Text(
          _label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── _WindowControl ───────────────────────────────────────────────────────────

class _WindowControl extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowControl({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowControl> createState() => _WindowControlState();
}

class _WindowControlState extends State<_WindowControl> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  final _focusNode = FocusNode();

  Color get _bg {
    if (_pressed) {
      return widget.isClose ? AppColors.danger : AppColors.borderDefault;
    }
    if (_hovered) {
      return widget.isClose ? AppColors.danger : AppColors.borderSubtle;
    }
    return Colors.transparent;
  }

  Color get _iconColor =>
      _hovered || _pressed ? AppColors.textPrimary : AppColors.textTertiary;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        excludeFromSemantics: true,
        child: Focus(
          focusNode: _focusNode,
          onFocusChange: (focused) => setState(() => _focused = focused),
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space)) {
              setState(() => _pressed = true);
              widget.onTap();
              Future.delayed(AppMotion.durInstant, () {
                if (mounted) setState(() => _pressed = false);
              });
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) {
                setState(() => _pressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _pressed = false),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: _focused
                      ? Border.all(color: AppColors.cyan, width: 2)
                      : const Border(),
                ),
                child: AnimatedScale(
                  scale: _pressed ? AppMotion.pressScale : 1.0,
                  duration: AppMotion.durInstant,
                  child: AnimatedContainer(
                    duration: AppMotion.durInstant,
                    curve: AppMotion.easeStandard,
                    width: 46,
                    height: AppDimens.titleBarHeight,
                    color: _bg,
                    child: Center(
                      child: Icon(widget.icon, size: 16, color: _iconColor),
                    ),
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

// ─── _MaximizeControl ─────────────────────────────────────────────────────────

class _MaximizeControl extends StatefulWidget {
  const _MaximizeControl();

  @override
  State<_MaximizeControl> createState() => _MaximizeControlState();
}

class _MaximizeControlState extends State<_MaximizeControl>
    with WindowListener {
  bool _isMaximized = false;
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncState();
  }

  Future<void> _syncState() async {
    final v = await windowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = v);
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  void dispose() {
    windowManager.removeListener(this);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_isMaximized) {
      await windowManager.restore();
    } else {
      await windowManager.maximize();
    }
  }

  Color get _bg {
    if (_pressed) return AppColors.borderDefault;
    if (_hovered) return AppColors.borderSubtle;
    return Colors.transparent;
  }

  Color get _iconColor =>
      _hovered || _pressed ? AppColors.textPrimary : AppColors.textTertiary;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final icon = _isMaximized ? AppIcons.winRestore : AppIcons.winMaximize;
    final tooltip =
        _isMaximized ? 'Restaurar ventana' : 'Maximizar ventana';

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: Focus(
          focusNode: _focusNode,
          onFocusChange: (focused) => setState(() => _focused = focused),
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space)) {
              setState(() => _pressed = true);
              _onTap().catchError((_) {});
              Future.delayed(AppMotion.durInstant, () {
                if (mounted) setState(() => _pressed = false);
              });
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) {
                setState(() => _pressed = false);
                _onTap().catchError((_) {});
              },
              onTapCancel: () => setState(() => _pressed = false),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: _focused
                      ? Border.all(color: AppColors.cyan, width: 2)
                      : const Border(),
                ),
                child: AnimatedScale(
                  scale: _pressed ? AppMotion.pressScale : 1.0,
                  duration: AppMotion.durInstant,
                  child: AnimatedContainer(
                    duration: AppMotion.durInstant,
                    curve: AppMotion.easeStandard,
                    width: 46,
                    height: AppDimens.titleBarHeight,
                    color: _bg,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: reduced
                            ? Duration.zero
                            : AppMotion.durFast,
                        child: Icon(
                          icon,
                          key: ValueKey(_isMaximized),
                          size: 16,
                          color: _iconColor,
                        ),
                      ),
                    ),
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
