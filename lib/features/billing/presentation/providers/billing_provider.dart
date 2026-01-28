// Archivo: lib/features/billing/presentation/providers/billing_provider.dart
import 'dart:async';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:botslode/features/billing/domain/models/transaction.dart';
import 'package:botslode/features/billing/presentation/providers/billing_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart'; 

part 'billing_provider.g.dart';

enum FinanceHealth { stable, warning, critical }

@riverpod
class Billing extends _$Billing {
  static const double WARNING_THRESHOLD = 0.8; 

  @override
  FutureOr<BillingState> build() async {
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

      // 2. Lógica de Negocio (Cálculo de Límites)
      const double baseLimit = 500.0;
      const double incrementPerBlock = 500.0;
      
      final int blocksOfTen = (qualifiedBotCount / 10).floor(); 
      final double botsBasedLimit = baseLimit + (blocksOfTen * incrementPerBlock);

      // 3. Cálculo de Deuda
      double runningBalance = 0.0;
      for (var tx in transactions) {
        if (tx.type == TransactionType.cycleCharge) runningBalance += tx.amount;
        else if (tx.type == TransactionType.liquidation) {
          runningBalance -= tx.amount;
          if (runningBalance < 0) runningBalance = 0; 
        }
      }

      // 4. Ajuste dinámico de límite basado en deuda (Lógica de expansión de crédito)
      double adjustedDebt = runningBalance - 25.0; 
      if (adjustedDebt < 0) adjustedDebt = 0;

      double debtBasedLimit = baseLimit;
      if (adjustedDebt > baseLimit) {
         final double debtTiers = (adjustedDebt / incrementPerBlock).ceilToDouble();
         debtBasedLimit = debtTiers * incrementPerBlock;
      }

      final double finalLimit = (botsBasedLimit > debtBasedLimit) ? botsBasedLimit : debtBasedLimit;

      // 5. Selección de Tarjeta Principal
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
        creditLimit: 500.0 
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
        throw e; 
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
      throw e; 
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
    if (totalDebt >= (creditLimit * Billing.WARNING_THRESHOLD)) return FinanceHealth.warning;
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