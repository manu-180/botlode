import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:botslode/core/providers/shared_whatsapp_limit_provider.dart';
import 'package:botslode/core/services/whatsapp_api_service.dart';

// ---------------------------------------------------------------------------
// Modelo de contacto en cola
// ---------------------------------------------------------------------------

class QueueContact {
  const QueueContact({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.whatsappFallbackUrl,
  });

  /// ID de la entidad en Supabase (empresa o lead).
  final String id;
  final String nombre;
  final String telefono;

  /// URL de fallback wa.me con el mensaje pre-escrito, para usar si la API falla.
  final String whatsappFallbackUrl;
}

// ---------------------------------------------------------------------------
// Estado de la cola
// ---------------------------------------------------------------------------

class WhatsAppQueueState {
  const WhatsAppQueueState({
    this.isRunning = false,
    this.total = 0,
    this.sent = 0,
    this.failed = 0,
    this.currentIndex = 0,
    this.processingName,
    this.statusMessage,
    this.waitingSeconds = 0,
  });

  final bool isRunning;

  /// Cantidad total de contactos en la cola cuando se inició.
  final int total;
  final int sent;
  final int failed;

  /// Posición actual dentro de la cola (0-based).
  final int currentIndex;

  /// Nombre del contacto que se está procesando ahora.
  final String? processingName;

  /// Mensaje de estado para mostrar al usuario.
  final String? statusMessage;

  /// Segundos restantes de espera antes del próximo envío.
  final int waitingSeconds;

  int get pending => (total - currentIndex).clamp(0, total);

  bool get isFinished => isRunning && currentIndex >= total;

