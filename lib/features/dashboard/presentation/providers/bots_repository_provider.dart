// Archivo: lib/features/dashboard/presentation/providers/bots_repository_provider.dart
import 'package:botslode/features/dashboard/data/repositories/bots_repository_impl.dart';
import 'package:botslode/features/dashboard/domain/repositories/bots_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider de solo lectura que inyecta la dependencia de Supabase en el Repo Implementation
final botsRepositoryProvider = Provider<BotsRepository>((ref) {
  return BotsRepositoryImpl(Supabase.instance.client);
});