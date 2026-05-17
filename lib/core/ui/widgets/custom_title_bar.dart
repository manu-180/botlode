// lib/core/ui/widgets/custom_title_bar.dart
// Title bar «Hangar OS»: drag area + branding HUD + controles de ventana.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.titleBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.voidBlack,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ─── DRAG AREA + BRANDING ─────────────────────────────────────────
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                ),
                child: Row(
                  children: [
                    // Indicador reactor activo
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: AppDimens.brPill,
                        boxShadow: AppDimens.glowGold,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Text(
                      'BOTSLODE',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.gold,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Text(
                      '// FACTORY TERMINAL v2.0',
                      style: AppTextStyles.mono.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── CONTROLES DE VENTANA ─────────────────────────────────────────
          _WindowControl(
            icon: Icons.remove,
            tooltip: 'Minimizar',
            onTap: windowManager.minimize,
          ),
          _WindowControl(
            icon: Icons.crop_square_rounded,
            tooltip: 'Maximizar',
            onTap: () async {
              if (await windowManager.isMaximized()) {
                windowManager.restore();
              } else {
                windowManager.maximize();
              }
            },
          ),
          _WindowControl(
            icon: Icons.close,
            tooltip: 'Cerrar',
            isClose: true,
            onTap: windowManager.close,
          ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final bg = _hovered
        ? (widget.isClose
            ? AppColors.danger
            : AppColors.borderStrong)
        : Colors.transparent;

    final iconColor = _hovered
        ? AppColors.textPrimary
        : AppColors.textTertiary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 46,
            height: AppDimens.titleBarHeight,
            color: bg,
            child: Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}
