import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/features/seeder_bot/data/repositories/seeder_repository_impl.dart';
import 'package:botslode/features/seeder_bot/domain/repositories/seeder_repository.dart';

final seederRepositoryProvider = Provider<SeederRepository>((ref) {
  final repository = SeederRepositoryImpl(Supabase.instance.client);
  ref.onDispose(repository.dispose);
  return repository;
});
