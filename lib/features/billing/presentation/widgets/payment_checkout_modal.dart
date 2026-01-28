// Archivo: lib/features/billing/presentation/widgets/payment_checkout_modal.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/services/payment_error_service.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PaymentCheckoutModal extends ConsumerStatefulWidget {
  final double amount;      
  final double exchangeRate; 

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
  
  bool _hasFailed = false;
  bool _hasSucceeded = false;

  String _failureTitle = "";
  String _failureMessage = "";

  String _statusText = "INICIANDO...";
  double _progress = 0.0;

  void _startCardPaymentSequence() async {
    setState(() {
      _isCardProcessing = true;
      _hasFailed = false; 
      _hasSucceeded = false;
      _statusText = "ENCRIPTANDO...";
      _progress = 0.2;
    });

    // Simulación visual de pasos de seguridad
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _progress = 0.5;
      _statusText = "VALIDANDO TOKEN...";
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _progress = 0.8;
      _statusText = "AUTORIZANDO...";
    });

    try {
      await ref.read(billingProvider.notifier).processPayment(widget.amount);
      
      if (!mounted) return;
      
      setState(() {
        _isCardProcessing = false;
        _hasSucceeded = true; 
      });

      // Delay para que el usuario vea el éxito antes de cerrar
      await Future.delayed(const Duration(milliseconds: 3500));
      if (mounted) Navigator.of(context).pop(); 

    } catch (e) {
      if (!mounted) return;
      
      // DELEGACIÓN DE LÓGICA AL HANDLER DE DOMINIO
      final errorDetails = PaymentErrorService.parseError(e.toString());

      setState(() {
        _isCardProcessing = false;
        _hasFailed = true;
        _failureTitle = errorDetails.title;
        _failureMessage = errorDetails.message;
      });
    }
  }

  void _openPaymentLink() {
    // 🧪 MODO PRUEBAS: Sin conversión, enviar USD directo
    ref.read(billingProvider.notifier).openManualPaymentLink(widget.amount);
    Navigator.of(context).pop(); 
  }

  List<Color> get _currentGradient {
    if (_hasFailed) return [AppColors.error, AppColors.error.withOpacity(0.2)];
    if (_hasSucceeded) return [AppColors.success, AppColors.success.withOpacity(0.2)];
    return [AppColors.primary.withOpacity(0.3), Colors.transparent];
  }

  Color get _currentShadowColor {
    if (_hasFailed) return AppColors.error.withOpacity(0.1);
    if (_hasSucceeded) return AppColors.success.withOpacity(0.2);
    return Colors.black.withOpacity(0.5);
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final card = billingState.value?.primaryCard;
    final hasCard = card != null;
    final double approxARS = widget.amount * widget.exchangeRate;

    const mpBlue = Color(0xFF009EE3);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 480, 
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: _currentGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _currentShadowColor,
                blurRadius: 40,
                spreadRadius: 10,
              )
            ]
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF09090B),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: AppColors.borderGlass),
            ),
            child: _buildContent(hasCard, card, mpBlue, approxARS),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool hasCard, var card, Color mpBlue, double approxARS) {
    if (_hasFailed) return _buildFailureState();
    if (_hasSucceeded) return _buildSuccessState();
    return _buildNormalState(hasCard, card, mpBlue, approxARS);
  }

  Widget _buildNormalState(bool hasCard, var card, Color mpBlue, double approxARS) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

        Column(
          children: [
            if (hasCard) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isCardProcessing
                    ? _buildProcessingCard()
                    : _PaymentOptionButton(
                        key: const ValueKey('btn_pay'),
                        icon: Icons.flash_on_rounded,
                        label: "PAGAR AHORA",
                        subLabel: "Tarjeta •••• ${card.lastFour}",
                        color: AppColors.success, 
                        onTap: _startCardPaymentSequence,
                        isOutlined: false, 
                      ),
              ),
              const SizedBox(height: 20),
              
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isCardProcessing ? 0.3 : 1.0,
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.borderGlass)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("MÉTODOS ALTERNATIVOS", style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 10, letterSpacing: 1.5)),
                    ),
                    const Expanded(child: Divider(color: AppColors.borderGlass)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            IgnorePointer(
              ignoring: _isCardProcessing,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isCardProcessing ? 0.3 : 1.0,
                child: Column(
                  children: [
                    _PaymentOptionButton(
                      icon: FontAwesomeIcons.handshake,
                      label: "ENLACE DE PAGO WEB",
                      subLabel: "Pagar en Pesos vía Mercado Pago",
                      color: mpBlue,
                      onTap: _openPaymentLink,
                      isOutlined: hasCard, 
                    ),

                    if (!hasCard) ...[
                      const SizedBox(height: 16),
                      _PaymentOptionButton(
                        icon: Icons.add_card_rounded,
                        label: "VINCULAR TARJETA DE CRÉDITO",
                        subLabel: "Para mayor comodidad en futuros ciclos",
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context, 
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (c) => const AddCardModal()
                          );
                        },
                        isOutlined: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isCardProcessing ? 0.0 : 1.0,
          child: IgnorePointer(
            ignoring: _isCardProcessing,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(12)
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "CANCELAR OPERACIÓN", 
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9), 
                    fontSize: 11, 
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold
                  )
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      width: double.infinity,
      height: 80, 
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
              color: AppColors.primary, 
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusText,
                  style: const TextStyle(
                    color: AppColors.primary, 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                    fontFamily: 'Courier'
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 4,
                    backgroundColor: Colors.black,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.15), 
                blurRadius: 15,
                spreadRadius: 1
              )
            ]
          ),
          child: const Icon(Icons.gpp_bad_rounded, color: AppColors.error, size: 40),
        )
        .animate(onPlay: (c) => c.repeat(period: 3.seconds))
        .shimmer(duration: 1.5.seconds, color: Colors.white.withOpacity(0.4), angle: 0.5),
        
        const SizedBox(height: 24),
        
        Text(
          _failureTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.error,
            fontFamily: 'Oxanium',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(
            _failureMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("CERRAR"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _hasFailed = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("REINTENTAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.15), 
                blurRadius: 15,
                spreadRadius: 1,
              )
            ]
          ),
          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
        )
        .animate()
        .scale(duration: 400.ms, curve: Curves.elasticOut)
        .then()
        .animate(onPlay: (c) => c.repeat(period: 3.seconds))
        .shimmer(duration: 1.5.seconds, color: Colors.white.withOpacity(0.4), angle: 0.5),

        const SizedBox(height: 24),

        const Text(
          "PAGO APROBADO",
          style: TextStyle(
            color: AppColors.success,
            fontFamily: 'Oxanium',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ).animate().fadeIn().moveY(begin: 10, end: 0),

        const SizedBox(height: 12),

        Text(
          "La transferencia se ha completado exitosamente.\nLos sistemas están operativos.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 32),

        Text(
          "CERRANDO PROTOCOLO...",
          style: TextStyle(
            color: AppColors.success.withOpacity(0.5),
            fontSize: 10,
            fontFamily: 'Courier',
            letterSpacing: 2.0
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}

class _PaymentOptionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _PaymentOptionButton({
    super.key,
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