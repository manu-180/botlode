// Archivo: lib/features/bot_engine/presentation/widgets/bot_chat_console.dart
// Terminal HUD de prueba — Hangar OS. Requiere parent con altura finita (ej. Expanded).
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_grid_texture.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:botslode/core/ui/widgets/status_tag.dart';
import 'package:botslode/features/bot_engine/presentation/providers/chat_provider.dart';
import 'package:botslode/features/bot_engine/presentation/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BotChatConsole extends ConsumerStatefulWidget {
  final String botName;
  final Color botColor;
  final String botId;

  const BotChatConsole({
    super.key,
    required this.botName,
    required this.botColor,
    required this.botId,
  });

  @override
  ConsumerState<BotChatConsole> createState() => _BotChatConsoleState();
}

class _BotChatConsoleState extends ConsumerState<BotChatConsole> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isAtBottom = true;
  bool _hasUnseenMessages = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final atBottom = _scrollController.offset >= maxExtent - 64;
    if (atBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = atBottom;
        if (atBottom) _hasUnseenMessages = false;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    final reduce = AppMotion.reduced(context);
    if (reduce) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    } else {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppMotion.durBase,
        curve: AppMotion.easeStandard,
      );
    }
  }

  void _handleSubmit() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    setState(() {});
    _focusNode.requestFocus();
    // Force scroll to bottom when user sends a message
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    ref.read(chatProvider(widget.botId).notifier).sendMessage(text);
  }

  void _clearTerminal() {
    ref.invalidate(chatProvider(widget.botId));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.botId));
    final messages = chatState.messages;
    final isTyping = chatState.isTyping;
    final reduce = AppMotion.reduced(context);

    final tagStatus = isTyping ? UnitStatus.processing : UnitStatus.online;
    final hasConversation = messages.any((m) => !(m['isSystem'] as bool? ?? false));
    final canSend = _inputController.text.trim().isNotEmpty;

    ref.listen(chatProvider(widget.botId), (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_isAtBottom) {
            _scrollToBottom();
          } else {
            setState(() => _hasUnseenMessages = true);
          }
        });
      }
    });

    return Semantics(
      label: 'Terminal de chat de prueba',
      child: HoloPanel(
        padding: EdgeInsets.zero,
        borderColor: AppColors.borderDefault,
        child: Column(
          children: [
            // ── Barra de título (44 px) ───────────────────────────────────────
            _TitleBar(
              sessionId: chatState.sessionId.substring(0, 8).toUpperCase(),
              tagStatus: tagStatus,
              onClear: _clearTerminal,
            ),

            // ── Área de mensajes (Expanded) ───────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  // Fondo HUD con retícula
                  Positioned.fill(
                    child: Container(
                      color: AppColors.surfaceHud,
                      child: const HudGridTexture(opacity: 0.04),
                    ),
                  ),

                  // Estado vacío o lista de mensajes
                  if (!hasConversation)
                    _EmptyState(
                      onSuggestionTap: (text) {
                        _inputController.text = text;
                        setState(() {});
                        _focusNode.requestFocus();
                      },
                    )
                  else
                    Semantics(
                      liveRegion: isTyping,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppDimens.space16),
                        itemCount: messages.length + (isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Burbuja de "escribiendo"
                          if (index == messages.length && isTyping) {
                            return Padding(
                              key: const ValueKey('typing'),
                              padding: const EdgeInsets.only(
                                bottom: AppDimens.space12,
                              ),
                              child: ChatMessageBubble(
                                variant: ChatBubbleVariant.typing,
                                botColor: widget.botColor,
                                reduce: reduce,
                              ),
                            );
                          }

                          final msg = messages[index];
                          final isUser = msg['isUser'] as bool;
                          final isSystem = msg['isSystem'] as bool? ?? false;

                          if (isSystem) {
                            return ChatMessageBubble(
                              key: ValueKey('sys_$index'),
                              variant: ChatBubbleVariant.system,
                              text: msg['text'] as String,
                              reduce: reduce,
                            );
                          }

                          return Padding(
                            key: ValueKey('msg_$index'),
                            padding: const EdgeInsets.only(
                              bottom: AppDimens.space12,
                            ),
                            child: ChatMessageBubble(
                              variant: isUser
                                  ? ChatBubbleVariant.user
                                  : ChatBubbleVariant.bot,
                              text: msg['text'] as String,
                              botColor: widget.botColor,
                              botName: widget.botName,
                              reduce: reduce,
                            ),
                          );
                        },
                      ),
                    ),

                  // Botón "↓ Nuevos mensajes"
                  if (!_isAtBottom && _hasUnseenMessages)
                    Positioned(
                      bottom: AppDimens.space12,
                      right: AppDimens.space12,
                      child: _NewMessagesButton(
                        onTap: () {
                          setState(() => _hasUnseenMessages = false);
                          _scrollToBottom();
                        },
                        reduce: reduce,
                      ),
                    ),
                ],
              ),
            ),

            // ── Barra de input (~64 px) ───────────────────────────────────────
            _InputBar(
              controller: _inputController,
              focusNode: _focusNode,
              canSend: canSend,
              isTyping: isTyping,
              reduce: reduce,
              onChanged: (_) => setState(() {}),
              onSubmitted: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// _TitleBar
// ─────────────────────────────────────────────────────────────────────────────

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.sessionId,
    required this.tagStatus,
    required this.onClear,
  });

  final String sessionId;
  final UnitStatus tagStatus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHud,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          AppIcons.icon(
            AppIcons.terminal,
            size: AppDimens.iconXS,
            color: AppColors.gold.withValues(alpha: 0.70),
          ),
          const SizedBox(width: AppDimens.space8),
          Text(
            'TERMINAL DE CHAT',
            style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppDimens.space8),
          Text(
            '// PRUEBA',
            style: AppTextStyles.mono.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(width: AppDimens.space12),
          Flexible(
            child: Text(
              'SESSION: $sessionId',
              style: AppTextStyles.mono.copyWith(color: AppColors.textTertiary),
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          const Spacer(),
          StatusTag(status: tagStatus),
          const SizedBox(width: AppDimens.space8),
          AppIconButton(
            icon: AppIcons.delete,
            tooltip: 'Limpiar terminal',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  static const _suggestions = [
    'Hola, ¿cómo estás?',
    '¿Qué podés hacer?',
    'Explicame tu propósito',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcons.icon(
              AppIcons.terminal,
              size: AppDimens.iconL,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppDimens.space16),
            Text(
              'TERMINAL DE PRUEBA',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Escribí un mensaje para probar cómo responde la unidad.\nEsta conversación no se guarda.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyS,
            ),
            const SizedBox(height: AppDimens.space24),
            Wrap(
              spacing: AppDimens.space8,
              runSpacing: AppDimens.space8,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => _SuggestionChip(
                        label: s,
                        onTap: () => onSuggestionTap(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.durFast,
          curve: AppMotion.easeStandard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space12,
            vertical: AppDimens.space8,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.borderSubtle
                : Colors.transparent,
            borderRadius: AppDimens.brPill,
            border: Border.all(
              color: _hovered
                  ? AppColors.borderStrong
                  : AppColors.borderDefault,
            ),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.bodyS
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NewMessagesButton
// ─────────────────────────────────────────────────────────────────────────────

class _NewMessagesButton extends StatefulWidget {
  const _NewMessagesButton({required this.onTap, required this.reduce});
  final VoidCallback onTap;
  final bool reduce;

  @override
  State<_NewMessagesButton> createState() => _NewMessagesButtonState();
}

class _NewMessagesButtonState extends State<_NewMessagesButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final chip = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.durFast,
          curve: AppMotion.easeStandard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space12,
            vertical: AppDimens.space8,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceRaised : AppColors.surface,
            borderRadius: AppDimens.brPill,
            border: Border.all(
              color: _hovered ? AppColors.borderStrong : AppColors.borderDefault,
            ),
            boxShadow: AppDimens.elev2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcons.icon(
                AppIcons.chevronDown,
                size: AppDimens.iconXS,
                color: AppColors.cyan,
              ),
              const SizedBox(width: AppDimens.space4),
              Text(
                'Nuevos mensajes',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.cyan),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.reduce) return chip;

    return chip
        .animate()
        .fadeIn(
          duration: AppMotion.durFast,
          curve: AppMotion.easeEntrance,
        )
        .slideY(
          begin: 0.5,
          end: 0,
          duration: AppMotion.durFast,
          curve: AppMotion.easeEntrance,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InputBar
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isTyping,
    required this.reduce,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isTyping;
  final bool reduce;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_InputBar old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused ? AppColors.cyan : AppColors.borderDefault;
    final borderWidth = _isFocused ? 2.0 : 1.5;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHud,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Prefijo de prompt ">_"
          Text(
            '>_',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: AppDimens.space12),

          // Campo de input
          Expanded(
            child: Semantics(
              label: 'Escribí tu mensaje de prueba',
              child: AnimatedContainer(
                duration: widget.reduce
                    ? AppMotion.durCrossfadeReduced
                    : AppMotion.durFast,
                curve: AppMotion.easeStandard,
                decoration: BoxDecoration(
                  borderRadius: AppDimens.brM,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.cyanGlow.withValues(alpha: 0.18),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 3,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.gold,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => widget.onSubmitted(),
                  onChanged: widget.onChanged,
                  decoration: InputDecoration(
                    hintText: 'Escribí un mensaje de prueba...',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space12,
                      vertical: AppDimens.space8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppDimens.brM,
                      borderSide: BorderSide(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppDimens.brM,
                      borderSide: const BorderSide(
                        color: AppColors.borderDefault,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppDimens.brM,
                      borderSide: const BorderSide(
                        color: AppColors.cyan,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: AppDimens.space12),

          // Botón enviar
          AnimatedOpacity(
            opacity: widget.canSend ? 1.0 : 0.4,
            duration: widget.reduce
                ? AppMotion.durCrossfadeReduced
                : AppMotion.durFast,
            curve: AppMotion.easeStandard,
            child: AppIconButton(
              icon: AppIcons.send,
              tooltip: 'Enviar mensaje',
              variant: widget.canSend
                  ? AppButtonVariant.primary
                  : AppButtonVariant.ghost,
              size: AppButtonSize.md,
              onPressed: widget.canSend ? widget.onSubmitted : null,
            ),
          ),
        ],
      ),
    );
  }
}
