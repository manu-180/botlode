// lib/features/billing/presentation/services/invoice_pdf_downloader_stub.dart
// Stub for platforms where neither dart.library.html nor dart.library.io match.

import 'invoice_pdf_download_exceptions.dart';

Future<String?> platformDownloadPdf(
  String url,
  String filename, {
  void Function(double progress)? onProgress,
}) async {
  throw const PdfDownloadException(
    PdfDownloadErrorType.network,
    message: 'PDF download not supported on this platform',
  );
}
