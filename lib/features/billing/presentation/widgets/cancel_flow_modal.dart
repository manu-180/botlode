// Archivo: lib/features/billing/presentation/widgets/cancel_flow_modal.dart
//
// T4·12 — CancelFlowModal (Hangar OS HUD redesign)
//
// Three-step HUD cancellation flow:
//   Step 0 — Consecuencias + confirmación inicial.
//   Step 1 — Motivo de cancelación.
//   Step 2 — Ofertas de retención + confirmación destructiva.
//
// Always shown as a Dialog (desktop-only app).

import 'dart:ui';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_chamfer.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/hud/hud_reactor_bar.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:botslode/core/ui/widgets/app_text_field.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Shows the 3-step Hangar OS HUD cancel flow modal.
///
/// Reads [billingV2Provider] to obtain [Subscription.currentPeriodEnd] so the
/// confirmation screen can display "activa hasta {fecha}".
Future<void> showCancelFlowModal(BuildContext context, WidgetRef ref) async {
  // Capture the container before opening the overlay so providers are shared.
  final container = ProviderScope.containerOf(context);

  final modal = UncontrolledProviderScope(
    container: container,
    child: const _CancelFlowModal(),
  );

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => modal,
  );
}

// ---------------------------------------------------------------------------
// Reason options
// ---------------------------------------------------------------------------

enum _CancelReason {
  muyCaro('Muy caro'),
  noLoUso('No lo uso'),
  faltanFeatures('Faltan features'),
  otro('Otro');

  const _CancelReason(this.label);
  final String label;
}

// ---------------------------------------------------------------------------
// Internal widget
// ---------------------------------------------------------------------------

class _CancelFlowModal extends ConsumerStatefulWidget {
  const _CancelFlowModal();

  @override
  ConsumerState<_CancelFlowModal> createState() => _CancelFlowModalState();
}

class _CancelFlowModalState extends ConsumerState<_CancelFlowModal> {
  // Step management (0 = consecuencias, 1 = motivo, 2 = ofertas+confirm)
  int _step = 0;

  // Direction: 1 = forward (slide from right), -1 = backward (slide from left)
  int _direction = 1;

  // Step 1 state
  _CancelReason? _selectedReason;
  final _commentController = TextEditingController();

  // Step 2 state
  bool _doubleConfirmed = false;

  // Mutation state (step 2)
  bool _cancelling = false;
  String? _mutationError;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _selectedReasonText {
    if (_selectedReason == null) return '';
    final comment = _commentController.text.trim();
    final base = _selectedReason!.label;
    if (comment.isNotEmpty) return '$base: $comment';
    return base;
  }

  // ---------------------------------------------------------------------------
  // Navigation actions
  // ---------------------------------------------------------------------------

  void _advanceStep() {
    if (_step >= 2) return;
    setState(() {
      _direction = 1;
      _step++;
      _mutationError = null;
    });
  }

