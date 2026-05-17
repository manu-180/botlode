// Archivo: lib/features/bot_engine/presentation/widgets/chat_message_bubble.dart
// Burbujas de chat Hangar OS — prompt 39.
// Variantes: user, bot, system, typing, error.
// Cero hex colors. Cero magic numbers. Cero .withOpacity().
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_status_dot.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum de variantes
// ─────────────────────────────────────────────────────────────────────────────

enum ChatBubbleVariant { user, bot, system, typing, error }

// ─────────────────────────────────────────────────────────────────────────────
// ChatMessageBubble — widget principal
// ─────────────────────────────────────────────────────────────────────────────

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.variant,
    this.text,
    this.botColor,
    this.botName,
    this.timestamp,
    this.reduce = false,
    this.onRetry,
    this.systemIsError,
  });

  final ChatBubbleVariant variant;
  final String? text;
  final Color? botColor;
  final String? botName;

  /// Tiempo formateado, por ejemplo "14:32".
  final String? timestamp;

  /// Reduced-motion: sin translateY, typing estático.
  final bool reduce;

  /// Solo para variante error.
  final VoidCallback? onRetry;

  /// Para variante system: indica explícitamente si es error.
  /// Si es null, se infiere por emoji en el texto (compatibilidad con callers existentes).
  final bool? systemIsError;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ChatBubbleVariant.user    => _UserBubble(
          text: text ?? '',
          timestamp: timestamp,
          reduce: reduce,
        ),
      ChatBubbleVariant.bot     => _BotBubble(
          text: text ?? '',
          botColor: botColor ?? AppColors.cyan,
          botName: botName,
          timestamp: timestamp,
          reduce: reduce,
        ),
      ChatBubbleVariant.system  => _SystemBubble(
          text: text ?? '',
          reduce: reduce,
          isError: systemIsError ??
              (text?.contains('⚠️') ?? false) ||
              (text?.contains('❌') ?? false),
        ),
      ChatBubbleVariant.typing  => _TypingBubble(
          botColor: botColor ?? AppColors.cyan,
          reduce: reduce,
        ),
      ChatBubbleVariant.error   => _ErrorBubble(
          text: text ?? '',
          timestamp: timestamp,
          reduce: reduce,
          onRetry: onRetry,
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UserBubble
// ─────────────────────────────────────────────────────────────────────────────

class _UserBubble extends StatefulWidget {
  const _UserBubble({
    required this.text,
    this.timestamp,
    required this.reduce,
  });

  final String text;
  final String? timestamp;
  final bool reduce;

  @override
  State<_UserBubble> createState() => _UserBubbleState();
}

class _UserBubbleState extends State<_UserBubble> {
  bool _hovered = false;

  // Fix 4: Color.lerp hoisted to static final — not recomputed on every build.
  static final Color _bubbleFill =
      Color.lerp(AppColors.surfaceRaised, AppColors.gold, 0.05)!;

  @override
  Widget build(BuildContext context) {
    final bubble = Align(
      alignment: Alignment.centerRight,
      child: LayoutBuilder(
        builder: (context, parentConstraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: parentConstraints.maxWidth * 0.62,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.basic,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _bubbleFill,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimens.radiusM),
                        topRight: Radius.circular(AppDimens.radiusM),
                        bottomLeft: Radius.circular(AppDimens.radiusM),
                        bottomRight: Radius.circular(AppDimens.radiusXS),
                      ),
                      border: Border.all(color: AppColors.borderGold),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space16,
                      vertical: AppDimens.space12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.text,
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        if (widget.timestamp != null) ...[
                          const SizedBox(height: AppDimens.space4),
                          AnimatedOpacity(
                            opacity: _hovered ? 1.0 : 0.6,
                            duration: AppMotion.durFast,
                            curve: AppMotion.easeStandard,
                            child: Text(
                              widget.timestamp!,
                              style: AppTextStyles.mono.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Botón copiar — aparece en hover
                  if (_hovered)
                    Positioned(
                      top: -AppDimens.space4,
                      right: -AppDimens.space4,
                      child: AppIconButton(
                        icon: AppIcons.copy,
                        tooltip: 'Copiar mensaje',
                        variant: AppButtonVariant.ghost,
                        size: AppButtonSize.sm,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.text));
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return _EntryAnimation(reduce: widget.reduce, child: bubble);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BotAvatar — Fix 3: extracted from _BotBubble and _TypingBubble
// ─────────────────────────────────────────────────────────────────────────────

class _BotAvatar extends StatelessWidget {
  const _BotAvatar({required this.botColor, required this.status});
  final Color botColor;
  final HudStatus status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceHud,
              shape: BoxShape.circle,
              border: Border.all(
                color: botColor.withValues(alpha: 0.70),
                width: 1.5,
              ),
            ),
            child: Center(
              child: AppIcons.icon(
                AppIcons.botUnit,
                size: AppDimens.iconXS,
                color: botColor.withValues(alpha: 0.85),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: HudStatusDot(status: status, size: 8, showLabel: false),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BotBubble
// ─────────────────────────────────────────────────────────────────────────────

class _BotBubble extends StatelessWidget {
  const _BotBubble({
    required this.text,
    required this.botColor,
    this.botName,
    this.timestamp,
    required this.reduce,
  });

  final String text;
  final Color botColor;
  final String? botName;
  final String? timestamp;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final label = (botName ?? 'SISTEMA').toUpperCase();

    final bubbleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: botColor,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        _MarkdownText(text: text),
        if (timestamp != null) ...[
          const SizedBox(height: AppDimens.space4),
          Text(
            timestamp!,
            style: AppTextStyles.mono.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );

    // Fix 5: FractionallySizedBox replaces LayoutBuilder + ConstrainedBox.
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fix 3: _BotAvatar replaces duplicated avatar Stack.
        _BotAvatar(botColor: botColor, status: HudStatus.online),
        const SizedBox(width: AppDimens.space12),
        Flexible(
          child: FractionallySizedBox(
            widthFactor: 0.62,
            alignment: Alignment.centerLeft,
            child: HoloPanel(
              padding: const EdgeInsets.all(AppDimens.space12),
              borderColor: botColor.withValues(alpha: 0.25),
              child: bubbleContent,
            ),
          ),
        ),
      ],
    );

    return _EntryAnimation(reduce: reduce, child: row);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SystemBubble
// ─────────────────────────────────────────────────────────────────────────────

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({
    required this.text,
    required this.reduce,
    required this.isError,
  });

  final String text;
  final bool reduce;
  // Fix 7: isError is now a typed parameter instead of being inferred from emoji.
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.cyan;
    final iconData = isError ? AppIcons.warning : AppIcons.info;

    final bubble = Semantics(
      liveRegion: isError,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppDimens.space12),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space12,
            vertical: AppDimens.space8,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: AppDimens.brS,
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcons.icon(iconData, size: 12, color: color),
              const SizedBox(width: AppDimens.space8),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.mono.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return _EntryAnimation(reduce: reduce, child: bubble);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TypingBubble
// ─────────────────────────────────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({
    required this.botColor,
    required this.reduce,
  });

  final Color botColor;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      label: 'La unidad está escribiendo',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fix 3: _BotAvatar replaces duplicated avatar Stack.
          _BotAvatar(botColor: botColor, status: HudStatus.processing),
          const SizedBox(width: AppDimens.space12),
          // Mini burbuja con los 3 puntos
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space12,
              vertical: AppDimens.space12,
            ),
            decoration: BoxDecoration(
              color: botColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimens.radiusM),
                topRight: Radius.circular(AppDimens.radiusM),
                bottomRight: Radius.circular(AppDimens.radiusM),
              ),
              border: Border.all(color: botColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(
                  color: botColor,
                  delay: Duration.zero,
                  reduce: reduce,
                ),
                const SizedBox(width: AppDimens.space4),
                _AnimatedDot(
                  color: botColor,
                  delay: AppMotion.durFast,
                  reduce: reduce,
                ),
                const SizedBox(width: AppDimens.space4),
                _AnimatedDot(
                  color: botColor,
                  delay: AppMotion.durSlow,
                  reduce: reduce,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return _EntryAnimation(reduce: reduce, child: row);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedDot — Fix 2: StatefulWidget with explicit AnimationController
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot({
    required this.color,
    required this.delay,
    required this.reduce,
  });
  final Color color;
  final Duration delay;
  final bool reduce;

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  Animation<double>? _opacity;

  @override
  void initState() {
    super.initState();
    if (!widget.reduce) {
      _ctrl = AnimationController(
        vsync: this,
        duration: AppMotion.durSlow,
      );
      _opacity = CurvedAnimation(parent: _ctrl!, curve: AppMotion.easeStandard);
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl!.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: widget.reduce ? 0.50 : 0.80),
        shape: BoxShape.circle,
      ),
    );
    final ctrl = _ctrl;
    if (ctrl == null || _opacity == null) return dot;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, child) => Opacity(opacity: _opacity!.value, child: child),
      child: dot,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBubble
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBubble extends StatefulWidget {
  const _ErrorBubble({
    required this.text,
    this.timestamp,
    required this.reduce,
    this.onRetry,
  });

  final String text;
  final String? timestamp;
  final bool reduce;
  final VoidCallback? onRetry;

  @override
  State<_ErrorBubble> createState() => _ErrorBubbleState();
}

class _ErrorBubbleState extends State<_ErrorBubble> {
  bool _hovered = false;

  // Fix 4: Color.lerp hoisted to static final — not recomputed on every build.
  static final Color _bubbleFill =
      Color.lerp(AppColors.surfaceRaised, AppColors.danger, 0.05)!;

  @override
  Widget build(BuildContext context) {
    final bubble = Semantics(
      liveRegion: true,
      child: Align(
        alignment: Alignment.centerRight,
        child: LayoutBuilder(
          builder: (context, parentConstraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: parentConstraints.maxWidth * 0.62,
              ),
              child: MouseRegion(
                cursor: SystemMouseCursors.basic,
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _bubbleFill,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppDimens.radiusM),
                          topRight: Radius.circular(AppDimens.radiusM),
                          bottomLeft: Radius.circular(AppDimens.radiusM),
                          bottomRight: Radius.circular(AppDimens.radiusXS),
                        ),
                        border: Border.all(color: AppColors.danger),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space16,
                        vertical: AppDimens.space12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.text,
                            style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                          if (widget.timestamp != null) ...[
                            const SizedBox(height: AppDimens.space4),
                            AnimatedOpacity(
                              opacity: _hovered ? 1.0 : 0.6,
                              duration: AppMotion.durFast,
                              curve: AppMotion.easeStandard,
                              child: Text(
                                widget.timestamp!,
                                style: AppTextStyles.mono.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppDimens.space4),
                          // Indicador de error
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcons.icon(
                                AppIcons.warning,
                                size: 12,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: AppDimens.space4),
                              Text(
                                'No entregado',
                                style: AppTextStyles.mono.copyWith(
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                          if (widget.onRetry != null) ...[
                            const SizedBox(height: AppDimens.space8),
                            AppButton(
                              label: 'Reintentar',
                              variant: AppButtonVariant.ghost,
                              size: AppButtonSize.sm,
                              onPressed: widget.onRetry,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_hovered)
                      Positioned(
                        top: -AppDimens.space4,
                        right: -AppDimens.space4,
                        child: AppIconButton(
                          icon: AppIcons.copy,
                          tooltip: 'Copiar mensaje',
                          variant: AppButtonVariant.ghost,
                          size: AppButtonSize.sm,
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.text),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    return _EntryAnimation(reduce: widget.reduce, child: bubble);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MarkdownText — renderizado markdown-lite para mensajes de bot
// ─────────────────────────────────────────────────────────────────────────────

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text});

  final String text;

  // Fix 1: RegExp hoisted to static final — compiled once, not on every call.
  // _combinedPattern covers both bold (**...**) and inline-code (`...`).
  // Bold is group(1), code is group(2) — no second regex needed.
  static final RegExp _combinedPattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) children.add(const SizedBox(height: AppDimens.space4));

      if (line.startsWith('- ')) {
        // Lista con viñeta
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Flexible(child: _buildInlineSpans(line.substring(2))),
            ],
          ),
        );
      } else {
        children.add(_buildInlineSpans(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildInlineSpans(String line) {
    final spans = <InlineSpan>[];

    int cursor = 0;
    for (final match in _combinedPattern.allMatches(line)) {
      // Texto literal antes del match
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: line.substring(cursor, match.start),
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
          ),
        );
      }

      // Fix 1: check capture groups instead of running _boldPattern again.
      if (match.group(1) != null) {
        // Negrita
        spans.add(
          TextSpan(
            text: match.group(1),
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      } else {
        // Código inline — envuelto en WidgetSpan con fondo surfaceHud
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space4,
                vertical: AppDimens.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceHud,
                borderRadius: AppDimens.brXS,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                match.group(2) ?? '',
                style: AppTextStyles.mono.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }

      cursor = match.end;
    }

    // Resto del texto tras el último match
    if (cursor < line.length) {
      spans.add(
        TextSpan(
          text: line.substring(cursor),
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    if (spans.isEmpty) {
      spans.add(
        TextSpan(
          text: line,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    // Fix 6: Text.rich respects DefaultTextStyle and OS text scaling.
    return Text.rich(TextSpan(children: spans));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EntryAnimation — fade + slideY de entrada, reduce-motion aware
// ─────────────────────────────────────────────────────────────────────────────

class _EntryAnimation extends StatelessWidget {
  const _EntryAnimation({
    required this.reduce,
    required this.child,
  });

  final bool reduce;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduce) {
      return child
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
    }
    return child
        .animate()
        .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: AppMotion.durBase,
          curve: AppMotion.easeEntrance,
        );
  }
}
