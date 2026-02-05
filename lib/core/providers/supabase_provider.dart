// Archivo: lib/core/providers/supabase_provider.dart
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

/// Provider para obtener el ID del usuario actual
/// 
/// Retorna null si no hay usuario autenticado.
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

/// Provider para obtener el email del usuario actual
/// 
/// Retorna string vacío si no hay usuario autenticado o no tiene email.
final currentUserEmailProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email ?? '';
});

/// UUID del usuario con ciclo en velocidad aumentada (30 seg = 1 ciclo mensual).
/// Solo este usuario ve el ciclo turbo; el resto usa ciclo real de 30 días.
const String _turboTimerUserId = '38152119-7da4-442e-9826-20901c65f42e';

/// Indica si el usuario actual debe usar ciclo en velocidad aumentada (turbo).
/// true = ciclo de 30 segundos; false = ciclo real de 30 días.
final useTurboTimerProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return userId == _turboTimerUserId;
});
