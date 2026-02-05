// Archivo: lib/features/hunter_bot/presentation/widgets/config_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/hunter_bot/domain/models/hunter_config.dart';
import 'package:botslode/features/hunter_bot/presentation/providers/hunter_provider.dart';
import 'package:botslode/features/hunter_bot/presentation/widgets/success_dialog.dart';

/// Panel de configuración de Resend para HunterBot
class ConfigPanel extends ConsumerStatefulWidget {
  const ConfigPanel({super.key});

  @override
  ConsumerState<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends ConsumerState<ConfigPanel> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _apiKeyController;
  late TextEditingController _fromEmailController;
  late TextEditingController _fromNameController;
  late TextEditingController _calendarLinkController;
  late TextEditingController _nichoController;
  late TextEditingController _ciudadesController;
  late TextEditingController _paisController;
  
  bool _isApiKeyVisible = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(hunterProvider).config;
    
    _apiKeyController = TextEditingController(text: config?.resendApiKey ?? '');
    _fromEmailController = TextEditingController(text: config?.fromEmail ?? '');
    _fromNameController = TextEditingController(text: config?.fromName ?? 'Mi Empresa');
    _calendarLinkController = TextEditingController(text: config?.calendarLink ?? '');
    _nichoController = TextEditingController(text: config?.nicho ?? 'inmobiliarias');
    _ciudadesController = TextEditingController(
      text: config?.ciudades.join(', ') ?? 'Buenos Aires, Córdoba, Rosario'
    );
    _paisController = TextEditingController(text: config?.pais ?? 'Argentina');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _fromEmailController.dispose();
    _fromNameController.dispose();
    _calendarLinkController.dispose();
    _nichoController.dispose();
    _ciudadesController.dispose();
    _paisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGlass),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info box
                      _buildInfoBox(),
                      const SizedBox(height: 24),
                      
                      // API Key
                      _buildSectionTitle('CREDENCIALES RESEND'),
                      const SizedBox(height: 12),
                      _buildApiKeyField(),
                      const SizedBox(height: 8),
                      _buildResendLink(),
                      
                      const SizedBox(height: 24),
                      
                      // Email settings
                      _buildSectionTitle('CONFIGURACIÓN DE EMAIL'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _fromEmailController,
                        label: 'Email remitente',
                        hint: 'leads@tudominio.com',
                        icon: Icons.email_outlined,
                        validator: _validateEmail,
                        helperText: 'Debe ser un dominio verificado en Resend',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _fromNameController,
                        label: 'Nombre remitente',
                        hint: 'Tu Empresa',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _calendarLinkController,
                        label: 'Link de calendario (opcional)',
                        hint: 'https://calendly.com/tu-link',
                        icon: Icons.calendar_today_outlined,
                        helperText: 'Para el CTA del email',
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Bot configuration
                      _buildSectionTitle('CONFIGURACIÓN DEL BOT'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'El bot buscará dominios en Google automáticamente',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontFamily: 'Oxanium',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _nichoController,
                        label: 'Nicho / Industria',
                        hint: 'inmobiliarias, agencias de marketing, etc.',
                        icon: Icons.business_outlined,
                        helperText: 'Qué tipo de negocios buscar',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _ciudadesController,
                        label: 'Ciudades (separadas por coma)',
                        hint: 'Buenos Aires, Córdoba, Rosario',
                        icon: Icons.location_city_outlined,
                        helperText: 'Más ciudades = más resultados',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _paisController,
                        label: 'País',
                        hint: 'Argentina',
                        icon: Icons.flag_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(
          bottom: BorderSide(color: AppColors.borderGlass),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const FaIcon(
              FontAwesomeIcons.gear,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración de Hunter Bot',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Configura tus credenciales de Resend para enviar emails',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Oxanium',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.secondary.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Por qué necesito configurar Resend?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Para enviar emails de outreach, necesitas tu propia cuenta de Resend con un dominio verificado. Esto garantiza que los emails se envíen desde tu marca y evita problemas de spam.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                    fontFamily: 'Oxanium',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.6),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        fontFamily: 'Oxanium',
      ),
    );
  }

  Widget _buildApiKeyField() {
    return TextFormField(
      controller: _apiKeyController,
      obscureText: !_isApiKeyVisible,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Oxanium',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: 'API Key de Resend',
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Oxanium',
        ),
        hintText: 're_xxxxxxxxxxxxxxxx',
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.3),
          fontFamily: 'Oxanium',
        ),
        prefixIcon: const Icon(Icons.key, color: AppColors.textSecondary, size: 20),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _isApiKeyVisible = !_isApiKeyVisible),
          icon: Icon(
            _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: AppColors.background,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(focused: true),
        errorBorder: _inputBorder(error: true),
        focusedErrorBorder: _inputBorder(error: true),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'La API Key es requerida';
        }
        if (!value.startsWith('re_')) {
          return 'La API Key debe comenzar con "re_"';
        }
        return null;
      },
    );
  }

  Widget _buildResendLink() {
    return InkWell(
      onTap: _openResendDashboard,
      child: Row(
        children: [
          Icon(
            Icons.open_in_new,
            size: 12,
            color: AppColors.success.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            'Obtener API Key en resend.com/api-keys',
            style: TextStyle(
              color: AppColors.success.withOpacity(0.7),
              fontSize: 11,
              fontFamily: 'Oxanium',
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Oxanium',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Oxanium',
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.3),
          fontFamily: 'Oxanium',
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontSize: 10,
          fontFamily: 'Oxanium',
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(focused: true),
        errorBorder: _inputBorder(error: true),
        focusedErrorBorder: _inputBorder(error: true),
      ),
      validator: validator,
    );
  }

  OutlineInputBorder _inputBorder({bool focused = false, bool error = false}) {
    Color borderColor = AppColors.borderGlass;
    if (error) {
      borderColor = AppColors.error;
    } else if (focused) {
      borderColor = AppColors.success;
    }
    
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: borderColor,
        width: focused || error ? 1.5 : 1,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border(
          top: BorderSide(color: AppColors.borderGlass),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Oxanium'),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Guardar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Oxanium',
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final currentConfig = ref.read(hunterProvider).config;
      
      // Parsear ciudades (separadas por coma)
      final ciudadesStr = _ciudadesController.text.trim();
      final ciudades = ciudadesStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      final newConfig = (currentConfig ?? HunterConfig.empty('')).copyWith(
        resendApiKey: _apiKeyController.text.trim(),
        fromEmail: _fromEmailController.text.trim(),
        fromName: _fromNameController.text.trim(),
        calendarLink: _calendarLinkController.text.trim(),
        nicho: _nichoController.text.trim(),
        ciudades: ciudades.isNotEmpty ? ciudades : ['Buenos Aires'],
        pais: _paisController.text.trim(),
        isActive: true,
      );
      
      await ref.read(hunterProvider.notifier).saveConfig(newConfig);
      
      if (mounted) {
        Navigator.pop(context);
        
        // Mostrar diálogo épico de éxito
        await SuccessDialog.show(
          context,
          title: '¡HUNTER BOT CONFIGURADO!',
          message: 'Tu configuración ha sido guardada correctamente. Activa el bot para comenzar a buscar dominios automáticamente.',
          subtitle: 'Nicho: ${_nichoController.text.trim()} en ${_paisController.text.trim()}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar: $e',
              style: const TextStyle(fontFamily: 'Oxanium'),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openResendDashboard() async {
    final uri = Uri.parse('https://resend.com/api-keys');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
