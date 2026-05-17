// Archivo: lib/features/billing/presentation/widgets/reactivate_subscription_flow.dart
//
// T4·57 — ReactivateSubscriptionFlow (Hangar OS HUD redesign)
//
// Three visual states:
//   blocked  — no default payment method; prompts user to add one.
//   confirm  — has payment method; shows charge summary and REACTIVAR CTA.
//   success  — reactivation succeeded; brief success flash, then auto-close.
//
// Entry point: showReactivateFlow(BuildContext, WidgetRef)

import 'dart:ui';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Flow states
// ---------------------------------------------------------------------------

enum _FlowState { blocked, confirm, success }

// ---------------------------------------------------------------------------
// Internal result token
// ---------------------------------------------------------------------------

enum _ReactivateResult { addCard }

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Shows the Hangar OS HUD reactivation modal.
///
/// If no default payment method exists, shows the blocked state and opens
/// [AddCardModal] when the user taps "AGREGAR MÉTODO". Providers are shared
/// via [UncontrolledProviderScope] so no Supabase re-initialization occurs.
Future<void> showReactivateFlow(BuildContext context, WidgetRef ref) async {
  final container = ProviderScope.containerOf(context);

  final result = await showDialog<_ReactivateResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.scrim,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: const _ReactivateDialog(),
    ),
  );

  if (result == _ReactivateResult.addCard && context.mounted) {
    await AddCardModal.show(context);
  }
}

// ---------------------------------------------------------------------------
// Internal dialog widget
// ---------------------------------------------------------------------------

class _ReactivateDialog extends ConsumerStatefulWidget {
  const _ReactivateDialog();

  @override
  ConsumerState<_ReactivateDialog> createState() => _ReactivateDialogState();
}

