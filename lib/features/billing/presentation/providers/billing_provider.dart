// Archivo: lib/features/billing/presentation/providers/billing_provider.dart
import 'dart:async';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/data/services/payment_service.dart';
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:botslode/features/billing/domain/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 

part 'billing_provider.g.dart';

enum FinanceHealth { stable, warning, critical }

@riverpod
class Billing extends _$Billing {
  final _supabase = Supabase.instance.client;
  final _paymentService = PaymentService();

  static const double WARNING_THRESHOLD = 0.8; 

  @override
  FutureOr<BillingState> build() async {
    return _fetchFinancialData();
  }

  Future<BillingState> _fetchFinancialData() async {
    try {
      final txFuture = _supabase.from('transactions').select().order('created_at', ascending: true);
      final cardsFuture = _supabase.from('user_billing').select().order('created_at', ascending: false);
      final rateFuture = _paymentService.getDolarBlueRate(); 
      
      final botsCountFuture = _supabase
          .from('bots')
          .count(CountOption.exact)
          .or('status.eq.active,status.eq.maintenance');

      final results = await Future.wait<dynamic>([txFuture, cardsFuture, rateFuture, botsCountFuture]);

      final txResponse = results[0] as List;
      final cardsResponse = results[1] as List;
      final double dollarRate = results[2] as double;
      final int qualifiedBotCount = results[3] as int;

      const double baseLimit = 500.0;
      const double incrementPerBlock = 500.0;
      
      final int blocksOfTen = (qualifiedBotCount / 10).floor(); 
      final double botsBasedLimit = baseLimit + (blocksOfTen * incrementPerBlock);

      final transactions = txResponse.map((data) => BotTransaction.fromMap(data)).toList();
      
      double runningBalance = 0.0;
      for (var tx in transactions) {
        if (tx.type == TransactionType.cycleCharge) runningBalance += tx.amount;
        else if (tx.type == TransactionType.liquidation) {
          runningBalance -= tx.amount;
          if (runningBalance < 0) runningBalance = 0; 
        }
      }

      double adjustedDebt = runningBalance - 25.0; 
      if (adjustedDebt < 0) adjustedDebt = 0;

      double debtBasedLimit = baseLimit;
      if (adjustedDebt > baseLimit) {
         final double debtTiers = (adjustedDebt / incrementPerBlock).ceilToDouble();
         debtBasedLimit = debtTiers * incrementPerBlock;
      }

      final double finalLimit = (botsBasedLimit > debtBasedLimit) ? botsBasedLimit : debtBasedLimit;

      final List<CardInfo> allCards = cardsResponse.map((data) => CardInfo.fromMap(data)).toList();
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
    try {
      final newState = state.value!.copyWith(primaryCard: currentCard.copyWith(autoPayThreshold: amount));
      state = AsyncData(newState);
      await _supabase.from('user_billing').update({'auto_pay_threshold': amount}).eq('id', currentCard.id);
    } catch (e) { 
      ref.invalidateSelf(); 
    }
  }

  Future<void> processPayment(double amount) async {
      final card = state.value?.primaryCard;
      if (card == null) throw Exception("No hay tarjeta principal");
      
      // CAMBIO IMPORTANTE: Ya NO ponemos state = AsyncLoading().
      // Esto evita que la pantalla parpadee o muestre el Skeleton.
      // La operación ocurre "en silencio" y al final refresca los datos.
      
      try {
        await _paymentService.processRealPayment(amountUSD: amount, cardId: card.id);
        // Pequeño delay para asegurar que Supabase procese la inserción
        await Future.delayed(const Duration(milliseconds: 1000)); 
        ref.invalidateSelf(); // Solo aquí se refrescan los datos visuales
      } catch (e) {
        // Si falla, no rompemos la UI, solo lanzamos el error para que quien lo llamó lo maneje (ej: el Modal)
        throw e; 
      }
  }

  Future<void> setAsPrimary(String cardId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedCards = currentState.allCards.map((c) {
      return c.copyWith(isPrimary: c.id == cardId);
    }).toList();
    
    final newPrimary = updatedCards.firstWhere((c) => c.id == cardId);
    
    state = AsyncData(currentState.copyWith(
      allCards: updatedCards,
      primaryCard: newPrimary
    ));

    try { 
      await _paymentService.setPrimaryCard(cardId); 
    } catch (e) { 
      ref.invalidateSelf(); 
    }
  }

  Future<void> linkNewCard({required String number, required String month, required String year, required String cvv, required String holder, required String brand, required String lastFour}) async {
    // TAMBIÉN AQUÍ: Quitamos AsyncLoading para que el modal no rompa el fondo
    try {
      final userEmail = _supabase.auth.currentUser?.email ?? '';
      final token = await _paymentService.tokenizeCard(cardNumber: number, expirationMonth: month, expirationYear: year, securityCode: cvv, cardholderName: holder);
      await _paymentService.linkCardToUser(token: token, email: userEmail, brand: brand, lastFour: lastFour, holderName: holder, expiryDate: "$month/${year.substring(2)}");
      
      await Future.delayed(const Duration(seconds: 1));
      ref.invalidateSelf();
    } catch (e) { 
      throw e; 
    }
  }

  Future<void> removeCard(String cardId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedCards = currentState.allCards.where((c) => c.id != cardId).toList();
    CardInfo? newPrimary;
    
    if (currentState.primaryCard?.id == cardId && updatedCards.isNotEmpty) {
       newPrimary = updatedCards.first; 
    } else {
       newPrimary = currentState.primaryCard;
    }

    state = AsyncData(currentState.copyWith(allCards: updatedCards, primaryCard: newPrimary));

    try { 
      await _paymentService.deleteCard(cardId);
      if (updatedCards.isEmpty) ref.invalidateSelf(); 
    } catch (e) { 
      ref.invalidateSelf(); 
    }
  }

  Future<void> openManualPaymentLink(double amount) async {
    if (amount <= 0) return;
    try {
      final url = await _paymentService.createCheckoutLink(amount);
      if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) { 
      debugPrint("Error Link: $e"); 
    }
  }

  Future<void> registerCycleCharge(String botName, double amount, {required String botId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('transactions').insert({
        'user_id': user.id,
        'bot_id': botId,
        'bot_name': botName,
        'amount': amount,
        'type': 'cycle_charge',
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      ref.invalidateSelf();
    } catch (e) {
      debugPrint("❌ ERROR CRÍTICO: No se pudo registrar el cargo del ciclo para $botName: $e");
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