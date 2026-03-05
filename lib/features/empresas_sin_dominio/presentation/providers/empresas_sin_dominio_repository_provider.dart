import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/features/empresas_sin_dominio/data/repositories/empresas_sin_dominio_repository_impl.dart';
import 'package:botslode/features/empresas_sin_dominio/domain/repositories/empresas_sin_dominio_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final empresasSinDominioRepositoryProvider = Provider<EmpresasSinDominioRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EmpresasSinDominioRepositoryImpl(client);
});
