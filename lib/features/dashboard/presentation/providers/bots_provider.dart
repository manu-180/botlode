// Archivo: lib/features/dashboard/presentation/providers/bots_provider.dart
import 'dart:async';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

part 'bots_provider.g.dart';

const bool IS_TURBO_MODE = true; 

@riverpod
class Bots extends _$Bots {
  final _supabase = Supabase.instance.client;
  Timer? _timer;

  @override
  FutureOr<List<Bot>> build() async {
    try {
      final response = await _supabase
          .from('bots')
          .select()
          .order('created_at', ascending: false);
      
      final bots = (response as List).map((m) => Bot.fromMap(m)).toList();
      var currentBots = await _syncOfflineCharges(bots);
      _startTimer();
      ref.onDispose(() => _timer?.cancel());
      return currentBots;
    } catch (e) {
      return []; // Fallback silencioso offline
    }
  }

  Future<List<Bot>> _syncOfflineCharges(List<Bot> bots) async {
    if (IS_TURBO_MODE) return bots; 

    final List<Bot> updatedList = [];
    for (var bot in bots) {
      if (bot.status == BotStatus.active) {
        final double realDebt = bot.calculatedDebt;
        if (bot.daysActive >= 30) {
          await _closeBotCycle(bot);
          updatedList.add(bot.copyWith(currentBalance: 0.0, cycleStartDate: DateTime.now()));
        } else if (realDebt != bot.currentBalance) {
          try {
            await _supabase.from('bots').update({'current_balance': realDebt}).eq('id', bot.id);
          } catch (_) {} 
          updatedList.add(bot.copyWith(currentBalance: realDebt));
        } else {
          updatedList.add(bot);
        }
      } else {
        updatedList.add(bot);
      }
    }
    return updatedList;
  }

  void _startTimer() {
    final duration = IS_TURBO_MODE ? const Duration(milliseconds: 200) : const Duration(minutes: 1);
    _timer = Timer.periodic(duration, (timer) {
      if (state.value == null) return;
      if (IS_TURBO_MODE) {
        _simulateTurboTick();
      } else {
        ref.invalidateSelf();
      }
    });
  }

  void _simulateTurboTick() {
    final List<Bot> updatedBots = [];
    bool changed = false;

    for (var bot in state.value!) {
      if (bot.status == BotStatus.active) {
        final newStartDate = bot.cycleStartDate.subtract(const Duration(hours: 12));
        final simulatedBot = bot.copyWith(cycleStartDate: newStartDate);
        
        if (simulatedBot.daysActive >= 30) {
           _closeBotCycle(bot); 
           updatedBots.add(bot.copyWith(currentBalance: 0.0, cycleStartDate: DateTime.now()));
        } else {
           updatedBots.add(simulatedBot);
        }
        changed = true;
      } else {
        updatedBots.add(bot);
      }
    }

    if (changed) state = AsyncData(updatedBots);
  }

  // --- PERSISTENCIA ---

  Future<void> addBot({
    required String name,
    required String description,
    required Color color,
    required String systemPrompt,
  }) async {
    final newBot = Bot(
      id: '', // ID temporal vacío
      name: name, 
      description: description, 
      systemPrompt: systemPrompt,
      status: BotStatus.active, 
      primaryColor: color,
      lastActive: DateTime.now(), 
      cycleStartDate: DateTime.now(), 
      currentBalance: 0.0,
      themeMode: 'dark', 
      showOfflineAlert: true,
    );

    try {
      print("🤖 INTENTANDO ENSAMBLAR UNIDAD: ${newBot.name}...");
      
      final botData = newBot.toMap();
      botData.remove('id'); 

      final response = await _supabase
          .from('bots')
          .insert(botData) 
          .select()
          .single();

      print("✅ UNIDAD CREADA EN DB: $response");

      if (state.value != null) {
        state = AsyncData([Bot.fromMap(response), ...state.value!]);
      }
    } catch (e) {
      print("🔥 ERROR CRÍTICO AL CREAR BOT: $e"); 
    }
  }

  // --- NUEVA FUNCIÓN: ACTUALIZAR NOMBRE ---
  Future<void> updateBotName(String id, String newName) async {
    if (state.value == null) return;

    // 1. Optimismo
    final updatedList = state.value!.map((b) {
      return b.id == id ? b.copyWith(name: newName) : b;
    }).toList();
    state = AsyncData(updatedList);

    // 2. Persistencia
    try {
      await _supabase.from('bots').update({'name': newName}).eq('id', id);
    } catch (e) {
      print("❌ Error actualizando nombre: $e");
      ref.invalidateSelf();
    }
  }

  Future<void> updateBotPrompt(String id, String newDescription) async {
    if (state.value == null) return;

    final updatedList = state.value!.map((b) {
      return b.id == id ? b.copyWith(description: newDescription) : b;
    }).toList();
    
    state = AsyncData(updatedList);

    try {
      await _supabase
          .from('bots')
          .update({'description': newDescription}) 
          .eq('id', id);
    } catch (e) {
      print("❌ Error actualizando prompt: $e");
      ref.invalidateSelf(); 
    }
  }

