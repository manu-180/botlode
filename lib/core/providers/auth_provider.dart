// Archivo: lib/core/providers/auth_provider.dart
// 
// Este archivo re-exporta el provider de autenticación desde su ubicación correcta
// en el feature auth. Mantiene compatibilidad con código existente mientras
// respeta Clean Architecture.

export 'package:botslode/features/auth/presentation/providers/auth_state_provider.dart' show authStateProvider, AuthStateData, authUserIdProvider;

// Alias para retrocompatibilidad
import 'package:botslode/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider de autenticación (alias para retrocompatibilidad)
/// 
/// DEPRECATED: Usar authStateProvider directamente del feature auth.
final authProvider = authStateProvider;