// Archivo: lib/features/billing/presentation/services/invoice_pdf_downloader.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/domain/repositories/invoices_repository.dart';
import 'package:botslode/l10n/app_strings.dart';

import 'invoice_pdf_download_exceptions.dart';
import 'invoice_pdf_downloader_stub.dart'
    if (dart.library.html) 'invoice_pdf_downloader_web.dart'
    if (dart.library.io) 'invoice_pdf_downloader_native.dart';

typedef _DownloadFn = Future<String?> Function(
  String url,
  String filename, {
  void Function(double progress)? onProgress,
});

class InvoicePdfDownloader {
  final InvoicesRepository _repository;
  final _DownloadFn _downloadFn;

  InvoicePdfDownloader(this._repository) : _downloadFn = platformDownloadPdf;

  @visibleForTesting
  InvoicePdfDownloader.withDownloadFn(this._repository, this._downloadFn);

  Future<void> download(
    BuildContext context,
    Invoice invoice, {
    void Function(double progress)? onProgress,
  }) async {
    final url = invoice.pdfUrl;
    if (url == null || url.isEmpty) {
      _showError(context, AppStrings.billingInvoiceNoPdf);
      return;
    }

    final filename = 'invoice-${invoice.number}.pdf';
    String? filePath;

    try {
      filePath = await _tryDownload(url, filename, invoice, onProgress);
    } on PdfDownloadException catch (e) {
      if (!context.mounted) return;
      _showError(context, _errorMessage(e));
      return;
    } catch (_) {
      if (!context.mounted) return;
      _showError(context, AppStrings.billingInvoiceErrorUnexpected);
      return;
    }

    if (!context.mounted) return;

    // Native: show snackbar with open action.
    // Web: browser handles the download — filePath is null, no snackbar needed.
    if (filePath != null) {
      final path = filePath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.billingInvoicePdfDownloaded),
          action: SnackBarAction(
            label: AppStrings.billingInvoiceOpenPdf,
            onPressed: () => launchUrl(Uri.file(path)),
          ),
        ),
      );
    }
  }

  Future<String?> _tryDownload(
    String url,
    String filename,
    Invoice invoice,
    void Function(double)? onProgress,
  ) async {
    try {
      return await _downloadFn(url, filename, onProgress: onProgress);
    } on PdfDownloadException catch (e) {
      if (e.type != PdfDownloadErrorType.unauthorized) rethrow;

      // 1 retry: fetch a fresh invoice to get a renewed signed URL.
      final fresh = await _repository.getById(invoice.id);
      final freshUrl = fresh?.pdfUrl;
      if (freshUrl == null || freshUrl.isEmpty) rethrow;

      return await _downloadFn(freshUrl, filename, onProgress: onProgress);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorMessage(PdfDownloadException e) => switch (e.type) {
        PdfDownloadErrorType.unauthorized => AppStrings.billingInvoiceErrUnauthorized,
        PdfDownloadErrorType.notFound => AppStrings.billingInvoiceErrNotFound,
        PdfDownloadErrorType.network => AppStrings.billingInvoiceErrNetwork,
      };
}
