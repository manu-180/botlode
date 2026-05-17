// Archivo: lib/features/dashboard/presentation/widgets/tabs/bot_config_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/toasts/toast_service.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_text_field.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:botslode/features/dashboard/presentation/widgets/color_swatch_picker.dart';

const double _kEntrySlideY = 12.0;

class BotConfigTab extends ConsumerStatefulWidget {
  const BotConfigTab({
    super.key,
    required this.bot,
  });

  final Bot bot;

  @override
  ConsumerState<BotConfigTab> createState() => _BotConfigTabState();
}

class _BotConfigTabState extends ConsumerState<BotConfigTab> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _promptCtrl;
  late final TextEditingController _welcomeCtrl;

  final _nameFocus = FocusNode();
  final _promptFocus = FocusNode();

  late Color _selectedColor;
  bool _isLoading = false;

  bool get _isDirty =>
      _nameCtrl.text != widget.bot.name ||
      _promptCtrl.text != widget.bot.systemPrompt ||
      _welcomeCtrl.text != (widget.bot.initialMessage ?? '') ||
      _selectedColor != widget.bot.primaryColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.bot.name);
    _promptCtrl = TextEditingController(text: widget.bot.systemPrompt);
    _welcomeCtrl = TextEditingController(
      text: widget.bot.initialMessage ?? '',
    );
    _selectedColor = widget.bot.primaryColor;

    _nameCtrl.addListener(_onControllerChange);
    _promptCtrl.addListener(_onControllerChange);
    _welcomeCtrl.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(BotConfigTab old) {
    super.didUpdateWidget(old);
    if (old.bot != widget.bot && !_isDirty) {
      _syncFromBot();
    }
  }

  void _syncFromBot() {
    _nameCtrl.text = widget.bot.name;
    _promptCtrl.text = widget.bot.systemPrompt;
    _welcomeCtrl.text = widget.bot.initialMessage ?? '';
    setState(() => _selectedColor = widget.bot.primaryColor);
  }

  void _onControllerChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl
      ..removeListener(_onControllerChange)
      ..dispose();
    _promptCtrl
      ..removeListener(_onControllerChange)
      ..dispose();
    _welcomeCtrl
      ..removeListener(_onControllerChange)
      ..dispose();
    _nameFocus.dispose();
    _promptFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      _scrollController.animateTo(
        0,
        duration: AppMotion.durBase,
        curve: AppMotion.easeStandard,
      );
      _nameFocus.requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(botsProvider.notifier);
      final id = widget.bot.id;

      if (_nameCtrl.text != widget.bot.name) {
        await notifier.updateBotName(id, _nameCtrl.text);
      }
      if (_promptCtrl.text != widget.bot.systemPrompt) {
        await notifier.updateBotPrompt(id, _promptCtrl.text);
      }
      if (_welcomeCtrl.text != (widget.bot.initialMessage ?? '')) {
        await notifier.updateInitialMessage(id, _welcomeCtrl.text);
      }
      if (_selectedColor != widget.bot.primaryColor) {
        await notifier.updateBotColor(id, _selectedColor);
      }

      if (mounted) {
        ToastService.show(
          context: context,
          type: ToastType.success,
          message: 'Configuración actualizada',
        );
      }
    } catch (_) {
      if (mounted) {
        ToastService.show(
          context: context,
          type: ToastType.error,
          message: 'No se pudo guardar · reintentar',
          actionLabel: 'Reintentar',
          onAction: _save,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _discard() {
    _nameCtrl.text = widget.bot.name;
    _promptCtrl.text = widget.bot.systemPrompt;
    _welcomeCtrl.text = widget.bot.initialMessage ?? '';
    setState(() => _selectedColor = widget.bot.primaryColor);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space32,
        vertical: AppDimens.space24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSection(
                  index: 0,
                  reduce: reduce,
                  child: _buildIdentidadSection(),
                ),
                const SizedBox(height: AppDimens.space32),
                _buildSection(
                  index: 1,
                  reduce: reduce,
                  child: _buildComportamientoSection(),
                ),
                const SizedBox(height: AppDimens.space32),
                _buildSection(
                  index: 2,
                  reduce: reduce,
                  child: _buildAparienciaSection(),
                ),
                const SizedBox(height: AppDimens.space32),
                const HudDivider(),
                const SizedBox(height: AppDimens.space20),
                _buildSection(
                  index: 3,
                  reduce: reduce,
                  child: _ActionBar(
                    isDirty: _isDirty,
                    isLoading: _isLoading,
                    hasDraft: false,
                    onSave: _save,
                    onDiscard: _discard,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required int index,
    required bool reduce,
    required Widget child,
  }) {
    if (reduce) {
      return child
          .animate()
          .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance);
    }
    return child
        .animate(delay: (index * AppMotion.durStagger.inMilliseconds).ms)
        .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
        .moveY(
          begin: _kEntrySlideY,
          end: 0,
          duration: AppMotion.durBase,
          curve: AppMotion.easeEntrance,
        );
  }

  Widget _buildIdentidadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HudDivider(label: 'IDENTIDAD'),
        const SizedBox(height: AppDimens.space20),
        AppTextField(
          controller: _nameCtrl,
          focusNode: _nameFocus,
          label: 'Nombre de la unidad',
          maxLines: 1,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre no puede estar vacío';
            }
            if (value.length > 40) {
              return 'Máximo 40 caracteres';
            }
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimens.space4),
            child: Text(
              '${_nameCtrl.text.length}/40',
              style: AppTextStyles.mono.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComportamientoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HudDivider(label: 'COMPORTAMIENTO'),
        const SizedBox(height: AppDimens.space20),
        Text(
          '// DIRECTIVA PRINCIPAL',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        AppTextField(
          controller: _promptCtrl,
          focusNode: _promptFocus,
          label: 'System prompt',
          labelMode: AppTextFieldLabelMode.top,
          maxLines: 14,
          keyboardType: TextInputType.multiline,
          enabled: !_isLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El system prompt no puede estar vacío';
            }
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimens.space4),
            child: Text(
              '${_promptCtrl.text.length} caracteres',
              style: AppTextStyles.mono.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space20),
        AppTextField(
          controller: _welcomeCtrl,
          label: 'Mensaje de bienvenida',
          maxLines: 2,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildAparienciaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HudDivider(label: 'APARIENCIA'),
        const SizedBox(height: AppDimens.space20),
        ColorSwatchPicker(
          value: _selectedColor,
          enabled: !_isLoading,
          onChanged: (color) => setState(() => _selectedColor = color),
        ),
      ],
    );
  }
}

// ─── _ActionBar ───────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isDirty,
    required this.isLoading,
    required this.hasDraft,
    required this.onSave,
    required this.onDiscard,
  });

  final bool isDirty;
  final bool isLoading;
  final bool hasDraft;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (hasDraft)
          Text(
            'Borrador guardado',
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textTertiary,
            ),
          )
        else
          const SizedBox.shrink(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: isDirty ? 1.0 : 0.0,
              duration: AppMotion.durFast,
              curve: AppMotion.easeStandard,
              child: AppButton.ghost(
                label: 'Descartar cambios',
                size: AppButtonSize.sm,
                onPressed: isDirty ? onDiscard : null,
              ),
            ),
            const SizedBox(width: AppDimens.space8),
            AppButton.primary(
              label: 'Guardar configuración',
              size: AppButtonSize.md,
              loading: isLoading,
              onPressed: isDirty && !isLoading ? onSave : null,
            ),
          ],
        ),
      ],
    );
  }
}
