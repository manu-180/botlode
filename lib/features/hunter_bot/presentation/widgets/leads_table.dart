// Archivo: lib/features/hunter_bot/presentation/widgets/leads_table.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/hunter_bot/domain/models/lead.dart';
import 'package:botslode/features/hunter_bot/presentation/providers/hunter_provider.dart';

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

const int _kLeadsPageSize = 100;

/// Tabla de leads con acciones y paginación (100 por página)
class LeadsTable extends ConsumerStatefulWidget {
  final List<Lead> leads;

  const LeadsTable({super.key, required this.leads});

  @override
  ConsumerState<LeadsTable> createState() => _LeadsTableState();
}

class _LeadsTableState extends ConsumerState<LeadsTable> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final leads = widget.leads;
    if (leads.isEmpty) {
      return _buildEmptyState();
    }

    final total = leads.length;
    final totalPages = (total / _kLeadsPageSize).ceil().clamp(1, 0x7FFFFFFF);
    final page = _page.clamp(0, totalPages - 1);
    final start = page * _kLeadsPageSize;
    final end = (start + _kLeadsPageSize).clamp(0, total);
    final pageLeads = leads.sublist(start, end);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: pageLeads.length,
              itemBuilder: (context, index) {
                return _LeadRow(
                  lead: pageLeads[index],
                  isEven: index % 2 == 0,
                );
              },
            ),
          ),
          _buildPagination(total: total, start: start, end: end, totalPages: totalPages, page: page),
        ],
      ),
    );
  }

  Widget _buildPagination({
    required int total,
    required int start,
    required int end,
    required int totalPages,
    required int page,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
        border: Border(top: BorderSide(color: AppColors.borderGlass)),
      ),
      child: Row(
        children: [
          Text(
            '${start + 1}-$end de $total',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 11,
              fontFamily: 'Oxanium',
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: page > 0
                    ? () => setState(() => _page = page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left, size: 20),
                color: page > 0 ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 8),
              Text(
                '${page + 1} / $totalPages',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.9),
                  fontSize: 11,
                  fontFamily: 'Oxanium',
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: page < totalPages - 1
                    ? () => setState(() => _page = page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 20),
                color: page < totalPages - 1 ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: _buildEmptyContent(),
    );
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: AppColors.textSecondary.withOpacity(0.3),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay leads todavía',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'Oxanium',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega dominios arriba para empezar',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.3),
              fontSize: 12,
              fontFamily: 'Oxanium',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(
          bottom: BorderSide(color: AppColors.borderGlass),
        ),
      ),
      child: Row(
        children: [
          _headerCell('EMAIL', flex: 4),
          _headerCell('ESTADO', flex: 2),
          _headerCell('FECHA', flex: 2, align: TextAlign.right),
          _headerCell('', flex: 1, align: TextAlign.center),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.6),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontFamily: 'Oxanium',
        ),
      ),
    );
  }
}

class _LeadRow extends ConsumerWidget {
  final Lead lead;
  final bool isEven;

  const _LeadRow({required this.lead, required this.isEven});

  /// Fecha a mostrar: enviado > actualizado > creado
  DateTime get _leadDate =>
      lead.sentAt ?? lead.updatedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.transparent : AppColors.background.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: AppColors.borderGlass.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // Email (solo email, sin dominio)
          Expanded(
            flex: 4,
            child: lead.email != null
                ? Text(
                    lead.email!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 13,
                      fontFamily: 'Oxanium',
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    lead.status == LeadStatus.failed
                        ? 'No encontrado'
                        : '-',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.4),
                      fontSize: 13,
                      fontFamily: 'Oxanium',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),

          // Estado
          Expanded(
            flex: 2,
            child: _buildStatusBadge(),
          ),

          // Fecha (fecha y hora en gris, como el Seeder)
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(_leadDate),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 11,
                fontFamily: 'Oxanium',
              ),
            ),
          ),

          // Copiar (con fecha en gris en lo que se copia) + acciones
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (lead.email != null)
                  IconButton(
                    onPressed: () => _copyEmailWithDate(context),
                    tooltip: 'Copiar email',
                    icon: const Icon(Icons.copy, size: 16),
                    color: AppColors.textSecondary.withOpacity(0.6),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                if (lead.status == LeadStatus.failed)
                  IconButton(
                    onPressed: () => ref.read(hunterProvider.notifier).retryLead(lead.id),
                    tooltip: 'Reintentar',
                    icon: const Icon(Icons.refresh, size: 16),
                    color: AppColors.warning,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                IconButton(
                  onPressed: () => _confirmDelete(context, ref),
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: AppColors.error.withOpacity(0.7),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: lead.status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: lead.status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(lead.status.icon, size: 12, color: lead.status.color),
          const SizedBox(width: 4),
          Text(
            lead.status.displayName,
            style: TextStyle(
              color: lead.status.color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oxanium',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) {
      return 'Hoy ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _copyEmailWithDate(BuildContext context) {
    final email = lead.email;
    if (email == null || email.isEmpty) return;
    final dateStr = _formatDate(_leadDate);
    final textToCopy = '$email\n$dateStr';
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontFamily: 'Oxanium', color: Colors.white),
            children: [
              const TextSpan(text: 'Copiado: '),
              TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(
                text: ' • $dateStr',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Shortcuts(
        shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
        child: Actions(
          actions: {
            _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) {
              ref.read(hunterProvider.notifier).deleteLead(lead.id);
              Navigator.pop(context);
              return null;
            }),
          },
          child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Eliminar lead',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Oxanium',
          ),
        ),
        content: Text(
          '¿Estás seguro de eliminar ${lead.domain}?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Oxanium',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(hunterProvider.notifier).deleteLead(lead.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
