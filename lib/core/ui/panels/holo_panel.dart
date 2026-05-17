// lib/core/ui/panels/holo_panel.dart
// HoloPanel: contenedor de vidrio maestro «Hangar OS».
// Soporta: glassmorphism, hover/focus/press, brackets HUD, scanlines, header con
// HudDivider, chaflán o bordes redondeados, glow de acento, reduced-motion.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import '../hud/hud_corner_brackets.dart';
import '../hud/hud_scanlines.dart';
import '../hud/hud_divider.dart';
import '../hud/hud_chamfer.dart';

// ---------------------------------------------------------------------------
// Shape variants
// ---------------------------------------------------------------------------

enum HoloPanelShape {
  /// Bordes redondeados con AppDimens.brL (20 px).
  rounded,

  /// Cantos biselados a 45° con AppDimens.chamferM (12 px).
  chamfer,
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class HoloPanel extends StatefulWidget {
  final Widget child;

  /// Forma del panel. Por defecto [HoloPanelShape.rounded].
  final HoloPanelShape shape;

  /// Padding interior. Por defecto `EdgeInsets.all(AppDimens.space20)`.
  final EdgeInsetsGeometry padding;

  /// Dibuja escuadras HUD en las esquinas del panel.
  final bool cornerBrackets;

  /// Superpone textura de scanlines sobre el panel.
  final bool scanlines;

  /// Si no es nulo, renderiza una zona de encabezado con [HudDivider] y luego
  /// el [child].
  final String? header;

  /// Widgets adicionales a la derecha del título en la zona de encabezado.
  final List<Widget>? headerActions;

  /// Habilita los estados de hover y press. Si [onTap] != null, se activa
  /// automáticamente aunque este flag sea false.
  final bool interactive;

  /// Callback de pulsación; implica [interactive].
  final VoidCallback? onTap;

  /// Color de glow ambiental opcional (estado activo/énfasis).
  final Color? glowAccent;

  /// Sobreescribe el color de borde en estado de reposo. Los estados interactivos
  /// (hover → borderStrong, focus → cyan) siguen teniendo prioridad.
  final Color? borderColor;

  const HoloPanel({
    super.key,
    required this.child,
    this.shape = HoloPanelShape.rounded,
    this.padding = const EdgeInsets.all(AppDimens.space20),
    this.cornerBrackets = false,
    this.scanlines = false,
    this.header,
    this.headerActions,
    this.interactive = false,
    this.onTap,
    this.glowAccent,
    this.borderColor,
  });

  @override
  State<HoloPanel> createState() => _HoloPanelState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _HoloPanelState extends State<HoloPanel>
    with TickerProviderStateMixin {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  late final AnimationController _pressCtrl;
  late final Animation<double> _pressAnim;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durInstant,
      reverseDuration: AppMotion.durFast,
    );
    _pressAnim = CurvedAnimation(
      parent: _pressCtrl,
      curve: AppMotion.easeStandard,
      reverseCurve: AppMotion.easeStandard,
    );

    _entryCtrl = AnimationController(vsync: this, duration: AppMotion.durBase);
    _entryAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: AppMotion.easeEntrance,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _entryCtrl.duration = AppMotion.durCrossfadeReduced;
      }
      _entryCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(HoloPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInteractive) {
      _hovered = false;
      _focused = false;
      _pressed = false;
      _pressCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ---- Interaction helpers ------------------------------------------------

  bool get _isInteractive => widget.interactive || widget.onTap != null;

  void _onEnter(PointerEnterEvent _) {
    if (!_isInteractive) return;
    setState(() => _hovered = true);
  }

  void _onExit(PointerExitEvent _) {
    if (!_isInteractive) return;
    setState(() => _hovered = false);
  }

  void _onTapDown(TapDownDetails _) {
    if (!_isInteractive) return;
    setState(() => _pressed = true);
    final reduce = AppMotion.reduced(context);
    if (!reduce) _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isInteractive) return;
    setState(() => _pressed = false);
    _pressCtrl.reverse();
  }

  void _onTapCancel() {
    if (!_isInteractive) return;
    setState(() => _pressed = false);
    _pressCtrl.reverse();
  }

  void _onFocusChange(bool focused) {
    if (!_isInteractive) return;
    setState(() => _focused = focused);
  }

  void _handleActivate() {
    widget.onTap?.call();
    // Play press animation for keyboard activation
    if (!AppMotion.reduced(context)) {
      _pressCtrl.forward().then((_) => _pressCtrl.reverse());
    }
  }

  // ---- Decoration helpers -------------------------------------------------

  Color get _borderColor {
    if (_focused) return AppColors.cyan;
    if (_hovered || _pressed) return AppColors.borderStrong;
    return widget.borderColor ?? AppColors.glassBorder;
  }

  double get _borderWidth {
    if (_focused) return 2.0;
    if (_hovered || _pressed) return 1.5;
    return 1.0;
  }

