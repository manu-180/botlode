// Archivo: lib/features/dashboard/presentation/providers/bots_provider.dart
import 'dart:async';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

part 'bots_provider.g.dart';

const bool USE_TURBO_TIMER = true; 

@riverpod
class Bots extends _$Bots {
  final _supabase = Supabase.instance.client;
  Timer? _timer;
  bool _isAutoPaying = false;
  
  // NUEVO: Enfriamiento para evitar loops de pago
  DateTime? _lastAutoPayAttempt;

  static const double CYCLE_PRICE = 20.00; 
  static const int CYCLE_SECONDS_REAL = 2592000; 

  @override
  FutureOr<List<Bot>> build() async {
    _timer?.cancel();
    try {
      final response = await _supabase.from('bots').select().order('created_at', ascending: false);
      final bots = (response as List).map((m) => Bot.fromMap(m)).toList();
      
      _enforceCreditLimit(bots);
      var currentBots = await _syncOfflineCharges(bots);
      
      _startTimer();
      
      ref.onDispose(() => _timer?.cancel());
      return currentBots;
    } catch (e) {
      debugPrint("Error fetching bots: $e");
      return [];
    }
  }

  void _enforceCreditLimit(List<Bot> bots) {
    final billing = ref.read(billingProvider).valueOrNull;
    if (billing != null && billing.totalDebt >= billing.creditLimit) {
       // Lógica preventiva si fuera necesaria
    }
  }

  void _startTimer() {
    final duration = USE_TURBO_TIMER ? const Duration(seconds: 1) : const Duration(minutes: 1);
    
    _timer = Timer.periodic(duration, (timer) async {
      if (state.value == null) return;

      final billingAsync = ref.read(billingProvider);
      if (billingAsync.isLoading || billingAsync.isRefreshing || _isAutoPaying) return; 

      final billing = billingAsync.valueOrNull;
      if (billing == null) return;

      // --- AUTOPAGO BLINDADO ---
      final autoThreshold = billing.primaryCard?.autoPayThreshold ?? 0.0;
      final currentDebt = billing.totalDebt;

      // Verificamos si pasó suficiente tiempo desde el último intento (30 segundos)
      final bool canPay = _lastAutoPayAttempt == null || 
                          DateTime.now().difference(_lastAutoPayAttempt!) > const Duration(seconds: 30);

      if (canPay && autoThreshold > 0 && currentDebt >= autoThreshold && !_isAutoPaying) {
          debugPrint("🤖 AUTOPAGO INICIADO: Deuda ($currentDebt) >= Límite ($autoThreshold)");
          _isAutoPaying = true; 
          _lastAutoPayAttempt = DateTime.now(); // Marcamos el intento
          
          try {
            await ref.read(billingProvider.notifier).processPayment(currentDebt);
            debugPrint("✅ AUTOPAGO ENVIADO");
          } catch (e) {
            debugPrint("❌ FALLO EN AUTOPAGO: $e");
          } finally {
             _isAutoPaying = false; 
          }
          // Salimos para no mezclar lógica de pago con lógica de bots en el mismo tick
          return; 
      }

      final List<Bot> currentList = state.value!;
      final List<Bot> updatedList = [];
      bool moneyChanged = false; 

      double runningTotalDebt = billing.totalDebt;
      final double creditLimit = billing.creditLimit;

      for (var bot in currentList) {
        bool isLimitReached = runningTotalDebt >= (creditLimit - 0.01);

        // 1. SUSPENSIÓN
        if (isLimitReached && bot.status == BotStatus.active) {
           final debt = bot.calculatedDebt;
           final suspendedBot = bot.copyWith(status: BotStatus.creditSuspended, currentBalance: debt);
           await _updateBotInDb(suspendedBot);
           updatedList.add(suspendedBot);
           moneyChanged = true;
           continue; 
        }

        // 2. REACTIVACIÓN
        if (!isLimitReached && bot.status == BotStatus.creditSuspended) {
           final cycleLimit = USE_TURBO_TIMER ? 30 : CYCLE_SECONDS_REAL;
           final double fractionSpent = bot.currentBalance / CYCLE_PRICE;
           final double secondsToRewind = fractionSpent * cycleLimit;
           
           final reactivatedBot = bot.copyWith(
             status: BotStatus.active, 
             currentBalance: 0.0, 
             cycleStartDate: DateTime.now().subtract(Duration(seconds: secondsToRewind.round())) 
           );
           
           await _updateBotInDb(reactivatedBot);
           updatedList.add(reactivatedBot);
           moneyChanged = true;
           continue;
        }

        // 3. CICLO OPERATIVO
        if (bot.status == BotStatus.active) {
          final now = DateTime.now();
          final diffInSeconds = now.difference(bot.cycleStartDate).inSeconds;
          final cycleLimit = USE_TURBO_TIMER ? 30 : CYCLE_SECONDS_REAL;

          if (diffInSeconds >= cycleLimit) {
             if ((runningTotalDebt + CYCLE_PRICE) > creditLimit) {
               final suspendedBot = bot.copyWith(status: BotStatus.creditSuspended, currentBalance: bot.calculatedDebt);
               await _updateBotInDb(suspendedBot);
               updatedList.add(suspendedBot);
               runningTotalDebt += CYCLE_PRICE; 
             } else {
               await _chargeCycle(bot);
               runningTotalDebt += CYCLE_PRICE; 
               final nextCycleBot = bot.copyWith(currentBalance: 0.0, cycleStartDate: DateTime.now());
               await _updateBotInDb(nextCycleBot);
               updatedList.add(nextCycleBot);
             }
             moneyChanged = true;
          } else {
             updatedList.add(bot); 
          }
        } else {
          updatedList.add(bot);
        }
      }

      state = AsyncData([...updatedList]); 

      if (moneyChanged) {
        ref.invalidate(billingProvider); 
      }
    });
  }

