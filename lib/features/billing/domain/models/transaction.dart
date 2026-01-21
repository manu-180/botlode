// Archivo: lib/features/billing/domain/models/transaction.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum TransactionType { charge, liquidation, payment }

class BotTransaction {
  final String id;
  final String? botId;
  final String description; 
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String status;

  const BotTransaction({
    required this.id,
    this.botId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
  });

  // --- MAPEO ROBUSTO PARA SUPABASE ---
  factory BotTransaction.fromMap(Map<String, dynamic> map) {
    // FIX: Parseo insensible a mayúsculas y espacios para evitar errores silenciosos
    TransactionType parseType(String? typeStr) {
      final t = typeStr?.trim().toLowerCase() ?? '';
      if (t == 'cycle_charge') return TransactionType.charge;
      if (t == 'liquidation') return TransactionType.liquidation;
      // Cualquier otra cosa (ej: 'payment', 'abono') se asume como pago por seguridad
      return TransactionType.payment;
    }

    return BotTransaction(
      id: map['id']?.toString() ?? '',
      botId: map['bot_id'],
      description: map['bot_name'] ?? map['description'] ?? 'Transacción del Sistema',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      type: parseType(map['type']),
      status: map['status'] ?? 'COMPLETED',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bot_id': botId,
      'bot_name': description, 
      'amount': amount,
      'type': type.name, 
      'status': status,
    };
  }

  // --- UI HELPERS ---
  Color get color => switch (type) {
    TransactionType.liquidation => AppColors.primary, 
    TransactionType.charge => AppColors.error, 
    TransactionType.payment => AppColors.success, // Fallback verde
  };
  
  IconData get icon => switch (type) {
    TransactionType.liquidation => Icons.check_circle_outline_rounded,
    TransactionType.charge => Icons.bolt_rounded,
    TransactionType.payment => Icons.payment,
  };
}