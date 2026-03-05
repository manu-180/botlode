// Archivo: lib/features/hunter_bot/domain/models/hunter_config.dart

/// Configuración del HunterBot para un usuario
/// Contiene las credenciales de Resend y configuración de emails
class HunterConfig {
  final String id;
  final String userId;
  final String? resendApiKey;
  final String? fromEmail;
  final String? fromName;
  final String? calendarLink;
  final bool isActive;
  
  // Control del bot
  final bool botEnabled;
  final String nicho;
  final List<String> ciudades;
  final String pais;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const HunterConfig({
    required this.id,
    required this.userId,
    this.resendApiKey,
    this.fromEmail,
    this.fromName,
    this.calendarLink,
    this.isActive = false,
    this.botEnabled = false,
    this.nicho = 'Rotación automática',
    this.ciudades = const ['Buenos Aires', 'Córdoba', 'Rosario'],
    this.pais = 'Argentina',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Verifica si la configuración está completa para enviar emails
  bool get isConfigured => 
      resendApiKey != null && 
      resendApiKey!.isNotEmpty &&
      fromEmail != null && 
      fromEmail!.isNotEmpty;

  /// Verifica si el API key tiene el formato correcto (empieza con re_)
  bool get hasValidApiKeyFormat => 
      resendApiKey != null && resendApiKey!.startsWith('re_');

  /// Crea un HunterConfig desde un Map de Supabase
  factory HunterConfig.fromMap(Map<String, dynamic> map) {
    // Parse ciudades (puede venir como List o String)
    List<String> parsedCiudades = ['Buenos Aires', 'Córdoba', 'Rosario'];
    if (map['ciudades'] != null) {
      if (map['ciudades'] is List) {
        parsedCiudades = (map['ciudades'] as List).map((e) => e.toString()).toList();
      } else if (map['ciudades'] is String) {
        // Si viene como string, intentar parsear
        final str = map['ciudades'] as String;
        if (str.isNotEmpty && str != '{}') {
          parsedCiudades = str
              .replaceAll('{', '')
              .replaceAll('}', '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }
    
    return HunterConfig(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      resendApiKey: map['resend_api_key']?.toString(),
      fromEmail: map['from_email']?.toString(),
      fromName: map['from_name']?.toString(),
      calendarLink: map['calendar_link']?.toString(),
      isActive: map['is_active'] == true,
      botEnabled: map['bot_enabled'] == true,
      nicho: map['nicho']?.toString() ?? 'Rotación automática',
      ciudades: parsedCiudades,
      pais: map['pais']?.toString() ?? 'Argentina',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convierte el HunterConfig a Map para Supabase
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'resend_api_key': resendApiKey,
      'from_email': fromEmail,
      'from_name': fromName,
      'calendar_link': calendarLink,
      'is_active': isActive,
      'bot_enabled': botEnabled,
      'nicho': nicho,
      'ciudades': ciudades,
      'pais': pais,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Crea una configuración vacía para un usuario
  factory HunterConfig.empty(String userId) {
    final now = DateTime.now();
    return HunterConfig(
      id: '',
      userId: userId,
      resendApiKey: null,
      fromEmail: null,
      fromName: 'Mi Empresa',
      calendarLink: null,
      isActive: false,
      botEnabled: false,
      nicho: 'Rotación automática',
      ciudades: const ['Buenos Aires', 'Córdoba', 'Rosario'],
      pais: 'Argentina',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copia con modificaciones
  HunterConfig copyWith({
    String? id,
    String? userId,
    String? resendApiKey,
    String? fromEmail,
    String? fromName,
    String? calendarLink,
    bool? isActive,
    bool? botEnabled,
    String? nicho,
    List<String>? ciudades,
    String? pais,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HunterConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      resendApiKey: resendApiKey ?? this.resendApiKey,
      fromEmail: fromEmail ?? this.fromEmail,
      fromName: fromName ?? this.fromName,
      calendarLink: calendarLink ?? this.calendarLink,
      isActive: isActive ?? this.isActive,
      botEnabled: botEnabled ?? this.botEnabled,
      nicho: nicho ?? this.nicho,
      ciudades: ciudades ?? this.ciudades,
      pais: pais ?? this.pais,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'HunterConfig(userId: $userId, isConfigured: $isConfigured, botEnabled: $botEnabled, nicho: $nicho)';
}
