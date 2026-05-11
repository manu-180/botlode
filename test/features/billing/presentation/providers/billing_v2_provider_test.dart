// Archivo: test/features/billing/presentation/providers/billing_v2_provider_test.dart
//
// Tests unitarios para BillingV2Notifier (T4).
//
// Estrategia:
//   - Usa ProviderContainer con overrides de repositorios (fakes).
//   - No requiere mockito/mocktail; los fakes implementan las interfaces directamente.
//   - currentUserIdProvider se sobreescribe con un valor fijo para simular tenant.
//   - Los tests verifican: build() exitoso, build() con error, previewProration y
//     la guardia de removePaymentMethod cuando es el único PM activo.

import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/features/billing/domain/exceptions/billing_exception.dart';
import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';
import 'package:botslode/features/billing/domain/repositories/invoices_repository.dart';
import 'package:botslode/features/billing/domain/repositories/payment_methods_repository.dart';
import 'package:botslode/features/billing/domain/repositories/plans_repository.dart';
import 'package:botslode/features/billing/domain/repositories/subscriptions_repository.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_repository_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../_fakes/fake_invoices_repository.dart';
import '../../_fakes/fake_payment_methods_repository.dart';
import '../../_fakes/fake_plans_repository.dart';
import '../../_fakes/fake_subscriptions_repository.dart';

// ---------------------------------------------------------------------------
// Helpers de fixtures
// ---------------------------------------------------------------------------

const _kTenantId = 'tenant-test-001';

Plan _makePlan({
  required String id,
  required String code,
  required int priceCents,
  String currency = 'USD',
}) =>
    Plan(
      id: id,
      code: code,
      name: code,
      priceCents: priceCents,
      currency: currency,
      interval: BillingInterval.month,
      maxBots: 5,
      maxConversations: 1000,
      createdAt: DateTime.utc(2026),
    );

final _starterPlan = _makePlan(id: 'plan-starter', code: 'starter', priceCents: 2900);
final _proPlan = _makePlan(id: 'plan-pro', code: 'pro', priceCents: 7900);

Subscription _makeSubscription({
  SubscriptionStatus status = SubscriptionStatus.active,
  String planId = 'plan-starter',
  bool withPeriod = true,
}) =>
    Subscription(
      id: 'sub-001',
      tenantId: _kTenantId,
      planId: planId,
      status: status,
      currentPeriodStart: withPeriod ? DateTime.utc(2026, 5, 1) : null,
      currentPeriodEnd: withPeriod ? DateTime.utc(2026, 6, 1) : null,
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 1),
    );

PaymentMethod _makePm({
  required String id,
  bool isDefault = false,
}) =>
    PaymentMethod(
      id: id,
      tenantId: _kTenantId,
      gateway: PaymentGateway.stripe,
      gatewayToken: 'tok_test_$id',
      brand: 'visa',
      last4: '4242',
      expMonth: 12,
      expYear: 2028,
      isDefault: isDefault,
      createdAt: DateTime.utc(2026),
    );

