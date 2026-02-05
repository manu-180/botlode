// Archivo: lib/features/hunter_bot/domain/models/lead.dart
import 'package:flutter/material.dart';
import 'package:botslode/core/config/theme/app_colors.dart';

/// Estados posibles de un lead en el pipeline
enum LeadStatus {
  pending,
  scraping,
  scraped,
  queuedForSend,
  sending,
  sent,
  failed;

  /// Convierte el string de la base de datos al enum
  static LeadStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return LeadStatus.pending;
      case 'scraping':
        return LeadStatus.scraping;
      case 'scraped':
        return LeadStatus.scraped;
      case 'queued_for_send':
        return LeadStatus.queuedForSend;
      case 'sending':
        return LeadStatus.sending;
      case 'sent':
        return LeadStatus.sent;
      case 'failed':
        return LeadStatus.failed;
      default:
        return LeadStatus.pending;
    }
  }

  /// Convierte el enum a string para la base de datos
  String toDbString() {
    switch (this) {
      case LeadStatus.pending:
        return 'pending';
      case LeadStatus.scraping:
        return 'scraping';
      case LeadStatus.scraped:
        return 'scraped';
      case LeadStatus.queuedForSend:
        return 'queued_for_send';
      case LeadStatus.sending:
        return 'sending';
      case LeadStatus.sent:
        return 'sent';
      case LeadStatus.failed:
        return 'failed';
    }
  }

  /// Nombre para mostrar en la UI
  String get displayName {
    switch (this) {
      case LeadStatus.pending:
        return 'PENDIENTE';
      case LeadStatus.scraping:
        return 'ESCANEANDO';
      case LeadStatus.scraped:
        return 'ESCANEADO';
      case LeadStatus.queuedForSend:
        return 'EN COLA';
      case LeadStatus.sending:
        return 'ENVIANDO';
      case LeadStatus.sent:
        return 'ENVIADO';
      case LeadStatus.failed:
        return 'FALLIDO';
    }
  }

  /// Color asociado al estado
  Color get color {
    switch (this) {
      case LeadStatus.pending:
        return AppColors.textSecondary;
      case LeadStatus.scraping:
        return AppColors.secondary;
      case LeadStatus.scraped:
        return AppColors.primary;
      case LeadStatus.queuedForSend:
        return AppColors.warning;
      case LeadStatus.sending:
        return AppColors.secondary;
      case LeadStatus.sent:
        return AppColors.success;
      case LeadStatus.failed:
        return AppColors.error;
    }
  }

  /// Icono asociado al estado
  IconData get icon {
    switch (this) {
      case LeadStatus.pending:
        return Icons.schedule;
      case LeadStatus.scraping:
        return Icons.search;
      case LeadStatus.scraped:
        return Icons.check_circle_outline;
      case LeadStatus.queuedForSend:
        return Icons.queue;
      case LeadStatus.sending:
        return Icons.send;
      case LeadStatus.sent:
        return Icons.done_all;
      case LeadStatus.failed:
        return Icons.error_outline;
    }
  }
}

/// Modelo de un Lead (prospecto encontrado)
class Lead {
  final String id;
  final String userId;
  final String domain;
  final String? email;
  final String? metaTitle;
  final LeadStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scrapedAt;
  final DateTime? sentAt;

  const Lead({
    required this.id,
    required this.userId,
    required this.domain,
    this.email,
    this.metaTitle,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.scrapedAt,
    this.sentAt,
  });

  /// Crea un Lead desde un Map de Supabase
  factory Lead.fromMap(Map<String, dynamic> map) {
    return Lead(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      domain: map['domain']?.toString() ?? '',
      email: map['email']?.toString(),
      metaTitle: map['meta_title']?.toString(),
      status: LeadStatus.fromString(map['status']?.toString()),
      errorMessage: map['error_message']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      scrapedAt: map['scraped_at'] != null 
          ? DateTime.tryParse(map['scraped_at'].toString()) 
          : null,
      sentAt: map['sent_at'] != null 
          ? DateTime.tryParse(map['sent_at'].toString()) 
          : null,
    );
  }

  /// Convierte el Lead a Map para Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'domain': domain,
      'email': email,
      'meta_title': metaTitle,
      'status': status.toDbString(),
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'scraped_at': scrapedAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
    };
  }

  /// Copia con modificaciones
  Lead copyWith({
    String? id,
    String? userId,
    String? domain,
    String? email,
    String? metaTitle,
    LeadStatus? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scrapedAt,
    DateTime? sentAt,
  }) {
    return Lead(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      domain: domain ?? this.domain,
      email: email ?? this.email,
      metaTitle: metaTitle ?? this.metaTitle,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scrapedAt: scrapedAt ?? this.scrapedAt,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  @override
  String toString() => 'Lead(domain: $domain, status: ${status.displayName}, email: $email)';
}