  Future<void> _updateBotInDb(Bot bot) async {
    try {
      await _supabase.from('bots').update({
        'status': bot.status == BotStatus.creditSuspended ? 'credit_suspended' : bot.status.name,
        'current_balance': bot.currentBalance,
        'cycle_start_date': bot.cycleStartDate.toIso8601String()
      }).eq('id', bot.id);
    } catch (e) { debugPrint("DB Update Error: $e"); }
  }

  Future<void> _chargeCycle(Bot bot) async {
    await ref.read(billingProvider.notifier).registerCycleCharge(bot.name, CYCLE_PRICE, botId: bot.id);
  }

  Future<List<Bot>> _syncOfflineCharges(List<Bot> bots) async {
    final List<Bot> updatedList = [];
    final cycleLimit = USE_TURBO_TIMER ? 30 : CYCLE_SECONDS_REAL; 
    
    for (var bot in bots) {
      if (bot.status == BotStatus.active) {
        final secondsActive = DateTime.now().difference(bot.cycleStartDate).inSeconds;
        if (secondsActive >= cycleLimit) {
          await _chargeCycle(bot);
          updatedList.add(bot.copyWith(currentBalance: 0.0, cycleStartDate: DateTime.now()));
        } else {
          updatedList.add(bot);
        }
      } else {
        updatedList.add(bot);
      }
    }
    return updatedList;
  }

  // --- ACTIONS ---

  Future<void> addBot({required String name, required String description, required Color color, required String systemPrompt}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    final hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    final nowUtc = DateTime.now().toUtc();

    final newBotMap = {
      'user_id': user.id,
      'name': name,
      'description': description,
      'system_prompt': systemPrompt,
      'status': 'active', 
      'tech_color': hexColor,
      'current_balance': 0.0, 
      'cycle_start_date': nowUtc.toIso8601String(), 
      'created_at': nowUtc.toIso8601String(),
    };

    final response = await _supabase.from('bots').insert(newBotMap).select().single();
    final newBot = Bot.fromMap(response);

    final currentList = state.value ?? [];
    state = AsyncData([newBot, ...currentList]);
    
    ref.invalidate(billingProvider);
  }

  Future<void> toggleStatus(String id) async {
    if (state.value == null) return;
    final bot = state.value!.firstWhere((b) => b.id == id);
    
    if (bot.status == BotStatus.creditSuspended) {
       final newStatus = BotStatus.disabled;
       final updatedBot = bot.copyWith(status: newStatus); 
       await _updateBotInDb(updatedBot);
       state = AsyncData(state.value!.map((b) => b.id == id ? updatedBot : b).toList());
       return;
    }

    final isTurningOff = bot.status == BotStatus.active;
    
    if (!isTurningOff) { 
       final billing = ref.read(billingProvider).valueOrNull;
       if (billing != null && billing.totalDebt >= billing.creditLimit) {
         throw Exception("Límite de crédito excedido.");
       }
    }
    
    final newStatus = isTurningOff ? BotStatus.disabled : BotStatus.active;
    double newBalance;
    DateTime newStartDate;
    final cycleLimit = USE_TURBO_TIMER ? 30 : CYCLE_SECONDS_REAL;

    if (isTurningOff) {
      newBalance = bot.calculatedDebt; 
      newStartDate = bot.cycleStartDate; 
    } else {
      final double fractionSpent = bot.currentBalance / CYCLE_PRICE;
      final double secondsToRewind = fractionSpent * cycleLimit;
      newStartDate = DateTime.now().subtract(Duration(seconds: secondsToRewind.round()));
      newBalance = 0.0; 
    }

    final updatedBot = bot.copyWith(status: newStatus, currentBalance: newBalance, cycleStartDate: newStartDate);
    await _updateBotInDb(updatedBot);
    
    state = AsyncData(state.value!.map((b) => b.id == id ? updatedBot : b).toList());
    
    ref.invalidate(billingProvider);
  }

  Future<void> removeBot(String id) async {
    if (state.value == null) return;
    
    final botToDelete = state.value!.firstWhere((b) => b.id == id);
    final finalDebt = botToDelete.calculatedDebt;

    if (finalDebt > 0.001) { 
      await ref.read(billingProvider.notifier).registerCycleCharge(
        "${botToDelete.name} (LIQUIDACIÓN FINAL)", 
        finalDebt, 
        botId: id
      );
    }

    await _supabase.from('bots').delete().eq('id', id);
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.where((b) => b.id != id).toList());

    ref.invalidate(billingProvider);
  }

  Future<void> updateBotName(String id, String newName) async {
    await _supabase.from('bots').update({'name': newName}).eq('id', id);
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(name: newName) : b).toList());
  }

  Future<void> updateBotPrompt(String id, String newPrompt) async {
    await _supabase.from('bots').update({'description': newPrompt, 'system_prompt': newPrompt}).eq('id', id);
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(description: newPrompt, systemPrompt: newPrompt) : b).toList());
  }

  Future<void> updateThemeMode(String id, String mode) async {
    await _supabase.from('bots').update({'theme_mode': mode}).eq('id', id);
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(themeMode: mode) : b).toList());
  }

  Future<void> updateOfflineAlert(String id, bool enabled) async {
    await _supabase.from('bots').update({'show_offline_alert': enabled}).eq('id', id);
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(showOfflineAlert: enabled) : b).toList());
  }
}