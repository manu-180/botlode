// Archivo: lib/features/dashboard/presentation/widgets/tabs/bot_embed_tab.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:botslode/core/config/app_config.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_grid_texture.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/widgets/code_block_panel.dart';

// ─── Constantes locales (spec-derived, no magic numbers) ─────────────────────

const double _kPreviewHeight = 280.0;
const double _kBubbleSize = 48.0;
const double _kBubbleBorderWidth = 1.5;

// ─── BotEmbedTab ──────────────────────────────────────────────────────────────

class BotEmbedTab extends StatefulWidget {
  const BotEmbedTab({super.key, required this.bot});

  final Bot bot;

  @override
  State<BotEmbedTab> createState() => _BotEmbedTabState();
}

class _BotEmbedTabState extends State<BotEmbedTab> {
  String _bubblePosition = 'right';
  bool _urlCopied = false;
  Timer? _urlCopiedTimer;

  String get _playerUrl =>
      '${AppConfig.playerBaseUrl}?botId=${widget.bot.id}';

  @override
  void dispose() {
    _urlCopiedTimer?.cancel();
    super.dispose();
  }

  // ─── Embed code builder ───────────────────────────────────────────────────

  String _buildEmbedCode() {
    const String baseUrl = AppConfig.playerBaseUrl;
    final String botId = widget.bot.id;
    final String rightVal = _bubblePosition == 'right' ? '16px' : 'auto';
    final String leftVal = _bubblePosition == 'left' ? '16px' : 'auto';
    return '''<!-- BotLode - Burbuja flotante embebida -->
<!-- Pegar antes del </body> en cualquier HTML. -->

<style>
  #botlode-player {
    background: none !important;
    background-color: transparent !important;
    touch-action: manipulation !important;
    -webkit-tap-highlight-color: transparent !important;
  }
</style>

<link rel="preconnect" href="$baseUrl">
<link rel="dns-prefetch" href="$baseUrl">

<iframe
  id="botlode-player"
  tabindex="0"
  src="$baseUrl?botId=$botId&v=2.5"
  style="
    position: fixed;
    bottom: 16px;
    right: $rightVal;
    left: $leftVal;
    width: 150px;
    height: 150px;
    border: none;
    z-index: 100003;
    pointer-events: auto;
    background: transparent !important;
    opacity: 0;
    will-change: width, height;
    transform: translateZ(0);
  "
  sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-modals allow-top-navigation-by-user-activation"
  allow="clipboard-write"
  allowtransparency="true">
</iframe>

<script>
(function() {
  const iframe = document.getElementById('botlode-player');
  if (!iframe) return;
  // ... (embed controller script) ...
  window.addEventListener('message', function(e) {
    if (e.data === 'CMD_READY') { iframe.style.opacity = '1'; }
  });
})();
</script>''';
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: _playerUrl));
    setState(() => _urlCopied = true);
    _urlCopiedTimer?.cancel();
    _urlCopiedTimer = Timer(AppMotion.durHeartbeat, () {
      if (mounted) setState(() => _urlCopied = false);
    });
  }

  void _onCodeCopied() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_rounded, color: AppColors.success, size: AppDimens.iconS),
            const SizedBox(width: AppDimens.space8),
            Text(
              'CÓDIGO COPIADO AL PORTAPAPELES',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceRaised,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2000),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.brM,
          side: const BorderSide(color: AppColors.borderDefault),
        ),
      ),
    );
  }

  // ─── Section builders ─────────────────────────────────────────────────────

  Widget _buildUrlCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brL,
        border: Border.all(color: AppColors.borderDefault),
      ),
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, color: AppColors.cyan, size: AppDimens.iconS),
              const SizedBox(width: AppDimens.space8),
              Expanded(
                child: SelectableText(
                  _playerUrl,
                  style: AppTextStyles.mono.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                ),
              ),
              AppIconButton(
                icon: _urlCopied ? Icons.check_rounded : Icons.content_copy_rounded,
                onPressed: _copyUrl,
                tooltip: 'Copiar URL',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Enlace directo a la unidad en el player.',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brL,
        border: Border.all(color: AppColors.borderDefault),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'POSICIÓN DE LA BURBUJA',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.space12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PositionSegment(
                label: 'ABAJO DERECHA',
                selected: _bubblePosition == 'right',
                onTap: () => setState(() => _bubblePosition = 'right'),
              ),
              const SizedBox(width: AppDimens.space8),
              _PositionSegment(
                label: 'ABAJO IZQUIERDA',
                selected: _bubblePosition == 'left',
                onTap: () => setState(() => _bubblePosition = 'left'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPlaceholder() {
    return SizedBox(
      height: _kPreviewHeight,
      child: HudCornerBrackets(
        color: AppColors.borderGold,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceHud,
            borderRadius: AppDimens.brL,
            border: Border.all(color: AppColors.borderDefault),
          ),
          clipBehavior: Clip.antiAlias,
          child: HudGridTexture(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.open_in_browser_rounded,
                        color: AppColors.textTertiary,
                        size: AppDimens.space40,
                      ),
                      const SizedBox(height: AppDimens.space12),
                      Text(
                        'VISTA PREVIA DEL PLAYER',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space4),
                      Text(
                        'El player se ejecuta en el sitio del cliente.',
                        style: AppTextStyles.mono.copyWith(
                          color: AppColors.textTertiary.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: AppDimens.space16,
                  right: AppDimens.space16,
                  child: Container(
                    width: _kBubbleSize,
                    height: _kBubbleSize,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: AppDimens.brPill,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: _kBubbleBorderWidth,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    Widget animate(Widget child, int staggerIndex) {
      if (reduced) {
        return child
            .animate()
            .fade(duration: AppMotion.durBase, curve: AppMotion.easeEntrance);
      }
      return child
          .animate()
          .fade(
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
            delay: AppMotion.staggerDelay(staggerIndex),
          )
          .move(
            begin: const Offset(0, 12),
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
            delay: AppMotion.staggerDelay(staggerIndex),
          );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space24,
        horizontal: AppDimens.space32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HudDivider(label: 'DESPLIEGUE DE LA UNIDAD'),
          const SizedBox(height: AppDimens.space16),
          animate(_buildUrlCard(), 0),
          const SizedBox(height: AppDimens.space24),
          const HudDivider(label: 'CÓDIGO DE INSERCIÓN'),
          const SizedBox(height: AppDimens.space16),
          animate(
            CodeBlockPanel(
              code: _buildEmbedCode(),
              title: '// EMBED · iframe + script',
              onCopied: _onCodeCopied,
            ),
            1,
          ),
          const SizedBox(height: AppDimens.space24),
          const HudDivider(label: 'CONFIGURACIÓN'),
          const SizedBox(height: AppDimens.space16),
          animate(_buildConfigCard(), 2),
          const SizedBox(height: AppDimens.space24),
          const HudDivider(label: 'VISTA PREVIA'),
          const SizedBox(height: AppDimens.space16),
          animate(_buildPreviewPlaceholder(), 3),
          const SizedBox(height: AppDimens.space24),
        ],
      ),
    );
  }
}

// ─── _PositionSegment ─────────────────────────────────────────────────────────

class _PositionSegment extends StatelessWidget {
  const _PositionSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.durFast,
        curve: AppMotion.easeStandard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceRaised : Colors.transparent,
          borderRadius: AppDimens.brM,
          border: Border.all(
            color: selected ? AppColors.borderDefault : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
