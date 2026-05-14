// Archivo: lib/core/widgets/async_value_widget.dart
//
// Render uniforme de AsyncValue<T> en la fábrica.
// Coherente con el tema dark + dorado (#FFC000) de Oxanium.

import 'package:botslode/core/observability/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
    this.compact = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final WidgetBuilder? loading;
  final Widget Function(Object error, StackTrace? stack)? error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading?.call(context) ?? _DefaultLoading(compact: compact),
      error: (e, st) {
        AppLogger.warn('async.error', error: e);
        return error?.call(e, st) ??
            _DefaultError(error: e, onRetry: onRetry, compact: compact);
      },
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading({required this.compact});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: compact ? 16 : 24,
        height: compact ? 16 : 24,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFFFC000),
        ),
      ),
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError({required this.error, this.onRetry, required this.compact});
  final Object error;
  final VoidCallback? onRetry;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final msg = _humanize(error);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: compact ? 18 : 24, color: const Color(0xFFFF003C)),
            const SizedBox(height: 6),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: compact ? 11 : 13,
                fontFamily: 'Oxanium',
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFC000)),
                  foregroundColor: const Color(0xFFFFC000),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _humanize(Object error) {
    final s = error.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Sin conexión. Revisá tu red y reintentá.';
    }
    if (s.contains('AuthException')) return 'Sesión expirada. Volvé a entrar.';
    return 'No pude cargar esta sección.';
  }
}
