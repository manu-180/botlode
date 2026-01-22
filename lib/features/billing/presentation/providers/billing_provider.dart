// Archivo: lib/features/billing/presentation/providers/billing_provider.dart
import 'dart:async';
import 'package:botslode/features/billing/data/services/payment_service.dart';
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:botslode/features/billing/domain/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 

part 'billing_provider.g.dart';

@riverpod
class Billing extends _$Billing {
  final _supabase = Supabase.instance.client;
  final _paymentService = PaymentService();

  @override
  FutureOr<BillingState> build() async {
    return _fetchFinancialData();
  }

  Future<BillingState> _fetchFinancialData() async {
    try {
      final txFuture = _supabase.from('transactions').select().order('created_at', ascending: true);
      // AHORA TRAEMOS TODAS LAS TARJETAS (Lista)
      final cardsFuture = _supabase.from('user_billing').select().order('created_at', ascending: false);
      final rateFuture = _paymentService.getDolarBlueRate();

      final results = await Future.wait<dynamic>([txFuture, cardsFuture, rateFuture]);

      final txResponse = results[0] as List;
      final cardsResponse = results[1] as List; // Lista de mapas
      final double dollarRate = results[2] as double;

      final transactions = txResponse.map((data) => BotTransaction.fromMap(data)).toList();
      
      // Mapeamos todas las tarjetas
      final List<CardInfo> allCards = cardsResponse.map((data) => CardInfo.fromMap(data)).toList();
      
      // Buscamos la principal para mostrar en el Dashboard
      final CardInfo? primaryCard = allCards.isNotEmpty 
          ? (allCards.any((c) => c.isPrimary) ? allCards.firstWhere((c) => c.isPrimary) : allCards.first)
          : null;

      double runningBalance = 0.0;
      for (var tx in transactions) {
        if (tx.type == TransactionType.cycleCharge) runningBalance += tx.amount;
        else if (tx.type == TransactionType.liquidation) {
          runningBalance -= tx.amount;
          if (runningBalance < 0) runningBalance = 0; 
        }
      }

      return BillingState(
        totalDebt: runningBalance,
        transactions: List<BotTransaction>.from(transactions.reversed),
        primaryCard: primaryCard,
        allCards: allCards, // Guardamos todas
        dollarRate: dollarRate,
      );
    } catch (e) {
      print("Error Billing: $e");
      return BillingState(totalDebt: 0, transactions: [], primaryCard: null, allCards: [], dollarRate: 1500.0);
    }
  }

  // --- ACCIONES ---

  Future<void> linkNewCard({
    required String number, required String month, required String year,
    required String cvv, required String holder, required String brand, required String lastFour,
  }) async {
    state = const AsyncLoading(); 
    try {
      final userEmail = _supabase.auth.currentUser?.email ?? '';
      final token = await _paymentService.tokenizeCard(
        cardNumber: number, expirationMonth: month, expirationYear: year, 
        securityCode: cvv, cardholderName: holder
      );
      await _paymentService.linkCardToUser(
        token: token, email: userEmail, brand: brand, lastFour: lastFour, holderName: holder, expiryDate: "$month/${year.substring(2)}"
      );
      await Future.delayed(const Duration(seconds: 1));
      ref.invalidateSelf();
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchFinancialData());
      throw e; 
    }
  }

  Future<void> removeCard(String cardId) async {
    state = const AsyncLoading();
    try {
      await _paymentService.deleteCard(cardId);
      await Future.delayed(const Duration(milliseconds: 500));
      ref.invalidateSelf();
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchFinancialData());
    }
  }

  Future<void> setAsPrimary(String cardId) async {
    state = const AsyncLoading();
    try {
      await _paymentService.setPrimaryCard(cardId);
      await Future.delayed(const Duration(milliseconds: 500));
      ref.invalidateSelf();
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchFinancialData());
    }
  }

  // (Mantener processPayment, openManualPaymentLink, registerCycleCharge igual)
  Future<void> processPayment(double amount) async { /* ... Mismo código ... */ }
  Future<void> openManualPaymentLink(double amount) async { /* ... Mismo código ... */ }
  Future<void> registerCycleCharge(String n, double a, {required String botId}) async { /* ... */ }
}

class BillingState {
  final double totalDebt;
  final List<BotTransaction> transactions;
  final CardInfo? primaryCard; // La que se muestra grande
  final List<CardInfo> allCards; // La lista para el modal
  final double dollarRate;
  
  BillingState({required this.totalDebt, required this.transactions, this.primaryCard, required this.allCards, required this.dollarRate});
}