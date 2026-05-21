// Archivo: lib/features/dashboard/presentation/widgets/credit_limit_reached_dialog.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

/// Diálogo de diseño sci-fi que informa que se alcanzó el límite de crédito
/// y no se puede activar el bot. Incluye CTA para ir a Pagos.
class CreditLimitReachedDialog extends StatelessWidget {
  const CreditLimitReachedDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreditLimitReachedDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
      child: Actions(
        actions: {
          _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) {
            Navigator.of(context).pop();
            context.goNamed(BillingView.routeName);
            return null;
          }),
        },
        child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            gradient: LinearGradient(
              colors: [
                AppColors.warning,
                AppColors.warning.withValues(alpha: 0.4),
                AppColors.gold.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: -4,
              ),
            ],
          ),
          child: HudCornerBrackets(
            armLength: 16,
            color: AppColors.borderGold,
            child: Container(
              padding: const EdgeInsets.all(AppDimens.space24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                border: Border.all(
                  color: AppColors.borderDefault,
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono con anillo de estado
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: AppIcons.icon(AppIcons.warning, size: AppDimens.iconL, color: AppColors.warning),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  // Mono status line — primes the eye for the warning title.
                  ExcludeSemantics(
                    child: Text(
                      '// PROTOCOL_HALT — QUOTA_LIMIT_REACHED',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.mono.copyWith(
                        color: AppColors.warning.withValues(alpha: 0.85),
                        letterSpacing: 1.4,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    'LÍMITE DE CRÉDITO ALCANZADO',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleM.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Text(
                    'Tu pozo de crédito está al tope. No podés activar más unidades hasta que realices un pago y liberes capacidad.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  Text(
                    'Realizá un pago para seguir operando.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space24),
                  AppButton.primary(
                    label: 'IR A PAGOS',
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.goNamed(BillingView.routeName);
                    },
                    leadingIcon: Icons.payment_rounded,
                    expand: true,
                  ),
                  const SizedBox(height: AppDimens.space8),
                  AppButton.ghost(
                    label: 'CERRAR',
                    onPressed: () => Navigator.of(context).pop(),
                    expand: true,
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
