// Archivo: lib/features/dashboard/presentation/widgets/delete_protocol_dialog.dart
import 'dart:async';
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

class DeleteProtocolDialog extends StatefulWidget {
  final String botName;
  final double currentBalance;
  final VoidCallback onConfirm;

  const DeleteProtocolDialog({
    super.key,
    required this.botName,
    required this.currentBalance,
    required this.onConfirm,
  });

  @override
  State<DeleteProtocolDialog> createState() => _DeleteProtocolDialogState();
}

class _DeleteProtocolDialogState extends State<DeleteProtocolDialog> {
  int _countdown = 3;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _countdown == 0;

    return Shortcuts(
      shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
      child: Actions(
        actions: {
          _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) {
            if (isEnabled) {
              widget.onConfirm();
              Navigator.of(context).pop();
            }
            return null;
          }),
        },
        child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            gradient: LinearGradient(
              colors: [
                AppColors.danger,
                AppColors.danger.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(AppDimens.space24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: AppDimens.space8),

                // --- TÍTULO ---
                Text(
                  "DESMANTELAR UNIDAD",
                  style: AppTextStyles.titleL.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppDimens.space32),

                // --- BLOQUE DE ADVERTENCIA FINANCIERA ---
                Container(
                  padding: EdgeInsets.all(AppDimens.space16),
                  decoration: BoxDecoration(
                    color: AppColors.voidBlack.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "SALDO PENDIENTE A FACTURAR",
                        style: AppTextStyles.mono.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: AppDimens.space4),
                      Text(
                        "\$ ${widget.currentBalance.toStringAsFixed(2)}",
                        style: AppTextStyles.numericTicker.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppDimens.space24),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: 13,
                    ),
                    children: [
                      const TextSpan(text: "Al desmantelar la unidad "),
                      TextSpan(
                        text: widget.botName,
                        style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
                      ),
                      const TextSpan(text: ", sus procesos se detendrán irreversiblemente y "),
                      const TextSpan(
                        text: "el saldo pendiente será debitado inmediatamente.",
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppDimens.space32),

                Row(
                  children: [
                    Expanded(
                      // TODO: migrate to AppButton.danger per Hangar OS spec
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                          foregroundColor: AppColors.textSecondary,
                          padding: EdgeInsets.symmetric(vertical: AppDimens.space16),
                        ),
                        child: const Text("CANCELAR"),
                      ),
                    ),
                    SizedBox(width: AppDimens.space16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isEnabled
                            ? () {
                                widget.onConfirm();
                                Navigator.of(context).pop();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          disabledBackgroundColor: AppColors.surface.withValues(alpha: 0.5),
                          disabledForegroundColor: AppColors.textSecondary,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: AppDimens.space16),
                          side: isEnabled
                              ? BorderSide(color: AppColors.danger.withValues(alpha: 0.5))
                              : const BorderSide(color: AppColors.borderDefault),
                        ),
                        // --- CAMBIO DE TEXTO SOLICITADO ---
                        child: Text(
                          isEnabled
                              ? "ELIMINAR"
                              : "ELIMINAR (${_countdown}s)",
                          style: isEnabled
                              ? AppTextStyles.label
                              : AppTextStyles.mono.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }
}
