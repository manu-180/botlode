// lib/core/ui/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/app_icons.dart';
import 'app_button.dart';
import 'app_icon_button.dart';

enum AppTextFieldVariant { text, password, search }

enum AppTextFieldLabelMode { floating, top }

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.labelMode = AppTextFieldLabelMode.floating,
    this.variant = AppTextFieldVariant.text,
    this.prefixIcon,
    this.helperText,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.keyboardType,
    this.maxLines = 1,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final AppTextFieldLabelMode labelMode;
  final AppTextFieldVariant variant;
  final IconData? prefixIcon;
  final String? helperText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final TextInputType? keyboardType;
  final int maxLines;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => AppTextFieldState();
}

class AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _isFocused = false;
  bool _isHovered = false;
  bool _hadFocus = false;
  bool _obscureText = true;
  String? _errorText;

  bool get _hasText => widget.controller.text.isNotEmpty;
  bool get _hasError => _errorText != null;

  @override
  void initState() {
    super.initState();
    _initFocusNode();
    widget.controller.addListener(_onControllerChange);
  }

  void _initFocusNode() {
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
    if (old.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsFocusNode) _focusNode.dispose();
      _initFocusNode();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onControllerChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  /// Forces validation and shows the result inline.
  /// Returns true if the field is valid.
  bool validate() {
    final error = widget.validator?.call(widget.controller.text);
    if (mounted) {
      setState(() {
        _errorText = error;
        _hadFocus = true;
      });
    }
    return error == null;
  }

  void _onFocusChange() {
    final focused = _focusNode.hasFocus;
    if (!focused && _hadFocus) {
      final error = widget.validator?.call(widget.controller.text);
      if (mounted) setState(() => _errorText = error);
    }
    _hadFocus = focused;
    if (mounted) setState(() => _isFocused = focused);
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  // ─── Border colors ────────────────────────────────────────────────────────

  Color get _enabledBorderColor {
    if (_hasError) return AppColors.danger;
    if (_isHovered) return AppColors.borderStrong;
    return AppColors.borderDefault;
  }

  Color get _focusedBorderColor =>
      _hasError ? AppColors.danger : AppColors.borderGold;

  // ─── Glow shadows ─────────────────────────────────────────────────────────

  List<BoxShadow> get _glowShadows {
    if (!widget.enabled) return const [];
    if (_isFocused) {
      return [
        BoxShadow(
          color: _hasError
              ? AppColors.dangerGlow.withValues(alpha: 0.20)
              : AppColors.cyanGlow.withValues(alpha: 0.18),
          blurRadius: 12,
        ),
      ];
    }
    if (_hasError) {
      return [
        BoxShadow(
          color: AppColors.dangerGlow.withValues(alpha: 0.14),
          blurRadius: 10,
        ),
      ];
    }
    return const [];
  }

  // ─── Affix icon color ─────────────────────────────────────────────────────

  Color get _affixIconColor {
    if (!widget.enabled) return AppColors.textTertiary;
    if (_isFocused) return AppColors.cyan;
    return AppColors.textTertiary;
  }

  // ─── Border builder ───────────────────────────────────────────────────────

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: AppDimens.brM,
        borderSide: BorderSide(color: color, width: width),
      );

  // ─── Prefix icon ──────────────────────────────────────────────────────────

  Widget? _buildPrefixIcon() {
    final IconData? icon = widget.variant == AppTextFieldVariant.search
        ? AppIcons.search
        : widget.prefixIcon;
    if (icon == null) return null;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimens.space16,
        right: AppDimens.space12,
      ),
      child: AppIcons.icon(icon, size: AppDimens.iconS, color: _affixIconColor),
    );
  }

  // ─── Suffix icon ──────────────────────────────────────────────────────────

  Widget? _buildSuffixIcon() {
    switch (widget.variant) {
      case AppTextFieldVariant.password:
        return Padding(
          padding: const EdgeInsets.only(right: AppDimens.space8),
          child: AppIconButton(
            icon: _obscureText
                ? FontAwesomeIcons.eye
                : FontAwesomeIcons.eyeSlash,
            tooltip:
                _obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: widget.enabled
                ? () => setState(() => _obscureText = !_obscureText)
                : null,
          ),
        );

      case AppTextFieldVariant.search:
        // Always rendered; hidden with opacity when no text to avoid layout shifts.
        return AnimatedOpacity(
          opacity: _hasText ? 1.0 : 0.0,
          duration: AppMotion.durInstant,
          curve: AppMotion.easeStandard,
          child: IgnorePointer(
            ignoring: !_hasText,
            child: Padding(
              padding: const EdgeInsets.only(right: AppDimens.space8),
              child: AppIconButton(
                icon: AppIcons.close,
                tooltip: 'Limpiar',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: () {
                  widget.controller.clear();
                  _focusNode.requestFocus();
                },
              ),
            ),
          ),
        );

      case AppTextFieldVariant.text:
        return null;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final dur = reduce ? AppMotion.durCrossfadeReduced : AppMotion.durFast;
    final isFloating = widget.labelMode == AppTextFieldLabelMode.floating;

    final fillColor = widget.enabled
        ? AppColors.surfaceHud
        : AppColors.surfaceHud.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top label (mode == top)
        if (!isFloating && widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.space8),
        ],

        // Field: animated glow container + TextField
        MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.text
              : SystemMouseCursors.basic,
          onEnter: (_) {
            if (widget.enabled) setState(() => _isHovered = true);
          },
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: dur,
            curve: AppMotion.easeStandard,
            decoration: BoxDecoration(
              borderRadius: AppDimens.brM,
              boxShadow: _glowShadows,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              obscureText:
                  widget.variant == AppTextFieldVariant.password && _obscureText,
              keyboardType: widget.variant == AppTextFieldVariant.password
                  ? TextInputType.visiblePassword
                  : widget.keyboardType,
              maxLines: widget.variant == AppTextFieldVariant.password
                  ? 1
                  : widget.maxLines,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              cursorColor: AppColors.cyan,
              style: AppTextStyles.bodyM.copyWith(
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
              onChanged: (val) {
                widget.onChanged?.call(val);
                setState(() {});
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: fillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                  vertical: AppDimens.space12,
                ),
                // Floating label (mode == floating)
                labelText: isFloating ? widget.label : null,
                labelStyle: AppTextStyles.bodyM
                    .copyWith(color: AppColors.textTertiary),
                floatingLabelStyle: AppTextStyles.labelSmall.copyWith(
                  color: _hasError
                      ? AppColors.danger
                      : _isFocused
                          ? AppColors.cyan
                          : AppColors.textSecondary,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                // Borders — all driven from state, no errorText on InputDecoration
                border: _border(AppColors.borderDefault, 1.5),
                enabledBorder: _border(_enabledBorderColor, 1.5),
                focusedBorder: _border(_focusedBorderColor, 1.5),
                disabledBorder: _border(AppColors.borderSubtle, 1.0),
                errorBorder: _border(AppColors.danger, 1.5),
                focusedErrorBorder: _border(AppColors.danger, 1.5),
                // Prefix / suffix
                prefixIcon: _buildPrefixIcon(),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: _buildSuffixIcon(),
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ),
        ),

        // Helper / error row — always reserves space to prevent layout jumps
        _HelperErrorRow(
          helperText: widget.helperText,
          errorText: _errorText,
          reduced: reduce,
          duration: dur,
        ),
      ],
    );
  }
}

