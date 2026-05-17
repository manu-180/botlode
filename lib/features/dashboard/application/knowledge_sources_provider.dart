// Archivo: lib/features/dashboard/application/knowledge_sources_provider.dart
import 'dart:io';
import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class KnowledgeSource {
  final String id;
  final String? botId;
  final String tenantId;
  final String type;
  final String? sourceUri;
  final String? title;
  final String status;
  final String? lastError;
  final Map<String, dynamic> metadata;
  final DateTime? deletedAt;
  final DateTime createdAt;

  const KnowledgeSource({
    required this.id,
    this.botId,
    required this.tenantId,
    required this.type,
    this.sourceUri,
    this.title,
    required this.status,
    this.lastError,
    required this.metadata,
    this.deletedAt,
    required this.createdAt,
  });

  factory KnowledgeSource.fromJson(Map<String, dynamic> json) {
    return KnowledgeSource(
      id: json['id'] as String,
      botId: json['bot_id'] as String?,
      tenantId: json['tenant_id'] as String,
      type: json['type'] as String,
      sourceUri: json['source_uri'] as String?,
      title: json['title'] as String?,
      status: json['status'] as String,
      lastError: json['last_error'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─── Stream Provider (real-time list per bot) ─────────────────────────────

/// Lista en tiempo real las fuentes activas (deleted_at IS NULL) del bot dado.
/// La exclusión de soft-deleted se hace en cliente porque stream() no soporta IS NULL.
final knowledgeSourcesProvider =
    StreamProvider.family<List<KnowledgeSource>, String>((ref, botId) {
  final sb = ref.watch(supabaseClientProvider);
  return sb
      .from('knowledge_sources')
      .stream(primaryKey: ['id'])
      .eq('bot_id', botId)
      .order('created_at', ascending: false)
      .map((rows) => rows
          .where((r) => r['deleted_at'] == null)
          .map(KnowledgeSource.fromJson)
          .toList());
});

// ─── Upload state ─────────────────────────────────────────────────────────

class KnowledgeUploadState {
  final bool isUploading;
  final String? error;

  const KnowledgeUploadState({this.isUploading = false, this.error});

  KnowledgeUploadState copyWith({bool? isUploading, String? error}) {
    return KnowledgeUploadState(
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}

class KnowledgeUploadNotifier extends StateNotifier<KnowledgeUploadState> {
  final Ref _ref;

  KnowledgeUploadNotifier(this._ref) : super(const KnowledgeUploadState());

  Future<void> uploadFile(String botId, PlatformFile file) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      final sb = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Sin sesión activa');

      if (file.size > 25 * 1024 * 1024) {
        throw Exception('Archivo demasiado grande (máx. 25 MB)');
      }

      final ext = (file.extension ?? '').toLowerCase();
      final sourceType = ext == 'pdf' ? 'pdf' : 'markdown';
      final uniqueId = const Uuid().v4();
      final storagePath = 'tenants/$userId/$uniqueId.$ext';

      // Bytes disponibles en desktop (withData: true); fallback via path
      var bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) throw Exception('No se pudo leer el archivo');

      await sb.storage.from('knowledge').uploadBinary(storagePath, bytes);

      await sb.from('knowledge_sources').insert({
        'bot_id': botId,
        'tenant_id': userId,
        'type': sourceType,
        'source_uri': 'storage://knowledge/$storagePath',
        'title': file.name,
        'status': 'pending',
        'metadata': <String, dynamic>{},
      });

      state = state.copyWith(isUploading: false);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  Future<void> addUrl(String botId, String url) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      final sb = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Sin sesión activa');

      await sb.from('knowledge_sources').insert({
        'bot_id': botId,
        'tenant_id': userId,
        'type': 'url',
        'source_uri': url,
        'title': url,
        'status': 'pending',
        'metadata': <String, dynamic>{},
      });

      state = state.copyWith(isUploading: false);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  Future<void> addText(String botId, String text) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      final sb = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Sin sesión activa');

      final previewLen = text.length < 50 ? text.length : 50;
      final title = text.substring(0, previewLen) + (text.length > 50 ? '...' : '');

      // El contenido va en metadata.text para evitar migración adicional.
      // El embedder (T9·07) debe leer metadata->>'text' cuando type='text' y source_uri IS NULL.
      await sb.from('knowledge_sources').insert({
        'bot_id': botId,
        'tenant_id': userId,
        'type': 'text',
        'source_uri': null,
        'title': title,
        'status': 'pending',
        'metadata': {'text': text},
      });

      state = state.copyWith(isUploading: false);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  Future<void> softDelete(String sourceId) async {
    try {
      final sb = _ref.read(supabaseClientProvider);
      await sb
          .from('knowledge_sources')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', sourceId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final knowledgeUploadProvider = StateNotifierProvider
    .autoDispose<KnowledgeUploadNotifier, KnowledgeUploadState>((ref) {
  return KnowledgeUploadNotifier(ref);
});
