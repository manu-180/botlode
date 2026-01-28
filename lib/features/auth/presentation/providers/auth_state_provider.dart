// Archivo: lib/features/auth/presentation/providers/auth_state_provider.dart
import 'dart:async';
import 'package:botslode/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Estado de autenticación de la aplicación
/// 
/// Contiene la información del estado actual de login/logout,
/// errores de autenticación y la sesión activa si existe.
class AuthStateData {
  final bool isLoading;
  final String? error;
  final Session? session;

  AuthStateData({this.isLoading = false, this.error, this.session});

  AuthStateData copyWith({bool? isLoading, String? error, Session? session}) {
    return AuthStateData(
      isLoading: isLoading ?? this.isLoading,
      error: error, 
      session: session ?? this.session, 
    );
  }
}

/// Notifier que maneja toda la lógica de autenticación
/// 
/// Responsabilidades:
/// - Escuchar cambios en el estado de autenticación de Supabase
/// - Manejar signIn, signOut y updatePassword
/// - Mapear errores técnicos a mensajes amigables para el usuario
class AuthNotifier extends StateNotifier<AuthStateData> {
  final Ref _ref;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isSigningOut = false; 

  AuthNotifier(this._ref) : super(AuthStateData()) {
    _init();
  }

  void _init() {
    final repo = _ref.read(authRepositoryProvider);
    
    // 1. Check sesión inicial
    final session = repo.currentSession;
    if (session != null) {
      state = state.copyWith(session: session);
    }

    // 2. Escuchar cambios
    _authSubscription = repo.onAuthStateChange.listen((data) {
      if (_isSigningOut) return; 

      final event = data.event;
      final session = data.session;
      
      if (event == AuthChangeEvent.signedOut) {
        state = AuthStateData(); // Reset total al salir
      } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        state = state.copyWith(session: session, isLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // --- MAPEO DE ERRORES (TEXTOS AMIGABLES) ---
  String _mapAuthError(String rawError) {
    final msg = rawError.toLowerCase();
    
    if (msg.contains('invalid login credentials')) {
      return "DATOS INCORRECTOS: El correo o la contraseña no coinciden.";
    }
    if (msg.contains('user already registered')) {
      return "CUENTA EXISTENTE: Este correo ya está registrado.";
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('host lookup')) {
      return "SIN CONEXIÓN: No se pudo contactar con el servidor.";
    }
    if (msg.contains('password should be at least')) {
      return "SEGURIDAD DÉBIL: La contraseña debe tener al menos 6 caracteres.";
    }
    
    // Mensaje genérico sin exponer detalles técnicos
    return "Ocurrió un error al procesar tu solicitud. Por favor, intenta nuevamente.";
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref.read(authRepositoryProvider).signIn(email: email, password: password);
      // El stream actualizará el estado con la sesión
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e.message));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Se perdió la conexión. Verifica tu internet e intenta nuevamente.");
    }
  }

  Future<void> signOut() async {
    _isSigningOut = true;
    
    // Logout Optimista
    state = AuthStateData(); 

    try {
      await _ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      // Error silenciado
    } finally {
      _isSigningOut = false;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref.read(authRepositoryProvider).updatePassword(newPassword);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e.message));
      rethrow; 
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "No pudimos cambiar tu contraseña. Por favor, intenta nuevamente.");
      rethrow;
    }
  }
}

/// Provider principal de autenticación
/// 
/// Expone el estado de autenticación y los métodos para
/// realizar acciones de login/logout/registro.
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  return AuthNotifier(ref);
});
