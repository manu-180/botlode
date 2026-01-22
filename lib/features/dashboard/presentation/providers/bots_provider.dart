// Archivo: lib/features/dashboard/presentation/providers/bots_provider.dart
import 'dart:async';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

part 'bots_provider.g.dart';

// MODO TURBO: true = 1 segundo son 1 día (para pruebas rápidas)
// false = tiempo real (1 mes son 30 días reales)
const bool IS_TURBO_MODE = false; 

@riverpod
class Bots extends _$Bots {
  final _supabase = Supabase.instance.client;
  Timer? _timer;

  // CONSTANTES DE FACTURACIÓN
  static const double CYCLE_PRICE = 1.0; // $1.00 USD
  static const int CYCLE_SECONDS = 30 * 24 * 60 * 60; // 30 Días en segundos

  @override
  FutureOr<List<Bot>> build() async {
    try {
      final response = await _supabase
          .from('bots')
          .select()
          .order('created_at', ascending: false);
      
      final bots = (response as List).map((m) => Bot.fromMap(m)).toList();
      
      // Sincronización inicial
      var currentBots = await _syncOfflineCharges(bots);
      
      _startTimer();
      ref.onDispose(() => _timer?.cancel());
      
      return currentBots;
    } catch (e) {
      print("⚠️ Error cargando bots: $e");
      return [];
    }
  }

  // --- LOGICA DE COBRO AUTOMÁTICO (CICLO) ---
  void _startTimer() {
    // Si es Turbo, chequeamos cada 1s. Si es normal, cada 1 minuto.
    final duration = IS_TURBO_MODE ? const Duration(seconds: 1) : const Duration(minutes: 1);
    
    _timer = Timer.periodic(duration, (timer) async {
      if (state.value == null) return;
      
      final List<Bot> currentList = state.value!;
      final List<Bot> updatedList = [];
      bool anyChange = false;

      for (var bot in currentList) {
        if (bot.status == BotStatus.active) {
          // Calculamos tiempo transcurrido
          final now = DateTime.now();
          final diff = now.difference(bot.cycleStartDate);
          
          // Factor de velocidad (Turbo o Real)
          final effectiveDuration = IS_TURBO_MODE 
              ? diff * (CYCLE_SECONDS / 30) // Acelera el tiempo
              : diff;

          // Si pasó el ciclo (30 días)
          if (effectiveDuration.inSeconds >= CYCLE_SECONDS) {
             print("💰 COBRANDO CICLO PARA: ${bot.name}");
             
             // 1. Ejecutar cobro
             await _chargeCycle(bot);
             
             // 2. Resetear bot
             updatedList.add(bot.copyWith(
               currentBalance: 0.0,
               cycleStartDate: DateTime.now(), // Nuevo ciclo empieza YA
             ));
             anyChange = true;
          } else {
             // Solo actualizamos visualmente si es necesario (ej. barra de progreso)
             updatedList.add(bot); 
          }
        } else {
          updatedList.add(bot);
        }
      }

      if (anyChange) {
        state = AsyncData(updatedList);
      } else {
        // Forzamos rebuild para que la UI actualice la deuda en tiempo real
        // aunque no haya cobros, para que se vean los centavos subir
        ref.notifyListeners(); 
      }
    });
  }

  Future<void> _chargeCycle(Bot bot) async {
    try {
      // Llamada al Billing Provider para registrar la transacción
      await ref.read(billingProvider.notifier).registerCycleCharge(
        bot.name, 
        CYCLE_PRICE, 
        botId: bot.id
      );
      
      // Actualizamos DB
      await _supabase.from('bots').update({
        'current_balance': 0.0,
        'cycle_start_date': DateTime.now().toIso8601String(),
      }).eq('id', bot.id);
      
    } catch (e) {
      print("🔥 Error cobrando ciclo: $e");
    }
  }

