// Archivo: lib/core/providers/supabase_provider.dart
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider centralizado para el cliente de Supabase
/// 
/// Encapsula el acceso a Supabase.instance.client para facilitar
/// inyección de dependencias y testing.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider para obtener el usuario autenticado actual
/// 
/// Retorna null si no hay usuario autenticado.
/// Este provider se actualiza automáticamente cuando cambia el estado de autenticación.
final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
});

/// Provider para obtener el ID del usuario actual.
/// Usa authUserIdProvider (sesión de auth) como fuente de verdad para garantizar
/// que se actualice correctamente tras login y que useTurboTimer funcione.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authUserIdProvider);
});

/// Provider para obtener el email del usuario actual
/// 
/// Retorna string vacío si no hay usuario autenticado o no tiene email.
final currentUserEmailProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email ?? '';
});

/// Indica si el usuario actual debe usar ciclo en velocidad aumentada (turbo).
/// TODO T18: reemplazar por feature_flags por tenant/user.
/// Hasta entonces, el turbo timer queda apagado por defecto en producción.
final useTurboTimerProvider = Provider<bool>((ref) => false);
