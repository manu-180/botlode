// Archivo: lib/features/dashboard/presentation/widgets/edit_color_dialog.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditColorDialog extends ConsumerStatefulWidget {
  final Bot bot;

  const EditColorDialog({super.key, required this.bot});

  @override
  ConsumerState<EditColorDialog> createState() => _EditColorDialogState();
}

class _EditColorDialogState extends ConsumerState<EditColorDialog> {
  late Color _selectedColor;
  late TextEditingController _hexController;
  bool _isHexInputError = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.bot.primaryColor;
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
      final newColor = Color(int.parse('FF$hexCode', radix: 16));
      setState(() {
        _selectedColor = newColor;
        _isHexInputError = false;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => _isHexInputError = true);
    }
  }

  void _saveColor() async {
    await ref.read(botsProvider.notifier).updateBotColor(
      widget.bot.id,
      _selectedColor,
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF09090B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _selectedColor.withOpacity(0.5), width: 2),
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
              // HEADER
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderGlass)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedColor.withOpacity(0.5)),
                      ),
                      child: Icon(Icons.palette_rounded, color: _selectedColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CALIBRACIÓN DE NÚCLEO",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              letterSpacing: 1.2,
                              fontSize: 18,
                              fontFamily: 'Oxanium',
                            ),
                          ),
                          Text(
                            widget.bot.name,
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),

              // CONTENIDO
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // HEX INPUT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "CÓDIGO CROMÁTICO",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontFamily: 'Oxanium',
                          ),
                        ),
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

                    // COLOR PICKER
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

                    const SizedBox(height: 24),

                    // BOTÓN GUARDAR
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saveColor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor,
                          foregroundColor: ThemeData.estimateBrightnessForColor(_selectedColor) == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.save_rounded),
                        label: const Text(
                          "APLICAR CALIBRACIÓN",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Oxanium',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
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
}

// Helper para convertir a mayúsculas
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
