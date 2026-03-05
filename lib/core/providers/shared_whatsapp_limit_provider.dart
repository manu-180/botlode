import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/core/providers/supabase_provider.dart';

/// Estado compartido de límites WhatsApp para Empresas sin dominio y Assistify.
/// Cooldown 60s por toque, máx 20 aperturas/hora. Una sola “cuenta” entre ambas pantallas.
class WhatsAppLimitState {
  final int count;
  final DateTime? windowEnd;
  final int messageIndex;
  final DateTime? lastOpenAt;
  final List<DateTime> openTimes;
  final int dailyOpens;
  final DateTime? dailyOpensDate;
  final int empresasTotalSent;
  final int empresasTotalFailed;
  final int assistifyTotalSent;
  final int assistifyTotalFailed;

  const WhatsAppLimitState({
    this.count = 0,
    this.windowEnd,
    this.messageIndex = 0,
    this.lastOpenAt,
    this.openTimes = const [],
    this.dailyOpens = 0,
    this.dailyOpensDate,
    this.empresasTotalSent = 0,
    this.empresasTotalFailed = 0,
    this.assistifyTotalSent = 0,
    this.assistifyTotalFailed = 0,
  });

  static const int windowMinutes = 60;
  static const int limit = 20; // compat con increment()
  static const int cooldownSeconds = 300; // 5 minutos entre mensajes
  static const int maxOpensPerHour = 20;
  static const int maxDailyOpens = 200;

  int remainingSeconds(DateTime now) {
    if (windowEnd == null) return 0;
    return windowEnd!.difference(now).inSeconds.clamp(0, windowMinutes * 60);
  }

  int opensInLastHour(DateTime now) {
    final cutoff = now.subtract(const Duration(hours: 1));
    return openTimes.where((t) => t.isAfter(cutoff)).length;
  }

  int cooldownRemainingSeconds(DateTime now) {
    if (lastOpenAt == null) return 0;
    final end = lastOpenAt!.add(const Duration(seconds: cooldownSeconds));
    if (now.isAfter(end)) return 0;
    return end.difference(now).inSeconds;
  }

  bool isDailyLimitReached(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (dailyOpensDate == null) return false;
    final stateDay = DateTime(dailyOpensDate!.year, dailyOpensDate!.month, dailyOpensDate!.day);
    if (today != stateDay) return false;
    return dailyOpens >= maxDailyOpens;
  }

  /// Devuelve true si la hora actual está dentro del horario laboral (8:00–19:00).
  static bool isWithinBusinessHours(DateTime now) {
    return now.hour >= 8 && now.hour < 19;
  }

  int get dailyCount => dailyOpens;
  DateTime? get dailyDate => dailyOpensDate;

  WhatsAppLimitState copyWith({
    int? count,
    DateTime? windowEnd,
    int? messageIndex,
    DateTime? lastOpenAt,
    List<DateTime>? openTimes,
    int? dailyOpens,
    DateTime? dailyOpensDate,
    int? empresasTotalSent,
    int? empresasTotalFailed,
    int? assistifyTotalSent,
    int? assistifyTotalFailed,
  }) {
    return WhatsAppLimitState(
      count: count ?? this.count,
      windowEnd: windowEnd ?? this.windowEnd,
      messageIndex: messageIndex ?? this.messageIndex,
      lastOpenAt: lastOpenAt ?? this.lastOpenAt,
      openTimes: openTimes ?? this.openTimes,
      dailyOpens: dailyOpens ?? this.dailyOpens,
      dailyOpensDate: dailyOpensDate ?? this.dailyOpensDate,
      empresasTotalSent: empresasTotalSent ?? this.empresasTotalSent,
      empresasTotalFailed: empresasTotalFailed ?? this.empresasTotalFailed,
      assistifyTotalSent: assistifyTotalSent ?? this.assistifyTotalSent,
      assistifyTotalFailed: assistifyTotalFailed ?? this.assistifyTotalFailed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'window_end': windowEnd?.toUtc().toIso8601String(),
      'message_index': messageIndex,
      'last_open_at': lastOpenAt?.toUtc().toIso8601String(),
      'open_times': openTimes.map((t) => t.toUtc().toIso8601String()).toList(),
      'daily_opens': dailyOpens,
      'daily_opens_date': dailyOpensDate != null
          ? '${dailyOpensDate!.year}-${dailyOpensDate!.month.toString().padLeft(2, '0')}-${dailyOpensDate!.day.toString().padLeft(2, '0')}'
          : null,
      'empresas_total_sent': empresasTotalSent,
      'empresas_total_failed': empresasTotalFailed,
      'assistify_total_sent': assistifyTotalSent,
      'assistify_total_failed': assistifyTotalFailed,
    };
  }

  static WhatsAppLimitState fromMap(Map<String, dynamic> map) {
    List<DateTime> openTimes = const [];
    final raw = map['open_times'];
    if (raw is List) {
      openTimes = raw
          .map((e) => DateTime.tryParse(e is String ? e : e.toString()))
          .whereType<DateTime>()
          .toList();
    }
    DateTime? parseIso(String? v) {
      if (v == null) return null;
      return DateTime.tryParse(v);
    }
    DateTime? parseDate(String? v) {
      if (v == null) return null;
      final d = DateTime.tryParse(v);
      return d != null ? DateTime(d.year, d.month, d.day) : null;
    }
    return WhatsAppLimitState(
      count: (map['count'] as int?) ?? 0,
      windowEnd: parseIso(map['window_end'] as String?),
      messageIndex: (map['message_index'] as int?) ?? 0,
      lastOpenAt: parseIso(map['last_open_at'] as String?),
      openTimes: openTimes,
      dailyOpens: (map['daily_opens'] as int?) ?? 0,
      dailyOpensDate: parseDate(map['daily_opens_date'] as String?),
      empresasTotalSent: (map['empresas_total_sent'] as int?) ?? 0,
      empresasTotalFailed: (map['empresas_total_failed'] as int?) ?? 0,
      assistifyTotalSent: (map['assistify_total_sent'] as int?) ?? 0,
      assistifyTotalFailed: (map['assistify_total_failed'] as int?) ?? 0,
    );
  }
}

