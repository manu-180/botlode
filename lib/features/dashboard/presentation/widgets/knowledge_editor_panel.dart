// Archivo: lib/features/dashboard/presentation/widgets/knowledge_editor_panel.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_text_field.dart';
import 'package:botslode/core/ui/toasts/toast_service.dart';
import 'package:botslode/features/dashboard/application/knowledge_sources_provider.dart';

const int _kMinTextChars = 50;
const int _kMaxTextBytes = 100 * 1024;

class KnowledgeEditorPanel extends ConsumerStatefulWidget {
  const KnowledgeEditorPanel({
    super.key,
    required this.botId,
    required this.onDone,
    required this.onCancel,
    this.editing,
  });

  final String botId;

  /// Si es no-nulo, modo edición: precarga el texto del fragmento.
  final KnowledgeSource? editing;

  final VoidCallback onDone;
  final VoidCallback onCancel;

  bool get isEditMode => editing != null;

  @override
  ConsumerState<KnowledgeEditorPanel> createState() => _KnowledgeEditorPanelState();
}

class _KnowledgeEditorPanelState extends ConsumerState<KnowledgeEditorPanel> {
  /// 0 = texto, 1 = URL, 2 = archivo (solo en modo alta)
  int _mode = 0;

  final _textCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _textFocus = FocusNode();

