// lib/core/ui/widgets/hud_popover_menu.dart
// HudPopoverMenu — Menú contextual flotante con estética HUD Hangar OS.
// Panel de vidrio, ítems con hover/focus/disabled, destructivos al final,
// cierre con click afuera / Esc, navegación por teclado ↑↓ Enter.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import '../hud/hud_divider.dart';
import '../states/empty_state.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class HudPopoverItem {
  const HudPopoverItem({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;
  final bool enabled;
}

// ─── Public helper ────────────────────────────────────────────────────────────

/// Muestra el popover anclado en [anchor] (coordenadas globales de pantalla).
/// Retorna un [Future] que se completa cuando el popover se cierra.
Future<void> showHudPopover({
  required BuildContext context,
  required Offset anchor,
  required List<HudPopoverItem> items,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  final focusNode = FocusScopeNode();

  void close() {
    focusNode.dispose();
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (ctx) => _HudPopoverShell(
      anchor: anchor,
      items: items,
      focusScopeNode: focusNode,
      onClose: close,
    ),
  );

  overlay.insert(entry);
  return Future<void>.value();
}

// ─── Shell (barrier + panel) ──────────────────────────────────────────────────

class _HudPopoverShell extends StatefulWidget {
  const _HudPopoverShell({
    required this.anchor,
    required this.items,
    required this.focusScopeNode,
    required this.onClose,
  });

  final Offset anchor;
  final List<HudPopoverItem> items;
  final FocusScopeNode focusScopeNode;
  final VoidCallback onClose;

  @override
  State<_HudPopoverShell> createState() => _HudPopoverShellState();
}

class _HudPopoverShellState extends State<_HudPopoverShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _translateY;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durBase);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance),
    );
    _translateY = Tween<double>(begin: 6, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance),
    );
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.focusScopeNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    final reduce = AppMotion.reduced(context);
    final exitDur =
        reduce ? AppMotion.durCrossfadeReduced : AppMotion.exitOf(AppMotion.durBase);
    await _ctrl.animateBack(0, duration: exitDur, curve: AppMotion.easeExit);
    widget.onClose();
  }

  void _onItemSelected(HudPopoverItem item) {
    _close().then((_) => item.onSelected());
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final screen = MediaQuery.of(context).size;

    // Position panel: below anchor by default, flip above if near bottom.
    const panelWidth = 280.0;
    final showAbove = widget.anchor.dy > screen.height * 0.6;

    double left = widget.anchor.dx;
    if (left + panelWidth > screen.width - AppDimens.space8) {
      left = screen.width - panelWidth - AppDimens.space8;
    }
    left = left.clamp(AppDimens.space8, screen.width - panelWidth - AppDimens.space8);

    return FocusScope(
      node: widget.focusScopeNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _close();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          // Barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          // Panel
          Positioned(
            left: left,
            top: showAbove ? null : widget.anchor.dy,
            bottom: showAbove ? screen.height - widget.anchor.dy : null,
            width: panelWidth,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) {
                if (reduce) {
                  return FadeTransition(opacity: _opacity, child: child);
                }
                return FadeTransition(
                  opacity: _opacity,
                  child: Transform.translate(
                    offset: Offset(0, showAbove ? -_translateY.value : _translateY.value),
                    child: ScaleTransition(
                      scale: _scale,
                      alignment: showAbove
                          ? Alignment.bottomCenter
                          : Alignment.topCenter,
                      child: child,
                    ),
                  ),
                );
              },
              child: _HudPopoverPanel(
                items: widget.items,
                onSelected: _onItemSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel ────────────────────────────────────────────────────────────────────

class _HudPopoverPanel extends StatefulWidget {
  const _HudPopoverPanel({
    required this.items,
    required this.onSelected,
  });

  final List<HudPopoverItem> items;
  final void Function(HudPopoverItem) onSelected;

  @override
  State<_HudPopoverPanel> createState() => _HudPopoverPanelState();
}

class _HudPopoverPanelState extends State<_HudPopoverPanel> {
  int _focusedIndex = 0;

  List<HudPopoverItem> get _regular =>
      widget.items.where((i) => !i.destructive).toList();
  List<HudPopoverItem> get _destructive =>
      widget.items.where((i) => i.destructive).toList();
  List<HudPopoverItem> get _all => [..._regular, ..._destructive];
  List<HudPopoverItem> get _enabled => _all.where((i) => i.enabled).toList();

  void _moveFocus(int delta) {
    if (_enabled.isEmpty) return;
    final newIndex = (_focusedIndex + delta).clamp(0, _enabled.length - 1);
    setState(() => _focusedIndex = newIndex);
  }

  void _activateFocused() {
    if (_focusedIndex < _enabled.length) {
      widget.onSelected(_enabled[_focusedIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _panelContainer(
        child: const Padding(
          padding: EdgeInsets.all(AppDimens.space16),
          child: EmptyState(
            icon: Icons.block_outlined,
            title: 'Sin acciones disponibles',
          ),
        ),
      );
    }

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _moveFocus(1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _moveFocus(-1);
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _activateFocused();
        }
      },
      child: _panelContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildRows(),
          ),
        ),
      ),
    );
  }

  Widget _panelContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: AppDimens.brM,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
          decoration: BoxDecoration(
            color: AppColors.glassSurfaceStrong,
            borderRadius: AppDimens.brM,
            border: const Border(
              top: BorderSide(color: AppColors.glassHighlightTop, width: 1),
              left: BorderSide(color: AppColors.glassBorder, width: 1),
              right: BorderSide(color: AppColors.glassBorder, width: 1),
              bottom: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
            boxShadow: AppDimens.elev3,
          ),
          child: child,
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];
    int enabledIdx = 0;

    // Regular items
    for (final item in _regular) {
      final isFocused =
          item.enabled && enabledIdx == _focusedIndex;
      rows.add(_ItemRow(
        item: item,
        isFocused: isFocused,
        onSelected: () => widget.onSelected(item),
        onHover: item.enabled
            ? () => setState(() => _focusedIndex = enabledIdx)
            : null,
      ));
      if (item.enabled) enabledIdx++;
    }

    // Destructive section separator
    if (_destructive.isNotEmpty && _regular.isNotEmpty) {
      rows.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.space4),
        child: HudDivider(),
      ));
    }

    for (final item in _destructive) {
      final isFocused =
          item.enabled && enabledIdx == _focusedIndex;
      rows.add(_ItemRow(
        item: item,
        isFocused: isFocused,
        onSelected: () => widget.onSelected(item),
        onHover: item.enabled
            ? () => setState(() => _focusedIndex = enabledIdx)
            : null,
      ));
      if (item.enabled) enabledIdx++;
    }

    return rows;
  }
}

