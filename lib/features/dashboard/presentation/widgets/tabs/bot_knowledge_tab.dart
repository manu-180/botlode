// Archivo: lib/features/dashboard/presentation/widgets/tabs/bot_knowledge_tab.dart
// Tab 2 del detalle de bot — base de conocimiento como archivo de fragmentos.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/empty_state.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/core/ui/toasts/toast_service.dart';
import 'package:botslode/features/dashboard/application/knowledge_sources_provider.dart';
import 'package:botslode/features/dashboard/presentation/widgets/knowledge_fragment_row.dart';
import 'package:botslode/features/dashboard/presentation/widgets/knowledge_editor_panel.dart';

class BotKnowledgeTab extends ConsumerStatefulWidget {
  const BotKnowledgeTab({super.key, required this.botId});

  final String botId;

  @override
  ConsumerState<BotKnowledgeTab> createState() => _BotKnowledgeTabState();
}

class _BotKnowledgeTabState extends ConsumerState<BotKnowledgeTab> {
  bool _showEditor = false;
  KnowledgeSource? _editingSource;
  final Set<String> _deletingIds = {};

  // ─── Editor lifecycle ────────────────────────────────────────────────────────

  void _openAdd() {
    setState(() {
      _showEditor = true;
      _editingSource = null;
    });
  }

  void _openEdit(KnowledgeSource source) {
    setState(() {
      _showEditor = true;
      _editingSource = source;
    });
  }

  void _closeEditor() {
    setState(() {
      _showEditor = false;
      _editingSource = null;
    });
  }

  // ─── Delete flow ─────────────────────────────────────────────────────────────

  Future<void> _requestDelete(BuildContext ctx, KnowledgeSource source) async {
    final confirmed = await _showDeleteDialog(ctx, source);
    if (!confirmed || !mounted) return;

    setState(() => _deletingIds.add(source.id));

    // Esperar que la animación de salida complete antes de borrar.
    final reduce = AppMotion.reduced(context);
    if (!reduce) {
      await Future.delayed(AppMotion.durFast);
    }

    await ref.read(knowledgeUploadProvider.notifier).softDelete(source.id);

    if (!mounted) return;
    setState(() => _deletingIds.remove(source.id));

    final uploadState = ref.read(knowledgeUploadProvider);
    if (uploadState.error != null) {
      ToastService.show(
        context: context,
        type: ToastType.error,
        message: 'No se pudo eliminar el fragmento',
      );
    }
  }

  Future<bool> _showDeleteDialog(
    BuildContext ctx,
    KnowledgeSource source,
  ) async {
    final title = source.title?.isNotEmpty == true
        ? source.title!
        : source.sourceUri ?? 'este fragmento';
    return await showDialog<bool>(
          context: ctx,
          barrierColor: AppColors.scrim,
          builder: (_) => _DeleteConfirmDialog(fragmentTitle: title),
        ) ??
        false;
  }

  // ─── Animaciones ─────────────────────────────────────────────────────────────

  Widget _animatedRow({
    required Widget child,
    required int index,
    required bool reduce,
  }) {
    if (reduce) {
      return child.animate().fadeIn(duration: AppMotion.durCrossfadeReduced);
    }
    final effectiveIndex = index.clamp(0, 9);
    return child
        .animate(delay: AppMotion.staggerDelay(effectiveIndex))
        .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
        .moveY(
          begin: 12,
          end: 0,
          duration: AppMotion.durBase,
          curve: AppMotion.easeEntrance,
        );
  }

  // ─── Skeletons ───────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Semantics(
      label: 'Cargando base de conocimiento',
      liveRegion: true,
      child: Column(
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < 2 ? AppDimens.space12 : 0),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: AppDimens.brM,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  const SkeletonBase(width: 32, height: 32),
                  const SizedBox(width: AppDimens.space16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBase(width: 160, height: 11),
                        SizedBox(height: AppDimens.space8),
                        SkeletonBase(width: double.infinity, height: 9),
                        SizedBox(height: AppDimens.space4),
                        SkeletonBase(width: 220, height: 9),
                        SizedBox(height: AppDimens.space8),
                        SkeletonBase(width: 100, height: 9),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final sourcesAsync = ref.watch(knowledgeSourcesProvider(widget.botId));

    // Excluir del render las filas que están animando salida (ya marcadas para borrar).
    final visibleSources = sourcesAsync.valueOrNull
        ?.where((s) => !_deletingIds.contains(s.id))
        .toList();
    final deletingSources = sourcesAsync.valueOrNull
        ?.where((s) => _deletingIds.contains(s.id))
        .toList();

    final fragmentCount = visibleSources?.length ?? 0;
    final totalChars = visibleSources?.fold<int>(
          0,
          (acc, s) => acc + ((s.metadata['text'] as String?) ?? '').length,
        ) ??
        0;

    final addButtonLabel = (_showEditor && _editingSource == null)
        ? 'CANCELAR'
        : 'AÑADIR CONOCIMIENTO';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ────────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: HudDivider(label: 'BASE DE CONOCIMIENTO'),
              ),
              const SizedBox(width: AppDimens.space16),
              AppButton.secondary(
                label: addButtonLabel,
                leadingIcon: (_showEditor && _editingSource == null)
                    ? AppIcons.close
                    : AppIcons.add,
                size: AppButtonSize.sm,
                onPressed: (_showEditor && _editingSource == null)
                    ? _closeEditor
                    : _openAdd,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),