  // --- CORRECCIÓN DE CONTINUIDAD TEMPORAL (TIME REWIND) ---
  Future<void> toggleStatus(String id) async {
    if (state.value == null) return;
    
    final bot = state.value!.firstWhere((b) => b.id == id);
    final isTurningOff = bot.status == BotStatus.active;
    final newStatus = isTurningOff ? BotStatus.disabled : BotStatus.active;

    double newBalance = bot.currentBalance;
    DateTime newStartDate = bot.cycleStartDate;

    // Constantes para cálculo de precisión (mismas que en el modelo)
    const double totalSecondsInCycle = 30.0 * 24.0 * 60.0 * 60.0; // 2,592,000 segs
    const double cycleCost = 20.0;

    if (isTurningOff) {
      // ⏸️ APAGAR: Convertimos TIEMPO -> DINERO
      // Cristalizamos la deuda temporal y la guardamos segura en la DB.
      newBalance = bot.calculatedDebt;
      print("⏸️ PAUSANDO. PROGRESO GUARDADO COMO DEUDA: \$$newBalance");
      
    } else {
      // ▶️ ENCENDER: Convertimos DINERO -> TIEMPO
      // Calculamos cuánto tiempo "ya pasó" basándonos en la deuda guardada.
      // Regla de tres: (Deuda / $20) * 30 días = Tiempo a retroceder.
      
      final double secondsElapsedPreviously = (bot.currentBalance / cycleCost) * totalSecondsInCycle;
      final int secondsToGoBack = secondsElapsedPreviously.round();

      // "Rebobinamos" el reloj hacia el pasado esa cantidad de segundos.
      // Así, visualmente el bot parecerá que nunca dejó de contar esos días.
      newStartDate = DateTime.now().subtract(Duration(seconds: secondsToGoBack));

      // CRÍTICO: Ponemos el saldo en 0.0.
      // ¿Por qué? Porque la deuda ahora está "viva" en la fecha antigua.
      // Si dejáramos el saldo, el sistema cobraría: SaldoViejo + TiempoAntiguo = ¡Doble Cobro!
      newBalance = 0.0;
      
      print("▶️ REACTIVANDO. RELOJ AJUSTADO A: -${Duration(seconds: secondsToGoBack).inDays} DÍAS.");
    }

    // 1. Actualización Optimista Local
    final updatedBot = bot.copyWith(
      status: newStatus,
      currentBalance: newBalance,
      cycleStartDate: newStartDate,
    );

    final newList = state.value!.map((b) => b.id == id ? updatedBot : b).toList();
    state = AsyncData(newList);
    
    // 2. Persistencia en Supabase
    try {
      await _supabase.from('bots').update({
        'status': newStatus.name,
        'current_balance': newBalance,
        'cycle_start_date': newStartDate.toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print("❌ Error al cambiar estado: $e");
      ref.invalidateSelf();
    }
  }

  Future<void> updateThemeMode(String id, String mode) async {
    if (state.value == null) return;
    state = AsyncData(state.value!.map((b) => b.id == id ? b.copyWith(themeMode: mode) : b).toList());
    try {
      await _supabase.from('bots').update({'theme_mode': mode}).eq('id', id);
    } catch (_) {}
  }

  Future<void> updateOfflineAlert(String id, bool enabled) async {
    if (state.value == null) return;
    state = AsyncData(state.value!.map((b) => b.id == id ? b.copyWith(showOfflineAlert: enabled) : b).toList());
    try {
      await _supabase.from('bots').update({'show_offline_alert': enabled}).eq('id', id);
    } catch (_) {}
  }

  Future<void> removeBot(String id) async {
    if (state.value == null) return;

    final botToDelete = state.value!.firstWhere((b) => b.id == id, orElse: () => throw Exception("Bot no encontrado"));
    final double finalDebt = botToDelete.calculatedDebt;

    print("🛑 INICIANDO PROTOCOLO DE BORRADO PARA: ${botToDelete.name}");
    print("💰 DEUDA FINAL CALCULADA (PRECISIÓN ALTA): \$$finalDebt");

    try {
      if (finalDebt > 0.001) {
        await ref.read(billingProvider.notifier).registerCycleCharge(
          "${botToDelete.name} (LIQUIDACIÓN)", 
          finalDebt, 
          botId: id
        );
        print("✅ COBRO REGISTRADO EN SUPABASE");
      }

      await _supabase.from('bots').delete().eq('id', id);
      
      state = AsyncData(state.value!.where((b) => b.id != id).toList());
      
      ref.invalidate(billingProvider); 
      
    } catch (e) {
      print("🔥 ERROR CRÍTICO EN ELIMINACIÓN: $e");
      ref.invalidateSelf(); 
    }
  }

  Future<void> _closeBotCycle(Bot bot) async {
    try {
      await ref.read(billingProvider.notifier).registerCycleCharge(bot.name, 20.0, botId: bot.id);
      await _supabase.from('bots').update({
        'current_balance': 0.0,
        'cycle_start_date': DateTime.now().toIso8601String(),
      }).eq('id', bot.id);
    } catch (_) {
      print("⚠️ Ciclo cerrado localmente (Offline).");
    }
  }
}