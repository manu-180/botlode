/// Modelo de un lead para Assistify (negocios con clases pagadas por mes: cerámica, gimnasios, etc.).
class AssistifyLead {
  final String id;
  final String? userId;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String ciudad;
  final String pais;
  final String rubro;
  final String source;
  final String? typeRaw;
  final DateTime createdAt;

  const AssistifyLead({
    required this.id,
    this.userId,
    required this.nombre,
    this.direccion,
    this.telefono,
    required this.ciudad,
    required this.pais,
    required this.rubro,
    this.source = 'seeder',
    this.typeRaw,
    required this.createdAt,
  });

  factory AssistifyLead.fromMap(Map<String, dynamic> map) {
    return AssistifyLead(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      nombre: (map['nombre'] as String?) ?? '',
      direccion: map['direccion'] as String?,
      telefono: map['telefono'] as String?,
      ciudad: (map['ciudad'] as String?) ?? '',
      pais: (map['pais'] as String?) ?? '',
      rubro: (map['rubro'] as String?) ?? '',
      source: (map['source'] as String?) ?? 'seeder',
      typeRaw: map['type_raw'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// URL de WhatsApp. Null si no hay teléfono válido.
  String? get whatsappUrl {
    final phone = telefono?.trim();
    if (phone == null || phone.isEmpty) return null;
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    while (digits.startsWith('0') && digits.length > 1) digits = digits.substring(1);
    if (digits.isEmpty) return null;
    if (digits.length == 10) return 'https://wa.me/54$digits';
    if (digits.length >= 10) return 'https://wa.me/$digits';
    return null;
  }

  bool get hasWhatsapp => whatsappUrl != null;
}