class SharedWhatsAppLimitNotifier extends StateNotifier<WhatsAppLimitState> {
  SharedWhatsAppLimitNotifier(this._supabase, this._userId) : super(const WhatsAppLimitState()) {
    _load();
  }

  final SupabaseClient _supabase;
  final String? _userId;

  Future<void> _load() async {
    if (_userId == null) return;
    try {
      final res = await _supabase
          .from('empresas_whatsapp_limit')
          .select()
          .eq('user_id', _userId)
          .maybeSingle();
      if (res != null) {
        state = WhatsAppLimitState.fromMap(res);
        checkReset();
        await _save();
      }
    } catch (e) {
      debugPrint('⚠️ [Límites WhatsApp] Error al cargar: $e');
    }
  }

  Future<bool> _save() async {
    if (_userId == null) return false;
    try {
      final payload = state.toMap()
        ..['user_id'] = _userId
        ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('empresas_whatsapp_limit').upsert(
        payload,
        onConflict: 'user_id',
      );
      return true;
    } catch (e) {
      debugPrint('⚠️ [Límites WhatsApp] Error al guardar: $e');
      return false;
    }
  }

  void increment() {
    if (state.count >= WhatsAppLimitState.limit) return;
    final now = DateTime.now();
    final newCount = state.count + 1;
    final newWindowEnd = state.count == 0
        ? now.add(const Duration(minutes: WhatsAppLimitState.windowMinutes))
        : state.windowEnd;
    state = state.copyWith(count: newCount, windowEnd: newWindowEnd);
    _save();
  }

  void checkReset() {
    final now = DateTime.now();
    if (state.windowEnd != null && now.isAfter(state.windowEnd!)) {
      state = state.copyWith(count: 0, windowEnd: null);
    }
    final today = DateTime(now.year, now.month, now.day);
    if (state.dailyOpensDate != null) {
      final d = state.dailyOpensDate!;
      final stateDay = DateTime(d.year, d.month, d.day);
      if (today != stateDay) {
        state = state.copyWith(dailyOpens: 0, dailyOpensDate: DateTime(now.year, now.month, now.day));
      }
    }
    final cutoff = now.subtract(const Duration(hours: 1));
    final trimmed = state.openTimes.where((t) => t.isAfter(cutoff)).toList();
    if (trimmed.length != state.openTimes.length) {
      state = state.copyWith(openTimes: trimmed);
    }
  }

  void advanceMessageIndex() {
    state = state.copyWith(messageIndex: (state.messageIndex + 1) % 5);
    _save();
  }

  /// [feature] opcional: 'empresas' | 'assistify' para incrementar el total enviado de ese feature.
  void recordOpen({String? feature}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int daily = state.dailyOpens;
    DateTime? dailyDate = state.dailyOpensDate;
    if (dailyDate == null) {
      dailyDate = today;
      daily = 0;
    } else {
      final stateDay = DateTime(dailyDate.year, dailyDate.month, dailyDate.day);
      if (stateDay != today) {
        daily = 0;
        dailyDate = today;
      }
    }
    final trimmed = state.openTimes.where((t) => t.isAfter(now.subtract(const Duration(hours: 1)))).toList();
    trimmed.add(now);
    var next = state.copyWith(
      lastOpenAt: now,
      openTimes: trimmed,
      dailyOpens: daily + 1,
      dailyOpensDate: dailyDate,
    );
    if (feature == 'empresas') {
      next = next.copyWith(empresasTotalSent: next.empresasTotalSent + 1);
    } else if (feature == 'assistify') {
      next = next.copyWith(assistifyTotalSent: next.assistifyTotalSent + 1);
    }
    state = next;
    _save();
  }

  void recordFailed(String feature) {
    if (feature == 'empresas') {
      state = state.copyWith(empresasTotalFailed: state.empresasTotalFailed + 1);
    } else if (feature == 'assistify') {
      state = state.copyWith(assistifyTotalFailed: state.assistifyTotalFailed + 1);
    }
    _save();
  }

  String? cannotOpenReason(DateTime now) {
    if (!WhatsAppLimitState.isWithinBusinessHours(now)) {
      return 'Fuera de horario laboral. Envíos habilitados de 8:00 a 19:00 hs.';
    }
    final cooldown = state.cooldownRemainingSeconds(now);
    if (cooldown > 0) return 'Esperá ${cooldown ~/ 60} min antes de abrir otro.';
    if (state.opensInLastHour(now) >= WhatsAppLimitState.maxOpensPerHour) {
      return 'Límite de aperturas por hora (${WhatsAppLimitState.maxOpensPerHour}). Esperá.';
    }
    if (state.isDailyLimitReached(now)) {
      return 'Límite diario (${WhatsAppLimitState.maxDailyOpens}). Mañana se reinicia.';
    }
    return null;
  }

  bool canOpen(DateTime now) => cannotOpenReason(now) == null;
}

/// Provider compartido: Empresas sin dominio y Assistify usan el mismo límite (misma tabla).
final sharedWhatsAppLimitProvider =
    StateNotifierProvider<SharedWhatsAppLimitNotifier, WhatsAppLimitState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  return SharedWhatsAppLimitNotifier(supabase, userId);
});
