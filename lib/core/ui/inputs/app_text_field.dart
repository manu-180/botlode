// lib/core/ui/inputs/app_text_field.dart
// Sistema de inputs «Hangar OS»: AppTextField, AppPasswordField, AppSearchField.
// Estados: default, focused (glow dorado), error (borde danger + mensaje), disabled.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  bool get _hasError => widget.errorText != null && widget.errorText!.isNotEmpty;

  Color get _borderColor {
    if (_hasError) return AppColors.danger;
    if (_focused) return AppColors.gold;
    return AppColors.borderDefault;
  }

  List<BoxShadow> get _shadow {
    if (_hasError && _focused) return AppDimens.glowStatus(AppColors.danger);
    if (_focused) return AppDimens.glowGold;
    return AppDimens.elev0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: AppMotion.durFast,
          curve: AppMotion.easeStandard,
          decoration: BoxDecoration(
            borderRadius: AppDimens.brM,
            border: Border.all(color: _borderColor, width: _focused ? 1.5 : 1),
            color: widget.enabled ? AppColors.bgElevated01 : AppColors.surface,
            boxShadow: _shadow,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textTertiary),
              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space12,
              ),
              counterText: '',
              fillColor: Colors.transparent,
              filled: false,
            ),
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: AppDimens.iconXS, color: AppColors.danger),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }
}

/// Input de contraseña con toggle de visibilidad.
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const AppPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint = 'Contraseña',
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      enabled: widget.enabled,
      keyboardType: TextInputType.visiblePassword,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      suffix: Semantics(
        label: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        button: true,
        child: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: AppColors.textTertiary,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        ),
      ),
    );
  }
}

/// Campo de búsqueda con ícono y botón limpiar.
class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final double? width;

  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Buscar...',
    this.onChanged,
    this.onClear,
    this.focusNode,
    this.width,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onTextChange);
  }

  void _onTextChange() {
    final v = (widget.controller?.text ?? '').isNotEmpty;
    if (v != _hasText) setState(() => _hasText = v);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: AppTextField(
        controller: widget.controller,
        hint: widget.hint,
        focusNode: widget.focusNode,
        onChanged: (v) {
          _onTextChange();
          widget.onChanged?.call(v);
        },
        prefix: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Icon(Icons.search, size: 18, color: AppColors.textTertiary),
        ),
        suffix: _hasText
            ? IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
                onPressed: () {
                  widget.controller?.clear();
                  widget.onClear?.call();
                  _hasText = false;
                },
                tooltip: 'Limpiar búsqueda',
              )
            : null,
      ),
    );
  }
}

