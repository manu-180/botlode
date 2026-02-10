import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/seeder_bot/domain/models/seeder_log_entry.dart';
import 'package:botslode/features/seeder_bot/presentation/providers/seeder_logs_provider.dart';

/// Panel de logs del Seeder Bot (estilo terminal, como Hunter).
class SeederRealtimeLogs extends ConsumerStatefulWidget {
  const SeederRealtimeLogs({super.key});

  @override
  ConsumerState<SeederRealtimeLogs> createState() => _SeederRealtimeLogsState();
}

class _SeederRealtimeLogsState extends ConsumerState<SeederRealtimeLogs> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(seederLogsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (logsState.autoScroll && _scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTerminalHeader(logsState),
          _buildFilters(logsState),
          Expanded(
            child: logsState.isLoading
                ? _buildLoadingState()
                : logsState.filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : _buildLogsList(logsState),
          ),
          _buildFooter(logsState),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader(SeederLogsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(bottom: BorderSide(color: AppColors.success.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Row(
            children: [
              _windowButton(AppColors.error),
              const SizedBox(width: 6),
              _windowButton(AppColors.warning),
              const SizedBox(width: 6),
              _windowButton(AppColors.success),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.terminal, color: AppColors.success.withOpacity(0.7), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'SEEDER LOGS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'Oxanium',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)],
                  ),
                ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 500.ms).then().fadeOut(duration: 500.ms),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(seederLogsProvider.notifier).toggleAutoScroll(),
            tooltip: state.autoScroll ? 'Siguiendo logs' : 'Scroll libre',
            icon: Icon(
              state.autoScroll ? Icons.vertical_align_top : Icons.pause,
              size: 16,
              color: state.autoScroll ? AppColors.success : AppColors.textSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _windowButton(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color.withOpacity(0.8), shape: BoxShape.circle),
    );
  }

  Widget _buildFilters(SeederLogsState state) {
    final okCount = state.logs.where((e) => e.isOk).length;
    final errCount = state.logs.where((e) => !e.isOk).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withOpacity(0.5),
        border: Border(bottom: BorderSide(color: AppColors.borderGlass.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          _filterChip('TODOS', state.logs.length, SeederLogFilter.all, state.filter == SeederLogFilter.all),
          const SizedBox(width: 8),
          _filterChip('OK', okCount, SeederLogFilter.ok, state.filter == SeederLogFilter.ok),
          const SizedBox(width: 8),
          _filterChip('ERR', errCount, SeederLogFilter.error, state.filter == SeederLogFilter.error),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int count, SeederLogFilter filter, bool isActive) {
    final color = filter == SeederLogFilter.error
        ? AppColors.error
        : filter == SeederLogFilter.ok
            ? AppColors.success
            : AppColors.textSecondary;
    return InkWell(
      onTap: () => ref.read(seederLogsProvider.notifier).setFilter(filter),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isActive ? color.withOpacity(0.4) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : AppColors.textSecondary.withOpacity(0.5),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(3)),
              child: Text(
                count.toString(),
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Oxanium'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success.withOpacity(0.5)),
          ),
          const SizedBox(height: 12),
          Text(
            'Conectando...',
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 12, fontFamily: 'Oxanium'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, color: AppColors.success.withOpacity(0.2), size: 48),
          const SizedBox(height: 16),
          Text(
            'Sin actividad',
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 14, fontFamily: 'Oxanium'),
          ),
          const SizedBox(height: 8),
          Text(
            'Los envíos a directorios aparecerán aquí',
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.3), fontSize: 11, fontFamily: 'Oxanium'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(SeederLogsState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.filteredLogs.length,
      itemBuilder: (context, index) {
        final entry = state.filteredLogs[index];
        final isNew = index < 3;
        return _LogEntryWidget(entry: entry, animate: isNew);
      },
    );
  }

  Widget _buildFooter(SeederLogsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
        border: Border(top: BorderSide(color: AppColors.success.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Text(
            'seeder@botslode',
            style: TextStyle(color: AppColors.success.withOpacity(0.6), fontSize: 10, fontFamily: 'Oxanium', fontWeight: FontWeight.bold),
          ),
          Text(
            ':~\$ ',
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 10, fontFamily: 'Oxanium'),
          ),
          Container(width: 6, height: 12, color: AppColors.success)
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 500.ms)
              .then()
              .fadeOut(duration: 500.ms),
          const Spacer(),
          Text(
            '${state.filteredLogs.length} logs',
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 10, fontFamily: 'Oxanium'),
          ),
        ],
      ),
    );
  }
}

class _LogEntryWidget extends StatelessWidget {
  final SeederLogEntry entry;
  final bool animate;

  const _LogEntryWidget({required this.entry, required this.animate});

  @override
  Widget build(BuildContext context) {
    final color = entry.isOk ? AppColors.success : AppColors.error;
    final time = _formatTime(entry.submittedAt);
    Widget content = Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: color.withOpacity(0.5), width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 10, fontFamily: 'Oxanium'),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(2)),
            child: Text(
              entry.status.toUpperCase(),
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Oxanium'),
            ),
          ),
          const SizedBox(width: 8),
          Icon(entry.isOk ? Icons.check_circle : Icons.error, color: color.withOpacity(0.6), size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.targetName ?? entry.url ?? entry.targetId,
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.85),
                    fontSize: 12,
                    fontFamily: 'Oxanium',
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.errorMessage != null && entry.errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.errorMessage!,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 10,
                      fontFamily: 'Oxanium',
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (animate) {
      content = content.animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0, duration: 300.ms, curve: Curves.easeOut);
    }
    return content;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
