// Archivo: test/features/billing/integration/upgrade_plan_smoke_test.dart
//
// T4·26 — Integration smoke test for the "upgrade plan" flow.
//
// Scenario: PlanPicker → ProrationPreviewModal → confirm → success / error.
// All I/O is mocked via _StubBillingV2 subclasses; no network calls are made.
//
// Two scenarios are covered:
//   1. Happy path: changePlan succeeds → snackbar "¡Plan actualizado!" +
//      SubscriptionSummaryCard reflects Pro.
//   2. Card declined: changePlan raises BillingException(card_declined) →
//      inline mutation-error widget shows humanised text from T4·21.
//
// Note on scenario 2: the real _ProrationPreviewModal shows non-"not_implemented"
// BillingExceptions inline (not as a SnackBar). The smoke test therefore
// verifies the inline error text rather than a SnackBar.

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/services/billing_error_mapper.dart';
import 'package:botslode/features/billing/presentation/widgets/plan_picker.dart';
import 'package:botslode/features/billing/presentation/widgets/proration_preview_modal.dart';
import 'package:botslode/features/billing/presentation/widgets/subscription_summary_card.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared fixture constants
// ---------------------------------------------------------------------------

const _kTenantId = 'tenant-smoke-test';
final _kNow = DateTime.utc(2026, 5, 1);
final _kPeriodEnd = DateTime.utc(2026, 5, 31);
const _kProPlanId = 'plan-pro-001';

final _kPlanStarter = Plan(
  id: 'plan-starter-001',
  code: 'starter',
  name: 'Starter',
  priceCents: 900,
  interval: BillingInterval.month,
  maxBots: 3,
  maxConversations: 50,
  features: const {},
  public: true,
  createdAt: _kNow,
);

final _kPlanPro = Plan(
  id: _kProPlanId,
  code: 'pro',
  name: 'Pro',
  priceCents: 2900,
  interval: BillingInterval.month,
  maxBots: 10,
  maxConversations: 500,
  features: const {},
  public: true,
  createdAt: _kNow,
);

final _kSubscriptionStarter = Subscription(
  id: 'sub-smoke-001',
  tenantId: _kTenantId,
  planId: _kPlanStarter.id,
  status: SubscriptionStatus.active,
  currentPeriodStart: _kNow,
  currentPeriodEnd: _kPeriodEnd,
  createdAt: _kNow,
  updatedAt: _kNow,
);

final _kSubscriptionPro = Subscription(
  id: 'sub-smoke-001',
  tenantId: _kTenantId,
  planId: _kProPlanId,
  status: SubscriptionStatus.active,
  currentPeriodStart: _kNow,
  currentPeriodEnd: _kPeriodEnd,
  createdAt: _kNow,
  updatedAt: _kNow,
);

final _kProrationOutput = ProrationOutput(
  lines: [
    ProrationLine(
      description: 'Crédito plan Starter (días restantes)',
      amountCents: -1500,
      periodStart: _kNow,
      periodEnd: _kPeriodEnd,
    ),
    ProrationLine(
      description: 'Cargo plan Pro (días restantes)',
      amountCents: 2900,
      periodStart: _kNow,
      periodEnd: _kPeriodEnd,
    ),
  ],
);

// ---------------------------------------------------------------------------
// Stub notifiers
// ---------------------------------------------------------------------------

/// Happy-path stub: previewProration returns fixture; changePlan updates state
/// to reflect the Pro subscription (simulates Edge Function success in T5).
class _StubBillingV2Success extends BillingV2 {
  @override
  Future<BillingV2State> build() async {
    return BillingV2State(
      subscription: _kSubscriptionStarter,
      availablePlans: [_kPlanStarter, _kPlanPro],
    );
  }

  @override
  Future<ProrationOutput> previewProration(String targetPlanId) async {
    return _kProrationOutput;
  }

  @override
  Future<void> changePlan(String planId, String idempotencyKey) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(subscription: _kSubscriptionPro));
  }
}

