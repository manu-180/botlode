// Archivo: lib/features/hunter_bot/presentation/widgets/leads_table.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/hunter_bot/domain/models/lead.dart';
import 'package:botslode/features/hunter_bot/presentation/providers/hunter_provider.dart';

/// Tabla de leads con acciones
class LeadsTable extends ConsumerWidget {
  final List<Lead> leads;

  const LeadsTable({super.key, required this.leads});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (leads.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Lista de leads
          Expanded(
            child: ListView.builder(
              itemCount: leads.length,
              itemBuilder: (context, index) {
                return _LeadRow(
                  lead: leads[index],
                  isEven: index % 2 == 0,
                );
              },
            ),
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
      child: Center(
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
          _headerCell('DOMINIO', flex: 3),
          _headerCell('EMAIL', flex: 3),
          _headerCell('ESTADO', flex: 2),
          _headerCell('ACCIONES', flex: 1, align: TextAlign.center),
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
          // Dominio
          Expanded(
            flex: 3,
            child: Text(
              lead.domain,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontFamily: 'Oxanium',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Email
          Expanded(
            flex: 3,
            child: lead.email != null
                ? InkWell(
                    onTap: () => _copyEmail(context, lead.email!),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lead.email!,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 13,
                              fontFamily: 'Oxanium',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy,
                          size: 12,
                          color: AppColors.success.withOpacity(0.5),
                        ),
                      ],
                    ),
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
          
          // Acciones
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email copiado: $email', style: const TextStyle(fontFamily: 'Oxanium')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
    );
  }
}
