// Archivo: lib/features/dashboard/presentation/providers/bots_provider.dart
import 'dart:async';
import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/dashboard/domain/exceptions/credit_limit_reached_exception.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

part 'bots_provider.g.dart';

@riverpod
class Bots extends _$Bots {
  bool get _useTurboTimer => ref.read(useTurboTimerProvider);
  Timer? _timer;
  bool _isAutoPaying = false;
  
  // Enfriamiento para evitar loops de pago
  DateTime? _lastAutoPayAttempt;

  static const double CYCLE_PRICE = 20.00; // Cada ciclo carga $20 al pozo
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
      final useTurbo = ref.read(useTurboTimerProvider);
      currentBots = currentBots.map((b) => b.copyWith(useTurboMode: useTurbo)).toList();

      _startTimer();

      ref.onDispose(() => _timer?.cancel());
      return currentBots;
    } catch (e) {
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
    final duration = _useTurboTimer ? const Duration(seconds: 1) : const Duration(minutes: 1);
    
    _timer = Timer.periodic(duration, (timer) {
      // 🚀 OPTIMIZACIÓN: Timer NO-BLOQUEANTE
      // Procesa cambios inmediatamente en UI, operaciones BD en background
      _processBotsTickNonBlocking();
    });
  }

  void _processBotsTickNonBlocking() {
    if (state.value == null) return;

    final billingAsync = ref.read(billingProvider);
    if (billingAsync.isLoading || billingAsync.isRefreshing || _isAutoPaying) return; 

    final billing = billingAsync.valueOrNull;
    if (billing == null) return;

    // --- AUTOPAGO (ejecutar en background) ---
    final autoThreshold = billing.primaryCard?.autoPayThreshold ?? 0.0;
    final currentDebt = billing.totalDebt;

    final bool canPay = _lastAutoPayAttempt == null || 
                        DateTime.now().difference(_lastAutoPayAttempt!) > const Duration(seconds: 30);

    if (canPay && autoThreshold > 0 && currentDebt >= autoThreshold && !_isAutoPaying) {
        _isAutoPaying = true; 
        _lastAutoPayAttempt = DateTime.now(); 
        
        // Ejecutar en background sin bloquear
        _executeAutoPay(currentDebt);
        return; 
    }

    // --- PROCESAMIENTO DE BOTS ---
    final List<Bot> currentList = state.value!;
    final List<Bot> updatedList = [];
    final List<Future<void>> backgroundTasks = []; // Operaciones BD en paralelo
    bool moneyChanged = false; 

    double runningTotalDebt = billing.totalDebt;
    final double creditLimit = billing.creditLimit;
    final repository = ref.read(botsRepositoryProvider);
    final now = DateTime.now();
    final cycleLimit = _useTurboTimer ? 30 : CYCLE_SECONDS_REAL;

    for (var bot in currentList) {
      bool isLimitReached = runningTotalDebt >= (creditLimit - 0.01);

      // 1. SUSPENSIÓN POR LÍMITE
      if (isLimitReached && bot.status == BotStatus.active) {
         final debt = bot.calculatedDebt;
         final suspendedBot = bot.copyWith(status: BotStatus.creditSuspended, currentBalance: debt);
         
         // UI: Actualización inmediata
         updatedList.add(suspendedBot);
         moneyChanged = true;
         
         // BD: En background
         backgroundTasks.add(repository.updateBot(suspendedBot));
         continue; 
      }

      // 2. REACTIVACIÓN
      if (!isLimitReached && bot.status == BotStatus.creditSuspended) {
         final double fractionSpent = bot.currentBalance / CYCLE_PRICE;
         final double secondsToRewind = fractionSpent * cycleLimit;
         
         final reactivatedBot = bot.copyWith(
           status: BotStatus.active, 
           currentBalance: 0.0, 
           cycleStartDate: now.subtract(Duration(seconds: secondsToRewind.round())) 
         );
         
         // UI: Actualización inmediata
         updatedList.add(reactivatedBot);
         moneyChanged = true;
         
         // BD: En background
         backgroundTasks.add(repository.updateBot(reactivatedBot));
         continue;
      }

      // 3. CICLO OPERATIVO
      if (bot.status == BotStatus.active) {
        final diffInSeconds = now.difference(bot.cycleStartDate).inSeconds;

        if (diffInSeconds >= cycleLimit) {
           if ((runningTotalDebt + CYCLE_PRICE) > creditLimit) {
             // Suspender por alcanzar límite al completar ciclo
             final suspendedBot = bot.copyWith(status: BotStatus.creditSuspended, currentBalance: bot.calculatedDebt);
             
             // UI: Actualización inmediata
             updatedList.add(suspendedBot);
             runningTotalDebt += CYCLE_PRICE;
             
             // BD: En background
             backgroundTasks.add(repository.updateBot(suspendedBot));
           } else {
             // ✅ Completar ciclo normalmente
             final nextCycleBot = bot.copyWith(currentBalance: 0.0, cycleStartDate: now);
             runningTotalDebt += CYCLE_PRICE;
             
             // UI: Actualización INMEDIATA (sin await)
             updatedList.add(nextCycleBot);
             
             // BD: En background (en paralelo)
             backgroundTasks.add(_chargeCycle(bot));
             backgroundTasks.add(repository.updateBot(nextCycleBot));
           }
           moneyChanged = true;
        } else {
           // No ha completado ciclo, continuar igual
           updatedList.add(bot); 
        }
      } else {
        updatedList.add(bot);
      }
    }

    // 🚀 ACTUALIZAR UI INMEDIATAMENTE (sin esperar BD)
    state = AsyncData([...updatedList]); 

    // 📡 Ejecutar operaciones BD en paralelo en background
    if (backgroundTasks.isNotEmpty) {
      Future.wait(backgroundTasks).catchError((e) {
        // Error silenciado
        return <void>[];
      });
    }

    // 💰 Invalidar billing si hubo cambios monetarios
    if (moneyChanged) {
      // Pequeño delay para que las transacciones se completen
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.invalidate(billingProvider);
      });
    }
  }

  void _executeAutoPay(double amount) {
    ref.read(billingProvider.notifier).processPayment(amount).then((_) {
      // Autopago completado
    }).catchError((e) {
      // Error silenciado
    }).whenComplete(() {
      _isAutoPaying = false;
    });
  }

  Future<void> _chargeCycle(Bot bot) async {
    await ref.read(billingProvider.notifier).registerCycleCharge(bot.name, CYCLE_PRICE, botId: bot.id);
  }

  Future<List<Bot>> _syncOfflineCharges(List<Bot> bots) async {
    final List<Bot> updatedList = [];
    final cycleLimit = _useTurboTimer ? 30 : CYCLE_SECONDS_REAL; 
    
    for (var bot in bots) {
      if (bot.status == BotStatus.active) {
        final secondsActive = DateTime.now().difference(bot.cycleStartDate).inSeconds;
        
        // 🔧 FIX: Protección contra fechas muy antiguas
        // Si el bot tiene una fecha de inicio muy antigua (más de 2 ciclos atrás),
        // lo reiniciamos en lugar de cobrar ciclos acumulados
        if (secondsActive > (cycleLimit * 2)) {
          updatedList.add(bot.copyWith(currentBalance: 0.0, cycleStartDate: DateTime.now()));
        } else if (secondsActive >= cycleLimit) {
          // Cobrar solo UN ciclo (no múltiples ciclos acumulados)
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

  Future<Map<String, String>> addBot({required String name, required String description, required Color color, required String systemPrompt}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception("Tu sesión expiró. Por favor, inicia sesión nuevamente.");
    }

    final repository = ref.read(botsRepositoryProvider);

    final newBot = await repository.createBot(
      userId: userId,
      name: name,
      description: description,
      systemPrompt: systemPrompt,
      color: color
    );

    final currentList = state.value ?? [];
    final useTurbo = ref.read(useTurboTimerProvider);
    state = AsyncData([newBot.copyWith(useTurboMode: useTurbo), ...currentList]);
    
    ref.invalidate(billingProvider);
    
    // ⬅️ NUEVO: Obtener PIN y alias del bot recién creado
    final supabase = Supabase.instance.client;
    final botData = await supabase
        .from('bots')
        .select('access_pin, alias')
        .eq('id', newBot.id)
        .single();
    
    return {
      'pin': botData['access_pin'] ?? '0000',
      'alias': botData['alias'] ?? name.toLowerCase().replaceAll(' ', '-'),
      'name': newBot.name,
    };
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
        throw const CreditLimitReachedException();
      }
    }
    
    final newStatus = isTurningOff ? BotStatus.disabled : BotStatus.active;
    double newBalance;
    DateTime newStartDate;
    final cycleLimit = _useTurboTimer ? 30 : CYCLE_SECONDS_REAL;

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
    // ⬅️ SIMPLIFICADO: Solo actualizar system_prompt (description ya no se usa)
    await repository.patchBot(id, {'system_prompt': newPrompt});
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(systemPrompt: newPrompt) : b).toList());
  }

  Future<void> updateBotColor(String id, Color newColor) async {
    final repository = ref.read(botsRepositoryProvider);
    final hexColor = '#${newColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    await repository.patchBot(id, {'tech_color': hexColor});
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(primaryColor: newColor) : b).toList());
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

  Future<void> updateInitialMessage(String id, String newMessage) async {
    final repository = ref.read(botsRepositoryProvider);
    await repository.patchBot(id, {'initial_message': newMessage});
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(initialMessage: newMessage) : b).toList());
  }

  /// Actualiza la configuración de la burbuja WhatsApp.
  /// Si [wpp] es true, [telefono] es obligatorio (no null ni vacío).
  Future<void> updateWppConfig(String id, bool wpp, String? telefono) async {
    if (wpp && (telefono == null || telefono.trim().isEmpty)) {
      throw Exception("Cuando la burbuja WhatsApp está activa, el número de contacto es obligatorio.");
    }
    final repository = ref.read(botsRepositoryProvider);
    await repository.patchBot(id, {
      'wpp': wpp,
      'telefono': wpp ? telefono!.trim() : null,
    });
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id
        ? b.copyWith(wpp: wpp, telefono: wpp ? telefono!.trim() : null)
        : b).toList());
  }

  /// Actualiza el tamaño de las burbujas flotantes (bot + WhatsApp).
  Future<void> updateBubbleSize(String id, double size) async {
    final repository = ref.read(botsRepositoryProvider);
    await repository.patchBot(id, {'bubble_size': size});
    
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((b) => b.id == id ? b.copyWith(bubbleSize: size) : b).toList());
  }
}