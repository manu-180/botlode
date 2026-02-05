// Archivo: lib/features/hunter_bot/domain/models/hunter_log.dart
import 'package:flutter/material.dart';
import 'package:botslode/core/config/theme/app_colors.dart';

/// Nivel de severidad del log
enum LogLevel {
  info,
  success,
  warning,
  error;

  static LogLevel fromString(String? value) {
    switch (value) {
      case 'info':
        return LogLevel.info;
      case 'success':
        return LogLevel.success;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  String toDbString() => name;

  Color get color {
    switch (this) {
      case LogLevel.info:
        return AppColors.secondary;
      case LogLevel.success:
        return AppColors.success;
      case LogLevel.warning:
        return AppColors.warning;
      case LogLevel.error:
        return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.success:
        return Icons.check_circle;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error;
    }
  }

  String get prefix {
    switch (this) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.success:
        return 'OK';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERR';
    }
  }
}

/// Tipo de acción que generó el log
enum LogAction {
  scrapeStart,
  scrapeEnd,
  emailFound,
  emailNotFound,
  sendStart,
  sendSuccess,
  sendFailed,
  configMissing,
  domainAdded,
  systemInfo;

  static LogAction fromString(String? value) {
    switch (value) {
      case 'scrape_start':
        return LogAction.scrapeStart;
      case 'scrape_end':
        return LogAction.scrapeEnd;
      case 'email_found':
        return LogAction.emailFound;
      case 'email_not_found':
        return LogAction.emailNotFound;
      case 'send_start':
        return LogAction.sendStart;
      case 'send_success':
        return LogAction.sendSuccess;
      case 'send_failed':
        return LogAction.sendFailed;
      case 'config_missing':
        return LogAction.configMissing;
      case 'domain_added':
        return LogAction.domainAdded;
      case 'system_info':
        return LogAction.systemInfo;
      default:
        return LogAction.systemInfo;
    }
  }

  String toDbString() {
    switch (this) {
      case LogAction.scrapeStart:
        return 'scrape_start';
      case LogAction.scrapeEnd:
        return 'scrape_end';
      case LogAction.emailFound:
        return 'email_found';
      case LogAction.emailNotFound:
        return 'email_not_found';
      case LogAction.sendStart:
        return 'send_start';
      case LogAction.sendSuccess:
        return 'send_success';
      case LogAction.sendFailed:
        return 'send_failed';
      case LogAction.configMissing:
        return 'config_missing';
      case LogAction.domainAdded:
        return 'domain_added';
      case LogAction.systemInfo:
        return 'system_info';
    }
  }

  IconData get icon {
    switch (this) {
      case LogAction.scrapeStart:
        return Icons.search;
      case LogAction.scrapeEnd:
        return Icons.search_off;
      case LogAction.emailFound:
        return Icons.email;
      case LogAction.emailNotFound:
        return Icons.email_outlined;
      case LogAction.sendStart:
        return Icons.send;
      case LogAction.sendSuccess:
        return Icons.done_all;
      case LogAction.sendFailed:
        return Icons.cancel_schedule_send;
      case LogAction.configMissing:
        return Icons.settings;
      case LogAction.domainAdded:
        return Icons.add_circle;
      case LogAction.systemInfo:
        return Icons.computer;
    }
  }
}

/// Modelo de un log del HunterBot
class HunterLog {
  final String id;
  final String userId;
  final String? leadId;
  final String domain;
  final LogLevel level;
  final LogAction action;
  final String message;
  final DateTime createdAt;

  const HunterLog({
    required this.id,
    required this.userId,
    this.leadId,
    required this.domain,
    required this.level,
    required this.action,
    required this.message,
    required this.createdAt,
  });

  /// Crea un HunterLog desde un Map de Supabase
  factory HunterLog.fromMap(Map<String, dynamic> map) {
    return HunterLog(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      leadId: map['lead_id']?.toString(),
      domain: map['domain']?.toString() ?? '',
      level: LogLevel.fromString(map['level']?.toString()),
      action: LogAction.fromString(map['action']?.toString()),
      message: map['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convierte el HunterLog a Map para Supabase
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'lead_id': leadId,
      'domain': domain,
      'level': level.toDbString(),
      'action': action.toDbString(),
      'message': message,
    };
  }

  /// Crea un log local (para mostrar antes de que llegue de Supabase)
  factory HunterLog.local({
    required String userId,
    required String domain,
    required LogLevel level,
    required LogAction action,
    required String message,
    String? leadId,
  }) {
    return HunterLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      leadId: leadId,
      domain: domain,
      level: level,
      action: action,
      message: message,
      createdAt: DateTime.now(),
    );
  }

  /// Timestamp formateado para la UI
  String get formattedTime {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    final s = createdAt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  String toString() => 'HunterLog([$formattedTime] [${level.prefix}] $message)';
}
