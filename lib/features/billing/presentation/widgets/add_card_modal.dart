// Archivo: lib/features/billing/presentation/widgets/add_card_modal.dart
import 'dart:async';
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddCardModal extends ConsumerStatefulWidget {
  const AddCardModal({super.key});
  @override
  ConsumerState<AddCardModal> createState() => _AddCardModalState();
}

class _AddCardModalState extends ConsumerState<AddCardModal> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  bool _isLoading = false;
  String _cardType = "UNKNOWN";

  @override
  void dispose() {
    _numberCtrl.dispose(); _expiryCtrl.dispose(); _cvvCtrl.dispose(); _holderCtrl.dispose();
    super.dispose();
  }

  void _detectBrand(String number) {
    String cleanNum = number.replaceAll(' ', '');
    String type = "UNKNOWN";
    if (cleanNum.startsWith('4')) type = "VISA";
    else if (RegExp(r'^(5[1-5]|222[1-9]|22[3-9]|2[3-6]|27[0-1]|2720)').hasMatch(cleanNum)) type = "MASTERCARD";
    if (_cardType != type) setState(() => _cardType = type);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final dateParts = _expiryCtrl.text.split('/');
    if (dateParts.length != 2) { setState(() => _isLoading = false); return; }

    try {
      final cleanNum = _numberCtrl.text.replaceAll(' ', '');
      final lastFour = cleanNum.length >= 4 ? cleanNum.substring(cleanNum.length - 4) : '0000';

      await ref.read(billingProvider.notifier).linkNewCard(
        number: _numberCtrl.text, month: dateParts[0], year: "20${dateParts[1]}",
        cvv: _cvvCtrl.text, holder: _holderCtrl.text.toUpperCase(), brand: _cardType, lastFour: lastFour,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar formulario

      // --- FEEDBACK AUTO-CLOSE (Timer) ---
      showGeneralDialog(
        context: context, barrierDismissible: false, barrierLabel: '',
        pageBuilder: (ctx, a1, a2) => Container(),
        transitionBuilder: (ctx, a1, a2, child) => ScaleTransition(scale: CurvedAnimation(parent: a1, curve: Curves.elasticOut), child: _SuccessDialog()),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ERROR: $e"), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: 500,
          decoration: BoxDecoration(color: const Color(0xFF09090B), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5)]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCardPreview(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("VINCULAR MÉTODO DE PAGO", style: TextStyle(color: Colors.white, fontFamily: 'Oxanium', fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 24),
                      _TechInput(label: "NÚMERO DE TARJETA", controller: _numberCtrl, icon: Icons.credit_card, hint: "0000 0000 0000 0000", inputType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, _CardNumberFormatter(), LengthLimitingTextInputFormatter(19)], onChanged: (val) { _detectBrand(val); setState(() {}); }, validator: (val) => (val == null || val.length < 19) ? "Incompleto" : null),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _TechInput(label: "EXPIRACIÓN", controller: _expiryCtrl, icon: Icons.calendar_today_rounded, hint: "MM/AA", inputType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, _DateFormatter(), LengthLimitingTextInputFormatter(5)], validator: (val) => (val == null || val.length < 5) ? "Inválido" : null)),
                          const SizedBox(width: 16),
                          Expanded(child: _TechInput(label: "CVV", controller: _cvvCtrl, icon: Icons.lock_outline_rounded, hint: "123", inputType: TextInputType.number, isObscure: true, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], validator: (val) => (val == null || val.length < 3) ? "Inválido" : null)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _TechInput(
                        label: "TITULAR DE LA CUENTA", controller: _holderCtrl, icon: Icons.person_outline_rounded, hint: "COMO FIGURA EN LA TARJETA", inputType: TextInputType.name, 
                        formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))], onChanged: (_) => setState(() {}), validator: (val) => val!.isEmpty ? "Requerido" : null,
                        // --- ENTER PARA ENVIAR ---
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(), 
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _isLoading 
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)), const SizedBox(width: 12), const Text("PROCESANDO...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))])
                            : const Text("INICIAR PROTOCOLO DE ENLACE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    Color brandColor = AppColors.primary; String brandName = "TARJETA";
    if (_cardType == 'VISA') { brandColor = const Color(0xFF1A1F71); brandName = "VISA"; } 
    else if (_cardType == 'MASTERCARD') { brandColor = const Color(0xFFEB001B); brandName = "MASTERCARD"; }
    return Container(
      width: double.infinity, height: 200, 
      decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), gradient: LinearGradient(colors: [brandColor.withValues(alpha: 0.8), Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.nfc, color: Colors.white54, size: 30), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)), child: Text(brandName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)))]),
        Text(_numberCtrl.text.isEmpty ? "0000 0000 0000 0000" : _numberCtrl.text, style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2.0, shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))])),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("TITULAR", style: TextStyle(color: Colors.white54, fontSize: 9)), Text(_holderCtrl.text.isEmpty ? "NOMBRE APELLIDO" : _holderCtrl.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("VENCE", style: TextStyle(color: Colors.white54, fontSize: 9)), Text(_expiryCtrl.text.isEmpty ? "MM/AA" : _expiryCtrl.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))])])
      ]),
    );
  }
}

