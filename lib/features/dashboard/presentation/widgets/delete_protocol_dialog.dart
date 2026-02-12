// Archivo: lib/features/dashboard/presentation/widgets/delete_protocol_dialog.dart
import 'dart:async';
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
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
    final theme = Theme.of(context);
    final isEnabled = _countdown == 0;
    
    // Color "Bordó" (Rojo oscuro industrial) para la acción destructiva
    final Color deepErrorColor = const Color(0xFF8B0000);

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
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                deepErrorColor,
                deepErrorColor.withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: deepErrorColor.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                
                // --- TÍTULO ---
                Text(
                  "DESMANTELAR UNIDAD", 
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontFamily: 'Oxanium',
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 30),
                
                // --- BLOQUE DE ADVERTENCIA FINANCIERA ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "SALDO PENDIENTE A FACTURAR",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$ ${widget.currentBalance.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Oxanium',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: 13,
                    ),
                    children: [
                      const TextSpan(text: "Al desmantelar la unidad "),
                      TextSpan(
                        text: widget.botName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ", sus procesos se detendrán irreversiblemente y "),
                      const TextSpan(
                        text: "el saldo pendiente será debitado inmediatamente.",
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text("CANCELAR"),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          backgroundColor: deepErrorColor, // Color Bordó
                          disabledBackgroundColor: AppColors.surface.withValues(alpha: 0.5),
                          disabledForegroundColor: AppColors.textSecondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: isEnabled 
                              ? BorderSide(color: Colors.red.withValues(alpha: 0.5))
                              : BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        // --- CAMBIO DE TEXTO SOLICITADO ---
                        child: Text(
                          isEnabled 
                              ? "ELIMINAR" 
                              : "ELIMINAR (${_countdown}s)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontFamily: isEnabled ? null : 'Courier', // Monospace para evitar saltos
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