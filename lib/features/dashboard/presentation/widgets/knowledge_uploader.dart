// Archivo: lib/features/dashboard/presentation/widgets/knowledge_uploader.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/dashboard/application/knowledge_sources_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KnowledgeUploader extends ConsumerStatefulWidget {
  final String botId;

  const KnowledgeUploader({super.key, required this.botId});

  @override
  ConsumerState<KnowledgeUploader> createState() => _KnowledgeUploaderState();
}

class _KnowledgeUploaderState extends ConsumerState<KnowledgeUploader> {
  int _tab = 0;
  final _urlController = TextEditingController();
  final _textController = TextEditingController();
  String? _urlError;
  String? _textError;

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  void _showSnack(String msg, Color bg, Color fg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: fg, fontSize: 12, letterSpacing: 0.5)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'md', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final notifier = ref.read(knowledgeUploadProvider.notifier);
    await notifier.uploadFile(widget.botId, result.files.first);

    final uploadState = ref.read(knowledgeUploadProvider);
    if (uploadState.error != null) {
      _showSnack(uploadState.error!, AppColors.danger, Colors.white);
    } else {
      _showSnack('Archivo agregado — procesando...', AppColors.success, Colors.black);
    }
  }

  Future<void> _addUrl() async {
    final url = _urlController.text.trim();
    if (!_isValidUrl(url)) {
      setState(() => _urlError = 'URL inválida (debe comenzar con http:// o https://)');
      return;
    }
    setState(() => _urlError = null);

    final notifier = ref.read(knowledgeUploadProvider.notifier);
    await notifier.addUrl(widget.botId, url);

    final uploadState = ref.read(knowledgeUploadProvider);
    if (uploadState.error != null) {
      _showSnack(uploadState.error!, AppColors.danger, Colors.white);
    } else {
      _urlController.clear();
      _showSnack('URL agregada — procesando...', AppColors.success, Colors.black);
    }
  }

  Future<void> _addText() async {
    final text = _textController.text.trim();
    if (text.length < 50) {
      setState(() => _textError = 'El texto debe tener al menos 50 caracteres');
      return;
    }
    if (text.length > 100 * 1024) {
      setState(() => _textError = 'El texto no puede superar 100 KB');
      return;
    }
    setState(() => _textError = null);

    final notifier = ref.read(knowledgeUploadProvider.notifier);
    await notifier.addText(widget.botId, text);

    final uploadState = ref.read(knowledgeUploadProvider);
    if (uploadState.error != null) {
      _showSnack(uploadState.error!, AppColors.danger, Colors.white);
    } else {
      _textController.clear();
      _showSnack('Texto agregado — procesando...', AppColors.success, Colors.black);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(knowledgeUploadProvider);
    final sourcesAsync = ref.watch(knowledgeSourcesProvider(widget.botId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SegmentedTabs(
          selected: _tab,
          onSelect: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 12),
        _buildTabContent(uploadState),
        const SizedBox(height: 20),
        _buildSourcesList(sourcesAsync),
      ],
    );
  }

  Widget _buildTabContent(KnowledgeUploadState uploadState) {
    switch (_tab) {
      case 0:
        return _FileTab(isUploading: uploadState.isUploading, onTap: _pickAndUpload);
      case 1:
        return _UrlTab(
          controller: _urlController,
          errorText: _urlError,
          isUploading: uploadState.isUploading,
          onAdd: _addUrl,
        );
      case 2:
        return _TextTab(
          controller: _textController,
          errorText: _textError,
          isUploading: uploadState.isUploading,
          onAdd: _addText,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSourcesList(AsyncValue<List<KnowledgeSource>> sourcesAsync) {
    return sourcesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))),
      ),
      error: (e, _) => Text(
        'Error cargando fuentes: $e',
        style: const TextStyle(color: AppColors.danger, fontSize: 11),
      ),
      data: (sources) {
        if (sources.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border.all(color: AppColors.borderDefault)),
            child: Center(
              child: Text(
                'Sin fuentes de conocimiento',
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 11, letterSpacing: 1),
              ),
            ),
          );
        }
        return Column(
          children: sources
              .map((s) => _SourceRow(
                    source: s,
                    onDelete: () => ref.read(knowledgeUploadProvider.notifier).softDelete(s.id),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ─── Segmented tabs ─────────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;

  const _SegmentedTabs({required this.selected, required this.onSelect});

  static const _labels = ['Archivo', 'URL', 'Texto'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final isSelected = selected == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.gold : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.gold : AppColors.borderDefault,
              ),
            ),
            child: Text(
              _labels[i],
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── File tab ────────────────────────────────────────────────────────────────

class _FileTab extends StatelessWidget {
  final bool isUploading;
  final VoidCallback onTap;

  const _FileTab({required this.isUploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Center(
          child: isUploading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.upload_file_outlined, color: AppColors.gold, size: 26),
                    const SizedBox(height: 6),
                    const Text(
                      'Seleccionar archivo  PDF / MD / TXT',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Máx. 25 MB',
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.45), fontSize: 9),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── URL tab ─────────────────────────────────────────────────────────────────

class _UrlTab extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool isUploading;
  final VoidCallback onAdd;

  const _UrlTab({
    required this.controller,
    this.errorText,
    required this.isUploading,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
            errorText: errorText,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.borderDefault)),
            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.borderDefault)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.gold)),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isUploading ? null : onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.3),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: isUploading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('AGREGAR URL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)),
        ),
      ],
    );
  }
}

// ─── Text tab ────────────────────────────────────────────────────────────────

class _TextTab extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool isUploading;
  final VoidCallback onAdd;

  const _TextTab({
    required this.controller,
    this.errorText,
    required this.isUploading,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          maxLines: 6,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Pegar texto aquí (mín. 50 caracteres)...',
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
            errorText: errorText,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.borderDefault)),
            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.borderDefault)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.gold)),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isUploading ? null : onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.3),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: isUploading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('AGREGAR TEXTO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)),
        ),
      ],
    );
  }
}

// ─── Source row ──────────────────────────────────────────────────────────────

class _SourceRow extends StatelessWidget {
  final KnowledgeSource source;
  final VoidCallback onDelete;

  const _SourceRow({required this.source, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          _TypeIcon(type: source.type),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  source.title ?? source.sourceUri ?? '—',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (source.status == 'failed' && source.lastError != null)
                  Tooltip(
                    message: source.lastError!,
                    child: const Text(
                      'Error — hover para ver detalle',
                      style: TextStyle(color: AppColors.danger, fontSize: 9),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(status: source.status),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 15),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final String type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'url' => Icons.link_rounded,
      'text' => Icons.text_snippet_outlined,
      _ => Icons.description_outlined,
    };
    return Icon(icon, size: 15, color: AppColors.gold);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'pending' => (AppColors.warning, 'PENDING'),
      'processing' => (AppColors.secondary, 'PROC...'),
      'ready' => (AppColors.success, 'READY'),
      'failed' => (AppColors.danger, 'FAILED'),
      _ => (AppColors.textSecondary, status.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
