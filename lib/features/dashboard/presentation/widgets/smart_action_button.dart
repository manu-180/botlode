// lib/features/dashboard/presentation/widgets/smart_action_button.dart
// Widget público extraído del CreditHudPanel.
// Alterna entre tres variantes de AppButton con crossfade animado y pulso
// urgente en modo payCard.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_dimens.dart';
import '../../../../core/config/theme/app_motion.dart';
import '../../../../core/ui/buttons/app_button.dart';

// ─── Modo interno ─────────────────────────────────────────────────────────────

enum _SmartActionMode { assemble, payCard, payLink }

// ─── SmartActionButton ────────────────────────────────────────────────────────

class SmartActionButton extends StatefulWidget {
  const SmartActionButton({
    super.key,
    required this.isCritical,
    required this.hasCard,
    required this.debtAmount,
    required this.onAssemble,
    required this.onPayCard,
    required this.onPayLink,
  });

  final bool isCritical;
  final bool hasCard;
  final double debtAmount;
  final VoidCallback onAssemble;
  final VoidCallback onPayCard;
  final VoidCallback onPayLink;

  @override
  State<SmartActionButton> createState() => _SmartActionButtonState();
}

class _SmartActionButtonState extends State<SmartActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseOpacity;

  _SmartActionMode get _mode {
    if (widget.isCritical && widget.hasCard) return _SmartActionMode.payCard;
    if (widget.isCritical && !widget.hasCard) return _SmartActionMode.payLink;
    return _SmartActionMode.assemble;
  }

  @override
  void initState() {
    super.initState();
    // durPulseUrgent: pulso más rápido que durHeartbeat para reforzar urgencia.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durPulseUrgent,
    );
    _pulseOpacity = Tween<double>(begin: 0.30, end: 0.50).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: AppMotion.easeStandard),
    );
    // No iniciar aquí: MediaQuery no está disponible todavía.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(SmartActionButton old) {
    super.didUpdateWidget(old);
    if (_modeFrom(old) != _mode) {
      _syncPulse();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  _SmartActionMode _modeFrom(SmartActionButton w) {
    if (w.isCritical && w.hasCard) return _SmartActionMode.payCard;
    if (w.isCritical && !w.hasCard) return _SmartActionMode.payLink;
    return _SmartActionMode.assemble;
  }

  void _syncPulse() {
    final reduced = AppMotion.reduced(context);
    if (_mode == _SmartActionMode.payCard && !reduced) {
      if (!_pulseCtrl.isAnimating) {
        _pulseCtrl.repeat(reverse: true);
      }
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  String get _tooltipText => switch (_mode) {
        _SmartActionMode.assemble => 'Ensamblar nueva unidad',
        _SmartActionMode.payCard  => 'Pagar deuda con tarjeta',
        _SmartActionMode.payLink  => 'Pagar online vía Mercado Pago',
      };

  Widget _buildButton() {
    return switch (_mode) {
      _SmartActionMode.assemble => AppButton.primary(
          key: const ValueKey(_SmartActionMode.assemble),
          label: 'Ensamblar unidad',
          onPressed: widget.onAssemble,
          leadingIcon: Icons.add_rounded,
          size: AppButtonSize.lg,
          expand: true,
        ),
      _SmartActionMode.payCard => AppButton.danger(
          key: const ValueKey(_SmartActionMode.payCard),
          label: 'Pagar \$${widget.debtAmount.toInt()} ahora',
          onPressed: widget.onPayCard,
          leadingIcon: Icons.flash_on_rounded,
          size: AppButtonSize.lg,
          expand: true,
        ),
      _SmartActionMode.payLink => AppButton.secondary(
          key: const ValueKey(_SmartActionMode.payLink),
          label: 'Pagar online',
          onPressed: widget.onPayLink,
          leadingIcon: FontAwesomeIcons.handshake,
          size: AppButtonSize.lg,
          expand: true,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final switchDuration =
        reduced ? AppMotion.durCrossfadeReduced : AppMotion.durBase;

    final animatedSwitcher = AnimatedSwitcher(
      duration: switchDuration,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _buildButton(),
    );

    final isPayCard = _mode == _SmartActionMode.payCard;

    Widget pulseLayer;
    if (isPayCard) {
      if (reduced) {
        pulseLayer = Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppDimens.brM,
                boxShadow: AppDimens.glowStatus(AppColors.danger),
              ),
            ),
          ),
        );
      } else {
        pulseLayer = Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppDimens.brM,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger
                          .withValues(alpha: _pulseOpacity.value),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } else {
      pulseLayer = const SizedBox.shrink();
    }

    return Tooltip(
      message: _tooltipText,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Stack(
          children: [
            animatedSwitcher,
            pulseLayer,
          ],
        ),
      ),
    );
  }
}
