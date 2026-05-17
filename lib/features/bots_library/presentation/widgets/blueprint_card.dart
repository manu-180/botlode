// Archivo: lib/features/bots_library/presentation/widgets/blueprint_card.dart
// BlueprintCard — panel de ingeniería premium «Hangar OS» (prompt 42).
// Glass manual (sin HoloPanel) + HUD components + stagger interno.
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/features/bots_library/domain/models/blueprint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BlueprintCard
// ─────────────────────────────────────────────────────────────────────────────

class BlueprintCard extends StatefulWidget {
  const BlueprintCard({
    super.key,
    required this.blueprint,
    required this.onTap,
    this.staggerIndex = 0,
  });

  final BotBlueprint blueprint;
  final VoidCallback onTap;
  final int staggerIndex;

  @override
  State<BlueprintCard> createState() => _BlueprintCardState();
}

class _BlueprintCardState extends State<BlueprintCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  late final AnimationController _hoverCtrl;
  late final CurvedAnimation _hoverAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durFast,
    );
    _hoverAnim = CurvedAnimation(
      parent: _hoverCtrl,
      curve: AppMotion.easeStandard,
    );
  }

  @override
  void dispose() {
    _hoverAnim.dispose();
    _hoverCtrl.dispose();
    super.dispose();
  }

  // ── Interaction handlers ──────────────────────────────────────────────────

  void _onEnter(PointerEnterEvent _) {
    setState(() => _hovered = true);
    _hoverCtrl.forward();
  }

  void _onExit(PointerExitEvent _) {
    setState(() => _hovered = false);
    _hoverCtrl.reverse();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
  }

  void _onFocusChange(bool focused) {
    setState(() => _focused = focused);
  }

  // ── Decoration helpers ────────────────────────────────────────────────────

  Color get _borderColor {
    if (_focused) return AppColors.cyan;
    final tc = widget.blueprint.techColor;
    return Color.lerp(
      AppColors.borderDefault,
      tc.withValues(alpha: 0.55),
      _hoverAnim.value,
    )!;
  }

  double get _borderWidth {
    if (_focused) return 2.0;
    return 1.0 + 0.5 * _hoverAnim.value;
  }

  List<BoxShadow> get _shadows {
    final elev = (_hovered && !_pressed) ? AppDimens.elev2 : AppDimens.elev1;
    final tc = widget.blueprint.techColor;
    return [
      ...elev,
      BoxShadow(
        color: tc.withValues(alpha: (_hovered && !_pressed) ? 0.28 : 0.14),
        blurRadius: 18,
        spreadRadius: 1,
      ),
    ];
  }

  double _targetScale(bool reduced) {
    if (reduced) return 1.0;
    if (_pressed) return 0.98;
    if (_hovered) return 1.02;
    return 1.0;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final tc = widget.blueprint.techColor;

    // Glass panel content
    Widget glassPanel = AnimatedBuilder(
      animation: _hoverAnim,
      builder: (context, _) {
        return AnimatedContainer(
          duration: AppMotion.durFast,
          curve: AppMotion.easeStandard,
          decoration: BoxDecoration(
            borderRadius: AppDimens.brL,
            border: Border.all(color: _borderColor, width: _borderWidth),
            boxShadow: _shadows,
          ),
          child: ClipRRect(
            borderRadius: AppDimens.brL,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Stack(
                children: [
                  // Glass fill
                  Positioned.fill(
                    child: Container(color: AppColors.glassSurface),
                  ),
                  // Top highlight (1 px gradient)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.glassHighlightTop,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Grid texture (animated opacity via hoverAnim)
                  Positioned.fill(
                    child: HudGridTexture(
                      color: tc,
                      opacity: 0.04 + 0.04 * _hoverAnim.value,
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.space20),
                    child: _buildContent(tc),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Corner brackets: visible on hover (animated) OR focused (instant full opacity)
    Widget card = AnimatedBuilder(
      animation: _hoverAnim,
      builder: (context, child) {
        final bracketAlpha = _focused ? 1.0 : _hoverAnim.value;
        return HudCornerBrackets(
          color: tc.withValues(alpha: bracketAlpha),
          armLength: 18,
          thickness: 1.5,
          child: child!,
        );
      },
      child: glassPanel,
    );

    // Full widget tree (outer → inner)
    card = Semantics(
      button: true,
      label: 'Plano ${widget.blueprint.name}',
      onTap: widget.onTap,
      child: Focus(
        onFocusChange: _onFocusChange,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedScale(
          scale: _targetScale(reduced),
          duration: _pressed ? AppMotion.durInstant : AppMotion.durFast,
          curve: AppMotion.easeStandard,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: _onEnter,
            onExit: _onExit,
            child: GestureDetector(
              onTap: widget.onTap,
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: card,
            ),
          ),
        ),
      ),
    );

    // Entrance stagger animation (outermost)
    if (reduced) {
      return card
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
    } else {
      return card
          .animate(delay: AppMotion.staggerDelay(widget.staggerIndex))
          .fadeIn(
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          )
          .move(
            begin: const Offset(0, 12),
            end: Offset.zero,
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          );
    }
  }

  // ── Content layout ────────────────────────────────────────────────────────

  Widget _buildContent(Color tc) {
    final bp = widget.blueprint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HEADER ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon HUD frame — 48×48, light chamfer approximation
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tc.withValues(alpha: 0.10),
                borderRadius: AppDimens.brS,
                border: Border.all(color: tc.withValues(alpha: 0.32)),
              ),
              child: Center(
                child: FaIcon(bp.icon, color: tc, size: 22),
              ),
            ),
            // ID tag
            HudIdTag(text: bp.id, color: AppColors.textTertiary),
          ],
        ),

        const SizedBox(height: AppDimens.space16),

        // ── CATEGORY ────────────────────────────────────────────────────────
        Text(
          bp.category.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(color: tc),
        ),

        const SizedBox(height: AppDimens.space4),

        // ── NAME ────────────────────────────────────────────────────────────
        Text(
          bp.name,
          style: AppTextStyles.titleM.copyWith(
            color: Color.lerp(
              AppColors.textPrimary,
              Colors.white,
              _hoverAnim.value * 0.35,
            ),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppDimens.space8),

        // ── DESCRIPTION ─────────────────────────────────────────────────────
        Text(
          bp.description,
          style: AppTextStyles.bodyS,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppDimens.space16),

        // ── SPECS BLOCK ─────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceHud,
            borderRadius: AppDimens.brS,
          ),
          padding: const EdgeInsets.fromLTRB(
            AppDimens.space12,
            AppDimens.space8,
            AppDimens.space12,
            AppDimens.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HudDivider(label: 'SPECS'),
              const SizedBox(height: AppDimens.space8),
              _SpecRow(label: 'ID', value: bp.id),
              const SizedBox(height: AppDimens.space4),
              _SpecRow(label: 'CATEGORÍA', value: bp.category),
              const SizedBox(height: AppDimens.space4),
              const _SpecRow(label: 'TIPO', value: 'PROTOTIPO'),
            ],
          ),
        ),

        const SizedBox(height: AppDimens.space12),

        // ── FOOTER DIVIDER ───────────────────────────────────────────────────
        const HudDivider(),

        const SizedBox(height: AppDimens.space12),

        // ── ENSAMBLAR BUTTON ─────────────────────────────────────────────────
        AppButton(
          label: 'ENSAMBLAR',
          onPressed: widget.onTap,
          variant: AppButtonVariant.secondary,
          expand: true,
          leadingIcon: Icons.precision_manufacturing_outlined,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpecRow
// ─────────────────────────────────────────────────────────────────────────────

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.hudReadout.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
