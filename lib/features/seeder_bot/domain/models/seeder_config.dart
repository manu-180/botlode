/// Configuración global del Seeder Bot (una sola fila en seeder_config).
class SeederConfig {
  final String id;
  final bool botEnabled;
  final DateTime updatedAt;

  const SeederConfig({
    required this.id,
    this.botEnabled = false,
    required this.updatedAt,
  });

  factory SeederConfig.fromMap(Map<String, dynamic> map) {
    return SeederConfig(
      id: map['id']?.toString() ?? '',
      botEnabled: map['bot_enabled'] == true,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bot_enabled': botEnabled,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SeederConfig copyWith({String? id, bool? botEnabled, DateTime? updatedAt}) {
    return SeederConfig(
      id: id ?? this.id,
      botEnabled: botEnabled ?? this.botEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
