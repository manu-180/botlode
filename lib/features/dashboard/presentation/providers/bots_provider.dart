// Archivo: lib/features/dashboard/presentation/providers/bots_provider.dart
import 'dart:async';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Solo para Auth (usuario actual)
import 'package:flutter/material.dart';

part 'bots_provider.g.dart';

const bool USE_TURBO_TIMER = true; 

@riverpod
class Bots extends _$Bots {
  Timer? _timer;
  bool _isAutoPaying = false;
  
  // Enfriamiento para evitar loops de pago
  DateTime? _lastAutoPayAttempt;

  static const double CYCLE_PRICE = 20.00; 
  static const int CYCLE_SECONDS_REAL = 2592000; 

  @override
  FutureOr<List<Bot>> build() async {
    _timer?.cancel();
    
    // Obtenemos el repositorio inyectado
    final repository = ref.read(botsRepositoryProvider);

    try {
      // 1. Carga inicial limpia usando el repositorio
      final bots = await repository.getBots();
      
      _enforceCreditLimit(bots);
      var currentBots = await _syncOfflineCharges(bots);
      
      _startTimer();
      
      ref.onDispose(() => _timer?.cancel());
      return currentBots;
    } catch (e) {
      debugPrint("Error fetching bots via Repo: $e");
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

      final bool canPay = _lastAutoPayAttempt == null || 
                          DateTime.now().difference(_lastAutoPayAttempt!) > const Duration(seconds: 30);

      if (canPay && autoThreshold > 0 && currentDebt >= autoThreshold && !_isAutoPaying) {
          debugPrint("🤖 AUTOPAGO INICIADO: Deuda ($currentDebt) >= Límite ($autoThreshold)");
          _isAutoPaying = true; 
          _lastAutoPayAttempt = DateTime.now(); 
          
          try {
            await ref.read(billingProvider.notifier).processPayment(currentDebt);
            debugPrint("✅ AUTOPAGO ENVIADO");
          } catch (e) {
            debugPrint("❌ FALLO EN AUTOPAGO: $e");
          } finally {
             _isAutoPaying = false; 
          }
          return; 
      }

      final List<Bot> currentList = state.value!;
      final List<Bot> updatedList = [];
      bool moneyChanged = false; 

      double runningTotalDebt = billing.totalDebt;
      final double creditLimit = billing.creditLimit;

      final repository = ref.read(botsRepositoryProvider);

      for (var bot in currentList) {
        bool isLimitReached = runningTotalDebt >= (creditLimit - 0.01);

        // 1. SUSPENSIÓN
        if (isLimitReached && bot.status == BotStatus.active) {
           final debt = bot.calculatedDebt;
           final suspendedBot = bot.copyWith(status: BotStatus.creditSuspended, currentBalance: debt);
           
           // USO DE REPO
           await repository.updateBot(suspendedBot);
           
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
           
           // USO DE REPO
           await repository.updateBot(reactivatedBot);

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
               
               // USO DE REPO
               await repository.updateBot(suspendedBot);

               updatedList.add(suspendedBot);
               runningTotalDebt += CYCLE_PRICE; 
             } else {
               await _chargeCycle(bot);
               runningTotalDebt += CYCLE_PRICE; 
               final nextCycleBot = bot.copyWith(currentBalance: 0.0, cycleStartDate: DateTime.now());
               
               // USO DE REPO
               await repository.updateBot(nextCycleBot);

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

  // --- ACTIONS (AHORA USAN REPO) ---

  Future<void> addBot({required String name, required String description, required Color color, required String systemPrompt}) async {
    // Nota: Aún necesitamos Supabase Auth directo aquí solo para obtener el ID del usuario actual.
    // En una refactorización futura, el User ID debería venir de un AuthRepository.
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    final repository = ref.read(botsRepositoryProvider);

    final newBot = await repository.createBot(
      userId: user.id, 
      name: name, 
      description: description, 
      systemPrompt: systemPrompt, 
      color: color
    );

    final currentList = state.value ?? [];
    state = AsyncData([newBot, ...currentList]);
    
    ref.invalidate(billingProvider);
  }

  Future<void> toggleStatus(String id) async {
    if (state.value == null) return;
    final bot = state.value!.firstWhere((b) => b.id == id);
    final repository = ref.read(botsRepositoryProvider);
    
    if (bot.status == BotStatus.creditSuspended) {
       final newStatus = BotStatus.disabled;
       final updatedBot = bot.copyWith(status: newStatus); 
       
       await repository.updateBot(updatedBot);
       
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
    
    await repository.updateBot(updatedBot);
    
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

    final repository = ref.read(botsRepositoryProvider);
    await repository.deleteBot(id);
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.where((b) => b.id != id).toList());

    ref.invalidate(billingProvider);
  }

  Future<void> updateBotName(String id, String newName) async {
    final repository = ref.read(botsRepositoryProvider);
    await repository.patchBot(id, {'name': newName});
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(name: newName) : b).toList());
  }

  Future<void> updateBotPrompt(String id, String newPrompt) async {
    final repository = ref.read(botsRepositoryProvider);
    await repository.patchBot(id, {'description': newPrompt, 'system_prompt': newPrompt});
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(description: newPrompt, systemPrompt: newPrompt) : b).toList());
  }

  Future<void> updateThemeMode(String id, String mode) async {
    final repository = ref.read(botsRepositoryProvider);
    await repository.patchBot(id, {'theme_mode': mode});
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(themeMode: mode) : b).toList());
  }

  Future<void> updateOfflineAlert(String id, bool enabled) async {
    final repository = ref.read(botsRepositoryProvider);
    await repository.patchBot(id, {'show_offline_alert': enabled});
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(showOfflineAlert: enabled) : b).toList());
  }
}