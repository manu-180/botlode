// Archivo: lib/features/hunter_bot/presentation/views/hunter_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/hunter_bot/presentation/providers/hunter_provider.dart';
import 'package:botslode/features/hunter_bot/presentation/widgets/config_panel.dart';
import 'package:botslode/features/hunter_bot/presentation/widgets/bot_control_button.dart';
import 'package:botslode/features/hunter_bot/presentation/widgets/help_button.dart';
import 'package:botslode/features/hunter_bot/presentation/widgets/realtime_logs.dart';
import 'package:botslode/features/hunter_bot/presentation/widgets/leads_table.dart';

class HunterView extends ConsumerStatefulWidget {
  static const String routeName = 'hunter';
  
  const HunterView({super.key});

  @override
  ConsumerState<HunterView> createState() => _HunterViewState();
}

class _HunterViewState extends ConsumerState<HunterView> with SingleTickerProviderStateMixin {
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
    final hunterState = ref.watch(hunterProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: hunterState.isLoading 
          ? _buildLoadingState()
          : _buildContent(hunterState),
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
            'Inicializando Hunter Bot...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Oxanium',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(HunterState state) {
    return Column(
      children: [
        // HEADER
        _buildHeader(state),
        
        // CONTENIDO PRINCIPAL
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final padding = isNarrow ? 16.0 : 24.0;
              
              if (isNarrow) {
                // Layout vertical con tabs para pantallas pequeñas
                return _buildNarrowLayout(state, padding);
              }
              
              // Layout horizontal para pantallas grandes
              return _buildWideLayout(state, padding);
            },
          ),
        ),
      ],
    );
  }
  
  /// Layout para pantallas anchas (dos columnas).
  /// Izquierda con más peso para stats y tabla; logs más estrecho pero legible.
  Widget _buildWideLayout(HunterState state, double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PANEL IZQUIERDO (Control del Bot + Stats + Tabla) — más terreno
          Expanded(
            flex: 5,
            child: Column(
              children: [
                const BotControlButton(),
                const SizedBox(height: 16),
                _buildStatsPanel(state),
                const SizedBox(height: 16),
                Expanded(
                  child: LeadsTable(leads: state.leads),
                ),
              ],
            ),
          ),
          
          SizedBox(width: padding),
          
          // PANEL DERECHO (Logs) — más flaco, suficiente para leer
          const Expanded(
            flex: 3,
            child: RealtimeLogs(),
          ),
        ],
      ),
    );
  }
  
  /// Layout para pantallas angostas (tabs)
  Widget _buildNarrowLayout(HunterState state, double padding) {
    return Column(
      children: [
        // Tabs
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.success,
            labelColor: AppColors.success,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontFamily: 'Oxanium',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            tabs: const [
              Tab(text: 'LEADS'),
              Tab(text: 'LOGS'),
            ],
          ),
        ),
        
        // Contenido de tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Leads
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    const BotControlButton(),
                    const SizedBox(height: 12),
                    _buildStatsPanel(state),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LeadsTable(leads: state.leads),
                    ),
                  ],
                ),
              ),
              // Tab 2: Logs
              Padding(
                padding: EdgeInsets.all(padding),
                child: const RealtimeLogs(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader(HunterState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 24, 
            vertical: isNarrow ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.success.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Título con icono
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isNarrow ? 8 : 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.crosshairs,
                      color: AppColors.success,
                      size: isNarrow ? 16 : 20,
                    ),
                  ),
                  SizedBox(width: isNarrow ? 10 : 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HUNTER BOT',
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
                          state.isConfigured 
                              ? 'Listo para cazar' 
                              : 'Configura Resend',
                          style: TextStyle(
                            color: state.isConfigured 
                                ? AppColors.success 
                                : AppColors.warning,
                            fontSize: 11,
                            fontFamily: 'Oxanium',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Botones de acción
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de configuración (solo en pantallas grandes)
                  if (!state.isConfigured && !isNarrow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.warning, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'SIN CONFIG',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Oxanium',
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Botón de ayuda (solo en pantallas grandes)
                  if (!isNarrow) ...[
                    const HelpButton(),
                    const SizedBox(width: 6),
                  ],
                  
                  // Botón de configuración
                  IconButton(
                    onPressed: () => _showConfigPanel(),
                    tooltip: 'Configuración de Resend',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    style: IconButton.styleFrom(
                      backgroundColor: !state.isConfigured 
                          ? AppColors.warning.withOpacity(0.1) 
                          : AppColors.glassSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: !state.isConfigured 
                              ? AppColors.warning.withOpacity(0.3) 
                              : AppColors.borderGlass,
                        ),
                      ),
                    ),
                    icon: Icon(
                      Icons.settings,
                      color: !state.isConfigured 
                          ? AppColors.warning 
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  // Botón de refresh
                  IconButton(
                    onPressed: () => ref.read(hunterProvider.notifier).refresh(),
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
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatsPanel(HunterState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Evitar constraints inválidos (ancho 0 o negativo)
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 400.0;
        // Si el ancho es menor a 500px, usar layout compacto (2x2 + 1)
        if (maxW < 500) {
          return Column(
            children: [
              Row(
                children: [
                  _buildStatCardCompact('TOTAL', state.totalCount.toString(), Icons.list_alt, AppColors.textSecondary),
                  const SizedBox(width: 8),
                  _buildStatCardCompact('PEND', state.pendingCount.toString(), Icons.schedule, AppColors.warning),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatCardCompact('Repetidos', state.otherCount.toString(), Icons.search, AppColors.primary),
                  const SizedBox(width: 8),
                  _buildStatCardCompact('FAIL', state.failedCount.toString(), Icons.error_outline, AppColors.error),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatCardCompact('ENVÍO', state.sentCount.toString(), Icons.done_all, AppColors.success),
                ],
              ),
            ],
          );
        }
        
        // Layout normal: todas las cards con el mismo ancho (flex: 1).
        // Solo limitamos maxWidth para no forzar mínimo y evitar constraints inválidos.
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Row(
            children: [
              _buildStatCard('TOTAL', state.totalCount.toString(), Icons.list_alt, AppColors.textSecondary, flex: 1),
            const SizedBox(width: 8),
            _buildStatCard('PEND', state.pendingCount.toString(), Icons.schedule, AppColors.warning, flex: 1),
            const SizedBox(width: 8),
            _buildStatCard('Repetidos', state.otherCount.toString(), Icons.search, AppColors.primary, flex: 1, tooltip: 'En cola, escaneando o enviando'),
            const SizedBox(width: 8),
            _buildStatCard('FAIL', state.failedCount.toString(), Icons.error_outline, AppColors.error, flex: 1),
            const SizedBox(width: 8),
            _buildStatCard('ENVÍO', state.sentCount.toString(), Icons.done_all, AppColors.success, flex: 1),
            ],
          ),
        );
      },
    );
  }
  
  /// Stat card compacta (layout vertical, para pantallas pequeñas)
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
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                fontFamily: 'Oxanium',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Stat card normal: mismo tamaño para todas (flex). Sin width infinito para evitar BoxConstraints inválidos.
  /// Tooltip va DENTRO del Expanded para que Expanded sea siempre hijo directo del Row (evita ParentDataWidget).
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
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                  ),
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
      child: tooltip != null
          ? Tooltip(message: tooltip, child: content)
          : content,
    );
  }
  
  void _showConfigPanel() {
    showDialog(
      context: context,
      builder: (context) => const ConfigPanel(),
    );
  }
}
