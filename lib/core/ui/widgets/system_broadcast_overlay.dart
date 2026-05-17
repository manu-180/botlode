// lib/core/ui/widgets/system_broadcast_overlay.dart
// Overlay de transmisión del sistema — reemplaza _showEpicNotify.
// No modal: no bloquea interacción. Se autodescarta. Variantes: info / success / error.
// Animación de entrada: fade + escala 0.92→1.0, easeEntrance, durSlow.
// Salida: fade + escala 1.0→0.96, easeExit, durBase.
// Reduced-motion: solo fade 120 ms, sin escala, sin tipeo, sin reveal de brackets.
import 'dart:async';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

enum BroadcastType { info, success, error }

class SystemBroadcastOverlay {
  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required String message,
    BroadcastType type = BroadcastType.info,
    String? statusLine,
  }) {
    // Dismiss any active overlay immediately before showing the new one.
    _activeEntry?.remove();
    _activeEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BroadcastWidget(
        message: message,
        type: type,
        statusLine: statusLine,
        onDismiss: () {
          entry.remove();
          if (_activeEntry == entry) _activeEntry = null;
        },
      ),
    );
    _activeEntry = entry;
    Overlay.of(context).insert(entry);
  }
}

// ---------------------------------------------------------------------------
// Internal widget
// ---------------------------------------------------------------------------

class _BroadcastWidget extends StatefulWidget {
  final String message;
  final BroadcastType type;
  final String? statusLine;
  final VoidCallback onDismiss;

  const _BroadcastWidget({
    required this.message,
    required this.type,
    required this.statusLine,
    required this.onDismiss,
  });

  @override
  State<_BroadcastWidget> createState() => _BroadcastWidgetState();
}

