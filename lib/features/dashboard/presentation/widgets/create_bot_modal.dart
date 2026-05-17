// Archivo: lib/features/dashboard/presentation/widgets/create_bot_modal.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/features/bots_library/domain/models/blueprint.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:botslode/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

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
      _selectedColor = AppColors.gold;
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
      builder: (context) => Shortcuts(
        shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
        child: Actions(
          actions: {
            _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            }),
          },
          child: AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            AppIcons.icon(AppIcons.lock, size: AppDimens.iconM, color: AppColors.gold),
            SizedBox(width: AppDimens.space12),
            Expanded(
              child: Text(
                "CREDENCIALES GENERADAS",
                style: AppTextStyles.bodyL.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
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
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppDimens.space24),
            _CredentialField(
              label: "ALIAS",
              value: credentials['alias'] ?? '',
              icon: Icons.alternate_email,
            ),
            SizedBox(height: AppDimens.space16),
            _CredentialField(
              label: "PIN DE ACCESO",
              value: credentials['pin'] ?? '',
              icon: Icons.lock,
              isPin: true,
            ),
            SizedBox(height: AppDimens.space20),
            Container(
              padding: EdgeInsets.all(AppDimens.space12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  AppIcons.icon(AppIcons.warning, size: AppDimens.iconS, color: AppColors.warning),
                  SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: Text(
                      "Guarda estas credenciales. Necesitarás el PIN para acceder al historial.",
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.warning,
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
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.textOnGold,
            ),
            child: const Text("ENTENDIDO"),
          ),
        ],
          ),
        ),
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
    final isTemplateMode = widget.template != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(AppDimens.space24),
        child: Container(
          width: 550,
          constraints: const BoxConstraints(maxHeight: 850),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: _selectedColor.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(AppDimens.space24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.durFast,
                      padding: EdgeInsets.all(AppDimens.space8),
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedColor.withValues(alpha: 0.5)),
                      ),
                      child: AppIcons.icon(
                        isTemplateMode ? widget.template!.icon : Icons.build_circle_outlined,
                        color: _selectedColor,
                      ),
                    ),
                    SizedBox(width: AppDimens.space12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTemplateMode ? "CONFIGURAR PROTOTIPO" : "ENSAMBLAR NUEVA UNIDAD",
                          style: AppTextStyles.titleL.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (isTemplateMode)
                          Text(
                            "Basado en: ${widget.template!.name}",
                            style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: AppIcons.icon(AppIcons.close, size: AppDimens.iconM, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppDimens.space32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("IDENTIFICADOR DE UNIDAD", style: _labelStyle),
                      SizedBox(height: AppDimens.space8),
                      TextField(
                        controller: _nameController,
                        style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: "Ej: Bot Pizzería Centro",
                          prefixIcon: Icon(Icons.smart_toy_outlined),
                        ),
                      ),

                      SizedBox(height: AppDimens.space32),

                      // --- TARJETA PRO: CALIBRACIÓN ESTRATÉGICA (MODIFICADO) ---
                      Container(
                        width: double.infinity, // Ocupar todo el ancho disponible
                        padding: EdgeInsets.all(AppDimens.space16),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.05), // Fondo dorado muy sutil
                          borderRadius: BorderRadius.circular(AppDimens.radiusS),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.6), // Borde dorado visible
                            width: 1.5
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.1),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        // Layout simplificado: Columna directa sin Row ni Icono
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CALIBRACIÓN DEL SYSTEM PROMPT",
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: AppDimens.space8),
                            RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodyS.copyWith(
                                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: "Esta plantilla es un chasis vacío. Para operatividad real, "),
                                  TextSpan(
                                    text: "debes inyectar los datos específicos del cliente",
                                    style: AppTextStyles.bodyS.copyWith(
                                      color: AppColors.textPrimary.withValues(alpha: 0.9),
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

                      SizedBox(height: AppDimens.space24),

                      Text("DIRECTIVA PRIMARIA (SYSTEM PROMPT)", style: _labelStyle),
                      SizedBox(height: AppDimens.space8),
                      TextField(
                        controller: _promptController,
                        maxLines: 8,
                        style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary, height: 1.4),
                        decoration: InputDecoration(
                          hintText: "Define aquí TODO: comportamiento, personalidad, tono, estilo...\nEj: 'Comportate serio y profesional' o 'Sé relajado y amigable'",
                          prefixIcon: Padding(
                            // 140 = layout-specific spacer to position icon above fold; not a token
                            padding: const EdgeInsets.only(bottom: 140),
                            child: AppIcons.icon(AppIcons.terminal, size: AppDimens.iconM, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimens.space24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text("CALIBRACIÓN DE NÚCLEO", style: _labelStyle)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 40,
                                child: TextField(
                                  controller: _hexController,
                                  style: AppTextStyles.mono.copyWith(
                                    color: _selectedColor,
                                    fontWeight: FontWeight.bold,
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
                                    prefixStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                                    filled: true,
                                    fillColor: AppColors.surfaceHud,
                                    contentPadding: EdgeInsets.symmetric(horizontal: AppDimens.space12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                                      borderSide: BorderSide(
                                        color: _isHexInputError ? AppColors.danger : AppColors.borderDefault,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                                      borderSide: BorderSide(
                                        color: _isHexInputError ? AppColors.danger : _selectedColor,
                                      ),
                                    ),
                                  ),
                                  onSubmitted: _handleHexSubmit,
                                  onTapOutside: (_) => _handleHexSubmit(_hexController.text),
                                ),
                              ),
                              if (_isHexInputError)
                                Semantics(
                                  liveRegion: true,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: AppDimens.space4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.error_outline, size: 12, color: AppColors.danger),
                                        const SizedBox(width: AppDimens.space4),
                                        Text(
                                          'Código hex inválido',
                                          style: AppTextStyles.bodyS.copyWith(color: AppColors.danger),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimens.space16),
                      Theme(
                        data: ThemeData.dark(),
                        child: Container(
                          padding: EdgeInsets.all(AppDimens.space16),
                          decoration: BoxDecoration(
                            color: AppColors.voidBlack.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(AppDimens.radiusL),
                            border: Border.all(color: AppColors.borderDefault),
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
                            pickerAreaBorderRadius: BorderRadius.circular(AppDimens.radiusS),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(AppDimens.space24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("CANCELAR"),
                    ),
                    SizedBox(width: AppDimens.space16),
                    ElevatedButton.icon(
                      onPressed: _createBot,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: ThemeData.estimateBrightnessForColor(_selectedColor) == Brightness.dark
                            ? AppColors.textPrimary
                            : AppColors.textOnGold,
                      ),
                      icon: AppIcons.icon(AppIcons.power, size: AppDimens.iconS, color: null),
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

  TextStyle get _labelStyle => AppTextStyles.bodyS.copyWith(
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
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.gold.withValues(alpha: 0.7),
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: AppDimens.space8),
        Container(
          padding: EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.voidBlack.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              AppIcons.icon(icon, size: AppDimens.iconS, color: AppColors.gold),
              SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.titleL.copyWith(
                    color: AppColors.gold,
                    fontSize: isPin ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: isPin ? 4.0 : 1.0,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copiar $label',
                icon: AppIcons.icon(AppIcons.copy, size: AppDimens.iconS, color: AppColors.gold.withValues(alpha: 0.7)),
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