class _ReactivateDialogState extends ConsumerState<_ReactivateDialog>
    with SingleTickerProviderStateMixin {
  _FlowState _flowState = _FlowState.confirm;
  bool _isLoading = false;
  String? _errorMessage;

  // Scale-in animation for the success check icon.
  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durBase,
    );
    _successScale = CurvedAnimation(
      parent: _successCtrl,
      curve: AppMotion.easeEntrance,
    );
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Reactivation action
  // ---------------------------------------------------------------------------

  Future<void> _onReactivate() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(billingV2Provider.notifier).reactivateSubscription();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _flowState = _FlowState.success;
      });

      // Animate check icon unless reduced motion is requested.
      if (!AppMotion.reduced(context)) {
        _successCtrl.forward();
      }

      // Brief pause so the user sees the success panel, then close.
      await Future.delayed(
        AppMotion.durDeliberate + const Duration(milliseconds: 400),
      );
      if (!mounted) return;
      navigator.pop();
    } on BillingException catch (e) {
      if (!mounted) return;
      if (e.code == 'not_implemented') {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.billingReactivateComingSoon)),
        );
      } else {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'No pudimos procesar la reactivación. Intentá de nuevo.';
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingV2Provider);
    final state = billingAsync.valueOrNull;
    final defaultPm =
        state?.paymentMethods.where((pm) => pm.isDefault).firstOrNull;

    // Resolve effective state: blocked when no PM, but don't override success.
    final effectiveState =
        (_flowState == _FlowState.confirm && defaultPm == null)
            ? _FlowState.blocked
            : _flowState;

    final reduced = AppMotion.reduced(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _GlassModalContainer(
          successGlow: effectiveState == _FlowState.success,
          child: AnimatedSwitcher(
            duration:
                reduced ? AppMotion.durCrossfadeReduced : AppMotion.durBase,
            switchInCurve:
                reduced ? Curves.linear : AppMotion.easeEntrance,
            switchOutCurve:
                reduced ? Curves.linear : AppMotion.easeExit,
            child: KeyedSubtree(
              key: ValueKey<_FlowState>(effectiveState),
              child: Semantics(
                label: _stepLabel(effectiveState),
                child: switch (effectiveState) {
                  _FlowState.blocked => _buildBlockedContent(),
                  _FlowState.confirm => _buildConfirmContent(state, defaultPm),
                  _FlowState.success => _buildSuccessContent(reduced),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stepLabel(_FlowState state) => switch (state) {
        _FlowState.blocked =>
          'Reactivación bloqueada: se requiere método de pago',
        _FlowState.confirm => 'Confirmar reactivación de suscripción',
        _FlowState.success => 'Suscripción reactivada correctamente',
      };

  // ---------------------------------------------------------------------------
  // State: blocked — no payment method
  // ---------------------------------------------------------------------------

  Widget _buildBlockedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          icon: Icons.lock_outline_rounded,
          iconColor: AppColors.warning,
          title: 'MÉTODO DE PAGO REQUERIDO',
        ),
        const SizedBox(height: AppDimens.space16),
        Text(
          'Necesitás agregar un método de pago antes de reactivar tu suscripción.',
          style: AppTextStyles.bodyM
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimens.space24),
        AppButton.primary(
          label: 'AGREGAR MÉTODO',
          onPressed: () =>
              Navigator.of(context).pop(_ReactivateResult.addCard),
          expand: true,
        ),
        const SizedBox(height: AppDimens.space12),
        AppButton.ghost(
          label: 'CANCELAR',
          onPressed: () => Navigator.of(context).pop(),
          expand: true,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // State: confirm — has payment method
  // ---------------------------------------------------------------------------

  Widget _buildConfirmContent(dynamic state, dynamic defaultPm) {
    final sub = state?.subscription;
    final periodEndStr = sub?.currentPeriodEnd != null
        ? DateFormat('dd/MM/yyyy').format(sub!.currentPeriodEnd!)
        : '—';

    final pmLast4 = (defaultPm?.last4 as String?) ?? '—';
    final pmBrand =
        ((defaultPm?.brand as String?) ?? '').toUpperCase();
    final pmLabel =
        pmBrand.isNotEmpty ? '$pmBrand •••• $pmLast4' : '•••• $pmLast4';

    final plan = sub != null
        ? (state?.availablePlans as List?)
            ?.where((p) => p.id == sub.planId)
            .firstOrNull
        : null;
    final planPriceStr = plan != null
        ? '\$${((plan.priceCents as int) / 100).toStringAsFixed(2)}/mes'
        : '—';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          icon: Icons.refresh_rounded,
          iconColor: AppColors.gold,
          iconGlowColor: AppColors.goldGlow,
          title: 'REACTIVAR SUSCRIPCIÓN',
        ),
        const SizedBox(height: AppDimens.space16),

        // HUD charge readout
        Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.surfaceHud,
            borderRadius: AppDimens.brM,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadoutRow('FECHA', periodEndStr, mono: true),
              const SizedBox(height: AppDimens.space8),
              _buildReadoutRow('MONTO', planPriceStr, gold: true),
              const SizedBox(height: AppDimens.space8),
              _buildReadoutRow('MÉTODO', pmLabel, mono: true),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: AppDimens.space12),
          _buildErrorBand(_errorMessage!),
        ],

        const SizedBox(height: AppDimens.space24),

        Semantics(
          label: _isLoading
              ? 'Procesando reactivación, por favor espere'
              : 'Reactivar suscripción — se cobrará $planPriceStr el $periodEndStr',
          liveRegion: _isLoading,
          button: true,
          excludeSemantics: true,
          child: AppButton.primary(
            label: 'REACTIVAR',
            onPressed: _isLoading ? null : _onReactivate,
            loading: _isLoading,
            expand: true,
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        AppButton.ghost(
          label: 'CANCELAR',
          onPressed:
              _isLoading ? null : () => Navigator.of(context).pop(),
          expand: true,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // State: success — brief celebration then auto-close
  // ---------------------------------------------------------------------------

  Widget _buildSuccessContent(bool reduced) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: reduced
              ? const AlwaysStoppedAnimation(1.0)
              : _successScale,
          child: const ExcludeSemantics(
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: AppDimens.iconL,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space16),
        Semantics(
          liveRegion: true,
          child: Text(
            'SISTEMA REACTIVADO',
            style: AppTextStyles.titleM.copyWith(color: AppColors.success),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        Text(
          'Tu suscripción está activa nuevamente.',
          style: AppTextStyles.bodyS,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared sub-builders
  // ---------------------------------------------------------------------------

  Widget _buildHeader({
    required IconData icon,
    required Color iconColor,
    Color? iconGlowColor,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.space8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: AppDimens.brS,
            boxShadow: iconGlowColor != null
                ? [
                    BoxShadow(
                      color: iconGlowColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
          child: ExcludeSemantics(
            child: Icon(icon, color: iconColor, size: AppDimens.iconM),
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.titleM),
          ),
        ),
      ],
    );
  }

  Widget _buildReadoutRow(
    String label,
    String value, {
    bool mono = false,
    bool gold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.textTertiary),
        ),
        Text(
          value,
          style: gold
              ? AppTextStyles.hudReadout.copyWith(color: AppColors.gold)
              : mono
                  ? AppTextStyles.mono
                  : AppTextStyles.bodyS,
        ),
      ],
    );
  }

  Widget _buildErrorBand(String message) {
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
                style: AppTextStyles.bodyS.copyWith(color: AppColors.danger),
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

/// Custom glass container for modals — matches the cancel flow's container.
/// When [successGlow] is true, the border and brackets shift to [AppColors.success]
/// with a subtle success glow on the outer shadow layer.
class _GlassModalContainer extends StatelessWidget {
  const _GlassModalContainer({
    required this.child,
    this.successGlow = false,
  });

  final Widget child;
  final bool successGlow;

  @override
  Widget build(BuildContext context) {
    // Outer AnimatedContainer carries the box shadow (outside the clip).
    return AnimatedContainer(
      duration: AppMotion.durBase,
      curve: AppMotion.easeStandard,
      decoration: BoxDecoration(
        borderRadius: AppDimens.brXL,
        boxShadow: successGlow
            ? [
                ...AppDimens.elev3,
                ...AppDimens.glowStatus(AppColors.success),
              ]
            : AppDimens.elev3,
      ),
      child: HudCornerBrackets(
        color: successGlow ? AppColors.success : AppColors.borderGold,
        armLength: 18,
        child: ClipRRect(
          borderRadius: AppDimens.brXL,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: AppMotion.durBase,
              curve: AppMotion.easeStandard,
              decoration: BoxDecoration(
                color: AppColors.glassSurfaceStrong,
                borderRadius: AppDimens.brXL,
                border: Border.all(
                  color: successGlow
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.glassBorder,
                ),
              ),
              padding: const EdgeInsets.all(AppDimens.space24),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
