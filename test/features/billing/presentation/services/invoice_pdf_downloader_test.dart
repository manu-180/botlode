// Archivo: test/features/billing/presentation/services/invoice_pdf_downloader_test.dart
//
// T4·14 — Tests for InvoicePdfDownloader.
//
// Tests cover:
//   1. Successful download calls platform fn with invoice's pdfUrl
//   2. Success on native: shows "PDF descargado" snackbar
//   3. 401 → retries with renewed URL from fresh invoice
//   4. 401 on retry → shows "URL expirada" error snackbar
//   5. 404 → shows "Factura no encontrada" error snackbar
//   6. null pdfUrl → shows "no tiene PDF" error without calling download fn
//   7. Progress callback forwarded to platform fn

import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/presentation/services/invoice_pdf_download_exceptions.dart';
import 'package:botslode/features/billing/presentation/services/invoice_pdf_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../_fakes/fake_invoices_repository.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);
const _kOriginalUrl = 'https://storage.example.com/signed?token=orig';
const _kRenewedUrl = 'https://storage.example.com/signed?token=renewed';

Invoice _makeInvoice({String? pdfUrl = _kOriginalUrl}) => Invoice(
      id: 'inv-1',
      tenantId: 'tenant-1',
      number: 'INV-001',
      totalCents: 5000,
      status: InvoiceStatus.paid,
      pdfUrl: pdfUrl,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<BuildContext> _pumpScaffold(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ),
    ),
  );
  return ctx;
}

// ---------------------------------------------------------------------------
// Download-fn factory
// ---------------------------------------------------------------------------

typedef _DownloadFn = Future<String?> Function(
  String url,
  String filename, {
  void Function(double progress)? onProgress,
});

/// Returns a download function that records called [urls] and can throw
/// [errorOnCall1] / [errorOnCall2] on the respective invocations.
_DownloadFn _makeDownloadFn(
  List<String> urls, {
  Exception? errorOnCall1,
  Exception? errorOnCall2,
  String? returnPath = '/downloads/invoice-INV-001.pdf',
}) {
  var calls = 0;
  return (url, filename, {onProgress}) async {
    calls++;
    urls.add(url);
    if (calls == 1 && errorOnCall1 != null) throw errorOnCall1;
    if (calls == 2 && errorOnCall2 != null) throw errorOnCall2;
    return returnPath;
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('InvoicePdfDownloader', () {
    late FakeInvoicesRepository repo;
    late List<String> downloadedUrls;

    setUp(() {
      repo = FakeInvoicesRepository();
      downloadedUrls = [];
    });

    testWidgets('success: calls platform fn with invoice pdfUrl', (tester) async {
      final ctx = await _pumpScaffold(tester);
      final downloader = InvoicePdfDownloader.withDownloadFn(
        repo,
        _makeDownloadFn(downloadedUrls),
      );

      await downloader.download(ctx, _makeInvoice());

      expect(downloadedUrls, [_kOriginalUrl]);
    });

    testWidgets('success: shows "PDF descargado" snackbar on native', (tester) async {
      final ctx = await _pumpScaffold(tester);
      final downloader = InvoicePdfDownloader.withDownloadFn(
        repo,
        _makeDownloadFn(downloadedUrls),
      );

      await downloader.download(ctx, _makeInvoice());
      await tester.pump();

      expect(find.text('PDF descargado'), findsOneWidget);
    });

    testWidgets('401: retries once with renewed URL from repo', (tester) async {
      final ctx = await _pumpScaffold(tester);
      repo.addInvoice(_makeInvoice(pdfUrl: _kRenewedUrl));
      final downloader = InvoicePdfDownloader.withDownloadFn(
        repo,
        _makeDownloadFn(
          downloadedUrls,
          errorOnCall1: PdfDownloadException.unauthorized(),
        ),
      );

      await downloader.download(ctx, _makeInvoice());

      expect(downloadedUrls.length, 2);
      expect(downloadedUrls.first, _kOriginalUrl);
      expect(downloadedUrls.last, _kRenewedUrl);
    });

    testWidgets('401 on retry: shows URL expirada snackbar', (tester) async {
      final ctx = await _pumpScaffold(tester);
      repo.addInvoice(_makeInvoice(pdfUrl: _kRenewedUrl));
      final downloader = InvoicePdfDownloader.withDownloadFn(
        repo,
        _makeDownloadFn(
          downloadedUrls,
          errorOnCall1: PdfDownloadException.unauthorized(),
          errorOnCall2: PdfDownloadException.unauthorized(),
        ),
      );

      await downloader.download(ctx, _makeInvoice());
      await tester.pump();

      expect(find.text('URL expirada. Intente de nuevo.'), findsOneWidget);
    });

    testWidgets('404: shows Factura no encontrada snackbar', (tester) async {
      final ctx = await _pumpScaffold(tester);
      final downloader = InvoicePdfDownloader.withDownloadFn(
        repo,
        _makeDownloadFn(
          downloadedUrls,
          errorOnCall1: PdfDownloadException.notFound(),
        ),
      );

      await downloader.download(ctx, _makeInvoice());
      await tester.pump();

      expect(find.text('Factura no encontrada.'), findsOneWidget);
    });

    testWidgets('null pdfUrl: shows no-PDF error without calling download fn', (tester) async {
      final ctx = await _pumpScaffold(tester);
      final downloader = InvoicePdfDownloader.withDownloadFn(
        repo,
        _makeDownloadFn(downloadedUrls),
      );

      await downloader.download(ctx, _makeInvoice(pdfUrl: null));
      await tester.pump();

      expect(downloadedUrls, isEmpty);
      expect(find.text('Esta factura no tiene PDF disponible.'), findsOneWidget);
    });

    testWidgets('progress: callback forwarded to platform fn', (tester) async {
      final ctx = await _pumpScaffold(tester);
      final reported = <double>[];
      final downloader = InvoicePdfDownloader.withDownloadFn(
        repo,
        (url, filename, {onProgress}) async {
          onProgress?.call(0.5);
          onProgress?.call(1.0);
          return '/downloads/invoice-INV-001.pdf';
        },
      );

      await downloader.download(ctx, _makeInvoice(), onProgress: reported.add);

      expect(reported, [0.5, 1.0]);
    });
  });
}
