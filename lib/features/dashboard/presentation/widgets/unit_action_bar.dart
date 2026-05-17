// lib/features/dashboard/presentation/widgets/unit_action_bar.dart
// Barra de acciones de la unidad: Editar · Compartir · [divisor] · Eliminar.
// Se monta dentro de UnitCommandHeader, a la derecha del StatusTag.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';

class UnitActionBar extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const UnitActionBar({
    super.key,
    this.onEdit,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Acciones de la unidad',
      container: true,
      explicitChildNodes: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            icon: Icons.edit_rounded,
            tooltip: 'Editar unidad',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: onEdit,
          ),
          const SizedBox(width: AppDimens.space8),
          AppIconButton(
            icon: Icons.upload_rounded,
            tooltip: 'Compartir unidad',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: onShare,
          ),
          const SizedBox(width: AppDimens.space12),
          // Divisor vertical hairline
          Container(
            width: 1,
            height: 24,
            color: AppColors.borderSubtle,
          ),
          const SizedBox(width: AppDimens.space12),
          AppIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Eliminar unidad',
            variant: AppButtonVariant.danger,
            size: AppButtonSize.sm,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
