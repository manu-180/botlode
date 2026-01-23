// Archivo: lib/features/auth/domain/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Flujo de cambios en el estado de autenticación (Login, Logout, Token Refreshed).
  Stream<AuthState> get onAuthStateChange;

  /// Obtiene la sesión actual si existe.
  Session? get currentSession;

  /// Inicia sesión con correo y contraseña.
  Future<AuthResponse> signIn({required String email, required String password});

  /// Registra un nuevo usuario.
  Future<AuthResponse> signUp({required String email, required String password});

  /// Cierra la sesión actual.
  Future<void> signOut();

  /// Actualiza la contraseña del usuario autenticado.
  Future<UserResponse> updatePassword(String newPassword);
}