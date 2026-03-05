import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botslode/core/providers/shared_whatsapp_limit_provider.dart';

export 'package:botslode/core/providers/shared_whatsapp_limit_provider.dart' show WhatsAppLimitState;
import 'package:botslode/features/empresas_sin_dominio/domain/models/empresa_sin_dominio.dart';
import 'package:botslode/features/empresas_sin_dominio/domain/repositories/empresas_sin_dominio_repository.dart';
import 'package:botslode/features/empresas_sin_dominio/presentation/providers/empresas_sin_dominio_repository_provider.dart';

const _contactedIdsKey = 'empresas_sin_dominio_contacted_ids';

/// Mismo límite que Assistify: una sola “cuenta” compartida (tabla empresas_whatsapp_limit).
final empresasWhatsAppLimitProvider = sharedWhatsAppLimitProvider;

/// Filtro activo de verificación (por defecto: verifiedOnly).
final empresasVerificationFilterProvider =
    StateProvider<VerificationFilter>((ref) => VerificationFilter.verifiedOnly);

/// Provider de la lista de empresas sin dominio (filtra por verification_status).
final empresasSinDominioListProvider =
    FutureProvider.autoDispose<List<EmpresaSinDominio>>((ref) async {
  final repo = ref.watch(empresasSinDominioRepositoryProvider);
  final filter = ref.watch(empresasVerificationFilterProvider);
  return repo.getAll(filter: filter);
});

/// Provider para los IDs de empresas ya contactadas (clickeadas para WhatsApp).
final empresasContactadasProvider =
    StateNotifierProvider<EmpresasContactadasNotifier, Set<String>>((ref) {
  return EmpresasContactadasNotifier();
});

class EmpresasContactadasNotifier extends StateNotifier<Set<String>> {
  EmpresasContactadasNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_contactedIdsKey);
    if (list != null) {
      state = list.toSet();
    }
  }

  Future<void> markAsContacted(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_contactedIdsKey, state.toList());
  }

  Future<void> clearAll() async {
    state = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contactedIdsKey);
  }
}
