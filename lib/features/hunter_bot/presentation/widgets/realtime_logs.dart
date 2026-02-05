// Archivo: lib/features/hunter_bot/presentation/widgets/realtime_logs.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/hunter_bot/domain/models/hunter_log.dart';
import 'package:botslode/features/hunter_bot/presentation/providers/hunter_logs_provider.dart';

/// Widget de logs en tiempo real con estilo terminal profesional
class RealtimeLogs extends ConsumerStatefulWidget {
  const RealtimeLogs({super.key});

  @override
  ConsumerState<RealtimeLogs> createState() => _RealtimeLogsState();
}

class _RealtimeLogsState extends ConsumerState<RealtimeLogs> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(hunterLogsProvider);
    
    // Auto-scroll cuando llegan nuevos logs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (logsState.autoScroll && _scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Scroll al inicio (logs más recientes arriba)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14), // Negro profundo tipo terminal
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.2),
          width: 1,
        ),
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
          // Header de terminal
          _buildTerminalHeader(logsState),
          
          // Filtros rápidos
          _buildFilters(logsState),
          
          // Lista de logs
          Expanded(
            child: logsState.isLoading
                ? _buildLoadingState()
                : logsState.filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : _buildLogsList(logsState),
          ),
          
          // Footer con stats
          _buildFooter(logsState),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader(HunterLogsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(
          bottom: BorderSide(color: AppColors.success.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          // Botones de ventana (estilo macOS)
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
          
          // Título
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  color: AppColors.success.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'HUNTER LOGS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'Oxanium',
                  ),
                ),
                const SizedBox(width: 8),
                // Indicador de conexión
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 500.ms)
                  .then()
                  .fadeOut(duration: 500.ms),
              ],
            ),
          ),
          
          // Botón de auto-scroll (seguir logs nuevos)
          IconButton(
            onPressed: () => ref.read(hunterLogsProvider.notifier).toggleAutoScroll(),
            tooltip: state.autoScroll ? 'Siguiendo logs nuevos' : 'Scroll libre',
            icon: Icon(
              state.autoScroll ? Icons.vertical_align_top : Icons.pause,
              size: 16,
              color: state.autoScroll ? AppColors.success : AppColors.textSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          
          // Botón de limpiar
          IconButton(
            onPressed: () => ref.read(hunterLogsProvider.notifier).clearLogs(),
            tooltip: 'Limpiar logs',
            icon: Icon(
              Icons.clear_all,
              size: 16,
              color: AppColors.textSecondary.withOpacity(0.6),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFilters(HunterLogsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: AppColors.borderGlass.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          _filterChip(
            'TODOS',
            state.logs.length,
            null,
            state.filterLevel == null,
          ),
          const SizedBox(width: 8),
          _filterChip(
            'INFO',
            state.countByLevel(LogLevel.info),
            LogLevel.info,
            state.filterLevel == LogLevel.info,
          ),
          const SizedBox(width: 8),
          _filterChip(
            'OK',
            state.countByLevel(LogLevel.success),
            LogLevel.success,
            state.filterLevel == LogLevel.success,
          ),
          const SizedBox(width: 8),
          _filterChip(
            'WARN',
            state.countByLevel(LogLevel.warning),
            LogLevel.warning,
            state.filterLevel == LogLevel.warning,
          ),
          const SizedBox(width: 8),
          _filterChip(
            'ERR',
            state.countByLevel(LogLevel.error),
            LogLevel.error,
            state.filterLevel == LogLevel.error,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int count, LogLevel? level, bool isActive) {
    final color = level?.color ?? AppColors.textSecondary;
    
    return InkWell(
      onTap: () => ref.read(hunterLogsProvider.notifier).setFilter(level),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? color.withOpacity(0.4) : Colors.transparent,
          ),
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
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oxanium',
                ),
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.success.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Conectando...',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 12,
              fontFamily: 'Oxanium',
            ),
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
          Icon(
            Icons.receipt_long,
            color: AppColors.success.withOpacity(0.2),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin actividad',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.4),
              fontSize: 14,
              fontFamily: 'Oxanium',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los logs aparecerán aquí en tiempo real',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.3),
              fontSize: 11,
              fontFamily: 'Oxanium',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(HunterLogsState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.filteredLogs.length,
      itemBuilder: (context, index) {
        final log = state.filteredLogs[index];
        final isNew = index < 3; // Los 3 más recientes tienen animación
        
        return _LogEntry(log: log, animate: isNew);
      },
    );
  }

  Widget _buildFooter(HunterLogsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
        border: Border(
          top: BorderSide(color: AppColors.success.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Prompt style
          Text(
            'hunter@botslode',
            style: TextStyle(
              color: AppColors.success.withOpacity(0.6),
              fontSize: 10,
              fontFamily: 'Oxanium',
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ':~\$ ',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.4),
              fontSize: 10,
              fontFamily: 'Oxanium',
            ),
          ),
          // Cursor parpadeante
          Container(
            width: 6,
            height: 12,
            color: AppColors.success,
          ).animate(onPlay: (c) => c.repeat())
            .fadeIn(duration: 500.ms)
            .then()
            .fadeOut(duration: 500.ms),
          
          const Spacer(),
          
          // Indicador de orden
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward,
                size: 10,
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
              const SizedBox(width: 2),
              Text(
                'nuevos',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  fontSize: 9,
                  fontFamily: 'Oxanium',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.filteredLogs.length} logs',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.4),
                  fontSize: 10,
                  fontFamily: 'Oxanium',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget individual de un log
class _LogEntry extends StatelessWidget {
  final HunterLog log;
  final bool animate;

  const _LogEntry({required this.log, required this.animate});

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: log.level.color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: log.level.color.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            log.formattedTime,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.4),
              fontSize: 10,
              fontFamily: 'Oxanium',
            ),
          ),
          const SizedBox(width: 8),
          
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: log.level.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              log.level.prefix,
              style: TextStyle(
                color: log.level.color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Icono de acción
          Icon(
            log.action.icon,
            color: log.level.color.withOpacity(0.6),
            size: 12,
          ),
          const SizedBox(width: 6),
          
          // Mensaje
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.85),
                fontSize: 12,
                fontFamily: 'Oxanium',
                height: 1.4,
              ),
            ),
          ),
          
          // Dominio (si es diferente al mensaje)
          if (log.domain.isNotEmpty && !log.message.contains(log.domain))
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                log.domain,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 10,
                  fontFamily: 'Oxanium',
                ),
              ),
            ),
        ],
      ),
    );

    // Animar solo los logs nuevos
    if (animate) {
      content = content
          .animate()
          .fadeIn(duration: 300.ms)
          .slideX(begin: -0.05, end: 0, duration: 300.ms, curve: Curves.easeOut);
    }

    return content;
  }
}
