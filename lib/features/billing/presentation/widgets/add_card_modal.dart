// Archivo: lib/features/billing/presentation/widgets/add_card_modal.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/features/billing/domain/logic/card_validator_logic.dart'; // IMPORTACIÓN DE LA LÓGICA
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddCardModal extends ConsumerStatefulWidget {
  const AddCardModal({super.key});

  @override
  ConsumerState<AddCardModal> createState() => _AddCardModalState();
}

class _AddCardModalState extends ConsumerState<AddCardModal> {
  final _formKey = GlobalKey<FormState>();
  
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _holderController = TextEditingController();

  bool _isLinking = false;
  String? _errorMessage;
  
  // Estado local visual (la lógica de detección viene de la clase de dominio)
  CardBrand _detectedBrand = CardBrand.unknown;

  // --- MÁSCARAS ---
  final _cardMaskStandard = MaskTextInputFormatter(
    mask: '#### #### #### ####', 
    filter: {"#": RegExp(r'[0-9]')}
  );

  final _cardMaskAmex = MaskTextInputFormatter(
    mask: '#### ###### #####', 
    filter: {"#": RegExp(r'[0-9]')}
  );
  
  final _expiryMask = MaskTextInputFormatter(
    mask: '##/##', 
    filter: {"#": RegExp(r'[0-9]')}
  );

  @override
  void initState() {
    super.initState();
    _numberController.addListener(_onCardNumberChanged);
  }

  @override
  void dispose() {
    _numberController.removeListener(_onCardNumberChanged);
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  // Listener UI: Solo actualiza el estado visual si la marca cambia
  void _onCardNumberChanged() {
    final brand = CardValidatorLogic.detectBrand(_numberController.text);
    if (brand != _detectedBrand) {
      setState(() => _detectedBrand = brand);
    }
  }

  Future<void> _submit() async {
    if (_isLinking) return; 
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLinking = true;
      _errorMessage = null; 
    });

