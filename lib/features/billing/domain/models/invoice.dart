// lib/features/billing/domain/models/invoice.dart

class Invoice {
  final String id;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final String status;
  final String? pdfUrl;
  final String? hostedUrl;

  final String? number;

  const Invoice({
    required this.id,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.status,
    this.pdfUrl,
    this.hostedUrl,
    this.number,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'usd',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: map['status']?.toString() ?? 'unknown',
      pdfUrl: map['pdf_url']?.toString(),
      hostedUrl: map['hosted_url']?.toString(),
      number: map['number']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
        'status': status,
        'pdf_url': pdfUrl,
        'hosted_url': hostedUrl,
        'number': number,
      };
}