class _BroadcastWidgetState extends State<_BroadcastWidget>
    with TickerProviderStateMixin {
  // Entry: 0→1, scale 0.92→1.0, durSlow
  late final AnimationController _entryCtrl;
  // Exit: 0→1, scale 1.0→0.96, durBase
  late final AnimationController _exitCtrl;
  // HudCornerBrackets arm reveal: 0→20, durBase
  late final AnimationController _bracketCtrl;

  late final Animation<double> _entryOpacity;
  late final Animation<double> _entryScale;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;
  late final Animation<double> _armLength;

  // Typewriter state
  String _displayedText = '';
  int _charIndex = 0;
  bool _typingDone = false;
  bool _cursorVisible = true;

  Timer? _typingTimer;
  Timer? _cursorTimer;
  Timer? _dismissTimer;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: AppMotion.durSlow);
    _exitCtrl = AnimationController(vsync: this, duration: AppMotion.durBase);
    _bracketCtrl = AnimationController(vsync: this, duration: AppMotion.durBase);

    _entryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: AppMotion.easeEntrance),
    );
    _entryScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: AppMotion.easeEntrance),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: AppMotion.easeExit),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _exitCtrl, curve: AppMotion.easeExit),
    );
    _armLength = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _bracketCtrl, curve: AppMotion.easeEntrance),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = AppMotion.reduced(context);

      if (reduced) {
        // Reduced-motion: instant display, no scale, no bracket reveal
        _entryCtrl.duration = AppMotion.durCrossfadeReduced;
        _exitCtrl.duration = AppMotion.durCrossfadeReduced;
        _bracketCtrl.value = 1.0;
        _entryCtrl.forward().then((_) {
          if (mounted) _startTypingOrShow(reduced: true);
        });
      } else {
        _bracketCtrl.forward();
        _entryCtrl.forward().then((_) {
          if (mounted) _startTypingOrShow(reduced: false);
        });
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _exitCtrl.dispose();
    _bracketCtrl.dispose();
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _startTypingOrShow({required bool reduced}) {
    if (reduced) {
      // Show full text immediately
      if (mounted) {
        setState(() {
          _displayedText = widget.message;
          _typingDone = true;
        });
        _scheduleDismiss();
      }
      return;
    }

    // Typewriter: ~28 ms per character — not a standard motion token
    _typingTimer = Timer.periodic(
      const Duration(milliseconds: 28), // Typewriter tick — not a standard motion token
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _charIndex++;
          if (_charIndex <= widget.message.length) {
            _displayedText = widget.message.substring(0, _charIndex);
          }
          if (_charIndex >= widget.message.length) {
            timer.cancel();
            _typingDone = true;
            _startCursorBlink();
            _scheduleDismiss();
          }
        });
      },
    );
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(
      const Duration(milliseconds: 600), // Cursor blink rate — not a standard motion token
      (_) {
        if (mounted) setState(() => _cursorVisible = !_cursorVisible);
      },
    );
  }

  void _scheduleDismiss() {
    _dismissTimer = Timer(const Duration(milliseconds: 2000), () { // Auto-dismiss delay — not a standard motion token
      if (mounted) _exit();
    });
  }

  void _exit() {
    if (_exiting) return;
    _exiting = true;
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _exitCtrl.forward().then((_) => widget.onDismiss());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Color _accentColor() => switch (widget.type) {
        BroadcastType.info => AppColors.gold,
        BroadcastType.success => AppColors.success,
        BroadcastType.error => AppColors.danger,
      };

  IconData _icon() => switch (widget.type) {
        BroadcastType.info => AppIcons.terminal,
        BroadcastType.success => AppIcons.check,
        BroadcastType.error => AppIcons.warning,
      };

  String _defaultStatusLine() => switch (widget.type) {
        BroadcastType.info => 'OPERACIÓN COMPLETADA',
        BroadcastType.success => 'ESTADO: OK',
        BroadcastType.error => 'ESTADO: ERROR',
      };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final accent = _accentColor();
    final statusLine = widget.statusLine ?? _defaultStatusLine();

    // Cursor: only show while typing (not in reduced mode)
    final cursorChar =
        (!_typingDone && !reduced) ? (_cursorVisible ? '_' : ' ') : '';

    // Panel content
    final panelContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '// TRANSMISIÓN DEL SISTEMA',
          style: AppTextStyles.labelSmall.copyWith(
            color: accent,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        AppIcons.icon(_icon(), size: AppDimens.iconL, color: accent),
        const SizedBox(height: AppDimens.space16),
        // Expose full message text to semantics from the start (not the
        // typewriter-partial text) so screen readers announce it immediately.
        Semantics(
          liveRegion: true,
          label: widget.message,
          excludeSemantics: true,
          child: Text(
            _displayedText + cursorChar,
            style: AppTextStyles.titleM.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        Text(
          statusLine,
          style: AppTextStyles.mono.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );

    // HoloPanel (without built-in cornerBrackets — we animate them separately)
    Widget panel = HoloPanel(
      shape: HoloPanelShape.chamfer,
      cornerBrackets: false,
      scanlines: true,
      borderColor: accent,
      glowAccent: accent,
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space24,
        horizontal: AppDimens.space32,
      ),
      child: panelContent,
    );

    // Animated HudCornerBrackets (arm 0→20 during entry; static at 20 in reduced)
    panel = AnimatedBuilder(
      animation: _armLength,
      builder: (_, child) => HudCornerBrackets(
        color: accent,
        armLength: _armLength.value,
        child: child!,
      ),
      child: panel,
    );

    // Entry + exit animation overlay.
    // opacity = entryOpacity * exitOpacity (non-overlapping phases → multiplicative combine works)
    // scale   = entryScale   * exitScale   (same reasoning)
    panel = AnimatedBuilder(
      animation: Listenable.merge([_entryOpacity, _exitOpacity, _entryScale, _exitScale]),
      builder: (_, child) {
        final opacity = (_entryOpacity.value * _exitOpacity.value).clamp(0.0, 1.0);
        final scale = _entryScale.value * _exitScale.value;
        return Opacity(
          opacity: opacity,
          child: reduced ? child! : Transform.scale(scale: scale, child: child),
        );
      },
      child: panel,
    );

    // Constrained width, centered, non-interactive (IgnorePointer)
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, minWidth: 280),
              child: panel,
            ),
          ),
        ),
      ),
    );
  }
}
