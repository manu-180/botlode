// Archivo: lib/features/dashboard/presentation/widgets/create_bot_modal.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/bots_library/domain/models/blueprint.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:botslode/features/dashboard/presentation/views/dashboard_view.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 

class CreateBotModal extends ConsumerStatefulWidget {
  final BotBlueprint? template;

  const CreateBotModal({super.key, this.template});

  @override
  ConsumerState<CreateBotModal> createState() => _CreateBotModalState();
}

class _CreateBotModalState extends ConsumerState<CreateBotModal> {
  late Color _selectedColor;
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late TextEditingController _hexController;

  bool _isHexInputError = false;

  @override
  void initState() {
    super.initState();
    final template = widget.template;

    if (template != null) {
      _selectedColor = template.techColor;
      _nameController = TextEditingController(text: "${template.name} - Unit 01");
      // Usamos el Master Prompt completo
      _promptController = TextEditingController(text: template.masterPrompt);
    } else {
      _selectedColor = AppColors.primary;
      _nameController = TextEditingController();
      _promptController = TextEditingController();
    }

    _hexController = TextEditingController(
      text: _selectedColor.value.toRadixString(16).toUpperCase().substring(2)
    );
  }

  void _updateHexText(Color color) {
    if (mounted) {
       _hexController.text = color.value.toRadixString(16).toUpperCase().substring(2);
    }
  }

  void _handleHexSubmit(String value) {
    final hexCode = value.toUpperCase().replaceAll('#', '');
    if (hexCode.length != 6) {
      setState(() => _isHexInputError = true);
      return;
    }
    try {
      final newColor = Color(int.parse('0xFF$hexCode'));
      setState(() {
        _selectedColor = newColor;
        _isHexInputError = false;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => _isHexInputError = true);
    }
  }

  void _createBot() async {
    try {
      final credentials = await ref.read(botsProvider.notifier).addBot(
        name: _nameController.text.isEmpty ? 'Unidad Desconocida' : _nameController.text,
        description: '', // ⬅️ Ya no se usa, solo system_prompt
        systemPrompt: _promptController.text, 
        color: _selectedColor,
      );

      if (mounted) Navigator.of(context).pop();
      
      // ⬅️ NUEVO: Mostrar diálogo con PIN y alias generados
      if (mounted) {
        _showCredentialsDialog(context, credentials);
      }
      
      if (mounted) context.goNamed(DashboardView.routeName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear bot: $e')),
        );
      }
    }
  }
  
  // ⬅️ NUEVO: Diálogo para mostrar credenciales
  void _showCredentialsDialog(BuildContext context, Map<String, String> credentials) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.security, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "CREDENCIALES GENERADAS",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bot creado exitosamente: ${credentials['name']}",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _CredentialField(
              label: "ALIAS",
              value: credentials['alias'] ?? '',
              icon: Icons.alternate_email,
            ),
            const SizedBox(height: 16),
            _CredentialField(
              label: "PIN DE ACCESO",
              value: credentials['pin'] ?? '',
              icon: Icons.lock,
              isPin: true,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Guarda estas credenciales. Necesitarás el PIN para acceder al historial.",
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copiar PIN al portapapeles
              Clipboard.setData(ClipboardData(text: credentials['pin'] ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN copiado al portapapeles')),
              );
            },
            child: const Text("COPIAR PIN"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text("ENTENDIDO"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTemplateMode = widget.template != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 550,
          constraints: const BoxConstraints(maxHeight: 850),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderGlass),
            boxShadow: [
              BoxShadow(
                color: _selectedColor.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderGlass)),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedColor.withOpacity(0.5)),
                      ),
                      child: Icon(
                        isTemplateMode ? widget.template!.icon : Icons.build_circle_outlined, 
                        color: _selectedColor
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTemplateMode ? "CONFIGURAR PROTOTIPO" : "ENSAMBLAR NUEVA UNIDAD",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (isTemplateMode)
                          Text(
                            "Basado en: ${widget.template!.name}",
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("IDENTIFICADOR DE UNIDAD", style: _labelStyle),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Ej: Bot Pizzería Centro",
                          prefixIcon: Icon(Icons.smart_toy_outlined),
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // --- TARJETA PRO: CALIBRACIÓN ESTRATÉGICA (MODIFICADO) ---
                      Container(
                        width: double.infinity, // Ocupar todo el ancho disponible
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05), // Fondo dorado muy sutil
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.6), // Borde dorado visible
                            width: 1.5
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        // Layout simplificado: Columna directa sin Row ni Icono
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "CALIBRACIÓN DEL SYSTEM PROMPT",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Oxanium',
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: AppColors.textSecondary.withOpacity(0.9),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: "Esta plantilla es un chasis vacío. Para operatividad real, "),
                                  TextSpan(
                                    text: "debes inyectar los datos específicos del cliente",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: " (Precios, Horarios, Reglas de Reembolso). Sin esto, la unidad será genérica e inefectiva."),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      Text("DIRECTIVA PRIMARIA (SYSTEM PROMPT)", style: _labelStyle),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _promptController,
                        maxLines: 8, 
                        style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 12, height: 1.4),
                        decoration: const InputDecoration(
                          hintText: "Define aquí TODO: comportamiento, personalidad, tono, estilo...\nEj: 'Comportate serio y profesional' o 'Sé relajado y amigable'",
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 140), 
                            child: Icon(Icons.terminal_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("CALIBRACIÓN DE NÚCLEO", style: _labelStyle),
                          SizedBox(
                            width: 140,
                            height: 40,
                            child: TextField(
                              controller: _hexController,
                              style: TextStyle(
                                color: _selectedColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                                fontSize: 14,
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                                UpperCaseTextFormatter(),
                              ],
                              decoration: InputDecoration(
                                counterText: "",
                                prefixText: "# ",
                                prefixStyle: const TextStyle(color: AppColors.textSecondary),
                                filled: true,
                                fillColor: Colors.black,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: _isHexInputError ? AppColors.error : AppColors.borderGlass,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: _isHexInputError ? AppColors.error : _selectedColor,
                                  ),
                                ),
                              ),
                              onSubmitted: _handleHexSubmit,
                              onTapOutside: (_) => _handleHexSubmit(_hexController.text),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Theme(
                        data: ThemeData.dark(),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderGlass),
                          ),
                          child: ColorPicker(
                            pickerColor: _selectedColor,
                            onColorChanged: (color) {
                              setState(() {
                                _selectedColor = color;
                                _isHexInputError = false;
                                _updateHexText(color);
                              });
                            },
                            portraitOnly: true,
                            enableAlpha: false,
                            displayThumbColor: true,
                            paletteType: PaletteType.hsvWithHue,
                            hexInputBar: false,
                            labelTypes: const [],
                            pickerAreaHeightPercent: 0.6,
                            pickerAreaBorderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("CANCELAR"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _createBot,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: ThemeData.estimateBrightnessForColor(_selectedColor) == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      icon: const Icon(Icons.power_settings_new),
                      label: Text(isTemplateMode ? "INSTALAR UNIDAD" : "INICIAR SECUENCIA"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ⬅️ NUEVO: Widget para mostrar credenciales
class _CredentialField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isPin;

  const _CredentialField({
    required this.label,
    required this.value,
    required this.icon,
    this.isPin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primary.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.oxanium(
                    color: AppColors.primary,
                    fontSize: isPin ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: isPin ? 4.0 : 1.0,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                color: AppColors.primary.withOpacity(0.7),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copiado'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}