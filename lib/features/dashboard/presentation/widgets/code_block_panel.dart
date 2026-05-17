// Archivo: lib/features/dashboard/presentation/widgets/code_block_panel.dart
//
// Widget terminal-style reutilizable para mostrar bloques de código con
// numeración de líneas, scroll, copia al portapapeles y flash de borde al cambiar.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';

// ─── Constantes locales (no magic numbers — derivadas del spec) ───────────────

/// Alto fijo de la barra de título del terminal, alineado con AppDimens.titleBarHeight.
const double _kTitleBarHeight = AppDimens.titleBarHeight; // 36 px

/// Ancho fijo de la columna de números de línea.
const double _kLineNumberWidth = 44.0;

/// Altura máxima del área de código antes de activar scroll.
const double _kMaxCodeHeight = 320.0;

/// Diámetro de los círculos semáforo decorativos.
const double _kSemaphoreSize = 8.0;

/// Separación entre círculos semáforo.
const double _kSemaphoreGap = 6.0;

/// Opacidad de los círculos semáforo (muy atenuados, decorativos).
const double _kSemaphoreOpacity = 0.25;

/// Duración del estado «copiado» antes de restaurar la etiqueta del botón.
const Duration _kCopiedResetDuration = Duration(milliseconds: 1600);

// ─── CodeBlockPanel ───────────────────────────────────────────────────────────

class CodeBlockPanel extends StatefulWidget {
  const CodeBlockPanel({
    super.key,
    required this.code,
    this.title = '// EMBED · iframe + script',
    this.onCopied,
  });

  /// Código a mostrar en el bloque.
  final String code;

  /// Etiqueta de la barra de título del terminal.
  final String title;

  /// Callback invocado después de copiar al portapapeles (el padre muestra toast).
  final VoidCallback? onCopied;

  @override
  State<CodeBlockPanel> createState() => _CodeBlockPanelState();
}

class _CodeBlockPanelState extends State<CodeBlockPanel> {
  bool _copied = false;
  Timer? _copiedTimer;
  bool _borderFlash = false;

  // Controladores de scroll sincronizados para líneas y código.
  late final ScrollController _lineNumberScroll;
  late final ScrollController _codeScroll;

  @override
  void initState() {
    super.initState();
    _lineNumberScroll = ScrollController();
    _codeScroll = ScrollController();
    _codeScroll.addListener(_syncLineScroll);
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _codeScroll.removeListener(_syncLineScroll);
    _lineNumberScroll.dispose();
    _codeScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CodeBlockPanel old) {
    super.didUpdateWidget(old);
    if (old.code != widget.code) {
      _flashBorder();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<String> _lines(String code) => code.split('\n');

  void _syncLineScroll() {
    if (!_lineNumberScroll.hasClients) return;
    final offset = _codeScroll.offset;
    if (_lineNumberScroll.offset != offset) {
      _lineNumberScroll.jumpTo(offset);
    }
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    widget.onCopied?.call();

    // Anuncio de accesibilidad
    // ignore: deprecated_member_use
    SemanticsService.announce('Código copiado', TextDirection.ltr);

    _copiedTimer?.cancel();
    _copiedTimer = Timer(_kCopiedResetDuration, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _flashBorder() {
    if (AppMotion.reduced(context)) return;
    setState(() => _borderFlash = true);
    Future.delayed(AppMotion.durFast, () {
      if (mounted) setState(() => _borderFlash = false);
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final borderColor =
        _borderFlash ? AppColors.cyan : AppColors.borderDefault;

    return Semantics(
      label: 'Código de inserción del player, solo lectura',
      child: AnimatedContainer(
        duration: AppMotion.durFast,
        curve: AppMotion.easeStandard,
        decoration: BoxDecoration(
          color: AppColors.surfaceHud,
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TitleBar(
              title: widget.title,
              copied: _copied,
              onCopy: _handleCopy,
            ),
            _CodeBody(
              code: widget.code,
              lines: _lines(widget.code),
              lineNumberScroll: _lineNumberScroll,
              codeScroll: _codeScroll,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _TitleBar ────────────────────────────────────────────────────────────────

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.title,
    required this.copied,
    required this.onCopy,
  });

  final String title;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final titleBarBg =
        Color.lerp(AppColors.surfaceHud, Colors.black, 0.3)!;

    return Container(
      height: _kTitleBarHeight,
      decoration: BoxDecoration(
        color: titleBarBg,
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
      child: Row(
        children: [
          // Semáforo decorativo
          const _Semaphore(),
          // Título centrado
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.mono.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Botón copiar
          AppButton(
            label: copied ? 'COPIADO ✓' : 'COPIAR',
            onPressed: onCopy,
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            leadingIcon: copied
                ? Icons.check_rounded
                : Icons.content_copy_rounded,
          ),
        ],
      ),
    );
  }
}

// ─── _Semaphore ───────────────────────────────────────────────────────────────

class _Semaphore extends StatelessWidget {
  const _Semaphore();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SemaphoreCircle(color: AppColors.textTertiary),
          SizedBox(width: _kSemaphoreGap),
          _SemaphoreCircle(color: AppColors.danger),
          SizedBox(width: _kSemaphoreGap),
          _SemaphoreCircle(color: AppColors.success),
          SizedBox(width: AppDimens.space8),
        ],
      ),
    );
  }
}

class _SemaphoreCircle extends StatelessWidget {
  const _SemaphoreCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSemaphoreSize,
      height: _kSemaphoreSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _kSemaphoreOpacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── _CodeBody ────────────────────────────────────────────────────────────────

class _CodeBody extends StatelessWidget {
  const _CodeBody({
    required this.code,
    required this.lines,
    required this.lineNumberScroll,
    required this.codeScroll,
  });

  final String code;
  final List<String> lines;
  final ScrollController lineNumberScroll;
  final ScrollController codeScroll;

  @override
  Widget build(BuildContext context) {
    final lineNumberBg =
        Color.lerp(AppColors.surfaceHud, Colors.black, 0.15)!;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _kMaxCodeHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Columna de números de línea ──────────────────────────────────
          ExcludeSemantics(
            child: Container(
              width: _kLineNumberWidth,
              decoration: BoxDecoration(
                color: lineNumberBg,
                border: const Border(
                  right: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: ListView.builder(
                controller: lineNumberScroll,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.space16,
                ),
                itemCount: lines.length,
                itemBuilder: (context, index) => _LineNumber(
                  number: index + 1,
                ),
              ),
            ),
          ),
          // ── Columna de código ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: codeScroll,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: SelectableText(
                    code,
                    style: AppTextStyles.mono.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _LineNumber ──────────────────────────────────────────────────────────────

class _LineNumber extends StatelessWidget {
  const _LineNumber({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.space8),
      child: Text(
        '$number',
        textAlign: TextAlign.right,
        style: AppTextStyles.mono.copyWith(
          color: AppColors.textTertiary.withValues(alpha: 0.5),
          fontSize: 11,
        ),
      ),
    );
  }
}
