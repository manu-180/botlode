// Archivo: lib/features/billing/presentation/widgets/invoice_list.dart
//
// T4·13 — Lista paginada de facturas · tabla de registro HUD.
// Lógica conservada: scroll infinito, expansión de filas, onDownloadPdf,
// invoicesRepositoryProvider.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/hud/hud_reactor_bar.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:botslode/core/ui/widgets/empty_state.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/presentation/providers/billing_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ─── Column layout constants ───────────────────────────────────────────────────
const double _kColAmountWidth   = 120;
const double _kColStatusWidth   = 110;
const double _kColDownloadWidth =  48;
const double _kHeaderHeight     =  36;
const double _kChevronArea      =  26; // 18px icon + 8px gap

// ─── Formatters ───────────────────────────────────────────────────────────────
final _nfCache = <String, NumberFormat>{};

NumberFormat _nf(String currency) => _nfCache.putIfAbsent(
      currency,
      () => NumberFormat.simpleCurrency(name: currency.toUpperCase(), decimalDigits: 2),
    );

String _fmtAmount(double amount, String currency) => _nf(currency).format(amount);

final _dfDate = DateFormat('d MMM y');
String _fmtDate(DateTime dt) => _dfDate.format(dt);

String _invoiceLabel(Invoice invoice) =>
    invoice.number ?? 'INV-${invoice.id.substring(0, 8).toUpperCase()}';

// ─── Local status enum (derived from Invoice.status String) ───────────────────
enum _InvoiceStatus {
  paid, open, voided, uncollectible, draft, unknown;

  static _InvoiceStatus fromString(String s) => switch (s.toLowerCase()) {
        'paid'          => paid,
        'open'          => open,
        'void'          => voided,
        'voided'        => voided,
        'uncollectible' => uncollectible,
        'draft'         => draft,
        _               => unknown,
      };
}

String _statusLabel(_InvoiceStatus status) => switch (status) {
      _InvoiceStatus.paid          => 'PAGADA',
      _InvoiceStatus.open          => 'PENDIENTE',
      _InvoiceStatus.voided        => 'ANULADA',
      _InvoiceStatus.uncollectible => 'INCOBRABLE',
      _InvoiceStatus.draft         => 'BORRADOR',
      _InvoiceStatus.unknown       => 'DESCONOCIDO',
    };

// ─── Sort ─────────────────────────────────────────────────────────────────────
enum _SortColumn { date, amount }

// ─── InvoiceList ──────────────────────────────────────────────────────────────
class InvoiceList extends ConsumerStatefulWidget {
  const InvoiceList({super.key, this.onDownloadPdf});

  /// Called when the user taps "Descargar PDF" for an invoice that has a
  /// [Invoice.pdfUrl]. Wires the actual download logic externally.
  /// When null every download button is disabled.
  final void Function(Invoice)? onDownloadPdf;

  @override
  ConsumerState<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends ConsumerState<InvoiceList> {
  static const _pageSize      = 20;
  static const _triggerOffset = 200.0;
  static const _maxStaggered  = 10;

  final _scroll    = ScrollController();
  final _expanded  = <String>{};

  List<Invoice> _invoices    = [];
  int           _limit       = _pageSize;
  bool          _hasMore     = false;
  bool          _firstLoad   = true;
  bool          _loadingMore = false;
  Object?       _error;

  _SortColumn _sortColumn    = _SortColumn.date;
  bool        _sortAscending = false;

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

  // ─── Scroll trigger ────────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining <= _triggerOffset && !_loadingMore && _hasMore) _loadMore();
  }

  // ─── Data ops ──────────────────────────────────────────────────────────────