  bool _isSaving = false;
  bool _isPickingFile = false;
  String? _textError;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _textCtrl.text = (widget.editing!.metadata['text'] as String?) ?? '';
    }
    _textCtrl.addListener(_onTextChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _textCtrl.removeListener(_onTextChange);
    _textCtrl.dispose();
    _urlCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _onTextChange() => setState(() {});

  // ─── Validadores ────────────────────────────────────────────────────────────

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String? _validateText(String? text) {
    final v = text ?? '';
    if (v.trim().length < _kMinTextChars) {
      return 'El texto debe tener al menos $_kMinTextChars caracteres';
    }
    if (v.length > _kMaxTextBytes) return 'El texto no puede superar 100 KB';
    return null;
  }

  // ─── Acciones ───────────────────────────────────────────────────────────────

  Future<void> _saveText() async {
    final text = _textCtrl.text;
    final error = _validateText(text);
    if (error != null) {
      setState(() => _textError = error);
      return;
    }
    setState(() {
      _isSaving = true;
      _textError = null;
    });

    final notifier = ref.read(knowledgeUploadProvider.notifier);
    if (widget.isEditMode) {
      // Insertar nuevo primero para que el stream lo muestre antes de borrar el viejo.
      await notifier.addText(widget.botId, text);
      await notifier.softDelete(widget.editing!.id);
    } else {
      await notifier.addText(widget.botId, text);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    final uploadState = ref.read(knowledgeUploadProvider);
    if (uploadState.error != null) {
      ToastService.show(
        context: context,
        type: ToastType.error,
        message: 'No se pudo guardar el fragmento',
      );
    } else {
      ToastService.show(
        context: context,
        type: ToastType.success,
        message: widget.isEditMode
            ? 'Fragmento actualizado'
            : 'Fragmento añadido — procesando...',
      );
      widget.onDone();
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlCtrl.text.trim();
    if (!_isValidUrl(url)) {
      setState(() =>
          _urlError = 'URL inválida (debe comenzar con http:// o https://)');
      return;
    }
    setState(() {
      _isSaving = true;
      _urlError = null;
    });

    await ref.read(knowledgeUploadProvider.notifier).addUrl(widget.botId, url);

    if (!mounted) return;
    setState(() => _isSaving = false);

    final uploadState = ref.read(knowledgeUploadProvider);
    if (uploadState.error != null) {
      ToastService.show(
        context: context,
        type: ToastType.error,
        message: 'No se pudo guardar la URL',
      );
    } else {
      ToastService.show(
        context: context,
        type: ToastType.success,
        message: 'URL añadida — procesando...',
      );
      widget.onDone();
    }
  }

  Future<void> _pickAndSaveFile() async {
    setState(() => _isPickingFile = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'md', 'txt'],
      withData: true,
    );
    if (!mounted) {
      setState(() => _isPickingFile = false);
      return;
    }
    if (result == null || result.files.isEmpty) {
      setState(() => _isPickingFile = false);
      return;
    }

    setState(() {
      _isPickingFile = false;
      _isSaving = true;
    });

    await ref
        .read(knowledgeUploadProvider.notifier)
        .uploadFile(widget.botId, result.files.first);

    if (!mounted) return;
    setState(() => _isSaving = false);

    final uploadState = ref.read(knowledgeUploadProvider);
    if (uploadState.error != null) {
      ToastService.show(
        context: context,
        type: ToastType.error,
        message: uploadState.error!,
      );
    } else {
      ToastService.show(
        context: context,
        type: ToastType.success,
        message: 'Archivo cargado — procesando...',
      );
      widget.onDone();
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return HudCornerBrackets(
      color: AppColors.borderGold,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space20),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: AppDimens.brL,
          border: Border.all(color: AppColors.borderStrong, width: 1.5),
          boxShadow: AppDimens.elev2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isEditMode ? '// EDITANDO FRAGMENTO' : '// NUEVO FRAGMENTO',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.cyan),
            ),
            const SizedBox(height: AppDimens.space16),

            if (!widget.isEditMode) ...[
              _ModeSelector(
                selected: _mode,
                onSelect: (i) => setState(() {
                  _mode = i;
                  _textError = null;
                  _urlError = null;
                }),
              ),
              const SizedBox(height: AppDimens.space16),
            ],

            _buildInputArea(),

            const SizedBox(height: AppDimens.space20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.ghost(
                  label: 'CANCELAR',
                  size: AppButtonSize.sm,
                  onPressed: (_isSaving || _isPickingFile) ? null : widget.onCancel,
                ),
                if (!(!widget.isEditMode && _mode == 2)) ...[
                  const SizedBox(width: AppDimens.space12),
                  _buildSaveButton(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    if (widget.isEditMode || _mode == 0) return _buildTextInput();
    if (_mode == 1) return _buildUrlInput();
    return _buildFileInput();
  }

  Widget _buildTextInput() {
    final charCount = _textCtrl.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _textCtrl,
          focusNode: _textFocus,
          label: 'Contenido del fragmento',
          maxLines: 12,
          keyboardType: TextInputType.multiline,
          validator: _validateText,
        ),
        if (_textError != null) ...[
          const SizedBox(height: AppDimens.space4),
          Semantics(
            liveRegion: true,
            child: Text(
              _textError!,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.danger),
            ),
          ),
        ],
        const SizedBox(height: AppDimens.space8),
        Text(
          '$charCount caracteres',
          style: AppTextStyles.mono.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _urlCtrl,
          label: 'URL de la fuente',
          keyboardType: TextInputType.url,
          validator: (v) => _isValidUrl(v ?? '') ? null : 'URL inválida',
        ),
        if (_urlError != null) ...[
          const SizedBox(height: AppDimens.space4),
          Semantics(
            liveRegion: true,
            child: Text(
              _urlError!,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileInput() {
    return GestureDetector(
      onTap: (_isSaving || _isPickingFile) ? null : _pickAndSaveFile,
      child: MouseRegion(
        cursor: (_isSaving || _isPickingFile)
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surfaceHud,
            borderRadius: AppDimens.brM,
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Center(
            child: (_isSaving || _isPickingFile)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.cyan,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcons.icon(AppIcons.upload, size: 24, color: AppColors.cyan),
                      const SizedBox(height: AppDimens.space8),
                      Text(
                        'Seleccionar PDF / MD / TXT',
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space4),
                      Text(
                        'Máx. 25 MB',
                        style: AppTextStyles.mono.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    if (widget.isEditMode) {
      return AppButton.primary(
        label: 'GUARDAR CAMBIOS',
        size: AppButtonSize.sm,
        loading: _isSaving,
        onPressed: _isSaving ? null : _saveText,
      );
    }
    return switch (_mode) {
      0 => AppButton.primary(
          label: 'GUARDAR FRAGMENTO',
          size: AppButtonSize.sm,
          loading: _isSaving,
          onPressed: _isSaving ? null : _saveText,
        ),
      1 => AppButton.primary(
          label: 'AÑADIR URL',
          size: AppButtonSize.sm,
          loading: _isSaving,
          onPressed: _isSaving ? null : _saveUrl,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─── Selector de modo (Texto / URL / Archivo) ─────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onSelect});

  final int selected;
  final void Function(int) onSelect;

  static const _labels = ['TEXTO', 'URL', 'ARCHIVO'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _labels.length; i++) ...[
          if (i > 0) const SizedBox(width: AppDimens.space8),
          AppButton(
            label: _labels[i],
            variant: i == selected
                ? AppButtonVariant.secondary
                : AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: () => onSelect(i),
          ),
        ],
      ],
    );
  }
}
