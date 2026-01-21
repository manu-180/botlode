// Archivo: lib/core/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final Session? session;

  AuthState({this.isLoading = false, this.error, this.session});

  AuthState copyWith({bool? isLoading, String? error, Session? session}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error, 
      session: session ?? this.session, 
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSigningOut = false; 

  AuthNotifier() : super(AuthState()) {
    _checkCurrentSession();
    
    _supabase.auth.onAuthStateChange.listen((data) {
      if (_isSigningOut) return; 

      final event = data.event;
      final session = data.session;
      
      debugPrint("📢 AUTH EVENT: $event");
      
      if (event == AuthChangeEvent.signedOut) {
        state = AuthState(); // Reset total al salir
      } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        state = state.copyWith(session: session, isLoading: false);
      }
    });
  }

  void _checkCurrentSession() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      state = state.copyWith(session: session);
    }
  }

  // --- MAPEO DE ERRORES (TEXTOS AMIGABLES) ---
  String _mapAuthError(String rawError) {
    final msg = rawError.toLowerCase();
    
    // DETECCIÓN ESPECÍFICA: Credenciales incorrectas
    if (msg.contains('invalid login credentials')) {
      // CAMBIO AQUÍ: Mensaje más suave y claro para el humano
      return "DATOS INCORRECTOS: El correo o la contraseña no coinciden. Por favor, verifícalos e intenta de nuevo.";
    }
    
    if (msg.contains('user already registered')) {
      return "CUENTA EXISTENTE: Este correo ya está registrado en el sistema. Intenta iniciar sesión.";
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return "SIN CONEXIÓN: No se pudo contactar con el servidor. Revisa tu internet.";
    }
    
    return "ERROR DE SISTEMA: $rawError";
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      // Mapeamos el error amigable y quitamos el loading sin tocar la sesión
      state = state.copyWith(isLoading: false, error: _mapAuthError(e.message));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "ERROR CRÍTICO: Se interrumpió la conexión.");
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e.message));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "ERROR CRÍTICO: No se pudo crear el registro.");
    }
  }

  Future<void> signOut() async {
    debugPrint("🛑 EJECUTANDO PROTOCOLO DE SALIDA...");
    _isSigningOut = true;
    
    // Logout Optimista
    state = AuthState(); 

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("⚠️ Cierre local forzado.");
    } finally {
      _isSigningOut = false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});