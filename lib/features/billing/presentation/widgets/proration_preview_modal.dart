// Archivo: lib/features/billing/presentation/widgets/proration_preview_modal.dart
//
// T4·05 — ProrationPreviewModal
//
// Modal that shows a line-by-line proration breakdown before the user confirms
// a plan change. Opens as a Dialog on desktop (width ≥ 600) or as a
// ModalBottomSheet on mobile.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Shows a [_ProrationPreviewModal] as a [Dialog] on desktop (width ≥ 600) or
/// as a [ModalBottomSheet] on mobile.
///
/// Immediately calls `billingV2Provider.notifier.previewProration(targetPlanId)`
/// on open and blocks confirmation until the preview has loaded successfully.
Future<void> showProrationPreviewModal(
  BuildContext context,
  WidgetRef ref,
  String targetPlanId,
) async {
  final isDesktop = MediaQuery.of(context).size.width >= 600;

  // Capture the container before showing the dialog so that providers are
  // shared with the modal even when it runs in a separate route/overlay.
  final container = ProviderScope.containerOf(context);

  final modal = UncontrolledProviderScope(
    container: container,
    child: _ProrationPreviewModal(targetPlanId: targetPlanId),
  );

  if (isDesktop) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => modal,
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => modal,
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widget
// ---------------------------------------------------------------------------

class _ProrationPreviewModal extends ConsumerStatefulWidget {
  const _ProrationPreviewModal({required this.targetPlanId});

  final String targetPlanId;

  @override
  ConsumerState<_ProrationPreviewModal> createState() =>
      _ProrationPreviewModalState();
}

class _ProrationPreviewModalState
    extends ConsumerState<_ProrationPreviewModal> {
  // Proration loading / result
  bool _loadingPreview = true;
  ProrationOutput? _preview;
  String? _previewError;

  // Confirmation mutation
  bool _confirming = false;
  String? _mutationError;

  static const _kDisclaimer =
      'El cálculo final lo confirma la pasarela; pueden existir diferencias mínimas.';

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loadingPreview = true;
      _previewError = null;
      _preview = null;
    });

    try {
      final output = await ref
          .read(billingV2Provider.notifier)
          .previewProration(widget.targetPlanId);
      if (!mounted) return;
      setState(() {
        _preview = output;
        _loadingPreview = false;
      });
    } on BillingException catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.message;
        _loadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.toString();
        _loadingPreview = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_preview == null) return;

    final idempotencyKey = const Uuid().v4();

    setState(() {
      _confirming = true;
      _mutationError = null;
    });

    try {
      await ref
          .read(billingV2Provider.notifier)
          .changePlan(widget.targetPlanId, idempotencyKey);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.billingProrationSuccess)),
      );
    } on BillingException catch (e) {
      if (!mounted) return;
      if (e.code == 'not_implemented') {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.billingProrationComingSoon)),
        );
      } else {
        setState(() {
          _mutationError = e.message;
          _confirming = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mutationError = e.toString();
        _confirming = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    final content = _buildContent();

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _ModalContainer(child: content),
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => _ModalContainer(
        child: SingleChildScrollView(
          controller: scrollController,
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        if (_loadingPreview) _buildSkeleton(),
        if (!_loadingPreview && _previewError != null) _buildPreviewError(),
        if (!_loadingPreview && _preview != null) _buildTable(_preview!),
        if (_mutationError != null) ...[
          const SizedBox(height: 12),
          _buildMutationError(_mutationError!),
        ],
        const SizedBox(height: 16),
        _buildDisclaimer(),
        const SizedBox(height: 24),
        _buildActions(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.swap_horiz_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  'Cambio de plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Revisá el detalle antes de confirmar',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Skeleton (loading)
  // ---------------------------------------------------------------------------

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SkeletonRow(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview error
  // ---------------------------------------------------------------------------

  Widget _buildPreviewError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _previewError!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Proration table
  // ---------------------------------------------------------------------------

  Widget _buildTable(ProrationOutput output) {
    final billingState = ref.watch(billingV2Provider).valueOrNull;
    final periodEnd = billingState?.subscription?.currentPeriodEnd;

    // Build proration description for screen readers from line items.
    final creditLines = output.lines
        .where((l) => l.amountCents < 0)
        .map((l) => '\$${(l.amountCents.abs() / 100).toStringAsFixed(2)}')
        .toList();
    final chargeLines = output.lines
        .where((l) => l.amountCents > 0)
        .map((l) => '\$${(l.amountCents / 100).toStringAsFixed(2)}')
        .toList();
    final creditStr =
        creditLines.isNotEmpty ? 'se acreditarán ${creditLines.join(', ')} del plan actual' : '';
    final chargeStr =
        chargeLines.isNotEmpty ? 'se cobrarán ${chargeLines.join(', ')} por el nuevo plan' : '';
    final netStr =
        'Total a cobrar hoy: \$${(output.netAmountCents / 100).toStringAsFixed(2)}';
    final prorationDescription =
        'Ajuste de precio: ${[creditStr, chargeStr, netStr].where((s) => s.isNotEmpty).join(' y ')}';

    return Semantics(
      label: prorationDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...output.lines.map((line) => _ProrationLineRow(line: line)),

          const Divider(color: AppColors.borderGlass, height: 24),

          // Subtotal row
          Semantics(
            label: 'Total a cobrar hoy: \$${(output.netAmountCents / 100).toStringAsFixed(2)}',
            child: _TotalRow(
              label: 'Total a cobrar hoy',
              amountCents: output.netAmountCents,
            ),
          ),

          if (periodEnd != null) ...[
            const SizedBox(height: 8),
            _NextPeriodRow(periodEnd: periodEnd),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mutation error
  // ---------------------------------------------------------------------------

  Widget _buildMutationError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Disclaimer
  // ---------------------------------------------------------------------------

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.textSecondary, size: 15),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _kDisclaimer,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action buttons
  // ---------------------------------------------------------------------------

  Widget _buildActions() {
    final canConfirm = !_loadingPreview &&
        _previewError == null &&
        _preview != null &&
        !_confirming;

    // Resolve target plan details for the accessibility label.
    final billingState = ref.watch(billingV2Provider).valueOrNull;
    final targetPlan = billingState?.availablePlans
        .where((p) => p.id == widget.targetPlanId)
        .firstOrNull;
    final targetPlanName = targetPlan?.name ?? widget.targetPlanId;
    final targetPlanPrice = targetPlan != null
        ? '\$${(targetPlan.priceCents / 100).toStringAsFixed(2)}/mes'
        : '';
    final confirmLabel = _confirming
        ? 'Procesando cambio de plan, por favor espere'
        : 'Confirmar cambio de plan a $targetPlanName'
            '${targetPlanPrice.isNotEmpty ? ' por $targetPlanPrice' : ''}';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _confirming ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(AppStrings.billingProrationCancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            label: confirmLabel,
            liveRegion: _confirming,
            child: FilledButton(
              onPressed: canConfirm ? _confirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _confirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Confirmar cambio',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Container decoration
// ---------------------------------------------------------------------------

class _ModalContainer extends StatelessWidget {
  const _ModalContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Proration line row
// ---------------------------------------------------------------------------

class _ProrationLineRow extends StatelessWidget {
  const _ProrationLineRow({required this.line});

  final ProrationLine line;

  @override
  Widget build(BuildContext context) {
    final isCredit = line.amountCents < 0;
    final color = isCredit ? AppColors.success : AppColors.error;
    final formatted = _formatCents(line.amountCents);
    final dateRange = _formatDateRange(line.periodStart, line.periodEnd);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateRange,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatted,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  String _formatCents(int cents) {
    final dollars = cents.abs() / 100.0;
    final formatted =
        NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(dollars);
    return cents < 0 ? '-$formatted' : '+$formatted';
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('dd/MM/yyyy');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}

// ---------------------------------------------------------------------------
// Total row
// ---------------------------------------------------------------------------

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.amountCents});

  final String label;
  final int amountCents;

  @override
  Widget build(BuildContext context) {
    final isCredit = amountCents < 0;
    final color = isCredit ? AppColors.success : AppColors.primary;
    final dollars = amountCents.abs() / 100.0;
    final formatted =
        NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(dollars);
    final display = isCredit ? '-$formatted' : formatted;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          display,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Next period row
// ---------------------------------------------------------------------------

class _NextPeriodRow extends StatelessWidget {
  const _NextPeriodRow({required this.periodEnd});

  final DateTime periodEnd;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Row(
      children: [
        const Icon(Icons.calendar_today_outlined,
            color: AppColors.textSecondary, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Próximo cobro completo: ${fmt.format(periodEnd)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton row (loading placeholder)
// ---------------------------------------------------------------------------

class _SkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 70,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
