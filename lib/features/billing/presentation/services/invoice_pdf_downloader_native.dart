// Archivo: lib/features/billing/presentation/services/invoice_pdf_downloader_native.dart
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'invoice_pdf_download_exceptions.dart';

/// Downloads the PDF at [url] to the platform downloads directory.
/// Reports progress via [onProgress] (0.0–1.0) when Content-Length is known.
/// Returns the absolute path of the saved file.
Future<String?> platformDownloadPdf(
  String url,
  String filename, {
  void Function(double progress)? onProgress,
}) async {
  final client = http.Client();
  try {
    final response = await client.send(http.Request('GET', Uri.parse(url)));

    if (response.statusCode == 401) throw PdfDownloadException.unauthorized();
    if (response.statusCode == 404) throw PdfDownloadException.notFound();
    if (response.statusCode != 200) {
      throw PdfDownloadException.network('HTTP ${response.statusCode}');
    }

    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress?.call(received / total);
    }
    await sink.close();
    return file.path;
  } finally {
    client.close();
  }
}
