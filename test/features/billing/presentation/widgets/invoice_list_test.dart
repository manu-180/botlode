// Archivo: test/features/billing/presentation/widgets/invoice_list_test.dart
//
// T4·13 — Widget + smoke tests for InvoiceList.
//
// Covers:
//   - Empty state renders correct message
//   - Invoices load and display number, period and amount
//   - Status chips render correct label
//   - Download button enabled only when pdfUrl + callback provided
//   - Row tap expands detail panel and loads invoice items
//   - Pull-to-refresh reloads the list
//   - Pagination smoke: second page loads when scrolled near the bottom

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

class _FixedRepo implements InvoicesRepository {
  _FixedRepo({required this.invoices, this.items = const []});

  final List<Invoice> invoices;
  final List<InvoiceItem> items;
  int listCallCount = 0;

  @override
  Future<InvoicePage> listForTenant(
    String tenantId, {
    String? cursor,
    int limit = 20,
  }) async {
    listCallCount++;
    return InvoicePage(items: invoices, nextCursor: null);
  }

  @override
  Future<Invoice?> getById(String id) async =>
      invoices.where((i) => i.id == id).firstOrNull;

  @override
  Future<List<InvoiceItem>> itemsForInvoice(String invoiceId) async => items;
}

/// Returns different pages depending on whether a cursor is provided.
class _PaginatingRepo implements InvoicesRepository {
  _PaginatingRepo({required this.firstPage, required this.secondPage});

  final InvoicePage firstPage;
  final InvoicePage secondPage;

  @override
  Future<InvoicePage> listForTenant(
    String tenantId, {
    String? cursor,
    int limit = 20,
  }) async =>
      cursor == null ? firstPage : secondPage;

  @override
  Future<Invoice?> getById(String id) async => null;

  @override
  Future<List<InvoiceItem>> itemsForInvoice(String invoiceId) async => [];
}

// ─────────────────────────────────────────────────────── fixture helpers ──

const _kTenant = 'tenant-test';
final _kBase = DateTime.utc(2026, 1, 1);

