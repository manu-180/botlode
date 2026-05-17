// lib/features/dashboard/presentation/widgets/bot_card.dart
// Bot card «Hangar OS»: unidad operativa en grilla.
// Estados: default (reposo), hover (elevación + glow de color), pressed (scale).
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_id_tag.dart';
import 'package:botslode/core/ui/hud/hud_status_dot.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/widgets/rive_bot_card_display.dart';
import 'package:flutter/material.dart';

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
  Offset? _localMousePos;
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durInstant,
    );
    _scale = Tween<double>(begin: 1.0, end: AppMotion.pressScale)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  // ─── HELPERS DE ESTADO ───────────────────────────────────────────────────
  bool get _isActive    => widget.bot.status == BotStatus.active;
  bool get _isSuspended => widget.bot.status == BotStatus.creditSuspended;

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

  Color get _borderColor => _hovered
      ? widget.bot.primaryColor.withValues(alpha: 0.5)
      : AppColors.borderDefault;

  List<BoxShadow> get _shadow => _hovered
      ? [
          ...AppDimens.elev2,
          BoxShadow(
            color: widget.bot.primaryColor.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ]
      : AppDimens.elev1;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bot ${widget.bot.name} — estado: $_statusLabel',
      child: AnimatedBuilder(
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
              curve: AppMotion.easeHover,
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: AppDimens.brL,
                border: Border.all(color: _borderColor, width: _hovered ? 1.5 : 1),
                boxShadow: _shadow,
              ),
              child: HudCornerBrackets(
                color: widget.bot.primaryColor.withValues(alpha: _hovered ? 0.6 : 0.25),
                armLength: 14,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingCard),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header: avatar + badge ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RiveBotCardDisplay(
                            primaryColor: widget.bot.primaryColor,
                            cycleProgress: widget.bot.cycleProgress,
                            pointerLocalPos: _localMousePos,
                          ),
                          _StatusBadge(
                            color: _statusColor,
                            dotStatus: _dotStatus,
                            label: _statusLabel,
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ── Bot name ─────────────────────────────────────
                      Text(
                        widget.bot.name,
                        style: AppTextStyles.titleL.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.space4),

                      // ── Descripción ──────────────────────────────────
                      Text(
                        widget.bot.description ?? 'Unidad de propósito general.',
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.space12),

                      // ── ID tag ───────────────────────────────────────
                      HudIdTag(
                        text: 'ID: ${widget.bot.id.substring(0, 8)}…',
                        color: AppColors.textTertiary,
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
