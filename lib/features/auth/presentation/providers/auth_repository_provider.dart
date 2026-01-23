// Archivo: lib/features/auth/presentation/providers/auth_repository_provider.dart
import 'package:botslode/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:botslode/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(Supabase.instance.client);
});