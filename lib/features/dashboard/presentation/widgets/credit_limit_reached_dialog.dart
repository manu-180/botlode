// Archivo: lib/features/dashboard/presentation/widgets/credit_limit_reached_dialog.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                AppColors.warning,
                AppColors.warning.withValues(alpha: 0.4),
                AppColors.primary.withValues(alpha: 0.5),
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
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22.5),
              border: Border.all(
                color: AppColors.borderGlass,
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono con anillo de estado
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'LÍMITE DE CRÉDITO ALCANZADO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu pozo de crédito está al tope. No podés activar más unidades hasta que realices un pago y liberes capacidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Realizá un pago para seguir operando.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.goNamed(BillingView.routeName);
                    },
                    icon: const Icon(Icons.payment_rounded, size: 20),
                    label: const Text('IR A PAGOS'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CERRAR',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
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
