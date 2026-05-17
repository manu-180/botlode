// Archivo: lib/features/dashboard/presentation/widgets/knowledge_fragment_row.dart
import 'package:flutter/material.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/features/dashboard/application/knowledge_sources_provider.dart';

class KnowledgeFragmentRow extends StatefulWidget {
  const KnowledgeFragmentRow({
    super.key,
    required this.source,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
  });

  final KnowledgeSource source;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  State<KnowledgeFragmentRow> createState() => _KnowledgeFragmentRowState();
}

class _KnowledgeFragmentRowState extends State<KnowledgeFragmentRow>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  late final AnimationController _deleteCtrl;
  late final Animation<double> _deleteAnim;

  @override
  void initState() {
    super.initState();
    _deleteCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durFast,
      value: 1.0,
    );
    _deleteAnim = CurvedAnimation(parent: _deleteCtrl, curve: AppMotion.easeExit);
  }

  @override
  void didUpdateWidget(KnowledgeFragmentRow old) {
    super.didUpdateWidget(old);
    if (widget.isDeleting && !old.isDeleting) {
      _deleteCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _deleteCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  IconData _typeIcon() => switch (widget.source.type) {
        'pdf' => AppIcons.library,
        'url' => AppIcons.link,
        'text' || 'markdown' => AppIcons.blueprint,
        _ => AppIcons.knowledge,
      };

  String _title() {
    final src = widget.source;
    if (src.title != null && src.title!.isNotEmpty) return src.title!;
    if (src.sourceUri != null) return src.sourceUri!;
    return '—';
  }

  String _excerpt() {
    final src = widget.source;
    if (src.type == 'text') {
      final text = (src.metadata['text'] as String?) ?? '';
      return text.isEmpty ? '—' : text;
    }
    return src.sourceUri ?? src.title ?? '—';
  }

  int _charCount() {
    if (widget.source.type == 'text') {
      return ((widget.source.metadata['text'] as String?) ?? '').length;
    }
    return 0;
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(widget.source.createdAt);
    if (diff.inDays >= 1) return 'hace ${diff.inDays}d';
    if (diff.inHours >= 1) return 'hace ${diff.inHours}h';
    if (diff.inMinutes >= 1) return 'hace ${diff.inMinutes}m';
    return 'ahora';
  }

  bool get _canEdit => widget.source.type == 'text';

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final charCount = _charCount();
    final title = _title();

    final rowContent = Semantics(
      label: 'Fragmento: $title${charCount > 0 ? ', $charCount caracteres' : ''}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: reduce ? AppMotion.durInstant : AppMotion.durFast,
          curve: AppMotion.easeStandard,
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: AppDimens.brM,
            border: Border.all(
              color: _hovered ? AppColors.borderStrong : AppColors.borderDefault,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered ? AppDimens.elev2 : AppDimens.elev1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TypeIconBox(icon: _typeIcon()),
              const SizedBox(width: AppDimens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleM,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      _excerpt(),
                      style: AppTextStyles.bodyS,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      charCount > 0
                          ? '$charCount caracteres · ${_timeAgo()}'
                          : '${widget.source.type.toUpperCase()} · ${_timeAgo()}',
                      style: AppTextStyles.mono.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.7,
                duration: reduce ? AppMotion.durInstant : AppMotion.durFast,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_canEdit) ...[
                      AppIconButton(
                        icon: AppIcons.edit,
                        tooltip: 'Editar fragmento',
                        variant: AppButtonVariant.ghost,
                        size: AppButtonSize.sm,
                        onPressed: widget.onEdit,
                      ),
                      const SizedBox(width: AppDimens.space4),
                    ],
                    _DeleteButton(onDelete: widget.onDelete),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _deleteAnim,
      builder: (_, child) {
        final v = _deleteAnim.value;
        if (reduce) {
          return Opacity(
            opacity: v,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: v,
                child: child,
              ),
            ),
          );
        }
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(16 * (1 - v), 0),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: v,
                child: child,
              ),
            ),
          ),
        );
      },
      child: rowContent,
    );
  }
}

// ─── Type icon mini-box ───────────────────────────────────────────────────────

class _TypeIconBox extends StatelessWidget {
  const _TypeIconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brM,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Center(
        child: AppIcons.icon(icon, size: 14, color: AppColors.cyan),
      ),
    );
  }
}

// ─── Delete button (ghost → danger on hover) ─────────────────────────────────

class _DeleteButton extends StatefulWidget {
  const _DeleteButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AppIconButton(
        icon: AppIcons.delete,
        tooltip: 'Eliminar fragmento',
        variant: _hovered ? AppButtonVariant.danger : AppButtonVariant.ghost,
        size: AppButtonSize.sm,
        onPressed: widget.onDelete,
      ),
    );
  }
}