Invoice _makeInvoice({
  required String id,
  required String number,
  InvoiceStatus status = InvoiceStatus.open,
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
      periodStart: DateTime.utc(2026, 1, 1),
      periodEnd: DateTime.utc(2026, 1, 31),
      createdAt: _kBase,
      updatedAt: _kBase,
    );

InvoiceItem _makeItem({
  required String id,
  required String invoiceId,
  String description = 'Plan Pro',
  int amountCents = 9900,
}) =>
    InvoiceItem(
      id: id,
      invoiceId: invoiceId,
      description: description,
      unitPriceCents: amountCents,
      amountCents: amountCents,
      createdAt: _kBase,
    );

// ─────────────────────────────────────────────────────────── pump helper ──

Future<void> _pump(
  WidgetTester tester, {
  required InvoicesRepository repo,
  String tenantId = _kTenant,
  void Function(Invoice)? onDownloadPdf,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        invoicesRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue(tenantId),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: InvoiceList(onDownloadPdf: onDownloadPdf),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────── tests ──────

void main() {
  // -------------------------------------------------------------------------
  // Empty state
  // -------------------------------------------------------------------------
  testWidgets('shows empty state when no invoices', (tester) async {
    await _pump(tester, repo: _FixedRepo(invoices: []));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay facturas'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Basic rendering
  // -------------------------------------------------------------------------
  testWidgets('renders invoice number, period and amount', (tester) async {
    final invoice = _makeInvoice(
      id: 'inv-render',
      number: 'INV-2026-001',
      totalCents: 9900,
      currency: 'USD',
    );

    await _pump(tester, repo: _FixedRepo(invoices: [invoice]));
    await tester.pumpAndSettle();

    expect(find.text('INV-2026-001'), findsOneWidget);
    // period contains the month separator (locale-independent)
    expect(find.textContaining(' – '), findsOneWidget);
    // amount — USD 99.00 formatted by simpleCurrency
    expect(find.textContaining('99'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Status chip labels
  // -------------------------------------------------------------------------
  group('status chip labels', () {
    for (final (status, expectedLabel) in [
      (InvoiceStatus.paid, 'Pagada'),
      (InvoiceStatus.open, 'Pendiente'),
      (InvoiceStatus.voided, 'Anulada'),
      (InvoiceStatus.uncollectible, 'Incobrable'),
      (InvoiceStatus.draft, 'Borrador'),
    ]) {
      testWidgets('shows "$expectedLabel" for $status', (tester) async {
        final inv = _makeInvoice(
          id: 'inv-status',
          number: 'INV-STATUS',
          status: status,
        );
        await _pump(tester, repo: _FixedRepo(invoices: [inv]));
        await tester.pumpAndSettle();

        expect(find.text(expectedLabel), findsOneWidget);
      });
    }
  });

  // -------------------------------------------------------------------------
  // Download button state
  // -------------------------------------------------------------------------
  testWidgets('download button disabled when no pdfUrl', (tester) async {
    final inv = _makeInvoice(id: 'inv-dl', number: 'INV-DL');
    await _pump(
      tester,
      repo: _FixedRepo(invoices: [inv]),
      onDownloadPdf: (_) {},
    );
    await tester.pumpAndSettle();

    final btn = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('download button enabled when pdfUrl + callback provided',
      (tester) async {
    Invoice? tapped;
    final inv = _makeInvoice(
      id: 'inv-dl-enabled',
      number: 'INV-DL-ENABLED',
      pdfUrl: 'https://example.com/inv.pdf',
    );
    await _pump(
      tester,
      repo: _FixedRepo(invoices: [inv]),
      onDownloadPdf: (i) => tapped = i,
    );
    await tester.pumpAndSettle();

    final btn = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download),
    );
    expect(btn.onPressed, isNotNull);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.download));
    expect(tapped?.id, equals('inv-dl-enabled'));
  });

  // -------------------------------------------------------------------------
  // Expand row → loads items
  // -------------------------------------------------------------------------
  testWidgets('tapping a row expands and shows invoice items', (tester) async {
    final inv = _makeInvoice(id: 'inv-expand', number: 'INV-EXP');
    final items = [
      _makeItem(id: 'item-1', invoiceId: 'inv-expand', description: 'Plan Pro'),
      _makeItem(
          id: 'item-2',
          invoiceId: 'inv-expand',
          description: 'Soporte premium'),
    ];
    final repo = _FixedRepo(invoices: [inv], items: items);

    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    // items not visible yet
    expect(find.text('Plan Pro'), findsNothing);

    // tap the row
    await tester.tap(find.text('INV-EXP'));
    await tester.pumpAndSettle();

    expect(find.text('Plan Pro'), findsOneWidget);
    expect(find.text('Soporte premium'), findsOneWidget);
  });

  testWidgets('tapping expanded row collapses it', (tester) async {
    final inv = _makeInvoice(id: 'inv-collapse', number: 'INV-COL');
    final items = [
      _makeItem(
          id: 'item-c', invoiceId: 'inv-collapse', description: 'Plan Básico'),
    ];

    await _pump(tester, repo: _FixedRepo(invoices: [inv], items: items));
    await tester.pumpAndSettle();

    // expand
    await tester.tap(find.text('INV-COL'));
    await tester.pumpAndSettle();
    expect(find.text('Plan Básico'), findsOneWidget);

    // collapse
    await tester.tap(find.text('INV-COL'));
    await tester.pumpAndSettle();
    expect(find.text('Plan Básico'), findsNothing);
  });

  // -------------------------------------------------------------------------
  // Pull-to-refresh
  // -------------------------------------------------------------------------
  testWidgets('pull-to-refresh calls repo again', (tester) async {
    final inv = _makeInvoice(id: 'inv-refresh', number: 'INV-REF');
    final repo = _FixedRepo(invoices: [inv]);

    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(repo.listCallCount, equals(1));

    // drag down to trigger RefreshIndicator
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(repo.listCallCount, greaterThanOrEqualTo(2));
  });

  // -------------------------------------------------------------------------
  // Pagination smoke — scrolling near bottom loads next page
  // -------------------------------------------------------------------------
  testWidgets('loads second page when scrolled near bottom', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final page1Invoices = List.generate(
      20,
      (i) => _makeInvoice(
        id: 'p1-$i',
        number: 'P1-${i.toString().padLeft(3, '0')}',
        status: InvoiceStatus.open,
      ),
    );
    final page2Invoices = List.generate(
      5,
      (i) => _makeInvoice(
        id: 'p2-$i',
        number: 'P2-${i.toString().padLeft(3, '0')}',
        status: InvoiceStatus.paid,
      ),
    );

    final repo = _PaginatingRepo(
      firstPage: InvoicePage(items: page1Invoices, nextCursor: 'cursor-abc'),
      secondPage: InvoicePage(items: page2Invoices, nextCursor: null),
    );

    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    // first page visible; second page not yet loaded
    expect(find.text('P1-000'), findsOneWidget);
    expect(find.text('P2-000'), findsNothing);

    // Step 1: jump to maxScrollExtent — remaining=0 ≤ triggerOffset(200),
    // so _onScroll fires immediately and calls _loadMore.
    final scrollState =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    scrollState.position.jumpTo(scrollState.position.maxScrollExtent);
    await tester.pump(); // _onScroll fires → _loadMore starts
    await tester.pumpAndSettle(); // async _loadMore completes, list grows to 25

    // Step 2: jump to the NEW maxScrollExtent to bring page-2 rows into the
    // visible viewport. _hasMore is false so no further load is triggered.
    scrollState.position.jumpTo(scrollState.position.maxScrollExtent);
    await tester.pumpAndSettle();

    // page-2 items are visible near the bottom of the list
    expect(find.text('P2-004'), findsOneWidget);
  });
}