    try {
      final expiryParts = _expiryController.text.split('/');
      final month = expiryParts[0];
      final year = "20${expiryParts[1]}"; 
      final numberClean = _numberController.text.replaceAll(' ', '');
      
      // Mapeo seguro del nombre de la marca para el backend
      String brandStr = _detectedBrand.name; 
      if (_detectedBrand == CardBrand.unknown) brandStr = 'visa'; 

      await ref.read(billingProvider.notifier).linkNewCard(
        number: numberClean,
        month: month,
        year: year,
        cvv: _cvvController.text,
        holder: _holderController.text,
        brand: brandStr,
        lastFour: numberClean.length > 4 ? numberClean.substring(numberClean.length - 4) : '0000',
      );

      if (mounted) Navigator.of(context).pop(); 

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLinking = false;
          // Limpieza básica del mensaje de error técnico
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMask = _detectedBrand == CardBrand.amex ? _cardMaskAmex : _cardMaskStandard;
    final cvvLength = _detectedBrand == CardBrand.amex ? 4 : 3;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
        left: 16, 
        right: 16, 
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            // PANEL PRINCIPAL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFF09090B), 
                borderRadius: BorderRadius.all(Radius.circular(30)), 
                border: Border.fromBorderSide(BorderSide(color: AppColors.primary, width: 2)), 
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))
                ],
              ),
              child: Material(
                type: MaterialType.transparency, 
                child: Form(
                  key: _formKey,
                  child: Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "VINCULAR MÉTODO DE PAGO",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Oxanium',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Protocolo seguro de tokenización (PCI-DSS Compliant)",
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                          const SizedBox(height: 30),
                    
                          // INPUT: NÚMERO DE TARJETA
                          _buildLabel("NÚMERO DE TARJETA"),
                          _buildInput(
                            controller: _numberController,
                            hint: _detectedBrand == CardBrand.amex ? "0000 000000 00000" : "0000 0000 0000 0000",
                            icon: Icons.credit_card,
                            formatter: currentMask,
                            inputType: TextInputType.number,
                            suffix: _buildBrandBadge(),
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Número requerido";
                              
                              final clean = val.replaceAll(' ', '');
                              // Validación de longitud según marca
                              if (_detectedBrand == CardBrand.amex) {
                                if (clean.length < 15) return "Amex requiere 15 dígitos";
                              } else {
                                if (clean.length < 16) return "Número incompleto";
                              }

                              // Uso de la lógica de dominio
                              if (!CardValidatorLogic.isValidLuhn(clean)) return "Número inválido (Luhn Check)";
                              return null;
                            }
                          ),
                          const SizedBox(height: 20),
                    
                          // FILA: EXPIRACIÓN Y CVV
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("EXPIRACIÓN"),
                                    _buildInput(
                                      controller: _expiryController,
                                      hint: "MM/AA",
                                      icon: Icons.calendar_today,
                                      formatter: _expiryMask,
                                      inputType: TextInputType.number,
                                      // Uso de la lógica de dominio
                                      validator: CardValidatorLogic.validateExpiry,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("CVV"),
                                    _buildInput(
                                      controller: _cvvController,
                                      hint: _detectedBrand == CardBrand.amex ? "1234" : "123",
                                      icon: Icons.lock_outline,
                                      isObscure: true,
                                      inputType: TextInputType.number,
                                      maxLength: cvvLength,
                                      validator: (val) {
                                        if (val == null || val.length < cvvLength) return "Inválido";
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                    
                          // INPUT: TITULAR
                          _buildLabel("TITULAR DE LA CUENTA"),
                          _buildInput(
                            controller: _holderController,
                            hint: "Como aparece en la tarjeta",
                            icon: Icons.person_outline,
                            inputType: TextInputType.name,
                            textCapitalization: TextCapitalization.characters,
                            isLastField: true, 
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Nombre requerido";
                              if (val.contains(RegExp(r'[0-9]'))) return "Sin números";
                              return null;
                            }
                          ),
                          
                          const SizedBox(height: 30),
                    
                          // FEEDBACK DE ERROR
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ErrorFeedbackCard(
                                message: _errorMessage!,
                                onDismiss: () => setState(() => _errorMessage = null),
                              ),
                            ),
                            
                          // BOTÓN DE ACCIÓN
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLinking ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                              ),
                              child: _isLinking 
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20, height: 20, 
                                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "INICIANDO PROTOCOLO...",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Oxanium', letterSpacing: 1.0),
                                      )
                                    ],
                                  )
                                : const Text(
                                    "INICIAR PROTOCOLO DE ENLACE",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Oxanium',
                                      fontSize: 16,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Badge & Inputs) ---

  Widget _buildBrandBadge() {
    IconData icon;
    Color color;
    String text;

    switch (_detectedBrand) {
      case CardBrand.visa:
        icon = FontAwesomeIcons.ccVisa;
        color = Colors.white; 
        text = "VISA";
        break;
      case CardBrand.mastercard:
        icon = FontAwesomeIcons.ccMastercard;
        color = const Color(0xFFFF5F00);
        text = "MASTER";
        break;
      case CardBrand.amex:
        icon = FontAwesomeIcons.ccAmex;
        color = const Color(0xFF006FCF);
        text = "AMEX";
        break;
      case CardBrand.discover:
        icon = FontAwesomeIcons.ccDiscover;
        color = const Color(0xFFE55C20);
        text = "DISC";
        break;
      default:
        return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_detectedBrand),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputFormatter? formatter,
    bool isObscure = false,
    TextInputType inputType = TextInputType.text,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction action = TextInputAction.next,
    String? Function(String?)? validator,
    Widget? suffix,
    bool isLastField = false, 
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: inputType,
        textInputAction: TextInputAction.done, 
        onFieldSubmitted: (_) => _submit(), 
        textCapitalization: textCapitalization,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: formatter != null ? [formatter] : (maxLength != null ? [LengthLimitingTextInputFormatter(maxLength)] : []),
        style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontWeight: FontWeight.bold),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 20),
          suffixIcon: suffix != null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [suffix]) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          counterText: "", 
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 11, height: 0.8),
        ),
      ),
    );
  }
}