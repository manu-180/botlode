// Archivo: lib/features/billing/presentation/providers/billing_provider.dart
import 'dart:async';
import 'package:botslode/core/config/cycle_exempt_bots_config.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/features/billing/domain/exceptions/billing_exception.dart';
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:botslode/features/billing/domain/models/invoice_page.dart';
import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/models/transaction.dart';
import 'package:botslode/features/billing/domain/proration/proration_calculator.dart';
import 'package:botslode/features/billing/domain/proration/proration_input.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';
import 'package:botslode/features/billing/presentation/providers/billing_repository_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'billing_provider.g.dart';

enum FinanceHealth { stable, warning, critical }

@riverpod
class Billing extends _$Billing {
  static const double warningThreshold = 0.8;

  @override
  FutureOr<BillingState> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return BillingState(
        totalDebt: 0,
        transactions: [],
        primaryCard: null,
        allCards: [],
        dollarRate: 1200.0,
        creditLimit: 0.0,
      );
    }
    return _fetchFinancialData();
  }

  Future<BillingState> _fetchFinancialData() async {
    final repo = ref.read(billingRepositoryProvider);

    try {
      // 1. Fetching Paralelo Optimizado
      final results = await Future.wait<dynamic>([
        repo.getTransactions(),       // 0
        repo.getCards(),              // 1
        repo.getDolarBlueRate(),      // 2
        repo.getQualifiedBotCount(),  // 3
      ]);

      final transactions = results[0] as List<BotTransaction>;
      final allCards = results[1] as List<CardInfo>;
      final double dollarRate = results[2] as double;
      final int qualifiedBotCount = results[3] as int;

      // 2. Límite = total de bots (activos + desactivados) × 60 — todos cuentan para el tope (mín. 60)
      const double limitPerBot = 60.0;
      final double finalLimit = (qualifiedBotCount > 0 ? qualifiedBotCount : 1) * limitPerBot;

      // 3. Cálculo de Deuda (excluye cobros de bots exentos del ciclo)
      double runningBalance = 0.0;
      for (var tx in transactions) {
        if (tx.type == TransactionType.cycleCharge) {
          if (!CycleExemptBotsConfig.isExempt(tx.botId)) runningBalance += tx.amount;
        } else if (tx.type == TransactionType.liquidation) {
          runningBalance -= tx.amount;
          if (runningBalance < 0) runningBalance = 0;
        }
      }

      // 4. Selección de Tarjeta Principal
      CardInfo? primaryCard;
      if (allCards.isNotEmpty) {
        primaryCard = allCards.firstWhere((c) => c.isPrimary, orElse: () => allCards.first);
      }

      return BillingState(
        totalDebt: runningBalance,
        transactions: List<BotTransaction>.from(transactions.reversed),
        primaryCard: primaryCard,
        allCards: allCards,
        dollarRate: dollarRate,
        creditLimit: finalLimit, 
      );
    } catch (e) {
      // Fallback seguro para no romper UI
      return BillingState(
        totalDebt: 0, 
        transactions: [], 
        primaryCard: null, 
        allCards: [], 
        dollarRate: 1200.0, 
        creditLimit: 0.0
      );
    }
  }

  // --- ACTIONS ---

  Future<void> updateAutoPayThreshold(double amount) async {
    final currentCard = state.value?.primaryCard;
    if (currentCard == null) return;
    
    final repo = ref.read(billingRepositoryProvider);
    
    try {
      // Optimistic UI Update
      final newState = state.value!.copyWith(primaryCard: currentCard.copyWith(autoPayThreshold: amount));
      state = AsyncData(newState);
      
      await repo.updateAutoPayThreshold(currentCard.id, amount);
    } catch (e) { 
      ref.invalidateSelf(); 
    }
  }

  Future<void> processPayment(double amount) async {
      final card = state.value?.primaryCard;
      if (card == null) throw Exception("No hay tarjeta principal");
      
      final repo = ref.read(billingRepositoryProvider);

      try {
        await repo.processPayment(amountUSD: amount, cardId: card.id);
        
        // Pequeño delay para asegurar consistencia en BD
        await Future.delayed(const Duration(milliseconds: 1000)); 
        ref.invalidateSelf(); 
      } catch (e) {
        rethrow;
      }
  }

  Future<void> setAsPrimary(String cardId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(billingRepositoryProvider);

    // Optimistic UI
    final updatedCards = currentState.allCards.map((c) {
      return c.copyWith(isPrimary: c.id == cardId);
    }).toList();
    
    final newPrimary = updatedCards.firstWhere((c) => c.id == cardId);
    
    state = AsyncData(currentState.copyWith(
      allCards: updatedCards,
      primaryCard: newPrimary
    ));

    try { 
      await repo.setPrimaryCard(cardId); 
    } catch (e) { 
      ref.invalidateSelf(); 
    }
  }

  Future<void> linkNewCard({required String number, required String month, required String year, required String cvv, required String holder, required String brand, required String lastFour}) async {
    final repo = ref.read(billingRepositoryProvider);
    final userEmail = ref.read(currentUserEmailProvider);

    try {
      await repo.linkCard(
        number: number, 
        month: month, 
        year: year, 
        cvv: cvv, 
        holder: holder, 
        brand: brand, 
        lastFour: lastFour, 
        email: userEmail
      );
      
      // Forzar estado de loading antes de recargar
      state = const AsyncLoading();
      await Future.delayed(const Duration(milliseconds: 500));
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeCard(String cardId) async {
    final currentState = state.value;
    if (currentState == null) return;
    
    final repo = ref.read(billingRepositoryProvider);

    // Optimistic UI
    final updatedCards = currentState.allCards.where((c) => c.id != cardId).toList();
    CardInfo? newPrimary;
    
    if (currentState.primaryCard?.id == cardId && updatedCards.isNotEmpty) {
       newPrimary = updatedCards.first; 
    } else {
       newPrimary = currentState.primaryCard;
    }

    state = AsyncData(currentState.copyWith(allCards: updatedCards, primaryCard: newPrimary));

    try { 
      await repo.deleteCard(cardId);
      if (updatedCards.isEmpty) ref.invalidateSelf(); 
    } catch (e) { 
      ref.invalidateSelf(); 
    }
  }

  Future<void> openManualPaymentLink(double amount) async {
    if (amount <= 0) return;
    final repo = ref.read(billingRepositoryProvider);
    
    try {
      final url = await repo.createCheckoutLink(amount);
      if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) { 
      // Error silenciado
    }
  }

  Future<void> registerCycleCharge(String botName, double amount, {required String botId}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final repo = ref.read(billingRepositoryProvider);

    try {
      await repo.registerCycleCharge(
        botId: botId, 
        botName: botName, 
        amount: amount, 
        userId: user.id
      );
      ref.invalidateSelf();
    } catch (e) {
      // Error silenciado
    }
  }
}

class BillingState {
  final double totalDebt;
  final double creditLimit;
  final List<BotTransaction> transactions;
  final CardInfo? primaryCard; 
  final List<CardInfo> allCards;
  final double dollarRate;
  
  BillingState({
    required this.totalDebt, 
    required this.transactions, 
    this.primaryCard, 
    required this.allCards, 
    required this.dollarRate, 
    required this.creditLimit
  });

  double get usagePercentage => (totalDebt / creditLimit).clamp(0.0, 1.0);

  FinanceHealth get health {
    if (totalDebt >= creditLimit) return FinanceHealth.critical;
    if (totalDebt >= (creditLimit * Billing.warningThreshold)) return FinanceHealth.warning;
    return FinanceHealth.stable;
  }

  Color get statusColor {
    switch (health) {
      case FinanceHealth.stable: return AppColors.success; 
      case FinanceHealth.warning: return AppColors.warning; 
      case FinanceHealth.critical: return AppColors.error; 
    }
  }

  BillingState copyWith({
    double? totalDebt, 
    double? creditLimit, 
    List<BotTransaction>? transactions,
    CardInfo? primaryCard,
    List<CardInfo>? allCards,
    double? dollarRate
  }) {
    return BillingState(
      totalDebt: totalDebt ?? this.totalDebt,
      creditLimit: creditLimit ?? this.creditLimit,
      transactions: transactions ?? this.transactions,
      primaryCard: primaryCard ?? this.primaryCard,
      allCards: allCards ?? this.allCards,
      dollarRate: dollarRate ?? this.dollarRate,
    );
  }
}

// =============================================================================
// T4 — BillingV2Notifier
// =============================================================================
//
// Nuevo notifier que consume los repositorios del dominio T3 en lugar del
// legacy BillingRepository. Convive con el Billing notifier existente sin
// tocarlo.
//
// Responsabilidades:
//  - Carga inicial paralela de suscripción, planes, métodos de pago y facturas.
//  - Suscripción realtime a cambios de suscripción activa (watchActiveForTenant).
//  - Mutaciones optimistas o stubbed (las que requieren Edge Functions son T5).
//  - Cálculo local de prorrateo con ProrationCalculator.
//
// tenantId = userId (igual que el Billing legacy; en T5 se diferenciará si
// existen tenants multi-usuario).
// =============================================================================

/// Excepción estructurada de la capa de presentación de billing V2.
///
/// Distingue errores de negocio (p. ej. "only_pm_active") de errores técnicos.
/// Usada internamente y en los tests.
class BillingException implements Exception {
  final String code;
  final String message;

  const BillingException({required this.code, required this.message});

  @override
  String toString() => 'BillingException($code): $message';
}

/// Notifier T4 que expone [BillingV2State] a la capa de presentación.
///
/// Usa los repositorios del dominio T3 (SubscriptionsRepository,
/// PlansRepository, PaymentMethodsRepository, InvoicesRepository) para todas
/// las lecturas. Las mutaciones que requieren Edge Functions están stubbed
/// hasta T5.
@riverpod
class BillingV2 extends _$BillingV2 {
  /// Suscripción activa al stream de cambios de suscripción (realtime).
  StreamSubscription<Subscription?>? _subscriptionSub;

  @override
  FutureOr<BillingV2State> build() async {
    // Liberar el stream anterior si el provider se reconstruye.
    ref.onDispose(() {
      _subscriptionSub?.cancel();
    });

    final tenantId = ref.watch(currentUserIdProvider);
    if (tenantId == null) {
      return const BillingV2State();
    }

    final subscriptionsRepo = ref.read(subscriptionsRepositoryProvider);
    final plansRepo = ref.read(plansRepositoryProvider);
    final paymentMethodsRepo = ref.read(paymentMethodsRepositoryProvider);
    final invoicesRepo = ref.read(invoicesRepositoryProvider);

    // Carga paralela de todas las fuentes de datos.
    final futures = await Future.wait<dynamic>([
      subscriptionsRepo.getActiveForTenant(tenantId),   // 0
      plansRepo.listPublic(),                            // 1
      paymentMethodsRepo.listForTenant(tenantId),        // 2
      invoicesRepo.listForTenant(tenantId, limit: 20),  // 3
    ]);

    final subscription = futures[0] as Subscription?;
    final plans = List<Plan>.from(futures[1] as List);
    final paymentMethods =
        List<PaymentMethod>.from(futures[2] as List);
    final invoicePage = futures[3] as InvoicePage;

    final defaultPmId = paymentMethods
        .where((pm) => pm.isDefault)
        .map((pm) => pm.id)
        .firstOrNull;

    // Suscribir stream realtime y propagar cambios invalidando el provider.
    // skip(1): omite la emisión inicial (ya cargamos el valor arriba con getActiveForTenant)
    // y solo reacciona a cambios reales posteriores del servidor.
    _subscriptionSub?.cancel();
    _subscriptionSub = subscriptionsRepo
        .watchActiveForTenant(tenantId)
        .skip(1)
        .listen((_) => ref.invalidateSelf());

    return BillingV2State(
      subscription: subscription,
      availablePlans: plans,
      paymentMethods: paymentMethods,
      defaultPaymentMethodId: defaultPmId,
      invoices: invoicePage.items,
    );
  }

  // ---------------------------------------------------------------------------
  // Mutaciones de plan (T5 stub)
  // ---------------------------------------------------------------------------

  /// Cambia el plan de la suscripción activa.
  ///
  /// TODO(T5): implementar via Edge Function billing-change-plan.
  Future<void> changePlan(String planId, String idempotencyKey) async {
    throw const BillingException(
      code: 'not_implemented',
      message: 'Edge function billing-change-plan not yet deployed (T5)',
    );
  }

  /// Cancela la suscripción activa al final del período.
  ///
  /// TODO(T5): implementar via Edge Function billing-cancel.
  Future<void> cancelSubscription({String? reason}) async {
    throw const BillingException(
      code: 'not_implemented',
      message: 'Edge function billing-cancel not yet deployed (T5)',
    );
  }

  /// Reactiva una suscripción con cancelAtPeriodEnd = true.
  ///
  /// TODO(T5): implementar via Edge Function billing-reactivate.
  Future<void> reactivateSubscription() async {
    throw const BillingException(
      code: 'not_implemented',
      message: 'Edge function billing-reactivate not yet deployed (T5)',
    );
  }

  // ---------------------------------------------------------------------------
  // Mutaciones de método de pago
  // ---------------------------------------------------------------------------

  /// Agrega un nuevo método de pago vía token del gateway.
  ///
  /// TODO(T5): implementar via Edge Function billing-add-payment-method.
  Future<void> addPaymentMethod(
    String gatewayToken, {
    bool setAsDefault = false,
  }) async {
    throw const BillingException(
      code: 'not_implemented',
      message: 'Edge function billing-add-payment-method not yet deployed (T5)',
    );
  }

  /// Establece el método de pago predeterminado (optimistic update + invalidate).
  Future<void> setDefaultPaymentMethod(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update local.
    final updatedMethods = current.paymentMethods.map((pm) {
      return pm.copyWith(isDefault: pm.id == id);
    }).toList();

    state = AsyncData(
      current.copyWith(
        paymentMethods: updatedMethods,
        defaultPaymentMethodId: id,
        isLoading: true,
        errorCode: null,
        errorMessage: null,
      ),
    );

    try {
      // TODO(T5): llamar Edge Function billing-set-default-pm.
      // Por ahora invalidamos para recargar desde la BD.
      throw const BillingException(
        code: 'not_implemented',
        message: 'Edge function billing-set-default-pm not yet deployed (T5)',
      );
    } on BillingException catch (e) {
      state = AsyncData(
        current.copyWith(
          errorCode: e.code,
          errorMessage: e.message,
          isLoading: false,
        ),
      );
      rethrow;
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Elimina un método de pago.
  ///
  /// Lanza [BillingException] con código `'only_pm_active'` si es el único
  /// método de pago y la suscripción está activa o trialing.
  Future<void> removePaymentMethod(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Guardia: no eliminar si es el único PM con suscripción activa.
    final activeStatuses = {
      SubscriptionStatus.active,
      SubscriptionStatus.trialing,
      SubscriptionStatus.pastDue,
    };
    final hasActiveSub = current.subscription != null &&
        activeStatuses.contains(current.subscription!.status);
    final isOnlyPm = current.paymentMethods.length == 1 &&
        current.paymentMethods.first.id == id;

    if (hasActiveSub && isOnlyPm) {
      throw const BillingException(
        code: 'only_pm_active',
        message:
            'No se puede eliminar el único método de pago con una suscripción activa.',
      );
    }

    // TODO(T5): implementar via Edge Function billing-remove-payment-method.
    throw const BillingException(
      code: 'not_implemented',
      message: 'Edge function billing-remove-payment-method not yet deployed (T5)',
    );
  }

  // ---------------------------------------------------------------------------
  // Proration preview (cálculo local)
  // ---------------------------------------------------------------------------

  /// Genera un preview de prorrateo para el cambio al plan [targetPlanId].
  ///
  /// Requiere que haya una suscripción activa con período definido y que
  /// [targetPlanId] esté en la lista de planes disponibles.
  ///
  /// Lanza [BillingException] en caso de datos insuficientes.
  Future<ProrationOutput> previewProration(String targetPlanId) async {
    final current = state.valueOrNull;
    if (current == null) {
      throw const BillingException(
        code: 'no_state',
        message: 'El estado de billing aún no está disponible.',
      );
    }

    final subscription = current.subscription;
    if (subscription == null) {
      throw const BillingException(
        code: 'no_subscription',
        message: 'No hay suscripción activa para calcular el prorrateo.',
      );
    }

    if (subscription.currentPeriodStart == null ||
        subscription.currentPeriodEnd == null) {
      throw const BillingException(
        code: 'no_period',
        message:
            'La suscripción no tiene fechas de período definidas para el prorrateo.',
      );
    }

    final currentPlan = current.availablePlans
        .where((p) => p.id == subscription.planId)
        .firstOrNull;
    if (currentPlan == null) {
      throw BillingException(
        code: 'current_plan_not_found',
        message:
            'El plan actual (${subscription.planId}) no se encontró en el catálogo disponible.',
      );
    }

    final newPlan = current.availablePlans
        .where((p) => p.id == targetPlanId)
        .firstOrNull;
    if (newPlan == null) {
      throw BillingException(
        code: 'target_plan_not_found',
        message:
            'El plan destino ($targetPlanId) no se encontró en el catálogo disponible.',
      );
    }

    const calculator = ProrationCalculator();
    final input = ProrationInput(
      currentPlan: currentPlan,
      newPlan: newPlan,
      currentPeriodStart: subscription.currentPeriodStart!,
      currentPeriodEnd: subscription.currentPeriodEnd!,
      changeAt: DateTime.now().toUtc(),
      currency: currentPlan.currency,
    );

    try {
      final output = calculator.compute(input);

      // Persistir preview en el estado para que la UI lo acceda sin re-llamar.
      if (state.hasValue) {
        state = AsyncData(state.value!.copyWith(pendingProration: output));
      }

      return output;
    } on BillingRepositoryException catch (e) {
      throw BillingException(code: 'proration_error', message: e.message);
    }
  }

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------

  /// Fuerza la recarga de facturas invalidando el provider.
  Future<void> refreshInvoices() async {
    ref.invalidateSelf();
  }
}