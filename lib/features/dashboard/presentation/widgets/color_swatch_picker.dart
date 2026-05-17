// Archivo: lib/features/dashboard/presentation/widgets/color_swatch_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';

// ─── Predefined palette ────────────────────────────────────────────────────

class _SwatchEntry {
  const _SwatchEntry({required this.color, required this.label});
  final Color color;
  final String label;
}

const List<_SwatchEntry> _kPalette = [
  _SwatchEntry(color: AppColors.gold, label: 'Dorado'),
  _SwatchEntry(color: AppColors.cyan, label: 'Cian'),
  _SwatchEntry(color: AppColors.success, label: 'Verde'),
  _SwatchEntry(color: AppColors.danger, label: 'Rojo'),
  _SwatchEntry(color: AppColors.warning, label: 'Naranja'),
  _SwatchEntry(color: AppColors.info, label: 'Azul'),
  _SwatchEntry(color: AppColors.accentMagenta, label: 'Magenta'),
  _SwatchEntry(color: AppColors.accentViolet, label: 'Violeta'),
];

// ─── Public widget ─────────────────────────────────────────────────────────

class ColorSwatchPicker extends StatefulWidget {
  const ColorSwatchPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final Color value;
  final ValueChanged<Color> onChanged;
  final bool enabled;

  @override
  State<ColorSwatchPicker> createState() => _ColorSwatchPickerState();
}

class _ColorSwatchPickerState extends State<ColorSwatchPicker>
    with SingleTickerProviderStateMixin {
  bool _pickerOpen = false;

  // Holds the in-progress color while the HueRingPicker is open,
  // confirmed only when the user taps CONFIRMAR.
  late Color _pendingColor;

  // Which predefined entry is currently selected (null = custom).
  _SwatchEntry? _selectedEntry(Color c) {
    for (final e in _kPalette) {
      if (e.color == c) return e;
    }
    return null;
  }

  bool get _isCustom => _selectedEntry(widget.value) == null;

  @override
  void initState() {
    super.initState();
    _pendingColor = widget.value;
  }

  @override
  void didUpdateWidget(ColorSwatchPicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_pickerOpen) {
      _pendingColor = widget.value;
    }
  }

  void _selectPredefined(_SwatchEntry entry) {
    if (!widget.enabled) return;
    setState(() {
      _pickerOpen = false;
      _pendingColor = entry.color;
    });
    widget.onChanged(entry.color);
  }

  void _toggleCustomPicker() {
    if (!widget.enabled) return;
    setState(() {
      _pickerOpen = !_pickerOpen;
      if (_pickerOpen) _pendingColor = widget.value;
    });
  }

  void _confirmCustom() {
    widget.onChanged(_pendingColor);
    setState(() => _pickerOpen = false);
  }

  void _cancelCustom() {
    setState(() {
      _pickerOpen = false;
      _pendingColor = widget.value;
    });
  }

  // ─── Hex helper ────────────────────────────────────────────────────────────

  String _hexString(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final selected = _selectedEntry(widget.value);
    final expandDuration =
        reduce ? AppMotion.durCrossfadeReduced : AppMotion.durBase;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Label ──────────────────────────────────────────────────────────
          Text(
            '// COLOR TÉCNICO',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.space8),

          // ── Swatches row + preview ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Wrap(
                  spacing: AppDimens.space8,
                  runSpacing: AppDimens.space8,
                  children: [
                    ..._kPalette.map((e) {
                      final isSelected = selected?.color == e.color;
                      return _SwatchTile(
                        color: e.color,
                        label: e.label,
                        isSelected: isSelected,
                        reduce: reduce,
                        onTap: () => _selectPredefined(e),
                      );
                    }),
                    _CustomSwatchTile(
                      isActive: _isCustom,
                      isOpen: _pickerOpen,
                      reduce: reduce,
                      activeColor: widget.value,
                      onTap: _toggleCustomPicker,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.space16),
              _ColorPreview(
                color: widget.value,
                hexLabel: _hexString(widget.value),
              ),
            ],
          ),

          // ── Inline color picker ────────────────────────────────────────────
          AnimatedContainer(
            duration: expandDuration,
            curve: reduce ? Curves.linear : AppMotion.easeStandard,
            height: _pickerOpen ? 280 : 0,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 0,
                maxHeight: 280,
                child: _InlineColorPicker(
                  color: _pendingColor,
                  onColorChanged: (c) => setState(() => _pendingColor = c),
                  onConfirm: _confirmCustom,
                  onCancel: _cancelCustom,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _SwatchTile ───────────────────────────────────────────────────────────

class _SwatchTile extends StatefulWidget {
  const _SwatchTile({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.reduce,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool isSelected;
  final bool reduce;
  final VoidCallback onTap;

  @override
  State<_SwatchTile> createState() => _SwatchTileState();
}

class _SwatchTileState extends State<_SwatchTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durFast,
      value: widget.isSelected ? 1.0 : 0.9,
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance),
    );
    if (widget.isSelected) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_SwatchTile old) {
    super.didUpdateWidget(old);
    if (old.isSelected != widget.isSelected) {
      if (!widget.reduce) {
        widget.isSelected ? _ctrl.forward() : _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile();
    return Semantics(
      label: 'Color ${widget.label}, ${widget.isSelected ? 'seleccionado' : 'no seleccionado'}',
      button: true,
      selected: widget.isSelected,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (_, child) => Transform.scale(
              scale: widget.reduce ? 1.0 : _scaleAnim.value,
              child: child,
            ),
            child: tile,
          ),
        ),
      ),
    );
  }

  Widget _buildTile() {
    final inner = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: widget.isSelected
            ? AppDimens.glowStatus(widget.color)
            : null,
      ),
    );

    if (!widget.isSelected) return inner;

    return HudCornerBrackets(
      color: AppColors.textPrimary,
      armLength: 8,
      thickness: 1.0,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(AppDimens.radiusXS),
          border: Border.all(
            color: AppColors.textPrimary,
            width: 2,
          ),
          boxShadow: AppDimens.glowStatus(widget.color),
        ),
      ),
    );
  }
}

