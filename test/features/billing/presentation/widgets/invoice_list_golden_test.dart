// Archivo: test/features/billing/presentation/widgets/invoice_list_golden_test.dart
//
// T4·13 — Golden tests for InvoiceList.
//
// Strategy:
//   - Overrides invoicesRepositoryProvider with a lightweight fake; no real
//     Supabase calls are made.
//   - Fixed surface size of 400×800 for deterministic pixel output.
//   - Two scenarios: skeleton loading state and 5 mixed-status invoices.
//
// Generate / update goldens:
//   flutter test --update-goldens \
//     test/features/billing/presentation/widgets/invoice_list_golden_test.dart

import 'dart:async';

import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/domain/models/invoice_item.dart';
import 'package:botslode/features/billing/domain/models/invoice_page.dart';
import 'package:botslode/features/billing/domain/repositories/invoices_repository.dart';
import 'package:botslode/features/billing/presentation/providers/billing_repository_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/invoice_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────── fake repositories ──

/// Never resolves — keeps the list in skeleton state indefinitely.
class _NeverRepo implements InvoicesRepository {
  const _NeverRepo();

  @override
  Future<InvoicePage> listForTenant(
    String tenantId, {
    String? cursor,
    int limit = 20,
  }) =>
      Completer<InvoicePage>().future;

  @override
  Future<Invoice?> getById(String id) async => null;

  @override
  Future<List<InvoiceItem>> itemsForInvoice(String invoiceId) async => [];
}

/// Returns [_invoices] immediately for any tenant.
class _FixedRepo implements InvoicesRepository {
  const _FixedRepo(this._invoices);

  final List<Invoice> _invoices;

  @override
  Future<InvoicePage> listForTenant(
    String tenantId, {
    String? cursor,
    int limit = 20,
  }) async =>
      InvoicePage(items: _invoices, nextCursor: null);

  @override
  Future<Invoice?> getById(String id) async =>
      _invoices.where((i) => i.id == id).firstOrNull;

  @override
  Future<List<InvoiceItem>> itemsForInvoice(String invoiceId) async => [];
}

// ─────────────────────────────────────────────────────── fixture helpers ──

const _kTenant = 'tenant-golden';
final _kBase = DateTime.utc(2026, 1, 1);
final _kPeriodStart = DateTime.utc(2026, 1, 1);
final _kPeriodEnd = DateTime.utc(2026, 1, 31);

Invoice _makeInvoice({
  required String id,
  required String number,
  required InvoiceStatus status,
  int totalCents = 9900,
  String currency = 'USD',
  String? pdfUrl,
}) =>
    Invoice(
      id: id,
      tenantId: _kTenant,
      number: number,
      totalCents: totalCents,
      currency: currency,
      status: status,
      pdfUrl: pdfUrl,
      periodStart: _kPeriodStart,
      periodEnd: _kPeriodEnd,
      createdAt: _kBase,
      updatedAt: _kBase,
    );

// ─────────────────────────────────────────────────────── pump helper ──

Future<void> _pumpInvoiceList(
  WidgetTester tester, {
  required InvoicesRepository repo,
  void Function(Invoice)? onDownloadPdf,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        invoicesRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue(_kTenant),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            body: InvoiceList(onDownloadPdf: onDownloadPdf),
          ),
        ),
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────── golden tests ──

void main() {
  group('InvoiceList — golden', () {
    // -----------------------------------------------------------------------
    // 1. Skeleton loading state
    // -----------------------------------------------------------------------
    testWidgets('skeleton loading', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpInvoiceList(tester, repo: const _NeverRepo());
      // One frame starts the async load but the Completer never resolves.
      await tester.pump();

      await expectLater(
        find.byType(InvoiceList),
        matchesGoldenFile('goldens/invoice_list_loading.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 2. Five invoices with mixed statuses
    // -----------------------------------------------------------------------
    testWidgets('5 mixed invoices', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final invoices = [
        _makeInvoice(
          id: 'inv-1',
          number: 'INV-2026-001',
          status: InvoiceStatus.paid,
          totalCents: 9900,
          pdfUrl: 'https://example.com/inv-1.pdf',
        ),
        _makeInvoice(
          id: 'inv-2',
          number: 'INV-2026-002',
          status: InvoiceStatus.open,
          totalCents: 4900,
        ),
        _makeInvoice(
          id: 'inv-3',
          number: 'INV-2026-003',
          status: InvoiceStatus.voided,
          totalCents: 2900,
          currency: 'ARS',
        ),
        _makeInvoice(
          id: 'inv-4',
          number: 'INV-2026-004',
          status: InvoiceStatus.uncollectible,
          totalCents: 14900,
        ),
        _makeInvoice(
          id: 'inv-5',
          number: 'INV-2026-005',
          status: InvoiceStatus.draft,
          totalCents: 0,
        ),
      ];

      await _pumpInvoiceList(
        tester,
        repo: _FixedRepo(invoices),
        // provide callback so INV-2026-001 shows enabled download button
        onDownloadPdf: (_) {},
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(InvoiceList),
        matchesGoldenFile('goldens/invoice_list_5_invoices.png'),
      );
    });
  });
}
