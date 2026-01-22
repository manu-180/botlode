// Archivo: lib/features/billing/domain/models/transaction.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum TransactionType { 
  cycleCharge, // Cobro de ciclo ($20)
  liquidation,  // Pago del usuario
  refund,
  unknown 
}

class BotTransaction {
  final String id;
  final String? botId;
  final String botName; // Antes 'description'
  final double amount;
  final DateTime createdAt; // Antes 'date'
  final TransactionType type;
  final String status;
  final String? externalPaymentId; 

  const BotTransaction({
    required this.id,
    this.botId,
    required this.botName,
    required this.amount,
    required this.createdAt,
    required this.type,
    required this.status,
    this.externalPaymentId,
  });

  factory BotTransaction.fromMap(Map<String, dynamic> map) {
    TransactionType parseType(String? typeStr) {
      return switch (typeStr?.trim().toLowerCase()) {
        'cycle_charge' => TransactionType.cycleCharge,
        'liquidation'  => TransactionType.liquidation,
        'refund'       => TransactionType.refund,
        _              => TransactionType.unknown,
      };
    }

    return BotTransaction(
      id: map['id']?.toString() ?? '',
      botId: map['bot_id'],
      botName: map['bot_name'] ?? 'SISTEMA CORE',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      type: parseType(map['type']),
      status: map['status'] ?? 'COMPLETED',
      externalPaymentId: map['external_payment_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bot_id': botId,
      'bot_name': botName,
      'amount': amount,
      'type': switch(type) {
        TransactionType.cycleCharge => 'cycle_charge',
        TransactionType.liquidation => 'liquidation',
        TransactionType.refund      => 'refund',
        TransactionType.unknown     => 'unknown',
      },
      'status': status,
      'external_payment_id': externalPaymentId,
    };
  }

  // --- SCI-FI UI HELPERS ---
  Color get color => switch (type) {
    TransactionType.liquidation => AppColors.primary, 
    TransactionType.cycleCharge => AppColors.error, 
    _ => AppColors.textSecondary,
  };
  
  IconData get icon => switch (type) {
    TransactionType.liquidation => Icons.check_circle_outline_rounded,
    TransactionType.cycleCharge => Icons.bolt_rounded,
    TransactionType.refund      => Icons.history_rounded,
    _ => Icons.help_outline_rounded,
  };
}