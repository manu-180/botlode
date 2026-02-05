// Archivo: lib/features/hunter_bot/presentation/providers/hunter_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/features/hunter_bot/data/repositories/hunter_repository_impl.dart';
import 'package:botslode/features/hunter_bot/domain/repositories/hunter_repository.dart';

/// Provider del repositorio de HunterBot
/// Proporciona una instancia singleton del repositorio
final hunterRepositoryProvider = Provider<HunterRepository>((ref) {
  final repository = HunterRepositoryImpl(Supabase.instance.client);
  
  // Limpiar recursos cuando el provider se destruya
  ref.onDispose(() {
    (repository as HunterRepositoryImpl).dispose();
  });
  
  return repository;
});