Invoice _makeInvoice({required String id}) => Invoice(
      id: id,
      tenantId: _kTenantId,
      number: 'INV-$id',
      totalCents: 2900,
      status: InvoiceStatus.paid,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

// ---------------------------------------------------------------------------
// Factory de ProviderContainer con overrides
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer({
  String? tenantId = _kTenantId,
  SubscriptionsRepository? subscriptionsRepo,
  PlansRepository? plansRepo,
  PaymentMethodsRepository? paymentMethodsRepo,
  InvoicesRepository? invoicesRepo,
}) {
  return ProviderContainer(
    overrides: [
      // Simular usuario autenticado con un tenantId concreto.
      currentUserIdProvider.overrideWithValue(tenantId),

      if (subscriptionsRepo != null)
        subscriptionsRepositoryProvider.overrideWithValue(subscriptionsRepo),
      if (plansRepo != null)
        plansRepositoryProvider.overrideWithValue(plansRepo),
      if (paymentMethodsRepo != null)
        paymentMethodsRepositoryProvider.overrideWithValue(paymentMethodsRepo),
      if (invoicesRepo != null)
        invoicesRepositoryProvider.overrideWithValue(invoicesRepo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BillingV2Notifier', () {
    // -------------------------------------------------------------------------
    // build() — carga exitosa
    // -------------------------------------------------------------------------
    group('build()', () {
      test('carga datos de todos los repos y devuelve BillingV2State completo',
          () async {
        // Arrange
        final sub = _makeSubscription();
        final pm = _makePm(id: 'pm-001', isDefault: true);
        final invoice = _makeInvoice(id: 'inv-001');

        final subsRepo = FakeSubscriptionsRepository(sub);
        final plansRepo = FakePlansRepository()
          ..addPlan(_starterPlan)
          ..addPlan(_proPlan);
        final pmRepo = FakePaymentMethodsRepository([pm]);
        final invRepo = FakeInvoicesRepository([invoice]);

        final container = _makeContainer(
          subscriptionsRepo: subsRepo,
          plansRepo: plansRepo,
          paymentMethodsRepo: pmRepo,
          invoicesRepo: invRepo,
        );
        addTearDown(container.dispose);

        // Act
        final state = await container.read(billingV2Provider.future);

        // Assert
        expect(state.subscription, equals(sub));
        expect(state.availablePlans, hasLength(2));
        expect(state.paymentMethods, hasLength(1));
        expect(state.defaultPaymentMethodId, equals('pm-001'));
        expect(state.invoices, hasLength(1));
        expect(state.errorCode, isNull);
      });

      test('devuelve BillingV2State vacío cuando tenantId es null', () async {
        // Arrange
        final container = _makeContainer(tenantId: null);
        addTearDown(container.dispose);

        // Act
        final state = await container.read(billingV2Provider.future);

        // Assert
        expect(state.subscription, isNull);
        expect(state.availablePlans, isEmpty);
        expect(state.paymentMethods, isEmpty);
        expect(state.invoices, isEmpty);
      });

      test('estado es AsyncError cuando el repositorio lanza excepción',
          () async {
        // Arrange: repo que siempre lanza.
        final throwingSubsRepo = _ThrowingSubscriptionsRepository();

        final container = _makeContainer(
          subscriptionsRepo: throwingSubsRepo,
          plansRepo: FakePlansRepository(),
          paymentMethodsRepo: FakePaymentMethodsRepository(),
          invoicesRepo: FakeInvoicesRepository(),
        );
        addTearDown(container.dispose);

        // Act: esperar a que el provider se resuelva.
        await expectLater(
          container.read(billingV2Provider.future),
          throwsA(isA<BillingRepositoryException>()),
        );

        // Assert: el estado del provider es AsyncError.
        final stateValue = container.read(billingV2Provider);
        expect(stateValue.hasError, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // previewProration()
    // -------------------------------------------------------------------------
    group('previewProration()', () {
      test('calcula prorrateo y lo persiste en pendingProration', () async {
        // Arrange: suscripción activa al plan starter, período de 31 días.
        final sub = _makeSubscription(
          planId: _starterPlan.id,
          withPeriod: true,
        );
        final plansRepo = FakePlansRepository()
          ..addPlan(_starterPlan)
          ..addPlan(_proPlan);

        final container = _makeContainer(
          subscriptionsRepo: FakeSubscriptionsRepository(sub),
          plansRepo: plansRepo,
          paymentMethodsRepo: FakePaymentMethodsRepository(),
          invoicesRepo: FakeInvoicesRepository(),
        );
        addTearDown(container.dispose);

        // Esperar que el estado inicial se cargue.
        await container.read(billingV2Provider.future);

        final notifier = container.read(billingV2Provider.notifier);

        // Act
        final output = await notifier.previewProration(_proPlan.id);

        // Assert
        expect(output, isA<ProrationOutput>());
        // El output no debería estar vacío (starter != pro).
        expect(output.isEmpty, isFalse);

        // El estado debe tener el preview guardado.
        final updatedState = container.read(billingV2Provider).value;
        expect(updatedState?.pendingProration, isNotNull);
      });

      test('lanza BillingException cuando no hay suscripción activa', () async {
        // Arrange: sin suscripción.
        final plansRepo = FakePlansRepository()
          ..addPlan(_starterPlan)
          ..addPlan(_proPlan);

        final container = _makeContainer(
          subscriptionsRepo: FakeSubscriptionsRepository(null),
          plansRepo: plansRepo,
          paymentMethodsRepo: FakePaymentMethodsRepository(),
          invoicesRepo: FakeInvoicesRepository(),
        );
        addTearDown(container.dispose);

        await container.read(billingV2Provider.future);
        final notifier = container.read(billingV2Provider.notifier);

        // Act + Assert
        await expectLater(
          () => notifier.previewProration(_proPlan.id),
          throwsA(
            isA<BillingException>().having(
              (e) => e.code,
              'code',
              'no_subscription',
            ),
          ),
        );
      });

      test('lanza BillingException cuando el plan destino no existe', () async {
        // Arrange: suscripción activa pero sin el plan destino en el catálogo.
        final sub = _makeSubscription(planId: _starterPlan.id);
        final plansRepo = FakePlansRepository()..addPlan(_starterPlan);
        // _proPlan NO está en el catálogo.

        final container = _makeContainer(
          subscriptionsRepo: FakeSubscriptionsRepository(sub),
          plansRepo: plansRepo,
          paymentMethodsRepo: FakePaymentMethodsRepository(),
          invoicesRepo: FakeInvoicesRepository(),
        );
        addTearDown(container.dispose);

        await container.read(billingV2Provider.future);
        final notifier = container.read(billingV2Provider.notifier);

        // Act + Assert
        await expectLater(
          () => notifier.previewProration('plan-inexistente'),
          throwsA(
            isA<BillingException>().having(
              (e) => e.code,
              'code',
              'target_plan_not_found',
            ),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // removePaymentMethod() — guardia
    // -------------------------------------------------------------------------
    group('removePaymentMethod()', () {
      test(
          'lanza BillingException(only_pm_active) cuando es el único PM '
          'y la suscripción está activa', () async {
        // Arrange
        final sub = _makeSubscription(status: SubscriptionStatus.active);
        final pm = _makePm(id: 'pm-solo', isDefault: true);

        final container = _makeContainer(
          subscriptionsRepo: FakeSubscriptionsRepository(sub),
          plansRepo: FakePlansRepository()..addPlan(_starterPlan),
          paymentMethodsRepo: FakePaymentMethodsRepository([pm]),
          invoicesRepo: FakeInvoicesRepository(),
        );
        addTearDown(container.dispose);

        await container.read(billingV2Provider.future);
        final notifier = container.read(billingV2Provider.notifier);

        // Act + Assert
        await expectLater(
          () => notifier.removePaymentMethod('pm-solo'),
          throwsA(
            isA<BillingException>().having(
              (e) => e.code,
              'code',
              'only_pm_active',
            ),
          ),
        );
      });

      test(
          'lanza BillingException(only_pm_active) cuando es el único PM '
          'y la suscripción está trialing', () async {
        // Arrange
        final sub = _makeSubscription(status: SubscriptionStatus.trialing);
        final pm = _makePm(id: 'pm-solo');

        final container = _makeContainer(
          subscriptionsRepo: FakeSubscriptionsRepository(sub),
          plansRepo: FakePlansRepository()..addPlan(_starterPlan),
          paymentMethodsRepo: FakePaymentMethodsRepository([pm]),
          invoicesRepo: FakeInvoicesRepository(),
        );
        addTearDown(container.dispose);

        await container.read(billingV2Provider.future);
        final notifier = container.read(billingV2Provider.notifier);

        // Act + Assert
        await expectLater(
          () => notifier.removePaymentMethod('pm-solo'),
          throwsA(
            isA<BillingException>().having(
              (e) => e.code,
              'code',
              'only_pm_active',
            ),
          ),
        );
      });

      test(
          'lanza BillingException(not_implemented) cuando hay múltiples PMs '
          '(guardia no se activa, pasa al stub T5)', () async {
        // Arrange: dos métodos de pago → la guardia de "único PM" no aplica.
        final sub = _makeSubscription(status: SubscriptionStatus.active);
        final pm1 = _makePm(id: 'pm-001', isDefault: true);
        final pm2 = _makePm(id: 'pm-002');

        final container = _makeContainer(
          subscriptionsRepo: FakeSubscriptionsRepository(sub),
          plansRepo: FakePlansRepository()..addPlan(_starterPlan),
          paymentMethodsRepo: FakePaymentMethodsRepository([pm1, pm2]),
          invoicesRepo: FakeInvoicesRepository(),
        );
        addTearDown(container.dispose);

        await container.read(billingV2Provider.future);
        final notifier = container.read(billingV2Provider.notifier);

        // Act + Assert: pasa la guardia pero choca con el stub T5.
        await expectLater(
          () => notifier.removePaymentMethod('pm-002'),
          throwsA(
            isA<BillingException>().having(
              (e) => e.code,
              'code',
              'not_implemented',
            ),
          ),
        );
      });

      test(
          'permite eliminar el único PM cuando no hay suscripción activa '
          '(llega al stub T5)', () async {
        // Arrange: sin suscripción y un solo PM.
        final pm = _makePm(id: 'pm-solo');

        final container = _makeContainer(
          subscriptionsRepo: FakeSubscriptionsRepository(null),
          plansRepo: FakePlansRepository()..addPlan(_starterPlan),
          paymentMethodsRepo: FakePaymentMethodsRepository([pm]),
          invoicesRepo: FakeInvoicesRepository(),
        );
        addTearDown(container.dispose);

        await container.read(billingV2Provider.future);
        final notifier = container.read(billingV2Provider.notifier);

        // Act + Assert: guardia no aplica (sin sub), llega al stub T5.
        await expectLater(
          () => notifier.removePaymentMethod('pm-solo'),
          throwsA(
            isA<BillingException>().having(
              (e) => e.code,
              'code',
              'not_implemented',
            ),
          ),
        );
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers internos al test
// ---------------------------------------------------------------------------

/// Repositorio de suscripciones que siempre lanza para simular error de red.
class _ThrowingSubscriptionsRepository implements SubscriptionsRepository {
  @override
  Future<Subscription?> getActiveForTenant(String tenantId) async {
    throw BillingRepositoryException(
      'Error simulado de red en SubscriptionsRepository',
    );
  }

  @override
  Future<List<Subscription>> listForTenant(String tenantId,
          {int limit = 20}) async =>
      throw BillingRepositoryException('Error simulado');

  @override
  Future<Subscription?> getById(String id) async =>
      throw BillingRepositoryException('Error simulado');

  @override
  Stream<Subscription?> watchActiveForTenant(String tenantId) =>
      Stream.error(BillingRepositoryException('Error simulado stream'));
}
