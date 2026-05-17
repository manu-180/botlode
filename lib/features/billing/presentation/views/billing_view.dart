// Archivo: lib/features/billing/presentation/views/billing_view.dart
//
// T4·03 — BillingView refactored to 4-tab Material 3 layout.
// Replaces the legacy desktop-only billing view with a responsive tab structure
// that consumes billingV2Provider (BillingV2Notifier from T4·02).
//
// Tab 0 — Plan            (T4·04, T4·11, T4·15 stubs)
// Tab 1 — Métodos de pago (T4·09, T4·10, T4·12 stubs)
// Tab 2 — Facturas        (T4·13 stub)
// Tab 3 — Historial       (T4·13+ stub)

import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/dunning_warning_banner.dart';
import 'package:botslode/features/billing/presentation/widgets/trial_countdown_banner.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingView extends ConsumerStatefulWidget {
  static const String routeName = 'billing';

  const BillingView({super.key});

  @override
  ConsumerState<BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends ConsumerState<BillingView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingV2Provider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.billingViewTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isMobile,
          tabs: const [
            Tab(
              icon: Icon(Icons.workspace_premium_outlined),
              text: 'Plan',
            ),
            Tab(
              icon: Icon(Icons.credit_card_outlined),
              text: 'Métodos de pago',
            ),
            Tab(
              icon: Icon(Icons.receipt_long_outlined),
              text: 'Facturas',
            ),
            Tab(
              icon: Icon(Icons.history_outlined),
              text: 'Historial',
            ),
          ],
        ),
      ),
      body: billingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                AppStrings.billingViewErrorLoad,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(billingV2Provider),
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.billingViewRetry),
              ),
            ],
          ),
        ),
        data: (billingState) => _BillingTabsBody(
          tabController: _tabController,
          billingState: billingState,
          isMobile: isMobile,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — tabs + conditional banners
// ---------------------------------------------------------------------------

class _BillingTabsBody extends StatelessWidget {
  const _BillingTabsBody({
    required this.tabController,
    required this.billingState,
    required this.isMobile,
  });

  final TabController tabController;
  final BillingV2State billingState;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Conditional banners (above tabs) ---
        const DunningWarningBanner(),
        const TrialCountdownBanner(),

        // --- Tab content ---
        Expanded(
          child: _ResponsiveTabView(
            tabController: tabController,
            billingState: billingState,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive tab view wrapper
// ---------------------------------------------------------------------------

class _ResponsiveTabView extends StatelessWidget {
  const _ResponsiveTabView({
    required this.tabController,
    required this.billingState,
    required this.isMobile,
  });

  final TabController tabController;
  final BillingV2State billingState;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final tabBarView = TabBarView(
      controller: tabController,
      children: [
        Semantics(
          label: 'Tab Plan',
          child: _PlanTab(billingState: billingState),
        ),
        Semantics(
          label: 'Tab Métodos de pago',
          child: _PaymentMethodsTab(billingState: billingState),
        ),
        Semantics(
          label: 'Tab Facturas',
          child: _InvoicesTab(billingState: billingState),
        ),
        Semantics(
          label: 'Tab Historial',
          child: const _HistoryTab(),
        ),
      ],
    );

    // On desktop, constrain content width and center it.
    if (!isMobile) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: tabBarView,
        ),
      );
    }

    return tabBarView;
  }
}

// ---------------------------------------------------------------------------
// Tab 0 — Plan
// ---------------------------------------------------------------------------

class _PlanTab extends StatelessWidget {
  const _PlanTab({required this.billingState});

  final BillingV2State billingState;

  @override
  Widget build(BuildContext context) {
    final subscription = billingState.subscription;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.billingViewCurrentPlan,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Subscription status chip or loading shimmer placeholder.
          if (subscription != null)
            _SubscriptionStatusChip(status: subscription.status)
          else
            const _EmptyStatePill(label: AppStrings.billingViewNoPlan),

          const SizedBox(height: 24),

          // TODO(T4·15): embed SubscriptionSummaryCard
          const _PlaceholderCard(label: 'SubscriptionSummaryCard — T4·15'),

          const SizedBox(height: 16),

          // TODO(T4·04): embed PlanPicker
          const _PlaceholderCard(label: 'PlanPicker — T4·04'),

          const SizedBox(height: 16),

          // TODO(T4·11): embed AutoPaySettingsCard
          const _PlaceholderCard(label: 'AutoPaySettingsCard — T4·11'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Métodos de pago
// ---------------------------------------------------------------------------

class _PaymentMethodsTab extends StatelessWidget {
  const _PaymentMethodsTab({required this.billingState});

  final BillingV2State billingState;

  @override
  Widget build(BuildContext context) {
    final count = billingState.paymentMethods.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.billingViewPaymentMethods,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            count == 0
                ? AppStrings.billingViewNoPaymentMethods
                : '$count método${count == 1 ? '' : 's'} de pago registrado${count == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // TODO(T4·12): embed DigitalCard
          const _PlaceholderCard(label: 'DigitalCard — T4·12'),

          const SizedBox(height: 16),

          // TODO(T4·10): embed ManageCardsModal via button
          FilledButton.icon(
            onPressed: () {
              // TODO(T4·10): open ManageCardsModal
            },
            icon: const Icon(Icons.add_card),
            label: const Text(AppStrings.billingViewAddCard),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Facturas
// ---------------------------------------------------------------------------

class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab({required this.billingState});

  final BillingV2State billingState;

  @override
  Widget build(BuildContext context) {
    final count = billingState.invoices.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.billingViewInvoices,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            count == 0
                ? AppStrings.billingViewNoInvoices
                : '$count factura${count == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // TODO(T4·13): embed InvoiceList
          const _PlaceholderCard(label: 'InvoiceList — T4·13'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — Historial
// ---------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.billingViewHistory,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // TODO(T4·13+): embed billing_events filtered list
          const Text(
            AppStrings.billingViewHistoryComingSoon,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small shared helpers
// ---------------------------------------------------------------------------

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '[ $label ]',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EmptyStatePill extends StatelessWidget {
  const _EmptyStatePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.info_outline, size: 16),
    );
  }
}

class _SubscriptionStatusChip extends StatelessWidget {
  const _SubscriptionStatusChip({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SubscriptionStatus.active => ('Activa', Colors.green),
      SubscriptionStatus.trialing => ('En prueba', Colors.blue),
      SubscriptionStatus.pastDue => ('Pago pendiente', Colors.orange),
      SubscriptionStatus.canceled => ('Cancelada', Colors.red),
      SubscriptionStatus.incomplete => ('Incompleta', Colors.grey),
    };

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color, width: 1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}
