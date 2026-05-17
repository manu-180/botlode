// Archivo: lib/features/billing/presentation/widgets/plan_picker.dart
//
// T4·04 — PlanPicker widget.
//
// Lists available plans as comparison cards and allows the user to select one.
// Triggers `onPlanSelected(planId)` on card CTA tap — the parent (BillingView)
// is responsible for opening the proration preview modal.
//
// Accessibility: WCAG AA compliant — current plan identified by both border
// AND text badge (not color alone). Touch targets ≥ 48 dp on mobile.

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Displays a responsive grid of plan comparison cards with a
/// monthly/yearly interval toggle.
///
/// Call [onPlanSelected] with a plan ID when the user taps "Upgrade" or
/// "Downgrade" on a card. The parent is expected to open the proration
/// preview modal or navigate accordingly.
class PlanPicker extends ConsumerStatefulWidget {
  /// Called when the user taps the CTA of a non-current plan card.
  final void Function(String planId) onPlanSelected;

  const PlanPicker({super.key, required this.onPlanSelected});

  @override
  ConsumerState<PlanPicker> createState() => _PlanPickerState();
}

class _PlanPickerState extends ConsumerState<PlanPicker> {
  BillingInterval _selectedInterval = BillingInterval.month;

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingV2Provider);

    return billingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => _ErrorState(error: err),
      data: (state) => _PlanPickerContent(
        state: state,
        selectedInterval: _selectedInterval,
        onIntervalChanged: (interval) =>
            setState(() => _selectedInterval = interval),
        onPlanSelected: widget.onPlanSelected,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content — rendered when data is available
// ---------------------------------------------------------------------------

class _PlanPickerContent extends StatelessWidget {
  const _PlanPickerContent({
    required this.state,
    required this.selectedInterval,
    required this.onIntervalChanged,
    required this.onPlanSelected,
  });

  final BillingV2State state;
  final BillingInterval selectedInterval;
  final ValueChanged<BillingInterval> onIntervalChanged;
  final void Function(String planId) onPlanSelected;

  @override
  Widget build(BuildContext context) {
    final plans = state.availablePlans
        .where((p) => p.public && p.archivedAt == null)
        .toList();

    final filteredPlans = plans
        .where((p) => p.interval == selectedInterval)
        .toList()
      ..sort((a, b) => a.priceCents.compareTo(b.priceCents));

    final currentPlanId = state.subscription?.planId;
    final currentPlan = currentPlanId != null
        ? state.availablePlans
            .where((p) => p.id == currentPlanId)
            .firstOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Interval toggle ----
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _IntervalToggle(
            selected: selectedInterval,
            onChanged: onIntervalChanged,
          ),
        ),

        // ---- Plan cards grid ----
        if (filteredPlans.isEmpty)
          const _EmptyPlansState()
        else
          _PlanGrid(
            plans: filteredPlans,
            currentPlanId: currentPlanId,
            currentPlan: currentPlan,
            onPlanSelected: onPlanSelected,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Interval toggle (SegmentedButton)
// ---------------------------------------------------------------------------

class _IntervalToggle extends StatelessWidget {
  const _IntervalToggle({
    required this.selected,
    required this.onChanged,
  });

  final BillingInterval selected;
  final ValueChanged<BillingInterval> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.billingPlanPickerIntervalLabel,
      child: SegmentedButton<BillingInterval>(
        segments: const [
          ButtonSegment(
            value: BillingInterval.month,
            label: Text(AppStrings.billingPlanPickerMonthly),
            icon: Icon(Icons.calendar_today_outlined),
          ),
          ButtonSegment(
            value: BillingInterval.year,
            label: Text(AppStrings.billingPlanPickerAnnual),
            icon: Icon(Icons.calendar_month_outlined),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (newSet) {
          if (newSet.isNotEmpty) onChanged(newSet.first);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive grid of plan cards
// ---------------------------------------------------------------------------

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({
    required this.plans,
    required this.currentPlanId,
    required this.currentPlan,
    required this.onPlanSelected,
  });

  final List<Plan> plans;
  final String? currentPlanId;
  final Plan? currentPlan;
  final void Function(String planId) onPlanSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 1 column on mobile (<600), 2 cols on medium, 3 cols on wide.
    final crossAxisCount = switch (screenWidth) {
      < 600 => 1,
      < 900 => 2,
      _ => 3,
    };

    if (crossAxisCount == 1) {
      // Single-column: use a plain Column for better scrollability on mobile.
      return Column(
        children: [
          for (final plan in plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PlanCard(
                plan: plan,
                isCurrent: plan.id == currentPlanId,
                currentPlan: currentPlan,
                onTap: () => onPlanSelected(plan.id),
              ),
            ),
        ],
      );
    }

    // Multi-column: use a grid.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.55,
      ),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _PlanCard(
          plan: plan,
          isCurrent: plan.id == currentPlanId,
          currentPlan: currentPlan,
          onTap: () => onPlanSelected(plan.id),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual plan card
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.currentPlan,
    required this.onTap,
  });

  final Plan plan;
  final bool isCurrent;
  final Plan? currentPlan;
  final VoidCallback onTap;

  bool get _isHighlighted =>
      plan.code == 'starter' ||
      plan.features['highlighted'] == true;

  bool get _isUpgrade =>
      currentPlan == null || plan.priceCents > currentPlan!.priceCents;

  /// Extract string feature values from the features map to show as bullets.
  List<String> get _featureBullets {
    final excluded = {'highlighted'};
    return plan.features.entries
        .where((e) => !excluded.contains(e.key) && e.value is String)
        .map((e) => e.value as String)
        .toList();
  }

  String _formatPrice(BuildContext context) {
    final dollars = plan.priceCents / 100;
    final intervalLabel =
        plan.interval == BillingInterval.month ? 'mes' : 'año';
    return '\$${dollars.toStringAsFixed(2)}/$intervalLabel';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final borderColor = isCurrent
        ? colorScheme.primary
        : _isHighlighted
            ? colorScheme.secondary
            : colorScheme.outlineVariant;

    final borderWidth = isCurrent || _isHighlighted ? 2.0 : 1.0;

    return Semantics(
      label: 'Plan ${plan.name} - ${_formatPrice(context)}',
      selected: isCurrent,
      button: true,
      child: Card(
        elevation: _isHighlighted ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // min: card sizes to content, avoiding Flex-in-unbounded-height issues
            // when the card is inside a SingleChildScrollView (single-column path).
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Badges row (Wrap avoids overflow in narrow grid cells) ---
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (isCurrent)
                    _Badge(
                      label: AppStrings.billingPlanPickerCurrentPlanBadge,
                      backgroundColor:
                          colorScheme.primaryContainer,
                      labelColor: colorScheme.onPrimaryContainer,
                    ),
                  if (_isHighlighted)
                    Semantics(
                      label: 'Plan recomendado: ${plan.name}',
                      child: _Badge(
                        label: 'Recomendado',
                        backgroundColor:
                            colorScheme.secondaryContainer,
                        labelColor: colorScheme.onSecondaryContainer,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // --- Plan name ---
              Text(
                plan.name,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              // --- Price ---
              Text(
                _formatPrice(context),
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // --- Capacity limits ---
              _CapacityRow(
                icon: Icons.smart_toy_outlined,
                label: '${plan.maxBots} bots',
              ),
              const SizedBox(height: 4),
              _CapacityRow(
                icon: Icons.forum_outlined,
                label: '${plan.maxConversations} conversaciones',
              ),

              // --- Feature bullets ---
              if (_featureBullets.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                for (final feature in _featureBullets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // --- CTA button ---
              _PlanCta(
                isCurrent: isCurrent,
                isUpgrade: _isUpgrade,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small sub-widgets
// ---------------------------------------------------------------------------

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.labelColor,
  });

  final String label;
  final Color backgroundColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _CapacityRow extends StatelessWidget {
  const _CapacityRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ],
    );
  }
}

/// CTA button for a plan card. Shows disabled state for the current plan.
///
/// Minimum touch target: 48 × 48 dp (enforced via [SizedBox]).
class _PlanCta extends StatelessWidget {
  const _PlanCta({
    required this.isCurrent,
    required this.isUpgrade,
    required this.onTap,
  });

  final bool isCurrent;
  final bool isUpgrade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = isCurrent
        ? AppStrings.billingPlanPickerCurrentPlanBadge
        : isUpgrade
            ? 'Upgrade'
            : 'Downgrade';

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isCurrent
          ? OutlinedButton(
              onPressed: null, // Disabled — semantics still readable.
              child: Text(label),
            )
          : FilledButton(
              onPressed: onTap,
              child: Text(label),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyPlansState extends StatelessWidget {
  const _EmptyPlansState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay planes disponibles',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacta a soporte para conocer nuestras opciones.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.mail_outline),
            label: const Text(AppStrings.billingPlanPickerContactSupport),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'No se pudieron cargar los planes.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            error.toString(),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
