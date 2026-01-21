// Archivo: lib/features/billing/presentation/providers/billing_provider.dart
import 'dart:async'; // <--- FALTABA ESTO (Para FutureOr)
import 'package:botslode/features/billing/domain/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <--- FALTABA ESTO (Para AsyncData)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'billing_provider.g.dart';

@riverpod
class Billing extends _$Billing {
  final _supabase = Supabase.instance.client;

  @override
  FutureOr<BillingState> build() async {
    return _fetchFinancialData();
  }

  Future<BillingState> _fetchFinancialData() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .order('created_at', ascending: true); 

      final transactions = (response as List)
          .map((data) => BotTransaction.fromMap(data))
          .toList();

      // CÁLCULO DE SUELO CERO REFORZADO
      double runningBalance = 0.0;

      for (var tx in transactions) {
        if (tx.type == TransactionType.charge) {
          runningBalance += tx.amount;
        } else {
          // Si es 'liquidation' O 'payment' (fallback), RESTAMOS.
          runningBalance -= tx.amount;
          if (runningBalance < 0) runningBalance = 0; 
        }
      }

      final uiTransactions = List<BotTransaction>.from(transactions.reversed);

      return BillingState(
        totalDebt: runningBalance,
        transactions: uiTransactions,
      );
    } catch (e) {
      print("Error Billing: $e");
      return BillingState(totalDebt: 0, transactions: []);
    }
  }

  Future<void> registerCycleCharge(String botName, double amount, {required String botId}) async {
    // 1. GENERACIÓN DE TRANSACCIÓN VISUAL (Inmediata)
    final optimisticTx = BotTransaction(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}', 
      botId: botId,
      description: 'Ciclo completado: $botName', 
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.charge,
      status: 'PENDING',
    );

    // 2. ACTUALIZACIÓN DE ESTADO SIN ESPERAR RED
    final currentState = state.value;
    if (currentState != null) {
      final newTotal = currentState.totalDebt + amount;
      final newTransactions = [optimisticTx, ...currentState.transactions];
      
      state = AsyncData(BillingState(
        totalDebt: newTotal,
        transactions: newTransactions,
      ));
    }

    // 3. PERSISTENCIA
    final newTxMap = {
      'bot_id': botId,
      'amount': amount,
      'type': 'cycle_charge', 
      'status': 'COMPLETED',
      'bot_name': 'Ciclo completado: $botName', 
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase.from('transactions').insert(newTxMap);
    } catch (e) {
      print("🔥 Error crítico al registrar cargo: $e");
      ref.invalidateSelf(); 
    }
  }

  Future<void> processPayment() async {
    final currentState = state.value;
    if (currentState == null || currentState.totalDebt <= 0.01) {
      return;
    }

    final amountToPay = currentState.totalDebt;

    final newTx = {
      'amount': amountToPay,
      'type': 'liquidation', 
      'status': 'COMPLETED',
      'bot_name': 'Pago manual de operador',
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      // 1. Insertamos en DB
      await _supabase.from('transactions').insert(newTx);
      
      // 2. Optimismo UI (Saldo a 0 ya mismo)
      state = AsyncData(BillingState(
        totalDebt: 0.0, 
        transactions: [
          BotTransaction(
            id: 'pay-temp', 
            description: 'Procesando pago...', 
            amount: amountToPay, 
            date: DateTime.now(), 
            type: TransactionType.liquidation, 
            status: 'PENDING'
          ), 
          ...currentState.transactions
        ]
      ));

      // 3. ESPERA TÁCTICA DE CONSISTENCIA
      await Future.delayed(const Duration(milliseconds: 1000));

      // 4. Recarga real
      ref.invalidateSelf();
      
    } catch (e) {
      print("❌ Error procesando pago: $e");
      ref.invalidateSelf(); 
    }
  }
}

class BillingState {
  final double totalDebt;
  final List<BotTransaction> transactions; 
  BillingState({required this.totalDebt, required this.transactions});
}