// ─── _HelperErrorRow ──────────────────────────────────────────────────────────

class _HelperErrorRow extends StatelessWidget {
  const _HelperErrorRow({
    this.helperText,
    this.errorText,
    required this.reduced,
    required this.duration,
  });

  final String? helperText;
  final String? errorText;
  final bool reduced;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    final Widget content;
    if (hasError) {
      content = Semantics(
        liveRegion: true,
        key: const ValueKey<String>('err'),
        child: Row(
          children: [
            AppIcons.icon(
              AppIcons.error,
              size: AppDimens.iconXS,
              color: AppColors.danger,
            ),
            const SizedBox(width: AppDimens.space4),
            Flexible(
              child: Text(
                errorText!,
                style: AppTextStyles.bodyS.copyWith(color: AppColors.danger),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else if (helperText != null) {
      content = Text(
        helperText!,
        key: const ValueKey<String>('hlp'),
        style: AppTextStyles.bodyS.copyWith(color: AppColors.textTertiary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      content = const SizedBox.shrink(key: ValueKey<String>('mt'));
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.space8),
      child: SizedBox(
        height: 20,
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: reduced ? Curves.linear : AppMotion.easeEntrance,
          switchOutCurve: AppMotion.easeStandard,
          transitionBuilder: (child, animation) {
            if (reduced) {
              return FadeTransition(opacity: animation, child: child);
            }
            // Error entry: fade + 4 px slide up
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: content,
        ),
      ),
    );
  }
}
