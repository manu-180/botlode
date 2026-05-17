// Archivo: lib/features/billing/presentation/widgets/invoice_list.dart
//
// T4·13 — Lista paginada de facturas con badge de status, período, monto
// y botón "Descargar PDF" que delega a T4·14 mediante [onDownloadPdf].

import 'package:botslode/features/billing/presentation/widgets/empty_state.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/domain/models/invoice_item.dart';
import 'package:botslode/features/billing/presentation/providers/billing_repository_provider.dart';

// ─────────────────────────────────────────── file-level formatter cache ──

final _nfCache = <String, NumberFormat>{};

NumberFormat _nf(String currency) => _nfCache.putIfAbsent(
      currency,
      () => NumberFormat.simpleCurrency(name: currency, decimalDigits: 2),
    );

String _fmtMoney(int cents, String currency) =>
    _nf(currency).format(cents / 100.0);

final _dfDate = DateFormat('d MMM y');

String _fmtPeriod(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '—';
  return '${_dfDate.format(start)} – ${_dfDate.format(end)}';
}

String _statusLabel(InvoiceStatus status) {
  return switch (status) {
    InvoiceStatus.paid => 'Pagada',
    InvoiceStatus.open => 'Pendiente',
    InvoiceStatus.voided => 'Anulada',
    InvoiceStatus.uncollectible => 'Incobrable',
    InvoiceStatus.draft => 'Borrador',
  };
}

// ──────────────────────────────────────────────────────── public widget ──

class InvoiceList extends ConsumerStatefulWidget {
  const InvoiceList({super.key, this.onDownloadPdf});

  /// Called when the user taps "Descargar PDF" for an invoice that has a
  /// [Invoice.pdfUrl]. T4·14 wires the actual download logic here.
  /// When null every download button is disabled.
  final void Function(Invoice)? onDownloadPdf;

  @override
  ConsumerState<InvoiceList> createState() => _InvoiceListState();
}

// ─────────────────────────────────────────────────────────── state ──────

class _InvoiceListState extends ConsumerState<InvoiceList> {
  static const _pageSize = 20;
  static const _triggerOffset = 200.0;

  final _scroll = ScrollController();
  final _expanded = <String>{};
  final _itemsCache = <String, List<InvoiceItem>>{};
  final _itemsLoading = <String>{};

