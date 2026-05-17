// Archivo: lib/features/dashboard/presentation/widgets/mood_card.dart
// Tarjeta seleccionable de mood para el tab de personalidad del bot.
// Muestra ícono, nombre, descripción y reactor inferior del color del mood.
// Seleccionada: glow + HudCornerBrackets + borde de acento + chip ACTIVO.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_reactor_bar.dart';
import 'package:botslode/features/dashboard/presentation/widgets/unit_mood_colors.dart';
import 'package:flutter/material.dart';

class MoodCard extends StatefulWidget {
  final int moodIndex;
  final bool isSelected;
  final VoidCallback onTap;
  final bool disabled;

  const MoodCard({
    super.key,
    required this.moodIndex,
    required this.isSelected,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<MoodCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.03)
            .chain(CurveTween(curve: AppMotion.easeEntrance)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.03, end: 1.0)
            .chain(CurveTween(curve: AppMotion.easeExit)),
        weight: 50,
      ),
    ]).animate(_pulseCtrl);
  }

  @override
  void didUpdateWidget(MoodCard old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _triggerPulse();
    }
  }

  void _triggerPulse() {
    if (!mounted) return;
    if (AppMotion.isReduced(context)) return;
    _pulseCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = unitMoodColor(widget.moodIndex);
    final name = unitMoodName(widget.moodIndex);
    final icon = unitMoodIcon(widget.moodIndex);
    final description = unitMoodDescription(widget.moodIndex);
    final reduced = AppMotion.reduced(context);
    final isSelected = widget.isSelected;
    final isDisabled = widget.disabled;

    final borderColor = isSelected
        ? color.withValues(alpha: 0.80)
        : isDisabled
            ? AppColors.borderSubtle
            : _isHovered
                ? color.withValues(alpha: 0.35)
                : AppColors.borderDefault;

    final boxShadows = <BoxShadow>[
      ...(_isHovered && !isSelected ? AppDimens.elev2 : AppDimens.elev1),
      if (isSelected) ...AppDimens.glowStatus(color),
      if (_isHovered && !isSelected)
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 16,
        ),
    ];

    final cardContent = AnimatedContainer(
      duration: AppMotion.durFast,
      curve: AppMotion.easeStandard,
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brL,
        border: Border.all(
          color: borderColor,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: boxShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon box + selected chip row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: AppMotion.durFast,
                curve: AppMotion.easeStandard,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHud,
                  borderRadius: AppDimens.brM,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.22),
                            blurRadius: 10,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: AppIcons.icon(
                    icon,
                    size: AppDimens.iconM,
                    color: isSelected || _isHovered
                        ? color
                        : color.withValues(alpha: 0.70),
                  ),
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: AppMotion.durBase,
                curve: AppMotion.easeEntrance,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: AppDimens.brPill,
                    border: Border.all(
                      color: color.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ACTIVO',
                    style: AppTextStyles.labelSmall.copyWith(color: color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          Text(
            name,
            style: AppTextStyles.titleM.copyWith(
              color: isSelected ? color : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            description,
            style: AppTextStyles.bodyS,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.space16),
          HudReactorBar(
            axis: Axis.horizontal,
            thickness: 2,
            color: isSelected ? color : color.withValues(alpha: 0.30),
            pulsing: isSelected && !reduced,
          ),
        ],
      ),
    );

    // HudCornerBrackets always present; transparent when not selected so tree
    // stays stable and AnimatedContainer transitions are uninterrupted.
    final withBrackets = HudCornerBrackets(
      color: isSelected
          ? color.withValues(alpha: 0.70)
          : Colors.transparent,
      armLength: 16,
      thickness: 1.5,
      child: cardContent,
    );

    return Semantics(
      label: 'Modo $name: $description',
      selected: isSelected,
      button: true,
      excludeSemantics: false,
      child: Focus(
        onFocusChange: (hasFocus) => setState(() {}),
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return Opacity(
              opacity: isDisabled ? 0.4 : 1.0,
              child: MouseRegion(
                cursor: isDisabled
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                onEnter: isDisabled
                    ? null
                    : (_) => setState(() => _isHovered = true),
                onExit: isDisabled
                    ? null
                    : (_) => setState(() {
                          _isHovered = false;
                          _isPressed = false;
                        }),
                child: GestureDetector(
                  onTapDown: isDisabled
                      ? null
                      : (_) => setState(() => _isPressed = true),
                  onTapUp: isDisabled
                      ? null
                      : (_) {
                          setState(() => _isPressed = false);
                          widget.onTap();
                        },
                  onTapCancel: isDisabled
                      ? null
                      : () => setState(() => _isPressed = false),
                  child: AnimatedScale(
                    scale: _isPressed ? AppMotion.pressScale : 1.0,
                    duration:
                        _isPressed ? AppMotion.durInstant : AppMotion.durFast,
                    curve: AppMotion.easeEntrance,
                    child: AnimatedBuilder(
                      animation: _pulseScale,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseScale.value,
                        child: child,
                      ),
                      child: Container(
                        // Focus ring — 2 px cyan inset
                        decoration: hasFocus
                            ? BoxDecoration(
                                borderRadius: AppDimens.brL,
                                border: Border.all(
                                  color: AppColors.cyan,
                                  width: 2,
                                ),
                              )
                            : null,
                        child: withBrackets,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
