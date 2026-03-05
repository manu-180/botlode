enum WppDirection { inbound, outbound }
enum WppStatus   { received, sent, delivered, read, failed }

class WppMessage {
  const WppMessage({
    required this.id,
    required this.conversationId,
    this.twilioSid,
    required this.direction,
    this.body,
    this.mediaUrl,
    this.mediaType,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String? twilioSid;
  final WppDirection direction;
  final String? body;
  final String? mediaUrl;
  final String? mediaType;
  final WppStatus status;
  final DateTime createdAt;

  bool get isInbound  => direction == WppDirection.inbound;
  bool get isOutbound => direction == WppDirection.outbound;
  bool get hasMedia   => mediaUrl != null;

  factory WppMessage.fromMap(Map<String, dynamic> map) {
    return WppMessage(
      id:             map['id'] as String,
      conversationId: map['conversation_id'] as String,
      twilioSid:      map['twilio_sid'] as String?,
      direction:      map['direction'] == 'inbound'
          ? WppDirection.inbound
          : WppDirection.outbound,
      body:           map['body'] as String?,
      mediaUrl:       map['media_url'] as String?,
      mediaType:      map['media_type'] as String?,
      status:         _parseStatus(map['status'] as String?),
      createdAt:      DateTime.parse(map['created_at'] as String),
    );
  }

  static WppStatus _parseStatus(String? s) {
    switch (s) {
      case 'sent':      return WppStatus.sent;
      case 'delivered': return WppStatus.delivered;
      case 'read':      return WppStatus.read;
      case 'failed':    return WppStatus.failed;
      default:          return WppStatus.received;
    }
  }
}
