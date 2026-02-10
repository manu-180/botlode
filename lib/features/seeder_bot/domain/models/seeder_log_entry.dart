/// Una entrada de log de propagation_logs (con nombre del target si hay join).
class SeederLogEntry {
  final String id;
  final String targetId;
  final String? targetName;
  final String? url;
  final String status; // 'ok' | 'error'
  final String? errorMessage;
  final DateTime submittedAt;
  final Map<String, dynamic>? metadata;

  const SeederLogEntry({
    required this.id,
    required this.targetId,
    this.targetName,
    this.url,
    required this.status,
    this.errorMessage,
    required this.submittedAt,
    this.metadata,
  });

  factory SeederLogEntry.fromMap(Map<String, dynamic> map) {
    // Soporta respuesta con join: propagation_targets puede venir como objeto
    String? name;
    String? targetUrl;
    if (map['propagation_targets'] != null && map['propagation_targets'] is Map) {
      final t = map['propagation_targets'] as Map<String, dynamic>;
      name = t['name']?.toString();
      targetUrl = t['url']?.toString();
    }
    return SeederLogEntry(
      id: map['id']?.toString() ?? '',
      targetId: map['target_id']?.toString() ?? '',
      targetName: name ?? map['target_name']?.toString(),
      url: targetUrl ?? map['url']?.toString(),
      status: map['status']?.toString() ?? 'error',
      errorMessage: map['error_message']?.toString(),
      submittedAt: DateTime.tryParse(map['submitted_at']?.toString() ?? '') ?? DateTime.now(),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  bool get isOk => status == 'ok';
}
