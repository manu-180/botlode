// Archivo: lib/features/billing/presentation/widgets/payment_checkout_modal.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentCheckoutModal extends ConsumerStatefulWidget {
  final double amount;
  const PaymentCheckoutModal({super.key, required this.amount});

  @override
  ConsumerState<PaymentCheckoutModal> createState() => _PaymentCheckoutModalState();
}

class _PaymentCheckoutModalState extends ConsumerState<PaymentCheckoutModal> {
  bool _isProcessing = false;
  String _statusText = "ESPERANDO AUTORIZACIÓN";
  double _progress = 0.0;

  void _startPaymentSequence() async {
    setState(() {
      _isProcessing = true;
      _statusText = "ENCRIPTANDO ENLACE DE PAGO...";
    });

    // Simulación de "Secuencia de Seguridad" para el efecto WOW
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _progress = 0.4;
      _statusText = "VALIDANDO CREDENCIALES BANCARIAS...";
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _progress = 0.8;
      _statusText = "AUTORIZANDO TRANSFERENCIA DE CRÉDITO...";
    });

    // Ejecutar cobro real en Supabase
    await ref.read(billingProvider.notifier).processPayment();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _progress = 1.0;
      _statusText = "LIQUIDACIÓN COMPLETADA CON ÉXITO";
    });

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.5), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de Seguridad Animado
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.05),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    _progress < 1.0 ? Icons.security_rounded : Icons.verified_user_rounded,
                    color: _progress < 1.0 ? AppColors.primary : AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "TERMINAL DE PAGO SEGURO",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "\$ ${widget.amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontFamily: 'Oxanium',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                
                if (!_isProcessing) ...[
                  const Text(
                    "MÉTODO: TARJETA TERMINADA EN •••• 8842",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startPaymentSequence,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text("CONFIRMAR LIQUIDACIÓN"),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("ABORTAR", style: TextStyle(color: AppColors.error.withValues(alpha: 0.6))),
                  ),
                ] else ...[
                  // Barra de Progreso Industrial
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: Colors.black,
                          color: _progress < 1.0 ? AppColors.primary : AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _progress < 1.0 ? AppColors.textSecondary : AppColors.success,
                          fontFamily: 'Courier',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}