import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/seeder_bot/presentation/providers/seeder_provider.dart';
import 'package:botslode/features/seeder_bot/presentation/widgets/seeder_bot_control_button.dart';
import 'package:botslode/features/seeder_bot/presentation/widgets/seeder_realtime_logs.dart';

class SeederView extends ConsumerStatefulWidget {
  static const String routeName = 'seeder';

  const SeederView({super.key});

  @override
  ConsumerState<SeederView> createState() => _SeederViewState();
}

class _SeederViewState extends ConsumerState<SeederView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seederState = ref.watch(seederProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: seederState.isLoading ? _buildLoadingState() : _buildContent(seederState),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.success),
          SizedBox(height: 16),
          Text(
            'Inicializando Seeder Bot...',
            style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Oxanium'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SeederState state) {
    if (!state.hasAccess) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Inicia sesión para usar Seeder Bot',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontFamily: 'Oxanium'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        _buildHeader(state),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final padding = isNarrow ? 16.0 : 24.0;
              if (isNarrow) return _buildNarrowLayout(state, padding);
              return _buildWideLayout(state, padding);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(SeederState state, double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                const SeederBotControlButton(),
                const SizedBox(height: 16),
                _buildStatsPanel(state),
              ],
            ),
          ),
          SizedBox(width: padding),
          const Expanded(flex: 3, child: SeederRealtimeLogs()),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(SeederState state, double padding) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.success,
            labelColor: AppColors.success,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontFamily: 'Oxanium', fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [Tab(text: 'RESUMEN'), Tab(text: 'LOGS')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    const SeederBotControlButton(),
                    const SizedBox(height: 12),
                    _buildStatsPanel(state),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: const SeederRealtimeLogs(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(SeederState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 24, vertical: isNarrow ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.success.withOpacity(0.2), width: 1)),
          ),
          child: Row(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isNarrow ? 8 : 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: FaIcon(FontAwesomeIcons.seedling, color: AppColors.success, size: isNarrow ? 16 : 20),
                  ),
                  SizedBox(width: isNarrow ? 10 : 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEEDER BOT',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: isNarrow ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Oxanium',
                          letterSpacing: 2,
                        ),
                      ),
                      if (!isNarrow)
                        Text(
                          state.botEnabled ? 'Llenando formularios en directorios' : 'Pausado',
                          style: TextStyle(
                            color: state.botEnabled ? AppColors.success : AppColors.textSecondary,
                            fontSize: 11,
                            fontFamily: 'Oxanium',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => ref.read(seederProvider.notifier).refresh(),
                tooltip: 'Refrescar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.glassSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.borderGlass),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsPanel(SeederState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0 ? constraints.maxWidth : 400.0;
        if (maxW < 500) {
          return Column(
            children: [
              Row(
                children: [
                  _buildStatCardCompact('OK', state.okCount.toString(), Icons.done_all, AppColors.success),
                  const SizedBox(width: 8),
                  _buildStatCardCompact('FAIL', state.errorCount.toString(), Icons.error_outline, AppColors.error),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatCardCompact('TOTAL', state.totalLogs.toString(), Icons.list_alt, AppColors.textSecondary),
                  const SizedBox(width: 8),
                  _buildStatCardCompact('PEND', state.pendingTargets.toString(), Icons.schedule, AppColors.warning),
                ],
              ),
            ],
          );
        }
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Row(
            children: [
              _buildStatCard('OK', state.okCount.toString(), Icons.done_all, AppColors.success, flex: 1),
              const SizedBox(width: 8),
              _buildStatCard('FAIL', state.errorCount.toString(), Icons.error_outline, AppColors.error, flex: 1),
              const SizedBox(width: 8),
              _buildStatCard('TOTAL', state.totalLogs.toString(), Icons.list_alt, AppColors.textSecondary, flex: 1),
              const SizedBox(width: 8),
              _buildStatCard('PEND', state.pendingTargets.toString(), Icons.schedule, AppColors.warning, flex: 1),
              const SizedBox(width: 8),
              _buildStatCard('ENVIADOS', state.submittedTargets.toString(), Icons.check_circle, AppColors.primary, flex: 1, tooltip: 'Targets con envío exitoso'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCardCompact(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Oxanium'),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w600, fontFamily: 'Oxanium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {String? tooltip, int flex = 1}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Oxanium'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontFamily: 'Oxanium',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    return Expanded(
      flex: flex,
      child: tooltip != null ? Tooltip(message: tooltip, child: content) : content,
    );
  }
}
