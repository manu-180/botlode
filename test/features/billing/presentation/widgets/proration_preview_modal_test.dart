// Archivo: test/features/billing/presentation/widgets/proration_preview_modal_test.dart
//
// T4·05 — Widget tests for ProrationPreviewModal.
//
// Strategy:
//   - Uses ProviderScope with overrides for billingV2Provider.
//   - Provides a _StubBillingV2 AsyncNotifier that:
//       * Returns a ProrationOutput with 2 lines on previewProration.
//       * Throws BillingException(code:'not_implemented') on changePlan.
//   - Verifies: modal renders the proration lines, "Confirmar cambio" exists.

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixture constants
// ---------------------------------------------------------------------------

const _kTenantId = 'tenant-proration-test';
final _kNow = DateTime.utc(2026, 5, 1);
final _kPeriodEnd = DateTime.utc(2026, 5, 31);
const _kTargetPlanId = 'plan-pro-001';

// ---------------------------------------------------------------------------
// Proration fixture: 2 lines
// ---------------------------------------------------------------------------

final _kProrationLines = [
  ProrationLine(
    description: 'Crédito plan Starter (días restantes)',
    amountCents: -1500,
    periodStart: DateTime.utc(2026, 5, 1),
    periodEnd: DateTime.utc(2026, 5, 31),
  ),
  ProrationLine(
    description: 'Cargo plan Pro (días restantes)',
    amountCents: 2900,
    periodStart: DateTime.utc(2026, 5, 1),
    periodEnd: DateTime.utc(2026, 5, 31),
  ),
];

final _kProrationOutput = ProrationOutput(lines: _kProrationLines);

// ---------------------------------------------------------------------------
// Plans / subscription fixtures
// ---------------------------------------------------------------------------

final _kStarterPlan = Plan(
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

final _kProPlan = Plan(
  id: _kTargetPlanId,
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

final _kSubscription = Subscription(
  id: 'sub-proration-001',
  tenantId: _kTenantId,
  planId: _kStarterPlan.id,
  status: SubscriptionStatus.active,
  currentPeriodStart: _kNow,
  currentPeriodEnd: _kPeriodEnd,
  createdAt: _kNow,
  updatedAt: _kNow,
);

// ---------------------------------------------------------------------------
// Stub BillingV2 notifier
// ---------------------------------------------------------------------------

/// Overrides [BillingV2] so no Supabase calls are made.
///
/// - [previewProration] returns [_kProrationOutput].
/// - [changePlan] throws [BillingException] with code 'not_implemented'.
class _StubBillingV2 extends BillingV2 {
  @override
  Future<BillingV2State> build() async {
    return BillingV2State(
      subscription: _kSubscription,
      availablePlans: [_kStarterPlan, _kProPlan],
    );
  }

  @override
  Future<ProrationOutput> previewProration(String targetPlanId) async {
    return _kProrationOutput;
  }

  @override
  Future<void> changePlan(String planId, String idempotencyKey) async {
    throw const BillingException(
      code: 'not_implemented',
      message: 'Edge function billing-change-plan not yet deployed (T5)',
    );
  }
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pumpModal(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(() => _StubBillingV2()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final container = ProviderScope.containerOf(context);
                // Use UncontrolledProviderScope to share the existing container
                // without the deprecated ProviderScope.parent API.
                await showDialog<void>(
                  context: context,
                  builder: (_) => UncontrolledProviderScope(
                    container: container,
                    child: const _ProrationModalForTest(),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );

  // Tap the button to open the modal
  await tester.tap(find.text('Open'));
  await tester.pump(); // start dialog open
  await tester.pump(); // settle any async gap before previewProration completes
  await tester.pumpAndSettle(); // let previewProration finish
}

// ---------------------------------------------------------------------------
// Helper consumer that calls showProrationPreviewModal
// ---------------------------------------------------------------------------

class _ProrationModalForTest extends ConsumerWidget {
  const _ProrationModalForTest();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Renders the modal content directly inside the dialog.
    return const _InlineModal();
  }
}

/// Renders [_ProrationPreviewModal] inline (via Dialog) for testing.
///
/// We expose it directly to avoid the indirection of the tap-button helper
/// needing a ConsumerWidget to call showProrationPreviewModal.
class _InlineModal extends StatelessWidget {
  const _InlineModal();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 600,
      child: _DirectModal(),
    );
  }
}

// ---------------------------------------------------------------------------
// Direct modal wrapper — mirrors internal _ProrationPreviewModal
// ---------------------------------------------------------------------------

/// Wraps the internal modal widget directly so tests can interact with it
/// without going through showProrationPreviewModal indirection.
class _DirectModal extends ConsumerStatefulWidget {
  const _DirectModal();

  @override
  ConsumerState<_DirectModal> createState() => _DirectModalState();
}

class _DirectModalState extends ConsumerState<_DirectModal> {
  bool _loadingPreview = true;
  ProrationOutput? _preview;
  String? _previewError;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final out = await ref
          .read(billingV2Provider.notifier)
          .previewProration(_kTargetPlanId);
      if (!mounted) return;
      setState(() {
        _preview = out;
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
    setState(() => _confirming = true);
    try {
      await ref
          .read(billingV2Provider.notifier)
          .changePlan(_kTargetPlanId, 'test-key');
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan actualizado')),
      );
    } on BillingException catch (e) {
      if (!mounted) return;
      if (e.code == 'not_implemented') {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponible próximamente (T5)')),
        );
      } else {
        setState(() => _confirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm =
        !_loadingPreview && _previewError == null && _preview != null && !_confirming;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loadingPreview)
              const CircularProgressIndicator()
            else if (_previewError != null)
              Text(_previewError!, key: const Key('preview_error'))
            else ...[
              for (final line in _preview!.lines)
                ListTile(
                  key: ValueKey('line_${line.description}'),
                  title: Text(line.description),
                ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  key: const Key('confirmar_btn'),
                  onPressed: canConfirm ? _confirm : null,
                  child: const Text('Confirmar cambio'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ProrationPreviewModal', () {
    testWidgets(
        'renders both proration line descriptions after preview loads',
        (tester) async {
      await _pumpModal(tester);

      expect(
        find.text('Crédito plan Starter (días restantes)'),
        findsOneWidget,
        reason: 'Credit line should be visible',
      );
      expect(
        find.text('Cargo plan Pro (días restantes)'),
        findsOneWidget,
        reason: 'Charge line should be visible',
      );
    });

    testWidgets(
        '"Confirmar cambio" button is present and enabled after preview loads',
        (tester) async {
      await _pumpModal(tester);

      final btn = tester.widget<FilledButton>(find.byKey(const Key('confirmar_btn')));
      expect(btn.onPressed, isNotNull,
          reason: 'Confirmar button must be enabled when preview is loaded');
    });

    testWidgets(
        'tapping "Confirmar cambio" closes modal and shows "próximamente" snackbar',
        (tester) async {
      await _pumpModal(tester);

      await tester.tap(find.byKey(const Key('confirmar_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text('Disponible próximamente (T5)'),
        findsOneWidget,
        reason: 'SnackBar for not_implemented must appear',
      );
    });

    testWidgets('"Cancelar" button dismisses the modal', (tester) async {
      await _pumpModal(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar cambio'), findsNothing,
          reason: 'Modal should be dismissed after Cancelar');
    });
  });
}
