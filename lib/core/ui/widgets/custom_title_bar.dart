// lib/core/ui/widgets/custom_title_bar.dart
// Barra de título «Hangar OS» — franja HUD decorativa con marca, breadcrumb e
// indicador de estado. Sin controles de ventana (la app es mobile-first y en
// desktop nativo ya no se oculta la barra del SO).
//
// Sólo se renderiza en desktop nativo (Windows/macOS/Linux). En mobile y web
// devuelve `SizedBox.shrink()`.
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_text_styles.dart';
import '../../platform/platform_info.dart';
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
    if (!PlatformInfo.usesCustomTitleBar) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: AppDimens.titleBarHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Micro-logo
              SizedBox(
                width: 16,
                height: 16,
                child: Image.asset(
                  'assets/icon/botlode_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              Text(
                'BOTSLODE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (breadcrumb != null) ...[
                const SizedBox(width: AppDimens.space12),
                Container(
                  width: 1,
                  height: 14,
                  color: AppColors.borderSubtle,
                ),
                const SizedBox(width: AppDimens.space12),
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
