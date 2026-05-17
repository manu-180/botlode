// lib/core/ui/hud/connectivity_hud.dart
// Toast HUD de estado de enlace — «ENLACE RESTABLECIDO» / «SIN CONEXIÓN».
// ConnectivityHudController gestiona el OverlayEntry; el resto son privados.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_icons.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import 'hud_chamfer.dart';
import 'hud_reactor_bar.dart';
import 'hud_scanlines.dart';

// ─── Controller ──────────────────────────────────────────────────────────────

class ConnectivityHudController {
  OverlayEntry? _entry;

  /// Reemplaza cualquier toast de conectividad visible e inserta el nuevo.
  /// Si [isOnline], auto-descarta tras 4 s con animación de salida.
  void show({required BuildContext context, required bool isOnline}) {
    _removeImmediate();
    final key = GlobalKey<_HudOverlayState>();
    _entry = OverlayEntry(
      builder: (_) => _HudOverlay(
        key: key,
        isOnline: isOnline,
        onExited: _removeImmediate,
      ),
    );
    Overlay.of(context).insert(_entry!);

    if (isOnline) {
      final capturedKey = key;
      Future.delayed(const Duration(seconds: 4), () {
        capturedKey.currentState?.dismiss();
      });
    }
  }

  void dispose() => _removeImmediate();

  void _removeImmediate() {
    _entry?.remove();
    _entry = null;
  }
}

// ─── Overlay con enter / exit ─────────────────────────────────────────────────

class _HudOverlay extends StatefulWidget {
  final bool isOnline;
  final VoidCallback onExited;

  const _HudOverlay({
    super.key,
    required this.isOnline,
    required this.onExited,
  });

  @override
  State<_HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<_HudOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durSlow);
    _ctrl.forward();
  }

  /// Inicia la animación de salida y llama [onExited] al terminar.
  void dismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    final reduce = AppMotion.reduced(context);
    _ctrl
      ..reverseDuration = reduce
          ? AppMotion.durCrossfadeReduced
          : AppMotion.exitOf(AppMotion.durSlow)
      ..reverse().whenComplete(widget.onExited);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final curved = CurvedAnimation(
      parent: _ctrl,
      curve: reduce ? Curves.linear : AppMotion.easeEntrance,
      reverseCurve: reduce ? Curves.linear : AppMotion.easeExit,
    );
    final slide = reduce
        ? const AlwaysStoppedAnimation<Offset>(Offset.zero)
        : Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(curved);

    return Positioned(
      top: AppDimens.titleBarHeight + AppDimens.space16,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: slide,
            child: _ConnectivityHudToast(isOnline: widget.isOnline),
          ),
        ),
      ),
    );
  }
}

// ─── Widget visual ────────────────────────────────────────────────────────────

class _ConnectivityHudToast extends StatelessWidget {
  final bool isOnline;

  const _ConnectivityHudToast({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.isReduced(context);
    final color = isOnline ? AppColors.success : AppColors.danger;
    final icon = isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;
    final label = isOnline
        ? 'ENLACE RESTABLECIDO · SISTEMAS ONLINE'
        : 'SIN CONEXIÓN · MODO OFFLINE ACTIVO';

    return Semantics(
      liveRegion: true,
      label: label,
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              ...AppDimens.elev3,
              ...AppDimens.glowStatus(color),
            ],
          ),
          child: ChamferBox(
            chamfer: AppDimens.chamferM,
            fillColor: AppColors.surfaceHud,
            border: BorderSide(
              color: color.withValues(alpha: 0.70),
              width: 1.5,
            ),
            child: HudScanlines(
              opacity: 0.035,
              // Stack: Padding determina el tamaño; HudReactorBar se ancla al borde izq.
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      3.0 + AppDimens.space16, // reactor (3px) + gap
                      AppDimens.space12,
                      AppDimens.space20,
                      AppDimens.space12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppIcons.icon(icon, size: AppDimens.iconS, color: color),
                        const SizedBox(width: AppDimens.space12),
                        Text(
                          label,
                          style:
                              AppTextStyles.hudReadout.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                  // Reactor bar pegada al borde izquierdo interno, altura completa.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: HudReactorBar(
                      axis: Axis.vertical,
                      thickness: 3,
                      color: color,
                      // Offline: late continuo. Online: sin latido (pulsing:false → valor=1).
                      pulsing: !isOnline && !reduce,
                      duration: AppMotion.durHeartbeat,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
