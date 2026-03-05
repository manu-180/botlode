/// Modelo de una empresa sin dominio (Hunter Bot + Seeder Bot).
class EmpresaSinDominio {
  final String id;
  final String? userId;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String ciudad;
  final String pais;
  final String? nicho;
  final String source; // 'hunter' | 'seeder'
  final String? clasificacion; // 'ventas_reservas' | 'landing_info'
  final String? typeRaw;
  final String verificationStatus; // 'pending' | 'verified_no_web' | 'has_web'
  final int confidenceNoWeb; // 0-100
  final DateTime? verifiedAt;
  final String? verificationDetails;
  final DateTime createdAt;

  const EmpresaSinDominio({
    required this.id,
    this.userId,
    required this.nombre,
    this.direccion,
    this.telefono,
    required this.ciudad,
    required this.pais,
    this.nicho,
    required this.source,
    this.clasificacion,
    this.typeRaw,
    this.verificationStatus = 'pending',
    this.confidenceNoWeb = 0,
    this.verifiedAt,
    this.verificationDetails,
    required this.createdAt,
  });

  factory EmpresaSinDominio.fromMap(Map<String, dynamic> map) {
    return EmpresaSinDominio(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      nombre: (map['nombre'] as String?) ?? '',
      direccion: map['direccion'] as String?,
      telefono: map['telefono'] as String?,
      ciudad: (map['ciudad'] as String?) ?? '',
      pais: (map['pais'] as String?) ?? '',
      nicho: map['nicho'] as String?,
      source: (map['source'] as String?) ?? 'hunter',
      clasificacion: map['clasificacion'] as String?,
      typeRaw: map['type_raw'] as String?,
      verificationStatus: (map['verification_status'] as String?) ?? 'pending',
      confidenceNoWeb: (map['confidence_no_web'] as int?) ?? 0,
      verifiedAt: map['verified_at'] != null
          ? DateTime.tryParse(map['verified_at'] as String)
          : null,
      verificationDetails: map['verification_details'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isVerified => verificationStatus == 'verified_no_web';
  bool get isPending => verificationStatus == 'pending';

  /// URL de WhatsApp para abrir chat. Null si no hay teléfono válido.
  /// Normaliza formato: quita 0 inicial, agrega 54 para números argentinos.
  String? get whatsappUrl {
    final phone = telefono?.trim();
    if (phone == null || phone.isEmpty) return null;
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    // Quitar 0 inicial (formato local ej. 03414434513) — WhatsApp usa formato internacional
    while (digits.startsWith('0') && digits.length > 1) digits = digits.substring(1);
    if (digits.isEmpty) return null;
    // Argentina: 10 dígitos (cualquier código de área 11, 341, 351, etc.) -> agregar 54
    if (digits.length == 10) return 'https://wa.me/54$digits';
    // Ya tiene código de país (ej. 54...) o es otro formato válido
    if (digits.length >= 10) return 'https://wa.me/$digits';
    return null;
  }

  bool get hasWhatsapp => whatsappUrl != null;
}