/// Error-path stub: changePlan throws a card_declined BillingException.
/// The message is pre-mapped through BillingErrorMapper to simulate what a
/// real T5 implementation would surface after error normalisation (T4·21).
class _StubBillingV2CardDeclined extends BillingV2 {
  @override
  Future<BillingV2State> build() async {
    return BillingV2State(
      subscription: _kSubscriptionStarter,
      availablePlans: [_kPlanStarter, _kPlanPro],
    );
  }

  @override
  Future<ProrationOutput> previewProration(String targetPlanId) async {
    return _kProrationOutput;
  }

  @override
  Future<void> changePlan(String planId, String idempotencyKey) async {
    throw BillingException(
      code: 'card_declined',
      message: BillingErrorMapper.describe(BillingErrorCode.cardDeclined),
    );
  }
}

// ---------------------------------------------------------------------------
// Test scaffold
// ---------------------------------------------------------------------------

/// Composes PlanPicker + SubscriptionSummaryCard and wires onPlanSelected to
/// showProrationPreviewModal, mirroring what BillingView will do once T4·04
/// and T4·15 placeholders are replaced.
class _SmokeScaffold extends ConsumerWidget {
  const _SmokeScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SubscriptionSummaryCard(key: Key('summary_card')),
            PlanPicker(
              onPlanSelected: (planId) =>
                  showProrationPreviewModal(context, ref, planId),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _pumpSmoke(
  WidgetTester tester,
  BillingV2 Function() stubFactory,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [billingV2Provider.overrideWith(stubFactory)],
      child: const MaterialApp(home: _SmokeScaffold()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps the "Upgrade" FilledButton on the Pro plan card and waits for the
/// ProrationPreviewModal to load its preview.
Future<void> _openProModal(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Upgrade'));
  await tester.pump(); // start dialog open
  await tester.pumpAndSettle(); // let previewProration future complete
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('upgrade_plan smoke', () {
    testWidgets(
      'success path: confirms upgrade → snackbar + summary reflects Pro',
      (tester) async {
        await _pumpSmoke(tester, _StubBillingV2Success.new);

        await _openProModal(tester);

        // Modal is open; proration lines rendered.
        expect(
          find.text('Crédito plan Starter (días restantes)'),
          findsOneWidget,
          reason: 'Credit proration line must be visible in modal',
        );
        expect(
          find.text('Confirmar cambio'),
          findsOneWidget,
          reason: 'Confirm button must be present',
        );

        // Confirm upgrade.
        await tester.tap(find.text('Confirmar cambio'));
        await tester.pumpAndSettle();

        // Success snackbar.
        expect(
          find.text('¡Plan actualizado exitosamente!'),
          findsOneWidget,
          reason: 'Success SnackBar must appear after changePlan',
        );

        // SubscriptionSummaryCard shows the Pro plan name.
        expect(
          find.descendant(
            of: find.byKey(const Key('summary_card')),
            matching: find.text('Pro'),
          ),
          findsOneWidget,
          reason: 'Summary card must display Pro after state update',
        );
      },
    );

    testWidgets(
      'card_declined path: confirm → inline error with human-readable text (T4·21)',
      (tester) async {
        await _pumpSmoke(tester, _StubBillingV2CardDeclined.new);

        await _openProModal(tester);

        expect(find.text('Confirmar cambio'), findsOneWidget);

        await tester.tap(find.text('Confirmar cambio'));
        await tester.pumpAndSettle();

        // Modal stays open on non-"not_implemented" errors — no success snackbar.
        expect(
          find.text('¡Plan actualizado exitosamente!'),
          findsNothing,
          reason: 'No success SnackBar must appear on card_declined',
        );

        // Humanised error from BillingErrorMapper (T4·21) rendered inline.
        expect(
          find.text(AppStrings.billingErrCardDeclined),
          findsOneWidget,
          reason:
              'Inline mutation-error widget must show humanised card_declined message',
        );
      },
    );
  });
}
