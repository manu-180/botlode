// Archivo: lib/features/billing/presentation/services/invoice_pdf_downloader_web.dart
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Triggers a browser-initiated PDF download via an invisible anchor element.
/// Returns null because the browser owns the download — no local path exists.
Future<String?> platformDownloadPdf(
  String url,
  String filename, {
  void Function(double progress)? onProgress,
}) async {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return null;
}