// ─── _CustomSwatchTile ─────────────────────────────────────────────────────

class _CustomSwatchTile extends StatefulWidget {
  const _CustomSwatchTile({
    required this.isActive,
    required this.isOpen,
    required this.reduce,
    required this.onTap,
    this.activeColor,
  });

  final bool isActive;
  final bool isOpen;
  final bool reduce;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  State<_CustomSwatchTile> createState() => _CustomSwatchTileState();
}

class _CustomSwatchTileState extends State<_CustomSwatchTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durFast,
      value: widget.isActive ? 1.0 : 0.9,
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance),
    );
    if (widget.isActive) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_CustomSwatchTile old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive) {
      if (!widget.reduce) {
        widget.isActive ? _ctrl.forward() : _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor =
        (widget.isActive && widget.activeColor != null)
            ? widget.activeColor!
            : AppColors.textPrimary;

    final inner = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
        border: Border.all(
          color: widget.isActive
              ? AppColors.textPrimary
              : AppColors.borderStrong,
          width: widget.isActive ? 2 : 1.5,
        ),
        boxShadow: widget.isActive
            ? AppDimens.glowStatus(glowColor)
            : null,
      ),
      child: Center(
        child: AppIcons.icon(
          AppIcons.edit,
          size: AppDimens.iconXS,
          color: widget.isActive
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
      ),
    );

    final tile = widget.isActive
        ? HudCornerBrackets(
            color: AppColors.textPrimary,
            armLength: 8,
            thickness: 1.0,
            child: inner,
          )
        : inner;

    return Semantics(
      label: 'Color personalizado, ${widget.isActive ? 'seleccionado' : 'no seleccionado'}',
      button: true,
      selected: widget.isActive,
      child: Tooltip(
        message: 'Color personalizado',
        child: GestureDetector(
          onTap: widget.onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedBuilder(
              animation: _scaleAnim,
              builder: (_, child) => Transform.scale(
                scale: widget.reduce ? 1.0 : _scaleAnim.value,
                child: child,
              ),
              child: tile,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _ColorPreview ─────────────────────────────────────────────────────────

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({
    required this.color,
    required this.hexLabel,
  });

  final Color color;
  final String hexLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: AppDimens.space40,
          height: AppDimens.space40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: AppDimens.glowStatus(color),
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        Text(
          hexLabel,
          style: AppTextStyles.mono.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

// ─── _InlineColorPicker ────────────────────────────────────────────────────

class _InlineColorPicker extends StatelessWidget {
  const _InlineColorPicker({
    required this.color,
    required this.onColorChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.space8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HueRingPicker(
              pickerColor: color,
              onColorChanged: onColorChanged,
              enableAlpha: false,
              displayThumbColor: true,
            ),
            const SizedBox(height: AppDimens.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.ghost(
                  label: 'Cancelar',
                  size: AppButtonSize.sm,
                  onPressed: onCancel,
                ),
                const SizedBox(width: AppDimens.space8),
                AppButton.primary(
                  label: 'Confirmar',
                  size: AppButtonSize.sm,
                  onPressed: onConfirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