  Future<void> _loadFirst() async {
    if (!mounted) return;
    setState(() {
      _firstLoad = true;
      _error     = null;
      _expanded.clear();
      _limit = _pageSize;
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
        _invoices  = page.items;
        _hasMore   = page.hasMore;
        _firstLoad = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = e;
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
      final newLimit = _limit + _pageSize;
      final page = await ref
          .read(invoicesRepositoryProvider)
          .listForTenant(tenantId, limit: newLimit);
      if (!mounted) return;
      setState(() {
        _invoices    = page.items;
        _limit       = newLimit;
        _hasMore     = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _toggleRow(Invoice invoice) {
    setState(() {
      if (_expanded.contains(invoice.id)) {
        _expanded.remove(invoice.id);
      } else {
        _expanded.add(invoice.id);
      }
    });
  }

  void _toggleSort(_SortColumn col) {
    setState(() {
      if (_sortColumn == col) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn    = col;
        _sortAscending = false;
      }
    });
  }

  List<Invoice> get _sorted {
    final list = List<Invoice>.from(_invoices);
    list.sort((a, b) {
      final int cmp;
      switch (_sortColumn) {
        case _SortColumn.date:
          cmp = a.createdAt.compareTo(b.createdAt);
        case _SortColumn.amount:
          cmp = a.amount.compareTo(b.amount);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_firstLoad) return const _SkeletonList();
    if (_error != null) return _buildError();
    if (_invoices.isEmpty) return _buildEmpty();

    final sorted  = _sorted;
    final reduced = AppMotion.reduced(context);

    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: Column(
        children: [
          _ColumnHeader(
            sortColumn:    _sortColumn,
            sortAscending: _sortAscending,
            onSort:        _toggleSort,
          ),
          const HudDivider(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              physics:    const AlwaysScrollableScrollPhysics(),
              itemCount:  sorted.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == sorted.length) return const _PaginationFooter();

                final invoice  = sorted[index];
                final animated = !reduced && index < _maxStaggered;

                Widget row = _InvoiceRow(
                  key:        ValueKey(invoice.id),
                  invoice:    invoice,
                  isExpanded: _expanded.contains(invoice.id),
                  onTap:      () => _toggleRow(invoice),
                  onDownload:
                      invoice.pdfUrl != null && widget.onDownloadPdf != null
                          ? () => widget.onDownloadPdf!(invoice)
                          : null,
                );

                if (animated) row = _StaggeredEntry(index: index, child: row);
                return row;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 400,
            child: EmptyState(
              icon:        Icons.receipt_long,
              title:       'SIN FACTURAS',
              description: 'Aparecerán acá cuando se emita la primera.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: ErrorFeedbackCard(
          title:      'Error de carga',
          message:    'No pudimos cargar las facturas.',
          retryLabel: 'REINTENTAR',
          onRetry:    _loadFirst,
        ),
      ),
    );
  }
}

// ─── Column header ─────────────────────────────────────────────────────────────

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  final _SortColumn sortColumn;
  final bool        sortAscending;
  final void Function(_SortColumn) onSort;

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  _kHeaderHeight,
      color:   AppColors.surfaceHud,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
      child: Row(
        children: [
          const SizedBox(width: _kChevronArea),
          // FECHA — sortable
          Expanded(
            child: _SortableHeaderLabel(
              label:         'FECHA',
              column:        _SortColumn.date,
              sortColumn:    sortColumn,
              sortAscending: sortAscending,
              onSort:        onSort,
              align:         MainAxisAlignment.start,
            ),
          ),
          // MONTO — sortable
          SizedBox(
            width: _kColAmountWidth,
            child: _SortableHeaderLabel(
              label:         'MONTO',
              column:        _SortColumn.amount,
              sortColumn:    sortColumn,
              sortAscending: sortAscending,
              onSort:        onSort,
              align:         MainAxisAlignment.end,
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          // ESTADO — non-sortable
          SizedBox(
            width: _kColStatusWidth,
            child: Text(
              'ESTADO',
              style:     AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          // · download column indicator
          SizedBox(
            width: _kColDownloadWidth,
            child: Text(
              '·',
              style:     AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortableHeaderLabel extends StatelessWidget {
  const _SortableHeaderLabel({
    required this.label,
    required this.column,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    this.align = MainAxisAlignment.start,
  });

  final String                     label;
  final _SortColumn                column;
  final _SortColumn                sortColumn;
  final bool                       sortAscending;
  final void Function(_SortColumn) onSort;
  final MainAxisAlignment          align;

  @override
  Widget build(BuildContext context) {
    final isActive = sortColumn == column;
    final color    = isActive ? AppColors.gold : AppColors.textSecondary;
    final a11ySort = isActive
        ? (sortAscending ? 'ascendente' : 'descendente')
        : 'sin orden';

    return Semantics(
      button: true,
      label:  'Ordenar por $label, $a11ySort',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onSort(column),
          child: Row(
            mainAxisAlignment: align,
            mainAxisSize:      MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size:  12,
                  color: color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Invoice row ───────────────────────────────────────────────────────────────

class _InvoiceRow extends StatefulWidget {
  const _InvoiceRow({
    super.key,
    required this.invoice,
    required this.isExpanded,
    required this.onTap,
    this.onDownload,
  });

  final Invoice       invoice;
  final bool          isExpanded;
  final VoidCallback  onTap;
  final VoidCallback? onDownload;

  @override
  State<_InvoiceRow> createState() => _InvoiceRowState();
}

class _InvoiceRowState extends State<_InvoiceRow> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final dur     = reduced ? AppMotion.durInstant : AppMotion.durFast;

    final Color bgColor;
    if (_pressed) {
      bgColor = AppColors.surfaceRaised.withValues(alpha: 0.8);
    } else if (_hovered) {
      bgColor = AppColors.surfaceRaised;
    } else {
      bgColor = Colors.transparent;
    }

    final status = _InvoiceStatus.fromString(widget.invoice.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button:   true,
          expanded: widget.isExpanded,
          label: 'Factura ${_fmtDate(widget.invoice.createdAt)} '
              'por ${_fmtAmount(widget.invoice.amount, widget.invoice.currency)} — '
              'Estado: ${_statusLabel(status)}',
          child: MouseRegion(
            cursor:  SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit:  (_) => setState(() {
              _hovered = false;
              _pressed = false;
            }),
            child: GestureDetector(
              onTapDown:   (_) => setState(() => _pressed = true),
              onTapUp:     (_) {
                setState(() => _pressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedContainer(
                duration: dur,
                curve:    AppMotion.easeStandard,
                color:    bgColor,
                child: Stack(
                  children: [
                    // lateral HudReactorBar — visible on hover only
                    Positioned(
                      left:   0,
                      top:    0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        duration: dur,
                        opacity:  _hovered ? 1.0 : 0.0,
                        child: HudReactorBar(
                          axis:      Axis.vertical,
                          thickness: 2,
                          color:     AppColors.gold.withValues(alpha: 0.6),
                          pulsing:   _hovered && !reduced,
                        ),
                      ),
                    ),
                    // row content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space16,
                        vertical:   AppDimens.space12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // expand chevron
                          AnimatedRotation(
                            turns:    widget.isExpanded ? 0.25 : 0,
                            duration: dur,
                            child: const Icon(
                              Icons.chevron_right,
                              size:  18,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: AppDimens.space8),

                          // FECHA: invoice label + date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:  MainAxisAlignment.center,
                              children: [
                                Text(
                                  _invoiceLabel(widget.invoice),
                                  style: AppTextStyles.bodyM.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:      AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _fmtDate(widget.invoice.createdAt),
                                  style: AppTextStyles.mono.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // MONTO — tabular figures, right-aligned
                          SizedBox(
                            width: _kColAmountWidth,
                            child: Text(
                              _fmtAmount(
                                  widget.invoice.amount,
                                  widget.invoice.currency),
                              style:     AppTextStyles.hudReadout,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: AppDimens.space8),

                          // ESTADO
                          SizedBox(
                            width: _kColStatusWidth,
                            child: Center(
                              child: ExcludeSemantics(
                                child: _InvoiceStatusTag(status),
                              ),
                            ),
                          ),

                          // · download button
                          SizedBox(
                            width: _kColDownloadWidth,
                            child: Center(
                              child: Semantics(
                                label: 'Descargar factura PDF de '
                                    '${_fmtDate(widget.invoice.createdAt)}',
                                button:  true,
                                enabled: widget.onDownload != null,
                                child: ExcludeSemantics(
                                  child: AppIconButton(
                                    icon:      Icons.download,
                                    onPressed: widget.onDownload,
                                    tooltip:   'Descargar PDF',
                                    variant:   AppButtonVariant.ghost,
                                    size:      AppButtonSize.sm,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // expanded detail
        AnimatedSize(
          duration: AppMotion.durBase,
          curve:    AppMotion.easeStandard,
          child: widget.isExpanded
              ? _InvoiceDetail(invoice: widget.invoice)
              : const SizedBox.shrink(),
        ),

        // hairline divider between rows (no node)
        Container(height: 1, color: AppColors.borderSubtle),
      ],
    );
  }
}

// ─── Invoice status tag ────────────────────────────────────────────────────────

class _InvoiceStatusTag extends StatelessWidget {
  const _InvoiceStatusTag(this.status);

  final _InvoiceStatus status;

  Color get _color => switch (status) {
        _InvoiceStatus.paid          => AppColors.success,
        _InvoiceStatus.open          => AppColors.warning,
        _InvoiceStatus.voided        => AppColors.textTertiary,
        _InvoiceStatus.uncollectible => AppColors.danger,
        _InvoiceStatus.draft         => AppColors.info,
        _InvoiceStatus.unknown       => AppColors.textTertiary,
      };

  IconData get _icon => switch (status) {
        _InvoiceStatus.paid          => Icons.check_circle,
        _InvoiceStatus.open          => Icons.schedule,
        _InvoiceStatus.voided        => Icons.block,
        _InvoiceStatus.uncollectible => Icons.warning,
        _InvoiceStatus.draft         => Icons.edit,
        _InvoiceStatus.unknown       => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Semantics(
      label: 'Estado: ${_statusLabel(status)}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space8,
            vertical:   AppDimens.space2,
          ),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            border: Border.all(
              color: color.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                _statusLabel(status),
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Invoice expanded detail ───────────────────────────────────────────────────

class _InvoiceDetail extends StatelessWidget {
  const _InvoiceDetail({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColors.bgElevated01,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space24,
        vertical:   AppDimens.space12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'ID: ${invoice.id}',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (invoice.hostedUrl != null)
            Padding(
              padding: const EdgeInsets.only(left: AppDimens.space16),
              child: Text(
                'VER EN LÍNEA',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Skeleton list ─────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Real header (not skeleton) per spec §5.5
        _ColumnHeader(
          sortColumn:    _SortColumn.date,
          sortAscending: false,
          onSort:        (_) {},
        ),
        const HudDivider(),
        Expanded(
          child: ListView.separated(
            itemCount:        6,
            separatorBuilder: (_, __) =>
                Container(height: 1, color: AppColors.borderSubtle),
            itemBuilder: (_, __) => const _SkeletonRow(),
          ),
        ),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical:   AppDimens.space12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: _kChevronArea),
          // FECHA skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBase(width: 100, height: 13),
                SizedBox(height: AppDimens.space4),
                SkeletonBase(width: 140, height: 11),
              ],
            ),
          ),
          // MONTO skeleton
          SizedBox(
            width: _kColAmountWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: SkeletonBase(width: 68, height: 13),
            ),
          ),
          SizedBox(width: AppDimens.space8),
          // ESTADO skeleton (pill shape)
          SizedBox(
            width: _kColStatusWidth,
            child: Center(
              child: SkeletonBase(
                width:  72,
                height: 20,
                radius: AppDimens.radiusPill,
              ),
            ),
          ),
          // DOWNLOAD placeholder (no skeleton needed)
          SizedBox(width: _kColDownloadWidth),
        ],
      ),
    );
  }
}

// ─── Pagination footer ─────────────────────────────────────────────────────────

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width:  12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color:       AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          Text(
            'cargando…',
            style: AppTextStyles.mono.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Staggered entry animation ─────────────────────────────────────────────────

class _StaggeredEntry extends StatefulWidget {
  const _StaggeredEntry({required this.index, required this.child});

  final int    index;
  final Widget child;

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<double>   _slide;

  static const double _translateY = 12.0;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: AppMotion.durBase);
    _fade  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance),
    );
    _slide = Tween<double>(begin: _translateY, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance),
    );

    final delay = AppMotion.staggerDelay(widget.index);
    if (delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder:   (_, child) => Opacity(
        opacity: _fade.value,
        child:   Transform.translate(
          offset: Offset(0, _slide.value),
          child:  child,
        ),
      ),
      child: widget.child,
    );
  }
}
