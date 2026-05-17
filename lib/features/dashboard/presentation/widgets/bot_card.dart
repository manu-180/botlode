// lib/features/dashboard/presentation/widgets/bot_card.dart
// Bot card «Hangar OS»: unidad en su bahía — panel HUD con retrato, glow de color,
// badges de estado, brackets de hover y tratamiento desaturado para unidades sin energía.
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_grid_texture.dart';
import 'package:botslode/core/ui/hud/hud_id_tag.dart';
import 'package:botslode/core/ui/hud/hud_status_dot.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/widgets/rive_bot_card_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BotCard extends StatefulWidget {
  final Bot bot;
  final VoidCallback onTap;
  final int staggerIndex;

  const BotCard({
    super.key,
    required this.bot,
    required this.onTap,
    this.staggerIndex = 0,
  });

  @override
  State<BotCard> createState() => _BotCardState();
}

class _BotCardState extends State<BotCard> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _focused = false;
  Offset? _localMousePos;

  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durInstant,
      reverseDuration: AppMotion.durFast,
    );
    _scale = Tween<double>(begin: 1.0, end: AppMotion.pressScale)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: AppMotion.easeEntrance));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  // ─── STATE HELPERS ────────────────────────────────────────────────────────

  bool get _isActive    => widget.bot.status == BotStatus.active;
  bool get _isSuspended => widget.bot.status == BotStatus.creditSuspended;
  bool get _isDimmed    => !_isActive;

  Color get _statusColor {
    if (_isActive)    return AppColors.success;
    if (_isSuspended) return AppColors.warning;
    return AppColors.danger;
  }

  HudStatus get _dotStatus {
    if (_isActive)    return HudStatus.online;
    if (_isSuspended) return HudStatus.suspended;
    return HudStatus.offline;
  }

  String get _statusLabel {
    if (_isActive)    return 'ACTIVE';
    if (_isSuspended) return 'SUSPENDED';
    return 'OFFLINE';
  }

  String get _unitId {
    final id = widget.bot.id;
    final suffix = id.length >= 4
        ? id.substring(id.length - 4).toUpperCase()
        : id.toUpperCase();
    return 'UNIT-$suffix';
  }

  Color get _borderColor {
    if (_focused) return AppColors.cyan;
    if (_hovered) return widget.bot.primaryColor.withValues(alpha: 0.6);
    return AppColors.glassBorder;
  }

  double get _borderWidth => (_focused || _hovered) ? 1.5 : 1.0;

  List<BoxShadow> get _shadows {
    if (_focused) {
      return [
        ...AppDimens.elev2,
        const BoxShadow(color: AppColors.cyanGlow, blurRadius: 18, spreadRadius: 1),
      ];
    }
    if (_hovered) {
      return [
        ...AppDimens.elev2,
        BoxShadow(
          color: widget.bot.primaryColor.withValues(alpha: 0.22),
          blurRadius: 24,
          spreadRadius: 1,
        ),
      ];
    }
    return AppDimens.elev1;
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    Widget card = AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _localMousePos = null;
        }),
        onHover: (e) => setState(() => _localMousePos = e.localPosition),
        child: GestureDetector(
          onTapDown: (_) => _pressCtrl.forward(),
          onTapUp: (_) => _pressCtrl.reverse(),
          onTapCancel: _pressCtrl.reverse,
          onTap: widget.onTap,
          child: AnimatedContainer(
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
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: AppColors.glassSurface,
                  child: Stack(
                    children: [
                      // Top glass highlight hairline
                      Positioned(
                        top: 0, left: 0, right: 0,
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
                      // Card content
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimens.paddingCard),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPortrait()),
                              const SizedBox(height: AppDimens.space16),
                              _buildBody(),
                            ],
                          ),
                        ),
                      ),
                      // Hover corner brackets (opacity 0 → 1)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: (!reduced && _hovered) ? 1.0 : 0.0,
                            duration: _hovered
                                ? AppMotion.durFast
                                : AppMotion.exitOf(AppMotion.durFast),
                            child: HudCornerBrackets(
                              color: widget.bot.primaryColor,
                              armLength: 14,
                              thickness: 1.5,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Focus ring + keyboard activation
    card = Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          if (!reduced) {
            _pressCtrl.forward().then((_) => _pressCtrl.reverse());
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: card,
    );

    // Semantics
    card = Semantics(
      button: true,
      label: 'Unidad ${widget.bot.name}, estado $_statusLabel',
      child: card,
    );

    // Stagger entry animation
    if (reduced) {
      return card
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced, curve: Curves.linear);
    }
    return card
        .animate(delay: AppMotion.staggerDelay(widget.staggerIndex))
        .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
        .moveY(
          begin: 12,
          end: 0,
          duration: AppMotion.durBase,
          curve: AppMotion.easeEntrance,
        );
  }

  // ─── PORTRAIT ZONE ────────────────────────────────────────────────────────

  Widget _buildPortrait() {
    // Background: grid + radial glow + avatar — desaturated for dimmed units
    Widget background = Stack(
      fit: StackFit.expand,
      children: [
        // Technical grid tinted with bot color
        HudGridTexture(
          opacity: 0.05,
          color: widget.bot.primaryColor,
        ),
        // Radial color glow centered on avatar (active units only)
        if (_isActive)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.centerLeft,
                radius: 1.2,
                colors: [
                  widget.bot.primaryColor.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        // Avatar (eye-tracking preserved)
        Positioned(
          top: 0,
          left: 0,
          child: RiveBotCardDisplay(
            primaryColor: widget.bot.primaryColor,
            cycleProgress: widget.bot.cycleProgress,
            pointerLocalPos: _localMousePos,
          ),
        ),
      ],
    );

    // Desaturation filter for suspended / offline units (~35 % saturation)
    if (_isDimmed) {
      background = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.4882, 0.4649, 0.0469, 0, 0,
          0.1382, 0.8149, 0.0469, 0, 0,
          0.1382, 0.4649, 0.3969, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: background,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        // Status badge — full saturation, always readable
        Positioned(
          top: 0,
          right: 0,
          child: _StatusBadge(
            color: _statusColor,
            dotStatus: _dotStatus,
            label: _statusLabel,
          ),
        ),
        // Unit ID — bottom-left of portrait zone
        Positioned(
          bottom: 0,
          left: 0,
          child: HudIdTag(text: _unitId),
        ),
      ],
    );
  }

  // ─── BODY ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.bot.name,
          style: AppTextStyles.titleM.copyWith(color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimens.space4),
        Text(
          widget.bot.description ?? 'Unidad de propósito general.',
          style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimens.space12),
        _buildMetricsRow(),
      ],
    );
  }

  Widget _buildMetricsRow() {
    final pct = (widget.bot.cycleProgress * 100).round();
    return Row(
      children: [
        Text(
          'CICLO',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(width: AppDimens.space4),
        Text(
          '$pct%',
          style: AppTextStyles.mono.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final Color color;
  final HudStatus dotStatus;
  final String label;

  const _StatusBadge({
    required this.color,
    required this.dotStatus,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppDimens.brPill,
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudStatusDot(status: dotStatus, size: 6),
          const SizedBox(width: AppDimens.space4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