class _TechInput extends StatelessWidget {
  final String label; final TextEditingController controller; final IconData icon; final String hint; final TextInputType inputType; final List<TextInputFormatter>? formatters; final Function(String)? onChanged; final String? Function(String?)? validator; final bool isObscure; 
  final TextInputAction? textInputAction; final Function(String)? onSubmitted; 

  const _TechInput({required this.label, required this.controller, required this.icon, required this.hint, required this.inputType, this.formatters, this.onChanged, this.validator, this.isObscure = false, this.textInputAction, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)), const SizedBox(height: 8),
      TextFormField(controller: controller, keyboardType: inputType, inputFormatters: formatters, onChanged: onChanged, validator: validator, obscureText: isObscure, textInputAction: textInputAction, onFieldSubmitted: onSubmitted, style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontWeight: FontWeight.bold), decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.05), hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontFamily: 'Courier'), prefixIcon: Icon(icon, color: AppColors.primary, size: 20), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1)), errorStyle: TextStyle(color: AppColors.error.withValues(alpha: 0.8), fontSize: 10))),
    ]);
  }
}

class _CardNumberFormatter extends TextInputFormatter { @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) { var t = n.text; if (n.selection.baseOffset == 0) return n; var b = StringBuffer(); for (int i = 0; i < t.length; i++) { b.write(t[i]); var idx = i + 1; if (idx % 4 == 0 && idx != t.length) b.write(' '); } var s = b.toString(); return n.copyWith(text: s, selection: TextSelection.collapsed(offset: s.length)); } }
class _DateFormatter extends TextInputFormatter { @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) { var t = n.text; if (n.selection.baseOffset == 0) return n; var b = StringBuffer(); for (int i = 0; i < t.length; i++) { b.write(t[i]); if ((i + 1) == 2 && (i + 1) != t.length) b.write('/'); } var s = b.toString(); return n.copyWith(text: s, selection: TextSelection.collapsed(offset: s.length)); } }

// --- DIALOGO DE ÉXITO CON AUTO-CLOSE ---
class _SuccessDialog extends StatefulWidget {
  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  @override
  void initState() {
    super.initState();
    // Auto-Close después de 3.5 segundos
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.primary, width: 2), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 40, spreadRadius: 10)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.2)), child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 50)),
            const SizedBox(height: 24),
            const Text("PROTOCOLO EXITOSO", style: TextStyle(color: Colors.white, fontFamily: 'Oxanium', fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2.0)),
            const SizedBox(height: 8),
            Text("Tarjeta vinculada y encriptada correctamente.", style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}