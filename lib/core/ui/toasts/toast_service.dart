// lib/core/ui/toasts/toast_service.dart
// Ciclo de vida del sistema de toasts «Hangar OS»:
// cola (máx 3 visibles), AnimatedList en overlay, timer, hover-pause.
//
// Uso:
//   ToastService.show(context: context, type: ToastType.success, message: '...');
import 'package:flutter/material.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import 'app_toast.dart';

export 'app_toast.dart' show ToastType;

// ─── Modelo de datos ──────────────────────────────────────────────────────────

class _ToastData {
  static int _nextId = 0;

  final String id;
  final ToastType type;
  final String message;
  final String? title;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionLabel;

  _ToastData({
    required this.type,
    required this.message,
    this.title,
    required this.duration,
    this.onAction,
    this.actionLabel,
  }) : id = '${_nextId++}';
}

// ─── Item animado ─────────────────────────────────────────────────────────────

class _AnimatedToastItem extends StatefulWidget {
  final _ToastData data;
  final Animation<double> entryAnimation;
  final VoidCallback onDismiss;

  const _AnimatedToastItem({
    required super.key,
    required this.data,
    required this.entryAnimation,
    required this.onDismiss,
  });

  @override
  State<_AnimatedToastItem> createState() => _AnimatedToastItemState();
}

class _AnimatedToastItemState extends State<_AnimatedToastItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: widget.data.duration,
      value: 1.0, // comienza llena
    );
    _progressCtrl.reverse(); // vacía de 1.0 → 0.0 en `duration`
    _progressCtrl.addStatusListener(_onProgressStatus);
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted && !_dismissed) {
      _triggerDismiss();
    }
  }

  void _triggerDismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _progressCtrl.stop();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _progressCtrl.removeStatusListener(_onProgressStatus);
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);

    final curved = CurvedAnimation(
      parent: widget.entryAnimation,
      curve: reduce ? Curves.linear : AppMotion.easeEntrance,
    );

    final slide = reduce
        ? const AlwaysStoppedAnimation<Offset>(Offset.zero)
        : Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(curved);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space12),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: MouseRegion(
            onEnter: (_) => _progressCtrl.stop(),
            onExit: (_) {
              if (!_dismissed) _progressCtrl.reverse();
            },
            child: AppToast(
              type: widget.data.type,
              message: widget.data.message,
              title: widget.data.title,
              actionLabel: widget.data.actionLabel,
              onAction: widget.data.onAction,
              onDismiss: _triggerDismiss,
              progress: _progressCtrl,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Overlay (stack de toasts) ────────────────────────────────────────────────

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({required super.key});

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _items = <_ToastData>[];

  void add(_ToastData data) {
    final reduce = AppMotion.reduced(context);
    _items.insert(0, data);
    _listKey.currentState?.insertItem(
      0,
      duration: reduce ? AppMotion.durCrossfadeReduced : AppMotion.durSlow,
    );
  }

  void removeItem(String id) {
    final index = _items.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final removed = _items.removeAt(index);
    final reduce = AppMotion.reduced(context);
    final exitDuration = reduce
        ? AppMotion.durCrossfadeReduced
        : AppMotion.exitOf(AppMotion.durSlow);

    _listKey.currentState?.removeItem(
      index,
      (ctx, animation) => _buildExiting(removed, animation, reduce),
      duration: exitDuration,
    );
    ToastService.instance._onToastRemoved(exitDuration);
  }

  Widget _buildExiting(
    _ToastData data,
    Animation<double> animation,
    bool reduce,
  ) {
    // animation va de 1.0 → 0.0 durante la salida
    final curved = CurvedAnimation(
      parent: animation,
      curve: reduce ? Curves.linear : AppMotion.easeExit,
    );
    final slide = reduce
        ? const AlwaysStoppedAnimation<Offset>(Offset.zero)
        : Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(curved);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space12),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: AppToast(
            type: data.type,
            message: data.message,
            title: data.title,
            actionLabel: data.actionLabel,
            onAction: data.actionLabel != null ? () {} : null,
            onDismiss: () {},
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppDimens.titleBarHeight + AppDimens.space24,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 380,
          child: AnimatedList(
            key: _listKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            initialItemCount: 0,
            itemBuilder: (_, index, animation) {
              final data = _items[index];
              return _AnimatedToastItem(
                key: ValueKey(data.id),
                data: data,
                entryAnimation: animation,
                onDismiss: () => removeItem(data.id),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Servicio ─────────────────────────────────────────────────────────────────

class ToastService {
  ToastService._();
  static final ToastService instance = ToastService._();

  OverlayEntry? _overlayEntry;
  GlobalKey<_ToastOverlayState>? _overlayKey;
  final _queue = <_ToastData>[];
  int _visibleCount = 0;

  static const int _maxVisible = 3;

  static void show({
    required BuildContext context,
    required ToastType type,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    instance._show(
      context: context,
      type: type,
      message: message,
      title: title,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  void _show({
    required BuildContext context,
    required ToastType type,
    required String message,
    String? title,
    required Duration duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final data = _ToastData(
      type: type,
      message: message,
      title: title,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );

    _ensureOverlay(context);

    if (_visibleCount < _maxVisible) {
      _displayToast(data);
    } else {
      _queue.add(data);
    }
  }

  void _ensureOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    final key = GlobalKey<_ToastOverlayState>();
    _overlayKey = key;

    _overlayEntry = OverlayEntry(
      builder: (_) => _ToastOverlay(key: key),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _displayToast(_ToastData data) {
    _visibleCount++;
    // addPostFrameCallback garantiza que el overlay esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayKey?.currentState?.add(data);
    });
  }

  void _onToastRemoved(Duration exitDuration) {
    _visibleCount = (_visibleCount - 1).clamp(0, _maxVisible);

    if (_queue.isNotEmpty && _visibleCount < _maxVisible) {
      final next = _queue.removeAt(0);
      _displayToast(next);
    }

    // Esperar a que termine la animación de salida antes de retirar el overlay
    if (_visibleCount == 0 && _queue.isEmpty) {
      Future.delayed(
        exitDuration + const Duration(milliseconds: 50),
        () {
          if (_visibleCount == 0 && _queue.isEmpty) {
            _overlayEntry?.remove();
            _overlayEntry = null;
            _overlayKey = null;
          }
        },
      );
    }
  }
}
