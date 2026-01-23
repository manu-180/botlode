// Archivo: lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:botslode/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  @override
  Session? get currentSession => _supabase.auth.currentSession;

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      return await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      debugPrint("🔴 Auth Repo SignIn Error: $e");
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    try {
      return await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      debugPrint("🔴 Auth Repo SignUp Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("🔴 Auth Repo SignOut Error: $e");
      // No relanzamos, intentamos salir igual localmente
    }
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      debugPrint("🔴 Auth Repo UpdatePassword Error: $e");
      rethrow;
    }
  }
}