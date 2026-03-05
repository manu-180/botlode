// Archivo: lib/features/seeder_bot/presentation/widgets/seeder_submitted_urls_table.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/seeder_bot/domain/constants/seeder_constants.dart';
import 'package:botslode/features/seeder_bot/domain/models/seeder_log_entry.dart';
import 'package:botslode/features/seeder_bot/presentation/providers/seeder_logs_provider.dart';

/// Info agrupada por URL: cuántos envíos OK de los máximos posibles por target (bot + factory + perfiles extra).
class _SubmittedUrlInfo {
  final String url;
  final String targetName;
  final DateTime submittedAt;
  final int okCount; // Número real de envíos OK para este target (máx. seederMaxProfilesPerTarget)

  const _SubmittedUrlInfo({
    required this.url,
    required this.targetName,
    required this.submittedAt,
    required this.okCount,
  });
}

const int _kSeederPageSize = 100;

/// Tabla de URLs exitosamente enviadas (mismo estilo que LeadsTable en Hunter).
/// Muestra X/max envíos OK por target (ej. 3/8, 8/8 cuando están todos los perfiles).
/// Paginación: 100 por página.
class SeederSubmittedUrlsTable extends ConsumerStatefulWidget {
  const SeederSubmittedUrlsTable({super.key});

  @override
  ConsumerState<SeederSubmittedUrlsTable> createState() => _SeederSubmittedUrlsTableState();
}

class _SeederSubmittedUrlsTableState extends ConsumerState<SeederSubmittedUrlsTable> {
  int _page = 0;

  /// Agrupa logs OK por target_id: cuenta cuántos envíos OK hay por target (bot, factory, apex, etc.).
  static List<_SubmittedUrlInfo> _getGroupedOkUrls(List<SeederLogEntry> logs) {
    final okLogs = logs.where((e) => e.isOk).toList();
    okLogs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    final byTarget = <String, List<SeederLogEntry>>{};
    for (final e in okLogs) {
      final key = e.targetId.isNotEmpty ? e.targetId : (e.url ?? e.targetName ?? e.targetId);
      if (key.isEmpty) continue;
      byTarget.putIfAbsent(key, () => []).add(e);
    }

    final result = <_SubmittedUrlInfo>[];
    for (final entries in byTarget.values) {
      if (entries.isEmpty) continue;
      final first = entries.first;
      final url = first.url ?? first.targetName ?? first.targetId;
      if (url.isEmpty) continue;
      result.add(_SubmittedUrlInfo(
        url: url,
        targetName: first.targetName ?? url,
        submittedAt: first.submittedAt,
        okCount: entries.length,
      ));
    }
    result.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final logsState = ref.watch(seederLogsProvider);
    final submittedUrls = _getGroupedOkUrls(logsState.logs);

    if (submittedUrls.isEmpty) {
      return _buildEmptyState();
    }

    final total = submittedUrls.length;
    final totalPages = (total / _kSeederPageSize).ceil().clamp(1, 0x7FFFFFFF);
    final page = _page.clamp(0, totalPages - 1);
    final start = page * _kSeederPageSize;
    final end = (start + _kSeederPageSize).clamp(0, total);
    final pageUrls = submittedUrls.sublist(start, end);

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
              itemCount: pageUrls.length,
              itemBuilder: (context, index) {
                return _SubmittedUrlRow(
                  info: pageUrls[index],
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
                onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
                icon: const Icon(Icons.chevron_left, size: 20),
                color: page > 0 ? AppColors.success : AppColors.textSecondary.withOpacity(0.3),
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
                onPressed: page < totalPages - 1 ? () => setState(() => _page = page + 1) : null,
                icon: const Icon(Icons.chevron_right, size: 20),
                color: page < totalPages - 1 ? AppColors.success : AppColors.textSecondary.withOpacity(0.3),
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.success.withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no hay envíos exitosos',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'Oxanium',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los directorios enviados aparecerán aquí',
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
          _headerCell('URL ENVIADA', flex: 7),
          _headerCell('ENVÍOS', flex: 1),
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

class _SubmittedUrlRow extends StatelessWidget {
  final _SubmittedUrlInfo info;
  final bool isEven;

  const _SubmittedUrlRow({required this.info, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final maxTotal = seederMaxProfilesPerTarget;
    final isFull = info.okCount >= maxTotal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven ? Colors.transparent : AppColors.background.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: AppColors.borderGlass.withOpacity(0.5)),
        ),
        boxShadow: isFull
            ? [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.08),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // URL + indicador (solo el botón gris del final copia la URL)
          Expanded(
            flex: 7,
            child: Row(
              children: [
                _buildSubmissionBadge(isFull),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    info.url,
                    style: TextStyle(
                      color: isFull ? AppColors.success : AppColors.success.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: isFull ? FontWeight.w600 : FontWeight.normal,
                      fontFamily: 'Oxanium',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Envíos (compacto: X/max)
          Expanded(
            flex: 1,
            child: _buildCountBadge(isFull),
          ),

          // Fecha (alineada a la derecha para usar el espacio vacío)
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(info.submittedAt),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 11,
                fontFamily: 'Oxanium',
              ),
            ),
          ),

          // Botón copiar
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: () => _copyUrl(context),
              tooltip: 'Copiar URL',
              icon: const Icon(Icons.copy, size: 16),
              color: AppColors.textSecondary.withOpacity(0.6),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionBadge(bool isFull) {
    if (isFull) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success,
              AppColors.primary.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.4),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const FaIcon(
          FontAwesomeIcons.checkDouble,
          color: Colors.white,
          size: 12,
        ),
      );
    }
    return Icon(
      Icons.check_circle,
      size: 18,
      color: AppColors.success.withOpacity(0.85),
    );
  }

  Widget _buildCountBadge(bool isFull) {
    final maxTotal = seederMaxProfilesPerTarget;
    final text = '${info.okCount}/$maxTotal';
    if (isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.success, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
    return Tooltip(
      message: '${info.okCount} de $maxTotal envíos (bot, fábrica, perfiles extra)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.success.withOpacity(0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.success.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'Oxanium',
          ),
        ),
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

  void _copyUrl(BuildContext context) {
    final url = info.url;
    if (url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'URL copiada: $url',
          style: const TextStyle(fontFamily: 'Oxanium'),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
