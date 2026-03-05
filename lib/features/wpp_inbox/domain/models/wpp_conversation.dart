class WppConversation {
  const WppConversation({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    this.lastMessageAt,
    this.lastMessageBody,
    this.unreadCount = 0,
    required this.createdAt,
  });

  final String id;

  /// Número en formato Twilio: "whatsapp:+549XXXXXXXXXX"
  final String phoneNumber;

  /// Nombre de la empresa (resuelto desde empresas_sin_dominio o assistify_leads). Puede ser null.
  final String? displayName;

  final DateTime? lastMessageAt;
  final String? lastMessageBody;
  final int unreadCount;
  final DateTime createdAt;

  /// Nombre a mostrar en la UI: nombre de empresa o número formateado.
  String get title {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    return _formattedPhone;
  }

  /// Número sin prefijo "whatsapp:" para mostrar.
  String get _formattedPhone => phoneNumber.replaceFirst('whatsapp:', '');

  factory WppConversation.fromMap(Map<String, dynamic> map) {
    return WppConversation(
      id:               map['id'] as String,
      phoneNumber:      map['phone_number'] as String,
      displayName:      map['display_name'] as String?,
      lastMessageAt:    map['last_message_at'] != null
          ? DateTime.tryParse(map['last_message_at'] as String)
          : null,
      lastMessageBody:  map['last_message_body'] as String?,
      unreadCount:      (map['unread_count'] as int?) ?? 0,
      createdAt:        DateTime.parse(map['created_at'] as String),
    );
  }
}
