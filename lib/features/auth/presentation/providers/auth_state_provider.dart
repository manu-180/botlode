// Archivo: lib/features/auth/presentation/providers/auth_state_provider.dart
import 'dart:async';
import 'package:botslode/core/observability/app_logger.dart';
import 'package:botslode/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Estado de autenticación de la aplicación.
///
/// Información del login/logout, errores y sesión activa si existe.
class AuthStateData {
  final bool isLoading;
  final String? error;
  final Session? session;

  AuthStateData({this.isLoading = false, this.error, this.session});

  AuthStateData copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    Object? session = _sentinel,
  }) {
    return AuthStateData(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      session: identical(session, _sentinel) ? this.session : session as Session?,
    );
  }

  static const Object _sentinel = Object();
}

/// Notifier moderno (Riverpod 2.x) que maneja la lógica de autenticación.
///
/// • Escucha cambios en `Supabase.auth.onAuthStateChange`.
/// • Hace signIn, signOut, updatePassword.
/// • Mapea errores técnicos a mensajes amigables.
class AuthNotifier extends Notifier<AuthStateData> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isSigningOut = false;

  @override
  AuthStateData build() {
    final repo = ref.read(authRepositoryProvider);

    // 1. Check sesión inicial.
    final session = repo.currentSession;
    final initial =
        session != null ? AuthStateData(session: session) : AuthStateData();

    // 2. Escuchar cambios.
    _authSubscription = repo.onAuthStateChange.listen((data) {
      if (_isSigningOut) return;
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedOut) {
        state = AuthStateData(); // Reset total al salir.
      } else if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        state = state.copyWith(session: session, isLoading: false);
      }
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
      _authSubscription = null;
    });

    return initial;
  }

  // --- MAPEO DE ERRORES (TEXTOS AMIGABLES) ---
  String _mapAuthError(String rawError) {
    final msg = rawError.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'DATOS INCORRECTOS: El correo o la contraseña no coinciden.';
    }
    if (msg.contains('user already registered')) {
      return 'CUENTA EXISTENTE: Este correo ya está registrado.';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('host lookup')) {
      return 'SIN CONEXIÓN: No se pudo contactar con el servidor.';
    }
    if (msg.contains('password should be at least')) {
      return 'SEGURIDAD DÉBIL: La contraseña debe tener al menos 6 caracteres.';
    }
    return 'Ocurrió un error al procesar tu solicitud. Por favor, intenta nuevamente.';
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      // El stream actualizará el state.session.
    } on AuthException catch (e) {
      state =
          state.copyWith(isLoading: false, error: _mapAuthError(e.message));
    } catch (e, st) {
      AppLogger.error('auth.signIn', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        error: 'Se perdió la conexión. Verificá tu internet e intentá nuevamente.',
      );
    }
  }

  Future<void> signOut() async {
    _isSigningOut = true;
    // Logout optimista para que la UI responda al toque.
    state = AuthStateData();
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (e, st) {
      AppLogger.warn('auth.signOut.error', error: e);
      // No re-tiramos: ya está hecho local.
    } finally {
      _isSigningOut = false;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state =
          state.copyWith(isLoading: false, error: _mapAuthError(e.message));
      rethrow;
    } catch (e, st) {
      AppLogger.error('auth.updatePassword', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cambiar tu contraseña. Por favor, intentá nuevamente.',
      );
      rethrow;
    }
  }
}

/// Provider principal de autenticación.
final authStateProvider =
    NotifierProvider<AuthNotifier, AuthStateData>(AuthNotifier.new);

/// ID del usuario actual desde la sesión de auth.
///
/// Fuente de verdad para `userId`; se actualiza tras login/logout/refresh.
final authUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.session?.user.id;
});