  List<BoxShadow> get _shadows {
    final base = (_hovered && !_pressed) ? AppDimens.elev2 : AppDimens.elev1;
    if (widget.glowAccent != null) {
      final glowAlpha = _hovered && !_pressed ? 0.35 : 0.22;
      return [
        ...base,
        BoxShadow(
          color: widget.glowAccent!.withValues(alpha: glowAlpha),
          blurRadius: 18,
          spreadRadius: 1,
        ),
      ];
    }
    return base;
  }

  // ---- Decorations for rounded vs chamfer ---------------------------------

  Decoration get _roundedDecoration => BoxDecoration(
        color: Colors.transparent,
        borderRadius: AppDimens.brL,
        border: Border.all(color: _borderColor, width: _borderWidth),
        boxShadow: _shadows,
      );

  ShapeDecoration get _chamferDecoration => ShapeDecoration(
        color: Colors.transparent,
        shape: ChamferBorder(
          chamfer: AppDimens.chamferM,
          side: BorderSide(color: _borderColor, width: _borderWidth),
        ),
        shadows: _shadows,
      );

  // ---- Content (padding + optional header + child) ------------------------

  Widget _buildContent() {
    if (widget.header == null) {
      return Padding(padding: widget.padding, child: widget.child);
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.header!,
                  style: AppTextStyles.titleM.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ...?widget.headerActions,
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          const HudDivider(),
          const SizedBox(height: AppDimens.space16),
          widget.child,
        ],
      ),
    );
  }

  // ---- Glass layers (inside the clip) -------------------------------------

  Widget _buildGlassLayers() {
    final content = _buildContent();

    // Highlight de 1 px en el borde superior.
    final topHighlight = Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, AppColors.glassHighlightTop, Colors.transparent],
          ),
        ),
      ),
    );

    Widget glassStack = Stack(
      children: [
        // Relleno de vidrio.
        Positioned.fill(
          child: Container(color: AppColors.glassSurface),
        ),
        // Highlight superior.
        topHighlight,
        // Scanlines (si aplica).
        if (widget.scanlines)
          const Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: HudScanlines(
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        // Contenido (topmost — sobre scanlines; IgnorePointer gestiona eventos).
        content,
      ],
    );

    return glassStack;
  }

  // ---- Clipped + blurred panel --------------------------------------------

  Widget _buildPanel() {
    final glassContent = _buildGlassLayers();

    if (widget.shape == HoloPanelShape.rounded) {
      return AnimatedContainer(
        duration: AppMotion.durFast,
        curve: AppMotion.easeStandard,
        decoration: _roundedDecoration,
        child: ClipRRect(
          borderRadius: AppDimens.brL,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: glassContent,
          ),
        ),
      );
    } else {
      // chamfer
      return AnimatedContainer(
        duration: AppMotion.durFast,
        curve: AppMotion.easeStandard,
        decoration: _chamferDecoration,
        child: ClipPath(
          clipper: const ChamferClipper(chamfer: AppDimens.chamferM),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: glassContent,
          ),
        ),
      );
    }
  }

  // ---- Full widget build --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    // Press scale animation.
    Widget panel = AnimatedBuilder(
      animation: _pressAnim,
      builder: (_, child) {
        final scale = 1.0 - (_pressAnim.value * (1.0 - AppMotion.pressScale));
        return Transform.scale(scale: scale, child: child);
      },
      child: MouseRegion(
        cursor: _isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: _isInteractive ? _onEnter : null,
        onExit: _isInteractive ? _onExit : null,
        child: GestureDetector(
          onTapDown: _isInteractive ? _onTapDown : null,
          onTapUp: _isInteractive ? _onTapUp : null,
          onTapCancel: _isInteractive ? _onTapCancel : null,
          onTap: widget.onTap,
          child: _buildPanel(),
        ),
      ),
    );

    // Focus ring and keyboard activation.
    if (_isInteractive) {
      panel = Focus(
        onFocusChange: _onFocusChange,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            _handleActivate();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: panel,
      );
    }

    // Corner brackets outside the clip.
    // HudCornerBrackets already uses IgnorePointer on its CustomPaint overlay,
    // so pointer events pass through to the panel. CustomPaint emits no
    // semantic nodes, so no wrapper is needed.
    if (widget.cornerBrackets) {
      panel = HudCornerBrackets(
        color: AppColors.borderGold,
        child: panel,
      );
    }

    // Semantics wrapper for interactive panels.
    if (_isInteractive) {
      panel = Semantics(
        button: true,
        onTap: widget.onTap,
        child: panel,
      );
    }

    // Entry animation (runs once on mount via _entryCtrl).
    panel = AnimatedBuilder(
      animation: _entryAnim,
      builder: (_, child) {
        final t = _entryAnim.value;
        return Opacity(
          opacity: t,
          child: reduced
              ? child!
              : Transform.translate(
                  offset: Offset(0, (1.0 - t) * 12.0),
                  child: child,
                ),
        );
      },
      child: panel,
    );

    return panel;
  }
}