  void _backStep() {
    if (_step <= 0) return;
    setState(() {
      _direction = -1;
      _step--;
      _mutationError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Cancellation action
  // ---------------------------------------------------------------------------

  Future<void> _confirmCancel(String fecha) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _cancelling = true;
      _mutationError = null;
    });

    try {
      await ref
          .read(billingV2Provider.notifier)
          .cancelSubscription(reason: _selectedReasonText);

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${AppStrings.billingCancelSuccessPrefix}$fecha'),
        ),
      );
    } on BillingException catch (e) {
      if (!mounted) return;
      if (e.code == 'not_implemented') {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.billingCancelComingSoon)),
        );
      } else {
        setState(() {
          _mutationError = e.message;
          _cancelling = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mutationError = AppStrings.billingCancelErrorMsg;
        _cancelling = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Watch billingV2Provider so the auto-dispose provider stays alive for the
    // modal's lifetime and the date is available for step 2.
    final billingAsync = ref.watch(billingV2Provider);
    final periodEnd =
        billingAsync.valueOrNull?.subscription?.currentPeriodEnd;
    final fechaStr = periodEnd != null
        ? DateFormat('dd/MM/yyyy').format(periodEnd)
        : '—';

    final reduced = AppMotion.reduced(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: _GlassModalContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HUD Step Indicator
              _HudStepIndicator(currentStep: _step),
              const SizedBox(height: AppDimens.space24),

              // Animated step content
              AnimatedSwitcher(
                duration: reduced
                    ? AppMotion.durCrossfadeReduced
                    : AppMotion.durBase,
                switchInCurve:
                    reduced ? Curves.linear : AppMotion.easeEntrance,
                switchOutCurve:
                    reduced ? Curves.linear : AppMotion.easeExit,
                transitionBuilder: (child, animation) {
                  if (reduced) {
                    return FadeTransition(opacity: animation, child: child);
                  }
                  // Slide direction: forward = enter from right (+24 px), backward = enter from left (-24 px)
                  final slideBegin =
                      Offset(_direction * 24.0 / 300.0, 0.0);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: slideBegin,
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_step),
                  child: Semantics(
                    label: 'Paso ${_step + 1} de 3 del proceso de cancelación',
                    child: _buildCurrentStep(fechaStr),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(String fechaStr) {
    switch (_step) {
      case 0:
        return _buildStep0(fechaStr);
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2(fechaStr);
      default:
        return _buildStep0(fechaStr);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 0 — Consecuencias + confirmación inicial
  // ---------------------------------------------------------------------------

  Widget _buildStep0(String fechaStr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStep0Header(),
        const SizedBox(height: AppDimens.space16),
        _ConsequencesBullets(fecha: fechaStr),
        const SizedBox(height: AppDimens.space24),
        // Primary action: keep subscription (top, safe action)
        AppButton.primary(
          label: 'MANTENER SUSCRIPCIÓN',
          onPressed: () => Navigator.of(context).pop(),
          expand: true,
        ),
        const SizedBox(height: AppDimens.space12),
        // Secondary action: continue with cancellation (bottom, destructive path)
        AppButton.ghost(
          label: 'CONTINUAR CON LA CANCELACIÓN',
          onPressed: _advanceStep,
          expand: true,
        ),
      ],
    );
  }

  Widget _buildStep0Header() {
    return ClipPath(
      clipper: const ChamferClipper(chamfer: AppDimens.chamferM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space12,
        ),
        decoration: ShapeDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          shape: ChamferBorder(
            chamfer: AppDimens.chamferM,
            side: BorderSide(
              color: AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.link_off,
                color: AppColors.warning,
                size: AppDimens.iconM,
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  '¿SEGURO QUE QUERÉS CANCELAR?',
                  style: AppTextStyles.titleL,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Motivo
  // ---------------------------------------------------------------------------

  Widget _buildStep1() {
    final canContinue = _selectedReason != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackHeader('¿POR QUÉ TE VAS?'),
        const SizedBox(height: AppDimens.space20),
        ..._CancelReason.values.map(
          (reason) => _ReasonRadioTile(
            reason: reason,
            selected: _selectedReason == reason,
            onTap: () => setState(() => _selectedReason = reason),
          ),
        ),
        const SizedBox(height: AppDimens.space16),
        AppTextField(
          controller: _commentController,
          label: 'Contanos más (opcional)',
          maxLines: 3,
        ),
        const SizedBox(height: AppDimens.space24),
        AppButton.ghost(
          label: 'CONTINUAR',
          onPressed: canContinue ? _advanceStep : null,
          expand: true,
        ),
        const SizedBox(height: AppDimens.space8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space8,
              ),
            ),
            child: Text(
              'Mantener suscripción',
              style: AppTextStyles.bodyS
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Ofertas + confirmación destructiva
  // ---------------------------------------------------------------------------

  Widget _buildStep2(String fecha) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackHeader('UNA ÚLTIMA COSA'),
        const SizedBox(height: AppDimens.space20),

        // Offer cards (decorative placeholders)
        const Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: _OfferCard(
                  icon: Icons.pause_circle_outline,
                  title: 'PAUSAR SUSCRIPCIÓN',
                  subtitle: 'Pausá por 30 días sin perder tus bots.',
                ),
              ),
            ),
            SizedBox(width: AppDimens.space12),
            Expanded(
              child: ExcludeSemantics(
                child: _OfferCard(
                  icon: Icons.local_offer_outlined,
                  title: 'DESCUENTO DEL 20%',
                  subtitle: 'Seguí con un 20% off el próximo mes.',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space20),

        const HudDivider(label: 'CONFIRMACIÓN FINAL'),
        const SizedBox(height: AppDimens.space20),

        // Double-confirmation switch
        _HudConfirmSwitch(
          value: _doubleConfirmed,
          onChanged: _cancelling
              ? null
              : (v) => setState(() => _doubleConfirmed = v),
        ),
        const SizedBox(height: AppDimens.space16),

        // Mutation error
        if (_mutationError != null) ...[
          _buildMutationError(_mutationError!),
          const SizedBox(height: AppDimens.space12),
        ],

        // Destructive CTA
        Semantics(
          label:
              'Cancelar suscripción definitivamente — esta acción no puede deshacerse',
          button: true,
          excludeSemantics: true,
          child: AppButton.danger(
            label: 'CANCELAR DEFINITIVAMENTE',
            onPressed: (_doubleConfirmed && !_cancelling)
                ? () => _confirmCancel(fecha)
                : null,
            loading: _cancelling,
            expand: true,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared sub-builders
  // ---------------------------------------------------------------------------

  /// Header row with a back button and a title for steps 1 and 2.
  Widget _buildBackHeader(String title) {
    return Row(
      children: [
        Semantics(
          label: 'Volver al paso anterior',
          button: true,
          child: AppIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Volver',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: _cancelling ? null : _backStep,
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.titleL),
          ),
        ),
      ],
    );
  }

  Widget _buildMutationError(String message) {
    return Semantics(
      liveRegion: true,
      label: 'Error: $message',
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: AppDimens.brM,
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: AppDimens.iconS,
              ),
            ),
            const SizedBox(width: AppDimens.space8),
            Expanded(
              child: Text(
                message,
                style:
                    AppTextStyles.bodyS.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass modal container
// ---------------------------------------------------------------------------

/// Custom glass container for modals — uses [AppColors.glassSurfaceStrong] +
/// [BackdropFilter] blur 18, [AppDimens.brXL] radius, [HudCornerBrackets].
class _GlassModalContainer extends StatelessWidget {
  const _GlassModalContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HudCornerBrackets(
      color: AppColors.borderGold,
      armLength: 18,
      child: ClipRRect(
        borderRadius: AppDimens.brXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassSurfaceStrong,
              borderRadius: AppDimens.brXL,
              border: Border.all(color: AppColors.glassBorder),
            ),
            padding: const EdgeInsets.all(AppDimens.space24),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HUD Step Indicator
// ---------------------------------------------------------------------------

class _HudStepIndicator extends StatelessWidget {
  const _HudStepIndicator({required this.currentStep});

  final int currentStep;

  static const _labels = ['CONSECUENCIAS', 'MOTIVO', 'OFERTA'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i == currentStep;
        final isCompleted = i < currentStep;
        final isFuture = i > currentStep;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? AppDimens.space12 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 3,
                  child: isActive
                      ? const HudReactorBar(
                          axis: Axis.horizontal,
                          thickness: 3,
                          color: AppColors.warning,
                          pulsing: true,
                        )
                      : isCompleted
                          ? HudReactorBar(
                              axis: Axis.horizontal,
                              thickness: 3,
                              color: AppColors.success.withValues(alpha: 0.5),
                              pulsing: false,
                            )
                          : Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.borderSubtle,
                                borderRadius: AppDimens.brPill,
                              ),
                            ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[i],
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isFuture
                        ? AppColors.textTertiary
                        : isActive
                            ? AppColors.warning
                            : AppColors.success.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Consequences bullets
// ---------------------------------------------------------------------------

class _ConsequencesBullets extends StatelessWidget {
  const _ConsequencesBullets({required this.fecha});

  final String fecha;

  @override
  Widget build(BuildContext context) {
    final bullets = [
      'Tus bots seguirán activos hasta $fecha',
      'Las conversaciones acumuladas se conservan',
      'Podés reactivar en cualquier momento antes de esa fecha',
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brM,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bullets
            .map(
              (text) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Expanded(
                      child: Text(
                        text,
                        style: AppTextStyles.bodyM,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reason radio tile
// ---------------------------------------------------------------------------

class _ReasonRadioTile extends StatefulWidget {
  const _ReasonRadioTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final _CancelReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ReasonRadioTile> createState() => _ReasonRadioTileState();
}

class _ReasonRadioTileState extends State<_ReasonRadioTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.selected
        ? AppColors.borderGold
        : _hovered
            ? AppColors.borderStrong
            : AppColors.borderDefault;

    final Color fillColor = widget.selected
        ? AppColors.goldGlow.withValues(alpha: 0.4)
        : Colors.transparent;

    return Semantics(
      label: 'Motivo de cancelación: ${widget.reason.label}',
      selected: widget.selected,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          key: ValueKey('radio_${widget.reason.label}'),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.durFast,
            curve: AppMotion.easeStandard,
            margin: const EdgeInsets.only(bottom: AppDimens.space8),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space16,
              vertical: AppDimens.space12,
            ),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: AppDimens.brM,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Radio dot indicator
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.selected
                          ? AppColors.gold
                          : AppColors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: widget.selected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Text(
                    widget.reason.label,
                    style: AppTextStyles.bodyM.copyWith(
                      color: widget.selected
                          ? AppColors.gold
                          : AppColors.textPrimary,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Offer card
// ---------------------------------------------------------------------------

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: AppDimens.brM,
        border: Border.all(color: AppColors.borderGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: AppDimens.iconM),
          const SizedBox(height: AppDimens.space8),
          Text(
            title,
            style: AppTextStyles.label.copyWith(color: AppColors.gold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            subtitle,
            style: AppTextStyles.bodyS,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.space12),
          const AppButton.secondary(
            label: 'APLICAR',
            // Disabled placeholder — not yet wired
            onPressed: null,
            expand: true,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HUD double-confirmation switch
// ---------------------------------------------------------------------------

class _HudConfirmSwitch extends StatelessWidget {
  const _HudConfirmSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _trackW = 44;
  static const double _trackH = 24;
  static const double _knobSize = 18;
  static const double _knobPad = 3;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final dur =
        reduced ? AppMotion.durCrossfadeReduced : AppMotion.durFast;
    final isEnabled = onChanged != null;

    return Semantics(
      toggled: value,
      label:
          'Entiendo que perderé el acceso a mis bots. Doble confirmación: ${value ? 'activada' : 'desactivada'}',
      button: true,
      child: GestureDetector(
        onTap: isEnabled ? () => onChanged!(!value) : null,
        child: MouseRegion(
          cursor: isEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Toggle track
              AnimatedContainer(
                duration: dur,
                curve: AppMotion.easeStandard,
                width: _trackW,
                height: _trackH,
                decoration: BoxDecoration(
                  borderRadius: AppDimens.brPill,
                  color: value
                      ? AppColors.danger.withValues(alpha: 0.5)
                      : AppColors.surfaceHud,
                  border: Border.all(
                    color: value
                        ? AppColors.danger
                        : AppColors.borderDefault,
                  ),
                  boxShadow: value
                      ? AppDimens.glowStatus(AppColors.danger)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_knobPad),
                  child: AnimatedAlign(
                    duration: dur,
                    curve: AppMotion.easeStandard,
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: dur,
                      curve: AppMotion.easeStandard,
                      width: _knobSize,
                      height: _knobSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: value
                            ? AppColors.danger
                            : AppColors.textTertiary,
                        boxShadow: value
                            ? AppDimens.glowStatus(AppColors.danger)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  'Entiendo que perderé el acceso a mis bots',
                  style: AppTextStyles.bodyS
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