          // ── Resumen ───────────────────────────────────────────────────────
          if (fragmentCount > 0)
            Text(
              '$fragmentCount ${fragmentCount == 1 ? 'fragmento' : 'fragmentos'}'
              '${totalChars > 0 ? ' · ~$totalChars caracteres totales' : ''}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),

          // ── Editor inline ─────────────────────────────────────────────────
          if (reduce)
            _showEditor
                ? Padding(
                    padding: const EdgeInsets.only(top: AppDimens.space16),
                    child: KnowledgeEditorPanel(
                      botId: widget.botId,
                      editing: _editingSource,
                      onDone: _closeEditor,
                      onCancel: _closeEditor,
                    ),
                  )
                : const SizedBox.shrink()
          else
            AnimatedSize(
              duration: AppMotion.durBase,
              curve: AppMotion.easeEntrance,
              child: _showEditor
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppDimens.space16),
                      child: KnowledgeEditorPanel(
                        botId: widget.botId,
                        editing: _editingSource,
                        onDone: _closeEditor,
                        onCancel: _closeEditor,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

          const SizedBox(height: AppDimens.space16),

          // ── Lista de fragmentos ───────────────────────────────────────────
          sourcesAsync.when(
            loading: _buildSkeleton,
            error: (e, _) => ErrorFeedbackCard(
              title: 'Error al cargar la base de conocimiento',
              message:
                  'No se pudieron obtener los fragmentos. Revisá tu conexión e intentá de nuevo.',
              onRetry: () async {
                ref.invalidate(knowledgeSourcesProvider(widget.botId));
              },
              variant: ErrorVariant.inline,
            ),
            data: (sources) {
              // Filas animando salida (en _deletingIds) se muestran hasta que el stream las quite.
              final rowsToShow = [
                ...?deletingSources,
                ...?visibleSources,
              ];

              if (rowsToShow.isEmpty && !_showEditor) {
                return SizedBox(
                  height: 280,
                  child: EmptyState(
                    icon: AppIcons.knowledge,
                    title: 'Sin conocimiento cargado',
                    description:
                        'La unidad todavía no tiene conocimiento cargado. Añadí el primero para empezar.',
                    action: AppButton.primary(
                      label: 'AÑADIR PRIMER FRAGMENTO',
                      leadingIcon: AppIcons.add,
                      onPressed: _openAdd,
                    ),
                  ),
                );
              }

              if (rowsToShow.isEmpty) return const SizedBox.shrink();

              return Column(
                children: [
                  for (int i = 0; i < rowsToShow.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppDimens.space12),
                    _animatedRow(
                      index: i,
                      reduce: reduce,
                      child: KnowledgeFragmentRow(
                        key: ValueKey(rowsToShow[i].id),
                        source: rowsToShow[i],
                        isDeleting: _deletingIds.contains(rowsToShow[i].id),
                        onEdit: () => _openEdit(rowsToShow[i]),
                        onDelete: () => _requestDelete(context, rowsToShow[i]),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Diálogo de confirmación de borrado ───────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.fragmentTitle});

  final String fragmentTitle;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppDimens.space24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.brL,
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿ELIMINAR ESTE FRAGMENTO?',
              style: AppTextStyles.titleM.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: AppDimens.space12),
            Text(
              'El fragmento "$fragmentTitle" se eliminará de la base de conocimiento '
              'de esta unidad. Esta acción no se puede deshacer.',
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimens.space24),
            Row(
              children: [
                Expanded(
                  child: AppButton.ghost(
                    label: 'CANCELAR',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: AppButton.danger(
                    label: 'ELIMINAR',
                    leadingIcon: AppIcons.delete,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