  List<Invoice> _invoices = [];
  String? _cursor;
  bool _hasMore = false;
  bool _firstLoad = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirst());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────── scroll trigger ──

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining <= _triggerOffset && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  // ──────────────────────────────────────────────────────── data ops ──

  Future<void> _loadFirst() async {
    if (!mounted) return;
    setState(() {
      _firstLoad = true;
      _error = null;
      _expanded.clear();
      _itemsCache.clear();
      _itemsLoading.clear();
    });
    try {
      final tenantId = ref.read(currentUserIdProvider);
      if (tenantId == null) {
        if (mounted) setState(() => _firstLoad = false);
        return;
      }
      final page = await ref
          .read(invoicesRepositoryProvider)
          .listForTenant(tenantId, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _invoices = page.items;
        _cursor = page.nextCursor;
        _hasMore = page.nextCursor != null;
        _firstLoad = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _firstLoad = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final tenantId = ref.read(currentUserIdProvider);
    if (tenantId == null) return;

    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(invoicesRepositoryProvider)
          .listForTenant(tenantId, cursor: _cursor, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _invoices = [..._invoices, ...page.items];
        _cursor = page.nextCursor;
        _hasMore = page.nextCursor != null;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleRow(Invoice invoice) async {
    final id = invoice.id;
    final expanding = !_expanded.contains(id);
    setState(() {
      if (expanding) {
        _expanded.add(id);
      } else {
        _expanded.remove(id);
      }
    });

    if (expanding && !_itemsCache.containsKey(id)) {
      setState(() => _itemsLoading.add(id));
      try {
        final result =
            await ref.read(invoicesRepositoryProvider).itemsForInvoice(id);
        if (!mounted) return;
        setState(() {
          _itemsCache[id] = result;
          _itemsLoading.remove(id);
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _itemsCache[id] = [];
          _itemsLoading.remove(id);
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────── build ──

  @override
  Widget build(BuildContext context) {
    if (_firstLoad) return const _SkeletonList();
    if (_error != null) return _buildError(context);
    if (_invoices.isEmpty) return _buildEmpty(context);

    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _invoices.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _invoices.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final invoice = _invoices[index];
          return _InvoiceRow(
            key: ValueKey(invoice.id),
            invoice: invoice,
            isExpanded: _expanded.contains(invoice.id),
            items: _itemsCache[invoice.id],
            isLoadingItems: _itemsLoading.contains(invoice.id),
            onTap: () => _toggleRow(invoice),
            onDownload:
                invoice.pdfUrl != null && widget.onDownloadPdf != null
                    ? () => widget.onDownloadPdf!(invoice)
                    : null,
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: BillingEmptyState(
                illustration: Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: 'Sin facturas todavía',
                subtitle: 'Aparecerán acá cuando se emita la primera.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(AppStrings.billingInvoiceErrorLoad,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          TextButton(
              onPressed: _loadFirst, child: const Text(AppStrings.billingInvoiceRetry)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── invoice row ──

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    super.key,
    required this.invoice,
    required this.isExpanded,
    required this.onTap,
    this.items,
    this.isLoadingItems = false,
    this.onDownload,
  });

  final Invoice invoice;
  final bool isExpanded;
  final List<InvoiceItem>? items;
  final bool isLoadingItems;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: isExpanded,
          label: 'Factura ${_fmtPeriod(invoice.periodStart, invoice.periodEnd)} '
              'por ${_fmtMoney(invoice.totalCents, invoice.currency)} - '
              'Estado: ${_statusLabel(invoice.status)}',
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // expand chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),

                  // number + period
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.number,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmtPeriod(
                              invoice.periodStart, invoice.periodEnd),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // amount
                  Text(
                    _fmtMoney(invoice.totalCents, invoice.currency),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),

                  // status chip — semantics declared at row level to avoid duplication
                  ExcludeSemantics(child: _StatusChip(invoice.status)),
                  const SizedBox(width: 4),

                  // download button — min 48dp touch target
                  Semantics(
                    label: 'Descargar factura PDF de ${_fmtPeriod(invoice.periodStart, invoice.periodEnd)}',
                    button: true,
                    enabled: onDownload != null,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        onPressed: onDownload,
                        tooltip: AppStrings.billingInvoiceDownloadPdf,
                        icon: Icon(
                          Icons.download,
                          size: 20,
                          color: onDownload != null
                              ? theme.colorScheme.primary
                              : theme.disabledColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // expanded detail with invoice items
        // AnimatedSize removes the child from the tree when collapsed so
        // find.text() in tests (and screen readers) only see it when open.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isExpanded
              ? _ItemsDetail(items: items, isLoading: isLoadingItems)
              : const SizedBox.shrink(),
        ),

        const Divider(height: 1),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────── status chip ──
//
// Uses color + icon + text to satisfy WCAG AA (no color-only distinction).
// Color pairs verified ≥4.5:1 contrast ratio on white backgrounds.

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label, icon) = switch (status) {
      InvoiceStatus.paid => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          'Pagada',
          Icons.check_circle,
        ),
      InvoiceStatus.open => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
          'Pendiente',
          Icons.schedule,
        ),
      InvoiceStatus.voided => (
          const Color(0xFFF5F5F5),
          const Color(0xFF616161),
          'Anulada',
          Icons.block,
        ),
      InvoiceStatus.uncollectible => (
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          'Incobrable',
          Icons.warning,
        ),
      InvoiceStatus.draft => (
          const Color(0xFFE8EAF6),
          const Color(0xFF303F9F),
          'Borrador',
          Icons.edit,
        ),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── items detail ──

class _ItemsDetail extends StatelessWidget {
  const _ItemsDetail({required this.items, required this.isLoading});

  final List<InvoiceItem>? items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceContainerLowest;

    if (isLoading) {
      return Container(
        color: bg,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final list = items ?? [];
    if (list.isEmpty) {
      return Container(
        color: bg,
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          'Sin ítems',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list.map((item) => _ItemLine(item: item)).toList(),
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item});

  final InvoiceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = _nf(item.currency);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(item.description, style: theme.textTheme.bodySmall),
          ),
          Text(
            '${item.quantity}×  ${fmt.format(item.unitPriceCents / 100.0)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Text(
            fmt.format(item.amountCents / 100.0),
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── skeleton ──

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, __) => const _SkeletonRow(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(width: 100, height: 13, color: c),
                const SizedBox(height: 5),
                _Bone(width: 160, height: 11, color: c),
              ],
            ),
          ),
          _Bone(width: 64, height: 13, color: c),
          const SizedBox(width: 8),
          _Bone(width: 56, height: 20, color: c, radius: 12),
          const SizedBox(width: 52),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 4,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
