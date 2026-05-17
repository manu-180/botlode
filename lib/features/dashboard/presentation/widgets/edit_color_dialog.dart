// Archivo: lib/features/dashboard/presentation/widgets/edit_color_dialog.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

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
    return Shortcuts(
      shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
      child: Actions(
        actions: {
          _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) {
            _saveColor();
            return null;
          }),
        },
        child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
          padding: EdgeInsets.all(AppDimens.space24),
          decoration: BoxDecoration(
            color: AppColors.surfaceHud,
            borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            border: Border.all(color: _selectedColor.withValues(alpha: 0.5), width: 2),
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
              // HEADER
              Container(
                padding: EdgeInsets.all(AppDimens.space24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: AppDimens.space48,
                      height: AppDimens.space48,
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedColor.withValues(alpha: 0.5)),
                      ),
                      child: AppIcons.icon(Icons.palette_rounded, color: _selectedColor),
                    ),
                    SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CALIBRACIÓN DE NÚCLEO",
                            style: AppTextStyles.titleL.copyWith(
                              color: AppColors.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            widget.bot.name,
                            style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: AppIcons.icon(AppIcons.close, size: AppDimens.iconM, color: AppColors.textTertiary),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),

              // CONTENIDO
              Padding(
                padding: EdgeInsets.all(AppDimens.space24),
                child: Column(
                  children: [
                    // HEX INPUT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "CÓDIGO CROMÁTICO",
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
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
                              prefixStyle: const TextStyle(color: AppColors.textSecondary),
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
                      ],
                    ),
                    SizedBox(height: AppDimens.space16),

                    // COLOR PICKER
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

                    SizedBox(height: AppDimens.space24),

                    // BOTÓN GUARDAR
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saveColor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor,
                          foregroundColor: ThemeData.estimateBrightnessForColor(_selectedColor) == Brightness.dark
                              ? AppColors.textPrimary
                              : AppColors.textOnGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusS)),
                        ),
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          "APLICAR CALIBRACIÓN",
                          style: AppTextStyles.label.copyWith(
                            color: ThemeData.estimateBrightnessForColor(_selectedColor) == Brightness.dark
                                ? AppColors.textPrimary
                                : AppColors.textOnGold,
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