  WhatsAppQueueState copyWith({
    bool? isRunning,
    int? total,
    int? sent,
    int? failed,
    int? currentIndex,
    String? processingName,
    bool clearProcessingName = false,
    String? statusMessage,
    bool clearStatusMessage = false,
    int? waitingSeconds,
  }) {
    return WhatsAppQueueState(
      isRunning: isRunning ?? this.isRunning,
      total: total ?? this.total,
      sent: sent ?? this.sent,
      failed: failed ?? this.failed,
      currentIndex: currentIndex ?? this.currentIndex,
      processingName: clearProcessingName ? null : (processingName ?? this.processingName),
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
      waitingSeconds: waitingSeconds ?? this.waitingSeconds,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class WhatsAppAutoQueueNotifier extends StateNotifier<WhatsAppQueueState> {
  WhatsAppAutoQueueNotifier(this._ref, this._feature) : super(const WhatsAppQueueState());

  final Ref _ref;

  /// 'empresas' | 'assistify'
  final String _feature;

  List<QueueContact> _queue = [];
  Timer? _processTimer;
  Timer? _countdownTimer;

  /// Patrón de espera entre envíos (segundos): 5 min, 6 min, 4 min, 5 min...
  static const List<int> _cooldownPattern = [300, 360, 240];

  int _nextCooldownSeconds() {
    final idx = state.currentIndex % _cooldownPattern.length;
    return _cooldownPattern[idx];
  }

  /// Callback que la vista inyecta para marcar un contacto como enviado.
  void Function(String id)? onMarkContacted;

  /// Inicia la cola con los contactos pendientes.
  ///
  /// Si ya está corriendo, detiene la cola anterior y empieza de nuevo.
  void start(List<QueueContact> contacts, {void Function(String id)? markContacted}) {
    _stopTimers();
    onMarkContacted = markContacted;
    _queue = List.from(contacts);
    state = WhatsAppQueueState(
      isRunning: true,
      total: contacts.length,
      statusMessage: contacts.isEmpty ? 'Sin contactos pendientes' : null,
    );
    if (contacts.isEmpty) return;
    _processNext();
  }

  void pause() {
    _stopTimers();
    state = state.copyWith(
      isRunning: false,
      statusMessage: 'Pausado',
      clearProcessingName: true,
      waitingSeconds: 0,
    );
  }

  void resume() {
    if (_queue.isEmpty || state.currentIndex >= _queue.length) return;
    state = state.copyWith(isRunning: true, statusMessage: 'Reanudando...');
    _processNext();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  void _stopTimers() {
    _processTimer?.cancel();
    _countdownTimer?.cancel();
    _processTimer = null;
    _countdownTimer = null;
  }

  Future<void> _processNext() async {
    if (!state.isRunning) return;
    if (state.currentIndex >= _queue.length) {
      _stopTimers();
      state = state.copyWith(
        isRunning: false,
        statusMessage: 'Cola completada. ${state.sent} enviados, ${state.failed} fallidos.',
        clearProcessingName: true,
        waitingSeconds: 0,
      );
      return;
    }

    final now = DateTime.now();
    final limitNotifier = _ref.read(sharedWhatsAppLimitProvider.notifier);
    limitNotifier.checkReset();
    final reason = limitNotifier.cannotOpenReason(now);

    if (reason != null) {
      // Fuera de horario o límite alcanzado: esperar y reintentar en 5 min (a las 8:00 se habilita solo).
      _stopTimers();
      state = state.copyWith(
        statusMessage: reason,
        clearProcessingName: true,
        waitingSeconds: 300,
      );
      _startCountdown(300, onDone: _processNext);
      return;
    }

    final contact = _queue[state.currentIndex];
    state = state.copyWith(
      processingName: contact.nombre,
      statusMessage: 'Enviando...',
      waitingSeconds: 0,
    );

    // Obtener Content SID para este índice de rotación.
    final limitState = _ref.read(sharedWhatsAppLimitProvider);
    final wppService = _ref.read(whatsAppApiServiceProvider);
    final sid = await wppService.getContentSid(_feature, limitState.messageIndex);

    final result = await wppService.sendToContact(
      telefono: contact.telefono,
      nombre: contact.nombre,
      contentSid: sid ?? '',
      feature: _feature,
    );

    if (result == WhatsAppSendResult.sent) {
      limitNotifier.recordOpen(feature: _feature);
      limitNotifier.advanceMessageIndex();
      onMarkContacted?.call(contact.id);
      final secs = _nextCooldownSeconds();
      state = state.copyWith(
        sent: state.sent + 1,
        currentIndex: state.currentIndex + 1,
        statusMessage: 'Enviado a ${contact.nombre}. Próximo en ${secs ~/ 60} min...',
        clearProcessingName: true,
        waitingSeconds: secs,
      );
      _startCountdown(secs, onDone: _processNext);
    } else if (result == WhatsAppSendResult.disabled) {
      _stopTimers();
      state = state.copyWith(
        isRunning: false,
        statusMessage: 'Envío deshabilitado (kill switch activo).',
        clearProcessingName: true,
      );
    } else {
      // noSid o error: usar fallback con launchUrl y continuar con el siguiente.
      debugPrint('[AutoQueue] Fallback launchUrl para ${contact.nombre}');
      final uri = Uri.tryParse(contact.whatsappFallbackUrl);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          limitNotifier.recordOpen(feature: _feature);
          limitNotifier.advanceMessageIndex();
          onMarkContacted?.call(contact.id);
          final secs = _nextCooldownSeconds();
          state = state.copyWith(
            sent: state.sent + 1,
            currentIndex: state.currentIndex + 1,
            statusMessage: 'Fallback WhatsApp Web: ${contact.nombre}. Próximo en ${secs ~/ 60} min...',
            clearProcessingName: true,
            waitingSeconds: secs,
          );
          _startCountdown(secs, onDone: _processNext);
        } catch (_) {
          limitNotifier.recordFailed(_feature);
          final secs = _nextCooldownSeconds();
          state = state.copyWith(
            failed: state.failed + 1,
            currentIndex: state.currentIndex + 1,
            statusMessage: 'Error enviando a ${contact.nombre}. Próximo en ${secs ~/ 60} min...',
            clearProcessingName: true,
            waitingSeconds: secs,
          );
          _startCountdown(secs, onDone: _processNext);
        }
      } else {
        limitNotifier.recordFailed(_feature);
        state = state.copyWith(
          failed: state.failed + 1,
          currentIndex: state.currentIndex + 1,
          statusMessage: 'Sin teléfono válido para ${contact.nombre}. Siguiente...',
          clearProcessingName: true,
          waitingSeconds: 0,
        );
        _processTimer = Timer(const Duration(seconds: 2), _processNext);
      }
    }
  }

  void _startCountdown(int seconds, {required Future<void> Function() onDone}) {
    var remaining = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!state.isRunning) {
        t.cancel();
        return;
      }
      remaining--;
      state = state.copyWith(waitingSeconds: remaining.clamp(0, seconds));
      if (remaining <= 0) {
        t.cancel();
        onDone();
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Providers (uno por feature, así la cola de Empresas y Assistify son independientes)
// ---------------------------------------------------------------------------

final empresasAutoQueueProvider =
    StateNotifierProvider<WhatsAppAutoQueueNotifier, WhatsAppQueueState>(
  (ref) => WhatsAppAutoQueueNotifier(ref, 'empresas'),
);

final assistifyAutoQueueProvider =
    StateNotifierProvider<WhatsAppAutoQueueNotifier, WhatsAppQueueState>(
  (ref) => WhatsAppAutoQueueNotifier(ref, 'assistify'),
);
