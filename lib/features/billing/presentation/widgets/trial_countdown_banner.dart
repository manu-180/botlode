// Archivo: lib/features/billing/presentation/widgets/trial_countdown_banner.dart
//
// T4·18 — TrialCountdownBanner (HUD redesign T4-60)
//
// Banner HUD Hangar OS que muestra el conteo regresivo del período de prueba.
// Usa HudCornerBrackets, HudReactorBar, HudTicker y HudScanlines del design system.
// Incluye animación de entrada slide-down y salida slide-up al descartarlo.
//
// Severidad (días calendario restantes):
//   daysLeft > 7  → cyan   (AppColors.secondary) — informativo
//   daysLeft 3–7  → naranja (AppColors.warning)   — advertencia
//   daysLeft ≤ 2  → rojo   (AppColors.danger)     — crítico
//
// El banner solo se renderiza cuando:
//   - El provider tiene datos (no loading/error).
//   - sub.status == SubscriptionStatus.trialing && sub.currentPeriodEnd != null.
//   - El usuario no lo descartó (_dismissed == false).

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_reactor_bar.dart';
import 'package:botslode/core/ui/hud/hud_scanlines.dart';
import 'package:botslode/core/ui/hud/hud_ticker.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrialCountdownBanner extends ConsumerStatefulWidget {
  /// Hook de fecha para tests deterministas. En producción usa `DateTime.now()`.
  @visibleForTesting
  final DateTime? now;

  const TrialCountdownBanner({super.key, this.now});

  @override
  ConsumerState<TrialCountdownBanner> createState() =>
      _TrialCountdownBannerState();
}

class _TrialCountdownBannerState extends ConsumerState<TrialCountdownBanner> {
  bool _dismissed = false;

  // ---------------------------------------------------------------------------
  // Days calculation (date boundary, local timezone, clamped ≥ 0)
  // ---------------------------------------------------------------------------

  static int _daysLeft(DateTime trialEnd, DateTime now) {
    final localEnd = trialEnd.toLocal();
    final localNow = now.toLocal();
    final days = DateTime(localEnd.year, localEnd.month, localEnd.day)
        .difference(DateTime(localNow.year, localNow.month, localNow.day))
        .inDays;
    return days.clamp(0, 9999);
  }

  // ---------------------------------------------------------------------------
  // Severity mapping
  // ---------------------------------------------------------------------------

  static ({Color color, IconData icon}) _severity(int daysLeft) {
    if (daysLeft > 7) {
      return (color: AppColors.secondary, icon: Icons.hourglass_top_rounded);
    }
    if (daysLeft >= 3) {
      return (color: AppColors.warning, icon: Icons.hourglass_bottom_rounded);
    }
    return (color: AppColors.danger, icon: Icons.hourglass_disabled_rounded);
  }

  // ---------------------------------------------------------------------------
  // Open AddCardModal
  // ---------------------------------------------------------------------------

  void _openAddCard() {
    AddCardModal.show(context);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingV2Provider);

    return billingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        final sub = state.subscription;

        if (sub == null ||
            sub.status != SubscriptionStatus.trialing ||
            sub.currentPeriodEnd == null) {
          return const SizedBox.shrink();
        }

        final now = widget.now ?? DateTime.now();
        final daysLeft = _daysLeft(sub.currentPeriodEnd!, now);
        final hasDefaultPaymentMethod = state.defaultPaymentMethodId != null;
        final sev = _severity(daysLeft);

        final body = _BannerBody(
          daysLeft: daysLeft,
          hasDefaultPaymentMethod: hasDefaultPaymentMethod,
          color: sev.color,
          icon: sev.icon,
          onDismiss: () => setState(() => _dismissed = true),
          onAddPaymentMethod: _openAddCard,
        );

        return AnimatedSize(
          duration: Duration(
            milliseconds:
                (AppMotion.durSlow.inMilliseconds * 0.65).round(),
          ),
          curve: AppMotion.easeExit,
          clipBehavior: Clip.none,
          child:
              _dismissed ? const SizedBox.shrink() : _AnimatedBannerEntry(child: body),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedBannerEntry — slide-down + fade entrance
// ---------------------------------------------------------------------------

class _AnimatedBannerEntry extends StatefulWidget {
  final Widget child;
  const _AnimatedBannerEntry({required this.child});

  @override
  State<_AnimatedBannerEntry> createState() => _AnimatedBannerEntryState();
}

class _AnimatedBannerEntryState extends State<_AnimatedBannerEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durSlow);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    if (reduced) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// _BannerBody — presentación pura (sin acceso al provider)
// ---------------------------------------------------------------------------

class _BannerBody extends StatelessWidget {
  const _BannerBody({
    required this.daysLeft,
    required this.hasDefaultPaymentMethod,
    required this.color,
    required this.icon,
    required this.onDismiss,
    required this.onAddPaymentMethod,
  });

  final int daysLeft;
  final bool hasDefaultPaymentMethod;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;
  final VoidCallback onAddPaymentMethod;

  bool get _isDanger => color == AppColors.danger;
  bool get _isPulsing => color == AppColors.warning || color == AppColors.danger;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel =
        'Trial activo: $daysLeft días restantes. Severidad: ${_isDanger ? "crítica" : "advertencia"}';

    // Dismiss button hidden when danger AND !hasDefaultPaymentMethod
    final showDismiss = !(_isDanger && !hasDefaultPaymentMethod);

    return Semantics(
      liveRegion: true,
      label: semanticsLabel,
      child: HudCornerBrackets(
        color: color,
        armLength: 12,
        thickness: 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space8,
          ),
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
          child: HudScanlines(
            opacity: 0.035,
            animate: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: reactor bar spanning full content height
                HudReactorBar(
                  axis: Axis.vertical,
                  thickness: 3,
                  color: color,
                  pulsing: _isPulsing,
                ),
                const SizedBox(width: AppDimens.space12),

                // Severity icon — decorative
                ExcludeSemantics(
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppDimens.space12),

                // Center: count + optional CTA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Days ticker row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            AppStrings.billingTrialDaysPrefix,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          HudTicker(
                            value: daysLeft.toDouble(),
                            decimals: 0,
                            style: AppTextStyles.label.copyWith(
                              color: color,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            AppStrings.billingTrialDaysSuffix,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      if (!hasDefaultPaymentMethod) ...[
                        const SizedBox(height: AppDimens.space4),
                        Text(
                          AppStrings.billingTrialAddPaymentWarning,
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimens.space12),
                        AppButton(
                          label: AppStrings.billingTrialUpgradeCta,
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.sm,
                          onPressed: onAddPaymentMethod,
                        ),
                      ],
                    ],
                  ),
                ),

                // Right: dismiss button
                if (showDismiss)
                  IconButton(
                    tooltip: AppStrings.billingTrialDismissTooltip,
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: color.withValues(alpha: 0.6),
                    ),
                    onPressed: onDismiss,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