  // --- LÓGICA DE PAUSA / REANUDAR (FIX "VUELVE A EMPEZAR") ---
  Future<void> toggleStatus(String id) async {
    if (state.value == null) return;
    
    final bot = state.value!.firstWhere((b) => b.id == id);
    final isTurningOff = bot.status == BotStatus.active;
    final newStatus = isTurningOff ? BotStatus.disabled : BotStatus.active;

    double newBalance = bot.currentBalance;
    DateTime newStartDate = bot.cycleStartDate;

    if (isTurningOff) {
      // ⏸️ APAGAR: 
      // Calculamos la deuda exacta hasta este milisegundo y la guardamos.
      // La fecha de inicio ya no importa porque congelamos la deuda.
      final double currentDebt = bot.calculatedDebt; 
      newBalance = currentDebt; 
      
      print("⏸️ PAUSANDO ${bot.name}. Deuda congelada en: \$$newBalance");
      
    } else {
      // ▶️ ENCENDER (Time Rewind Logic): 
      // Si el bot tiene deuda (ej: $0.50), significa que ya consumió medio mes.
      // Debemos establecer la fecha de inicio EN EL PASADO para reflejar eso.
      
      // Regla de 3 simple: $1.00 = CYCLE_SECONDS. 
      // $0.50 = X segundos.
      final double secondsToRewind = (bot.currentBalance / CYCLE_PRICE) * CYCLE_SECONDS;
      
      // Ajustamos el reloj hacia atrás
      newStartDate = DateTime.now().subtract(Duration(seconds: secondsToRewind.round()));
      
      // Visualmente la deuda empieza a contar desde 0 sumando el tiempo transcurrido
      // O podemos mantener el balance en 0 y dejar que el getter calculatedDebt haga el trabajo.
      // Para consistencia con el modelo:
      newBalance = bot.currentBalance; // Mantenemos el valor base para el cálculo
      
      print("▶️ REANUDANDO ${bot.name}. Reloj ajustado a: $newStartDate (Back in time)");
    }

    // Actualizamos Estado Local Optimista
    final updatedBot = bot.copyWith(
      status: newStatus,
      currentBalance: newBalance,
      cycleStartDate: newStartDate,
    );

    final newList = state.value!.map((b) => b.id == id ? updatedBot : b).toList();
    state = AsyncData(newList);
    
    // Persistimos en DB
    try {
      await _supabase.from('bots').update({
        'status': newStatus.name,
        'current_balance': newBalance,
        'cycle_start_date': newStartDate.toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print("❌ Error guardando estado: $e");
      ref.invalidateSelf(); // Revertimos si falla
    }
  }

  // --- SINCRONIZACIÓN OFFLINE (Al abrir la app) ---
  Future<List<Bot>> _syncOfflineCharges(List<Bot> bots) async {
    final List<Bot> updatedList = [];
    
    for (var bot in bots) {
      if (bot.status == BotStatus.active) {
        // Si estuvo activo mientras la app estaba cerrada
        if (bot.daysActive >= 30) {
          // Se cumplió el ciclo offline
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

  // --- CRUD BÁSICO ---
  Future<void> addBot({required String name, required String description, required Color color, required String systemPrompt}) async {
    // ... (Tu código de agregar bot, no cambia) ...
    // Copiar del anterior si lo necesitas, pero es estándar insert
     try {
      final newBot = Bot(
        id: '', name: name, description: description, systemPrompt: systemPrompt,
        status: BotStatus.active, primaryColor: color, lastActive: DateTime.now(),
        cycleStartDate: DateTime.now(), currentBalance: 0.0, themeMode: 'dark', showOfflineAlert: true,
      );
      final botData = newBot.toMap(); botData.remove('id');
      final res = await _supabase.from('bots').insert(botData).select().single();
      if (state.value != null) state = AsyncData([Bot.fromMap(res), ...state.value!]);
    } catch (e) { print("Error Add: $e"); }
  }

  Future<void> removeBot(String id) async {
    if (state.value == null) return;
    final bot = state.value!.firstWhere((b) => b.id == id);
    
    // Liquidación final al borrar
    if (bot.calculatedDebt > 0.01) {
       await ref.read(billingProvider.notifier).registerCycleCharge(
        "${bot.name} (LIQUIDACIÓN FINAL)", 
        bot.calculatedDebt, 
        botId: id
      );
    }

    try {
      await _supabase.from('bots').delete().eq('id', id);
      state = AsyncData(state.value!.where((b) => b.id != id).toList());
      ref.invalidate(billingProvider); // Actualizar deuda global
    } catch (_) {}
  }
  
  // Actualizadores simples
  Future<void> updateBotName(String id, String n) async { /* ... */ }
  Future<void> updateBotPrompt(String id, String d) async { /* ... */ }
  Future<void> updateThemeMode(String id, String m) async { /* ... */ }
  Future<void> updateOfflineAlert(String id, bool e) async { /* ... */ }
}