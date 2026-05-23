// Archivo: lib/features/dashboard/presentation/widgets/unit_avatar_panel.dart
// Panel de contención del avatar Catbot con HUD ornaments y glow reactivo al mood.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_grid_texture.dart';
import 'package:botslode/core/ui/hud/hud_id_tag.dart';
import 'package:botslode/core/ui/hud/hud_scanlines.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/widgets/status_tag.dart';
import 'package:botslode/features/bot_engine/presentation/widgets/rive_bot_display.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/widgets/unit_mood_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Panel de contención del avatar Catbot: HoloPanel con chamfer, HUD ornaments
/// (corner brackets, grid texture, scanlines, ID tag) y glow reactivo al mood.
class UnitAvatarPanel extends ConsumerStatefulWidget {
  final Bot bot;
  final int moodIndex;
  final UnitStatus unitStatus;

  /// Ancho del panel izquierdo (determina el tamaño del avatar: ≥380 → 280, <380 → 240).
  final double leftWidth;

  const UnitAvatarPanel({
    super.key,
    required this.bot,
    required this.moodIndex,
    required this.unitStatus,
    required this.leftWidth,
  });

  @override
  ConsumerState<UnitAvatarPanel> createState() => _UnitAvatarPanelState();
}

class _UnitAvatarPanelState extends ConsumerState<UnitAvatarPanel>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  // Shimmer animation controller (vendor mood only, non-reduced-motion)
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durShimmer,
    );
    // No llamar _maybeStartShimmer() acá: usa AppMotion.reduced(context)
    // que depende de MediaQuery, y MediaQuery no está disponible en
    // initState. Se llama desde didChangeDependencies (corre antes del
    // primer build y cuando cambia MediaQuery).
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStartShimmer();
  }

  @override
  void didUpdateWidget(UnitAvatarPanel old) {
    super.didUpdateWidget(old);
    if (old.moodIndex != widget.moodIndex) {
      _maybeStartShimmer();
    }
  }

  void _maybeStartShimmer() {
    final reduced = AppMotion.reduced(context);
    if (widget.moodIndex == 3 && !reduced) {
      if (!_shimmerCtrl.isAnimating) _shimmerCtrl.repeat();
    } else {
      _shimmerCtrl.stop();
      _shimmerCtrl.reset();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final moodColor = unitMoodColor(widget.moodIndex);
    final avatarSize = widget.leftWidth >= 380.0 ? 280.0 : 240.0;

    // Glow alpha: lower when offline, higher when hovered.
    final bool isOffline = widget.unitStatus == UnitStatus.offline;
    final double baseGlowAlpha = isOffline ? 0.09 : 0.22;
    final double glowAlpha = _hovered && !isOffline ? 0.37 : baseGlowAlpha;

    // Panel contents (Stack, back to front):
    Widget panelContent = Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: grid texture
        const Positioned.fill(
          child: IgnorePointer(
            child: HudGridTexture(opacity: 0.04),
          ),
        ),

        // Layer 2: radial glow behind avatar
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: AppMotion.durFast,
              curve: AppMotion.easeStandard,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.7,
                  colors: [
                    moodColor.withValues(alpha: glowAlpha),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Layer 3: RiveBotDisplay centered
        Center(
          child: RiveBotDisplay(
            size: avatarSize,
            botColor: widget.bot.primaryColor,
          ),
        ),

        // Layer 4: scanlines overlay (non-interactive)
        const Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: HudScanlines(
                opacity: 0.035,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),

        // Layer 5: shimmer (vendor mood only, not reduced)
        if (widget.moodIndex == 3 && !reduced)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (context, _) {
                      return FractionalTranslation(
                        translation: Offset(
                          _shimmerCtrl.value * 3.0 - 1.5,
                          0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.gradGoldSheen,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

        // Layer 6: HudIdTag in top-left corner
        Positioned(
          top: AppDimens.space8,
          left: AppDimens.space8,
          child: HudIdTag(
            text: widget.bot.id.length >= 8
                ? widget.bot.id.substring(0, 8).toUpperCase()
                : widget.bot.id.toUpperCase(),
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );

    // Wrap in HoloPanel with chamfer shape and mood-colored border/glow
    Widget panel = HoloPanel(
      shape: HoloPanelShape.chamfer,
      cornerBrackets: false,
      scanlines: false,
      padding: EdgeInsets.zero,
      borderColor: moodColor.withValues(alpha: 0.32),
      glowAccent: moodColor,
      child: panelContent,
    );

    // Wrap in HudCornerBrackets outside the HoloPanel (mood-colored)
    panel = HudCornerBrackets(
      color: moodColor.withValues(alpha: 0.6),
      armLength: 20,
      thickness: 1.5,
      child: panel,
    );

    // MouseRegion for hover glow increase
    panel = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: panel,
    );

    // Entry animation
    if (!reduced) {
      panel = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: AppMotion.durSlow,
        curve: AppMotion.easeEntrance,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.96 + 0.04 * value,
              child: child,
            ),
          );
        },
        child: panel,
      );
    } else {
      panel = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: AppMotion.durCrossfadeReduced,
        curve: Curves.linear,
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: panel,
      );
    }

    // Semantics wrapper
    return Semantics(
      label: 'Avatar de la unidad ${widget.bot.name}, estado ${widget.unitStatus.name}',
      excludeSemantics: true,
      child: panel,
    );
  }
}
