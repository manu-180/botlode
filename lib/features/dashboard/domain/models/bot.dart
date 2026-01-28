// Archivo: lib/features/dashboard/domain/models/bot.dart
import 'package:flutter/material.dart';

enum BotStatus { active, maintenance, disabled, creditSuspended }

// MODO TURBO ACTIVO (30 seg = 1 mes)
const bool IS_TURBO_MODE = true; 

class Bot {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String systemPrompt;
  final BotStatus status;
  final Color primaryColor;
  final DateTime lastActive;
  final double currentBalance; 
  final DateTime cycleStartDate;
  final String themeMode; 
  final bool showOfflineAlert;

  const Bot({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.systemPrompt,
    required this.status,
    required this.primaryColor,
    required this.lastActive,
    this.currentBalance = 0.0,
    required this.cycleStartDate,
    this.themeMode = 'dark',
    this.showOfflineAlert = true,
  });

  // --- LÓGICA DE NEGOCIO ---

  static const double _CYCLE_PRICE = 20.00;

  double get daysActivePrecise {
    if (status == BotStatus.disabled || status == BotStatus.creditSuspended) {
      final double fraction = currentBalance / _CYCLE_PRICE; 
      return fraction * 30.0;
    }

    final now = DateTime.now();
    final ms = now.difference(cycleStartDate).inMilliseconds;
    
    // Protección contra valores negativos (por sincronización de reloj)
    if (ms < 0) return 0.0;

    double days;
    if (IS_TURBO_MODE) {
      days = ms / 1000.0; // En modo turbo, segundos = días
    } else {
      days = ms / 86400000.0; // Días reales
    }
    
    // 🔧 FIX: Limitar a 30 días máximo (1 ciclo completo)
    // Evita mostrar "miles de días" por fechas antiguas
    return days.clamp(0.0, 30.0);
  }

  int get daysActive {
    return daysActivePrecise.floor();
  }

  double get cycleProgress {
    final days = daysActivePrecise; 
    if (days >= 30.0) return 1.0;
    if (days < 0) return 0.0;
    return days / 30.0;
  }

  double get calculatedDebt {
    if (status == BotStatus.disabled || status == BotStatus.creditSuspended) {
      return currentBalance; 
    }
    
    final now = DateTime.now();
    final elapsedSeconds = now.difference(cycleStartDate).inSeconds;
    
    // Protección: Si acabamos de crearlo, elapsedSeconds podría ser -1 por milisegundos de diferencia
    if (elapsedSeconds <= 0) return currentBalance;

    double totalCycleSeconds;
    if (IS_TURBO_MODE) {
      totalCycleSeconds = 30.0; 
    } else {
      totalCycleSeconds = 2592000.0; 
    }
    
    // 🔧 FIX: Limitar a UN ciclo máximo de deuda acumulada
    // Si elapsedSeconds es mayor que totalCycleSeconds, significa que ya pasó
    // un ciclo completo y debería haberse cobrado. Solo calculamos hasta 1 ciclo.
    final cappedSeconds = elapsedSeconds.clamp(0.0, totalCycleSeconds);
    final accumulated = (cappedSeconds / totalCycleSeconds) * _CYCLE_PRICE;
    
    return currentBalance + accumulated;
  }

  // --- MAPEO DE SUPABASE ---
  factory Bot.fromMap(Map<String, dynamic> map) {
    Color parseColor(String? hexString) {
      if (hexString == null || hexString.isEmpty) return const Color(0xFFFFC000); 
      try {
        final buffer = StringBuffer();
        if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
        buffer.write(hexString.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return const Color(0xFFFFC000);
      }
    }

    return Bot(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      systemPrompt: map['system_prompt'] ?? '',
      status: _parseStatus(map['status']),
      primaryColor: parseColor(map['tech_color']),
      lastActive: DateTime.parse(map['created_at']),
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      cycleStartDate: map['cycle_start_date'] != null 
          ? DateTime.parse(map['cycle_start_date']) 
          : DateTime.now(),
      themeMode: map['theme_mode'] ?? 'dark',
      showOfflineAlert: map['show_offline_alert'] ?? true,
    );
  }

  static BotStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'active': return BotStatus.active;
      case 'maintenance': return BotStatus.maintenance;
      case 'disabled': return BotStatus.disabled;
      case 'credit_suspended': return BotStatus.creditSuspended;
      default: return BotStatus.active;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.isEmpty ? null : id,
      'name': name,
      'description': description,
      'category': category,
      'system_prompt': systemPrompt,
      'status': status == BotStatus.creditSuspended ? 'credit_suspended' : status.name,
      'tech_color': '#${primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      'current_balance': currentBalance,
      'cycle_start_date': cycleStartDate.toIso8601String(),
      'theme_mode': themeMode,
      'show_offline_alert': showOfflineAlert,
    };
  }

  Bot copyWith({
    String? name, String? description, String? category, String? systemPrompt,
    BotStatus? status, Color? primaryColor, double? currentBalance,
    DateTime? cycleStartDate, DateTime? lastActive, String? themeMode, bool? showOfflineAlert,
  }) {
    return Bot(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      status: status ?? this.status,
      primaryColor: primaryColor ?? this.primaryColor,
      lastActive: lastActive ?? this.lastActive,
      currentBalance: currentBalance ?? this.currentBalance,
      cycleStartDate: cycleStartDate ?? this.cycleStartDate,
      themeMode: themeMode ?? this.themeMode,
      showOfflineAlert: showOfflineAlert ?? this.showOfflineAlert,
    );
  }
}