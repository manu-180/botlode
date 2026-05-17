// lib/features/dashboard/presentation/widgets/unit_command_header.dart
// Barra de comando para la pantalla de detalle de unidad.
// Muestra: botón volver · nombre + HudIdTag · clase · StatusTag · UnitActionBar.
import 'dart:math' show min;

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_id_tag.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:botslode/core/ui/widgets/status_tag.dart';
import 'package:botslode/features/dashboard/presentation/widgets/unit_action_bar.dart';
import 'package:flutter/material.dart';

class UnitCommandHeader extends StatelessWidget {
  final String botName;
  final String botId;
  final UnitStatus status;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const UnitCommandHeader({
    super.key,
    required this.botName,
    required this.botId,
    required this.status,
    required this.onBack,
    this.onEdit,
    this.onShare,
    this.onDelete,
  });

  // Short ID: strip dashes, take first 6 chars uppercase.
  String get _shortId {
    final clean = botId.replaceAll('-', '');
    return clean.substring(0, min(6, clean.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: SizedBox(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── Back button ────────────────────────────────────────
            AppIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Volver al hangar',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              onPressed: onBack,
            ),

            const SizedBox(width: AppDimens.space16),

            // ─── Identity block ──────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: name + ID tag
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          botName.toUpperCase(),
                          style: AppTextStyles.titleL,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space12),
                      HudIdTag(text: 'UNIT-$_shortId'),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space4),
                  // Unit class line
                  Text(
                    'UNIDAD AUTÓNOMA',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppDimens.space16),

            // ─── Status tag ───────────────────────────────────────────
            StatusTag(status: status),

            const SizedBox(width: AppDimens.space16),

            // ─── Action bar ───────────────────────────────────────────
            UnitActionBar(
              onEdit: onEdit,
              onShare: onShare,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
