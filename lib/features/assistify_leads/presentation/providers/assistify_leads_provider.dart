import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botslode/core/providers/shared_whatsapp_limit_provider.dart';
import 'package:botslode/features/assistify_leads/domain/models/assistify_lead.dart';

export 'package:botslode/core/providers/shared_whatsapp_limit_provider.dart' show WhatsAppLimitState;
import 'package:botslode/features/assistify_leads/presentation/providers/assistify_lead_repository_provider.dart';

const _contactedIdsKey = 'assistify_leads_contacted_ids';

/// Mismo límite que Empresas sin dominio: una sola “cuenta” compartida (tabla empresas_whatsapp_limit).
final assistifyWhatsAppLimitProvider = sharedWhatsAppLimitProvider;

final assistifyLeadsListProvider =
    FutureProvider.autoDispose<List<AssistifyLead>>((ref) async {
  final repo = ref.watch(assistifyLeadRepositoryProvider);
  return repo.getAll();
});

final assistifyContactadasProvider =
    StateNotifierProvider<AssistifyContactadasNotifier, Set<String>>((ref) {
  return AssistifyContactadasNotifier();
});

class AssistifyContactadasNotifier extends StateNotifier<Set<String>> {
  AssistifyContactadasNotifier() : super({}) {
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
}
