// Archivo: lib/features/settings/presentation/widgets/change_password_dialog.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).updatePassword(_passController.text);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _success = true;
        });
        
        // Cierre automático tras éxito
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si hubo éxito, mostramos estado de confirmación limpio
    if (_success) {
      return _buildSuccessState();
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 2,
              )
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppColors.primary, size: 28)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "ACTUALIZAR CREDENCIALES",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Oxanium',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Establezca una nueva clave de acceso segura para el operador.",
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12),
                ),
                const SizedBox(height: 32),

                _buildPasswordField(
                  controller: _passController,
                  label: "NUEVA CONTRASEÑA",
                  textInputAction: TextInputAction.next, // Pasa al siguiente campo
                  validator: (val) {
                    if (val == null || val.length < 6) return "Mínimo 6 caracteres";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _confirmController,
                  label: "CONFIRMAR CONTRASEÑA",
                  textInputAction: TextInputAction.done, // Finaliza
                  onSubmitted: (_) => _submit(), // EJECUTA EL CAMBIO AL DAR ENTER
                  validator: (val) {
                    if (val != _passController.text) return "Las contraseñas no coinciden";
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ErrorFeedbackCard(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Text(
                          "GUARDAR CAMBIOS",
                          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Oxanium', letterSpacing: 1.5),
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

  Widget _buildSuccessState() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF09090B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.success),
            boxShadow: [
              BoxShadow(color: AppColors.success.withOpacity(0.2), blurRadius: 40, spreadRadius: 5)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 64)
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
              const SizedBox(height: 24),
              const Text(
                "CLAVE ACTUALIZADA",
                style: TextStyle(
                  color: AppColors.success,
                  fontFamily: 'Oxanium',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Las credenciales han sido renovadas correctamente en el sistema central.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
          cursorColor: AppColors.primary,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          textInputAction: textInputAction, // Configuración de teclado
          onFieldSubmitted: onSubmitted,    // Acción al dar Enter
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white24),
          ),
        ),
      ],
    );
  }
}