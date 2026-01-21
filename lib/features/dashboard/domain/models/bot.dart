// Archivo: lib/features/dashboard/domain/models/bot.dart
import 'package:flutter/material.dart';

enum BotStatus { active, maintenance, disabled }

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
  // --- NUEVOS CAMPOS CONFIGURABLES ---
  final String themeMode; // 'dark' o 'light'
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

  // Días visuales (Enteros para la UI "12 de 30 días")
  int get daysActive {
    final now = DateTime.now();
    final difference = now.difference(cycleStartDate).inDays;
    return difference < 0 ? 0 : difference;
  }

  // Progreso visual (0.0 a 1.0)
  double get cycleProgress {
    final days = daysActive;
    if (days >= 30) return 1.0;
    return days / 30.0;
  }

 // --- CÁLCULO DE DEUDA DE ALTA PRECISIÓN (CORREGIDO) ---
  // Tarifa: $20.00 por ciclo de 30 días.
  double get calculatedDebt {
    // Si está desactivado, mostramos solo lo que ya debía
    if (status != BotStatus.active) return currentBalance;

    final now = DateTime.now();
    // CAMBIO CRÍTICO: Usamos 'inSeconds' en lugar de 'inMinutes' para detectar deuda inmediata
    final differenceInSeconds = now.difference(cycleStartDate).inSeconds;
    
    if (differenceInSeconds <= 0) return currentBalance;

    // 30 días * 24 horas * 60 minutos * 60 segundos = 2,592,000 segundos
    const double totalSecondsInCycle = 30.0 * 24.0 * 60.0 * 60.0; 
    const double cycleCost = 20.0;

    // Regla de tres con precisión de segundos
    final double accumulated = (differenceInSeconds / totalSecondsInCycle) * cycleCost;

    final double total = currentBalance + accumulated;

    // Topeamos en 20.0
    return total > 20.0 ? 20.0 : total;
  }

  // --- MAPEO DE SUPABASE ---

  factory Bot.fromMap(Map<String, dynamic> map) {
    return Bot(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      systemPrompt: map['system_prompt'] ?? '',
      status: BotStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'active'),
        orElse: () => BotStatus.active,
      ),
      primaryColor: Color(int.parse(map['tech_color'].replaceFirst('#', '0xFF'))),
      lastActive: DateTime.parse(map['created_at']),
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      cycleStartDate: map['cycle_start_date'] != null 
          ? DateTime.parse(map['cycle_start_date']) 
          : DateTime.now(),
      themeMode: map['theme_mode'] ?? 'dark',
      showOfflineAlert: map['show_offline_alert'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.isEmpty ? null : id,
      'name': name,
      'description': description,
      'category': category,
      'system_prompt': systemPrompt,
      'status': status.name,
      'tech_color': '#${primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
      'current_balance': currentBalance,
      'cycle_start_date': cycleStartDate.toIso8601String(),
      'theme_mode': themeMode,
      'show_offline_alert': showOfflineAlert,
    };
  }

  Bot copyWith({
    String? name,
    String? description,
    String? category,
    String? systemPrompt,
    BotStatus? status,
    Color? primaryColor,
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? lastActive,
    String? themeMode,
    bool? showOfflineAlert,
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