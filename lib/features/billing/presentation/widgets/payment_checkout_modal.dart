// Archivo: lib/features/billing/presentation/widgets/payment_checkout_modal.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentCheckoutModal extends ConsumerStatefulWidget {
  final double amount;      // Monto en USD
  final double exchangeRate; // Cotización del día

  const PaymentCheckoutModal({
    super.key, 
    required this.amount,
    required this.exchangeRate,
  });

  @override
  ConsumerState<PaymentCheckoutModal> createState() => _PaymentCheckoutModalState();
}

class _PaymentCheckoutModalState extends ConsumerState<PaymentCheckoutModal> {
  bool _isCardProcessing = false;
  String _statusText = "INICIANDO PROTOCOLO...";
  double _progress = 0.0;

  void _startCardPaymentSequence() async {
    setState(() {
      _isCardProcessing = true;
      _statusText = "ENCRIPTANDO ENLACE DE PAGO...";
      _progress = 0.2;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _progress = 0.5;
      _statusText = "VALIDANDO TOKEN DE SEGURIDAD...";
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _progress = 0.8;
      _statusText = "AUTORIZANDO TRANSFERENCIA...";
    });

    try {
      await ref.read(billingProvider.notifier).processPayment(widget.amount);
      
      if (!mounted) return;
      setState(() {
        _progress = 1.0;
        _statusText = "LIQUIDACIÓN COMPLETADA";
      });

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop(); 
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCardProcessing = false;
        _statusText = "ERROR EN TRANSACCIÓN";
      });
    }
  }

  void _openPaymentLink() {
    final amountInArs = widget.amount * widget.exchangeRate;
    ref.read(billingProvider.notifier).openManualPaymentLink(amountInArs);
    Navigator.of(context).pop(); 
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    // CORRECCIÓN: Usamos primaryCard en lugar de card
    final card = billingState.value?.primaryCard;
    final hasCard = card != null;
    final double approxARS = widget.amount * widget.exchangeRate;

    // Color oficial de Mercado Pago
    const mpBlue = Color(0xFF009EE3);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 480, 
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.3), 
                Colors.transparent
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 10,
              )
            ]
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF09090B), // Fondo tech oscuro
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: AppColors.borderGlass),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                const Icon(Icons.hub_rounded, color: AppColors.primary, size: 40),
                const SizedBox(height: 16),
                const Text(
                  "PROTOCOLO DE LIQUIDACIÓN",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                    fontSize: 10,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Monto Grande en USD
                Text(
                  "\$ ${widget.amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontFamily: 'Oxanium',
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                // Conversión pequeña en ARS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2))
                  ),
                  child: Text(
                    "≈ \$ ${approxARS.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ARS",
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                // --- CONTENIDO DINÁMICO ---
                if (_isCardProcessing)
                  _buildProcessingState()
                else
                  Column(
                    children: [
                      // 1. SI TIENE TARJETA VINCULADA
                      if (hasCard) ...[
                        _PaymentOptionButton(
                          icon: Icons.flash_on_rounded,
                          label: "PAGAR AHORA",
                          subLabel: "Tarjeta •••• ${card.lastFour}",
                          color: AppColors.success, 
                          onTap: _startCardPaymentSequence,
                          isOutlined: false, 
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.borderGlass)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text("MÉTODOS ALTERNATIVOS", style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 10, letterSpacing: 1.5)),
                            ),
                            const Expanded(child: Divider(color: AppColors.borderGlass)),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 2. BOTÓN MERCADO PAGO
                      _PaymentOptionButton(
                        icon: Icons.handshake_rounded,
                        label: "ENLACE DE PAGO WEB",
                        subLabel: "Pagar en Pesos vía Mercado Pago",
                        color: mpBlue,
                        onTap: _openPaymentLink,
                        isOutlined: hasCard, 
                      ),

                      // 3. BOTÓN VINCULAR
                      if (!hasCard) ...[
                        const SizedBox(height: 16),
                        _PaymentOptionButton(
                          icon: Icons.add_card_rounded,
                          label: "VINCULAR TARJETA DE CRÉDITO",
                          subLabel: "Para mayor comodidad en futuros ciclos",
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(context: context, builder: (c) => const AddCardModal());
                          },
                          isOutlined: false,
                        ),
                      ],
                    ],
                  ),

                const SizedBox(height: 32),
                
                if (!_isCardProcessing)
                  // BOTÓN CANCELAR (BLANCO Y VISIBLE)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.white, // Letras blancas
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "CANCELAR OPERACIÓN", 
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9), // Blanco casi puro
                          fontSize: 11, 
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold
                        )
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

  Widget _buildProcessingState() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80, height: 80,
              child: CircularProgressIndicator(
                color: AppColors.primary, 
                strokeWidth: 2,
                backgroundColor: AppColors.primary.withOpacity(0.1),
              ),
            ),
            const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 30),
          ],
        ),
        const SizedBox(height: 30),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 4,
            backgroundColor: Colors.white10,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _statusText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Courier',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

// --- BOTÓN TECH INTERACTIVO (SUTIL) ---
class _PaymentOptionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _PaymentOptionButton({
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.color,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  State<_PaymentOptionButton> createState() => _PaymentOptionButtonState();
}

class _PaymentOptionButtonState extends State<_PaymentOptionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color;
    final Color backgroundColor = baseColor.withOpacity(_isHovered ? 0.1 : 0.05);
    final Color borderColor = baseColor.withOpacity(_isHovered ? 0.8 : 0.3);
    const double borderWidth = 1.0; 

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut, 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.isOutlined ? Colors.transparent : backgroundColor,
          border: Border.all(
            color: widget.isOutlined 
               ? baseColor.withOpacity(_isHovered ? 1.0 : 0.5) 
               : borderColor,
            width: borderWidth,
          ),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: baseColor.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 0,
            )
          ] : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: baseColor.withOpacity(0.2),
            highlightColor: baseColor.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: baseColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.0,
                            fontFamily: 'Oxanium'
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subLabel,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded, 
                    color: baseColor.withValues(alpha: _isHovered ? 1.0 : 0.4) 
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