import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:botslode/core/config/restricted_bots_config.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/shared_whatsapp_limit_provider.dart';
import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/core/providers/whatsapp_auto_queue_provider.dart';
import 'package:botslode/core/services/whatsapp_api_service.dart';
import 'package:botslode/core/serpapi/serpapi_keys_card.dart';
import 'package:botslode/features/assistify_leads/domain/models/assistify_lead.dart';
import 'package:botslode/features/assistify_leads/presentation/providers/assistify_leads_provider.dart';

class AssistifyLeadsView extends ConsumerWidget {
  static const String routeName = 'assistify';

  const AssistifyLeadsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final hasAccess = RestrictedBotsConfig.canUserSeeRestrictedBots(userId);

    if (!hasAccess) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Acceso restringido',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontFamily: 'Oxanium',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, ref),
          const Expanded(child: _AssistifyList()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const FaIcon(
              FontAwesomeIcons.whatsapp,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'ASSISTIFY',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oxanium',
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Clic en fila → API Twilio | fallback WhatsApp Web',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontFamily: 'Oxanium',
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AssistifyAutoEnviarButton(),
                  const SizedBox(width: 12),
                  const _AssistifyWhatsAppLimitPanel(),
                  const SizedBox(width: 16),
                  const SerpApiKeysCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistifyWhatsAppLimitPanel extends ConsumerStatefulWidget {
  const _AssistifyWhatsAppLimitPanel();

  @override
  ConsumerState<_AssistifyWhatsAppLimitPanel> createState() => _AssistifyWhatsAppLimitPanelState();
}

class _AssistifyWhatsAppLimitPanelState extends ConsumerState<_AssistifyWhatsAppLimitPanel> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(assistifyWhatsAppLimitProvider.notifier).checkReset();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(assistifyWhatsAppLimitProvider);
    final now = DateTime.now();
    final cooldownSec = s.cooldownRemainingSeconds(now);
    final opensHour = s.opensInLastHour(now);
    final dailyLimitReached = s.isDailyLimitReached(now);
    final hourLimitReached = opensHour >= WhatsAppLimitState.maxOpensPerHour;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: 'Cooldown 5 min entre envíos · Máx 20 aperturas en los últimos 60 min',
            child: Text(
              'Límites WhatsApp',
              style: TextStyle(
                fontFamily: 'Oxanium',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildChip(
                'Cooldown',
                cooldownSec > 0 ? '${cooldownSec ~/ 60}:${(cooldownSec % 60).toString().padLeft(2, '0')}' : 'Listo',
                cooldownSec > 0,
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Máx 20 en los últimos 60 min. Cada apertura deja de contar 1 h después (ventana deslizante).',
                child: _buildChip(
                  'Aperturas/hora',
                  '$opensHour/${WhatsAppLimitState.maxOpensPerHour}',
                  hourLimitReached,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Máx ${WhatsAppLimitState.maxDailyOpens} envíos por día. Se reinicia a las 0:00.',
                child: _buildChip(
                  'Hoy',
                  '${s.dailyCount}/${WhatsAppLimitState.maxDailyOpens} por día',
                  dailyLimitReached,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, bool isWarning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.error.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isWarning ? AppColors.error.withValues(alpha: 0.4) : AppColors.borderGlass,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'Oxanium',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Oxanium',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isWarning ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

const int _kPageSize = 100;

/// Construye la URL de wa.me con el mensaje del template correspondiente al índice.
String _assistifyWhatsAppUrlWithMessage(String baseUrl, String nombre, int messageIndex) {
  return _AssistifyListState._whatsappUrlWithMessage(baseUrl, nombre, messageIndex);
}

class _AssistifyList extends ConsumerStatefulWidget {
  const _AssistifyList();

  @override
  ConsumerState<_AssistifyList> createState() => _AssistifyListState();
}

class _AssistifyListState extends ConsumerState<_AssistifyList> {
  int _page = 0;
  final ScrollController _horizontalScroll = ScrollController();
  Timer? _autoRefreshTimer;

  static const _autoRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (mounted) ref.invalidate(assistifyLeadsListProvider);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final listAsync = ref.watch(assistifyLeadsListProvider);
    final contactedIds = ref.watch(assistifyContactadasProvider);

    return listAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $e',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (leads) {
        if (leads.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay leads Assistify aún',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontFamily: 'Oxanium',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El Seeder Bot irá cargando negocios (clases de cerámica, gimnasios, etc.)',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontFamily: 'Oxanium',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final sorted = List<AssistifyLead>.from(leads)
          ..sort((a, b) {
            final aContacted = contactedIds.contains(a.id);
            final bContacted = contactedIds.contains(b.id);
            if (aContacted == bContacted) return 0;
            return aContacted ? 1 : -1;
          });

        final total = sorted.length;
        final totalPages = (total / _kPageSize).ceil().clamp(1, 0x7FFFFFFF);
        final page = _page.clamp(0, totalPages - 1);
        final start = page * _kPageSize;
        final end = (start + _kPageSize).clamp(0, total);
        final pageRows = sorted.sublist(start, end);
        final limitState = ref.watch(assistifyWhatsAppLimitProvider);
        final pending = leads.where((e) => !contactedIds.contains(e.id)).length;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGlass),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _WppStatCards(
                  pending: pending,
                  hoy: limitState.dailyCount,
                  failed: limitState.assistifyTotalFailed,
                  sent: limitState.assistifyTotalSent,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final minTableWidth = (constraints.maxWidth - 32).clamp(1000.0, 1800.0);
                      return Scrollbar(
                        controller: _horizontalScroll,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalScroll,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 24),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 24, top: 12, bottom: 12),
                              child: SizedBox(
                                width: minTableWidth,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      AppColors.primary.withValues(alpha: 0.15),
                                    ),
                                    border: TableBorder.all(color: AppColors.borderGlass.withOpacity(0.6)),
                                    columnSpacing: 24,
                                    horizontalMargin: 16,
                                    columns: [
                                      _dataColumn('Nombre'),
                                      _dataColumn('Teléfono'),
                                      _dataColumn('Ciudad'),
                                      _dataColumn('País'),
                                      _dataColumn('Dirección'),
                                      _dataColumn('Rubro'),
                                      _dataColumn('Origen'),
                                      _dataColumn('Fecha'),
                                    ],
                                    rows: pageRows
                                        .map((e) => _buildRow(context, ref, e, contactedIds))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildPagination(total: total, start: start, end: end, totalPages: totalPages, page: page),
              ],
            ),
          ),
        );
      },
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
                onPressed: page < totalPages - 1 ? () => setState(() => _page = page + 1) : null,
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

  DataColumn _dataColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          fontFamily: 'Oxanium',
        ),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    AssistifyLead e,
    Set<String> contactedIds,
  ) {
    final wasContacted = contactedIds.contains(e.id);
    final rowId = e.id;
    final rowNombre = e.nombre;
    final rowWhatsappUrl = e.whatsappUrl;
    final rowTelefono = e.telefono;

    TextStyle cellStyle(bool contacted) => TextStyle(
          color: contacted ? AppColors.success.withValues(alpha: 0.9) : AppColors.textSecondary,
          fontSize: 12,
          fontFamily: 'Oxanium',
        );

    return DataRow(
      key: ValueKey(e.id),
      color: WidgetStateProperty.resolveWith((_) {
        if (wasContacted) return AppColors.success.withValues(alpha: 0.08);
        return null;
      }),
      cells: [
        DataCell(
          SizedBox(
            width: 220,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (e.hasWhatsapp)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.chat, color: AppColors.success, size: 16),
                  ),
                Flexible(
                  child: Text(
                    e.nombre,
                    style: TextStyle(
                      color: wasContacted ? AppColors.success.withValues(alpha: 0.9) : AppColors.textPrimary,
                      fontWeight: wasContacted ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(e.telefono ?? '—', style: cellStyle(wasContacted))),
        DataCell(Text(e.ciudad, style: cellStyle(wasContacted))),
        DataCell(Text(e.pais, style: cellStyle(wasContacted))),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              e.direccion ?? '—',
              style: cellStyle(wasContacted),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        DataCell(Text(e.rubro, style: cellStyle(wasContacted))),
        DataCell(
          Chip(
            label: Text(
              e.source.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            backgroundColor: AppColors.success.withValues(alpha: 0.2),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        DataCell(Text(
          _formatDate(e.createdAt),
          style: cellStyle(wasContacted),
        )),
      ],
      onSelectChanged: (rowWhatsappUrl != null && rowTelefono != null)
          ? (_) => _openWhatsApp(context, ref, id: rowId, nombre: rowNombre, telefono: rowTelefono, baseUrl: rowWhatsappUrl)
          : null,
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static const List<String> _whatsappMessageTemplates = [
    r'''Hola, soy Manuel. Te escribo por Assistify, una app que armé para que tus alumnas puedan cancelar clases y recuperarlas sin tener que hablarte a cada rato (ideal para talleres, gimnasios, clases de cerámica, idiomas, etc.).
Si te interesa probarla con tu taller/estudio, te paso el link para descargarla. Es gratuita.
¿Te gustaría que te cuente cómo funciona?''',
    r'''Hola, Manuel. Assistify es una app que hice para que tus alumnas cancelen y recuperen clases sin hablarte todo el tiempo (ideal para talleres, gimnasios, cerámica, idiomas).
Si te interesa probarla con {{NOMBRE}}, te paso el link. Es gratuita.
¿Te cuento cómo funciona?''',
    r'''Hola, soy Manuel. Te contacto por Assistify: una app para que las alumnas cancelen y recuperen clases sin molestarte (talleres, gimnasios, cerámica, idiomas, etc.).
Si querés probarla con tu negocio, te paso el link. Gratuita.
¿Te explico cómo va?''',
    r'''Hola, Manuel. Assistify es una app para que tus alumnas puedan cancelar y recuperar clases sin hablarte a cada rato. Ideal para talleres, gimnasios, cerámica, idiomas.
Te paso el link si te interesa. Es gratuita.
¿Te cuento cómo funciona?''',
    r'''Hola, soy Manuel. Armé Assistify para que tus alumnas cancelen clases y las recuperen sin tener que hablarte todo el tiempo (talleres, gimnasios, cerámica, idiomas).
Si te interesa probarla, te paso el link. Gratis.
¿Te explico cómo es?''',
  ];

  static String _whatsappUrlWithMessage(String baseUrl, String nombreEmpresa, int messageIndex) {
    final template = _whatsappMessageTemplates[messageIndex % _whatsappMessageTemplates.length];
    final message = template.replaceAll('{{NOMBRE}}', nombreEmpresa.trim().isNotEmpty ? nombreEmpresa : 'tu negocio');
    final uri = Uri.parse(baseUrl);
    final withText = uri.replace(queryParameters: {'text': message});
    return withText.toString();
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    WidgetRef ref, {
    required String id,
    required String nombre,
    required String telefono,
    required String baseUrl,
  }) async {
    final notifier = ref.read(assistifyWhatsAppLimitProvider.notifier);
    notifier.checkReset();
    final reason = notifier.cannotOpenReason(DateTime.now());
    if (reason != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final limitState = ref.read(assistifyWhatsAppLimitProvider);
    final messageIndex = limitState.messageIndex;
    final wppService = ref.read(whatsAppApiServiceProvider);

    // Intentar envío vía API Twilio primero.
    final sid = await wppService.getContentSid('assistify', messageIndex);
    final result = await wppService.sendToContact(
      telefono: telefono,
      nombre: nombre,
      contentSid: sid ?? '',
      feature: 'assistify',
    );

    if (result == WhatsAppSendResult.sent) {
      notifier.recordOpen(feature: 'assistify');
      notifier.advanceMessageIndex();
      ref.read(assistifyContactadasProvider.notifier).markAsContacted(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mensaje enviado a $nombre via API'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Fallback: abrir WhatsApp Web con el mensaje pre-escrito.
    final url = _whatsappUrlWithMessage(baseUrl, nombre, messageIndex);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      notifier.recordOpen(feature: 'assistify');
      notifier.advanceMessageIndex();
      ref.read(assistifyContactadasProvider.notifier).markAsContacted(id);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Botón Auto-Enviar para Assistify
// ---------------------------------------------------------------------------

class _AssistifyAutoEnviarButton extends ConsumerWidget {
  const _AssistifyAutoEnviarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(assistifyAutoQueueProvider);
    final isRunning = queueState.isRunning;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRunning || queueState.sent > 0 || queueState.failed > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderGlass),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (queueState.processingName != null)
                  Text(
                    'Enviando: ${queueState.processingName}',
                    style: TextStyle(color: AppColors.primary, fontSize: 10, fontFamily: 'Oxanium'),
                  ),
                if (queueState.statusMessage != null)
                  Text(
                    queueState.statusMessage!,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'Oxanium'),
                  ),
                Text(
                  '${queueState.sent} enviados · ${queueState.failed} fallidos · ${queueState.pending} pendientes'
                  '${queueState.waitingSeconds > 0 ? " · ${queueState.waitingSeconds}s" : ""}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'Oxanium'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        _buildButton(context, ref, isRunning, queueState),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref,
    bool isRunning,
    WhatsAppQueueState queueState,
  ) {
    if (isRunning) {
      return OutlinedButton.icon(
        onPressed: () => ref.read(assistifyAutoQueueProvider.notifier).pause(),
        icon: const Icon(Icons.pause, size: 16),
        label: const Text('Pausar', style: TextStyle(fontFamily: 'Oxanium', fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
        ),
      );
    }

    if (!isRunning && queueState.total > 0 && queueState.currentIndex < queueState.total) {
      return OutlinedButton.icon(
        onPressed: () => ref.read(assistifyAutoQueueProvider.notifier).resume(),
        icon: const Icon(Icons.play_arrow, size: 16),
        label: const Text('Reanudar', style: TextStyle(fontFamily: 'Oxanium', fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _startQueue(context, ref),
      icon: const Icon(Icons.send, size: 16),
      label: const Text('Auto-Enviar', style: TextStyle(fontFamily: 'Oxanium', fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        foregroundColor: AppColors.success,
        side: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
        elevation: 0,
      ),
    );
  }

  void _startQueue(BuildContext context, WidgetRef ref) {
    final listAsync = ref.read(assistifyLeadsListProvider);
    final contactedIds = ref.read(assistifyContactadasProvider);
    final limitState = ref.read(assistifyWhatsAppLimitProvider);

    final leads = listAsync.valueOrNull ?? [];
    final pendientes = leads
        .where((e) => !contactedIds.contains(e.id) && e.hasWhatsapp && e.telefono != null)
        .toList();

    if (pendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay leads pendientes con WhatsApp'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }

    final contacts = pendientes.map((e) {
      final url = _assistifyWhatsAppUrlWithMessage(e.whatsappUrl!, e.nombre, limitState.messageIndex);
      return QueueContact(
        id: e.id,
        nombre: e.nombre,
        telefono: e.telefono!,
        whatsappFallbackUrl: url,
      );
    }).toList();

    ref.read(assistifyAutoQueueProvider.notifier).start(
      contacts,
      markContacted: (id) =>
          ref.read(assistifyContactadasProvider.notifier).markAsContacted(id),
    );
  }
}

/// Cards de estadísticas WhatsApp (PEND, HOY, FAIL, ENVIADOS) para Assistify.
class _WppStatCards extends StatelessWidget {
  const _WppStatCards({
    required this.pending,
    required this.hoy,
    required this.failed,
    required this.sent,
  });
  final int pending;
  final int hoy;
  final int failed;
  final int sent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(child: _card('PEND', pending, Icons.schedule, AppColors.warning)),
          const SizedBox(width: 8),
          Expanded(child: _card('HOY', hoy, Icons.today, AppColors.secondary)),
          const SizedBox(width: 8),
          Expanded(child: _card('FAIL', failed, Icons.error_outline, AppColors.error)),
          const SizedBox(width: 8),
          Expanded(child: _card('ENVIADOS', sent, Icons.done_all, AppColors.success)),
        ],
      ),
    );
  }

  Widget _card(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oxanium',
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Oxanium',
            ),
          ),
        ],
      ),
    );
  }
}