// ─── Item row ─────────────────────────────────────────────────────────────────

class _ItemRow extends StatefulWidget {
  const _ItemRow({
    required this.item,
    required this.isFocused,
    required this.onSelected,
    this.onHover,
  });

  final HudPopoverItem item;
  final bool isFocused;
  final VoidCallback onSelected;
  final VoidCallback? onHover;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _isEnabled => widget.item.enabled;

  Color get _iconTextColor {
    if (!_isEnabled) return AppColors.textTertiary;
    if (widget.item.destructive) return AppColors.danger;
    if (_hovered || widget.isFocused) return AppColors.textPrimary;
    return AppColors.textSecondary;
  }

  Color get _fillColor {
    if (!_isEnabled) return Colors.transparent;
    if (_pressed) return AppColors.surfaceHud;
    if (_hovered || widget.isFocused) return AppColors.borderSubtle;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final row = AnimatedContainer(
      duration: AppMotion.durFast,
      curve: AppMotion.easeStandard,
      height: 40,
      color: _fillColor,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
      child: Row(
        children: [
          Icon(
            widget.item.icon,
            size: AppDimens.iconXS,
            color: _isEnabled
                ? _iconTextColor
                : AppColors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Text(
              widget.item.label,
              style: AppTextStyles.bodyM.copyWith(
                color: _isEnabled
                    ? _iconTextColor
                    : AppColors.textTertiary.withValues(alpha: 0.4),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Focus ring indicator
          if (widget.isFocused && _isEnabled)
            Container(
              width: 2,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.cyan,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );

    if (!_isEnabled) {
      return ExcludeSemantics(child: row);
    }

    return Semantics(
      button: true,
      label: widget.item.label,
      enabled: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovered = true);
          widget.onHover?.call();
        },
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onSelected();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: row,
        ),
      ),
    );
  }
}
