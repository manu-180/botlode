// lib/features/billing/presentation/services/invoice_pdf_download_exceptions.dart

enum PdfDownloadErrorType { unauthorized, notFound, network }

class PdfDownloadException implements Exception {
  final PdfDownloadErrorType type;
  final String? message;

  const PdfDownloadException(this.type, {this.message});

  @override
  String toString() => 'PdfDownloadException(${type.name}): $message';
}
