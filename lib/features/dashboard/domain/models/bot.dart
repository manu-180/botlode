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
 // ... propiedades ...

  double get calculatedDebt {
    if (status == BotStatus.disabled) {
      return currentBalance; // Si está pausado, la deuda es la congelada
    }
    
    // Si está activo, calculamos tiempo real
    final now = DateTime.now();
    final elapsedSeconds = now.difference(cycleStartDate).inSeconds;
    
    // $1.00 cada 30 días (2,592,000 segundos)
    const totalSeconds = 2592000;
    const price = 1.0;
    
    final accumulated = (elapsedSeconds / totalSeconds) * price;
    
    // Retornamos deuda base (si venía de antes) + acumulada actual
    // Nota: En la lógica nueva de Time Rewind, currentBalance suele ser 0 al activarse
    // porque todo se traslada a cycleStartDate, pero por seguridad sumamos.
    return currentBalance + accumulated;
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