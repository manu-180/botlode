import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/features/assistify_leads/domain/models/assistify_lead.dart';
import 'package:botslode/features/assistify_leads/domain/repositories/assistify_lead_repository.dart';

class AssistifyLeadRepositoryImpl implements AssistifyLeadRepository {
  final SupabaseClient _supabase;

  AssistifyLeadRepositoryImpl(this._supabase);

  @override
  Future<List<AssistifyLead>> getAll({int? limit, int? offset}) async {
    var query = _supabase
        .from('assistify_leads')
        .select()
        .order('created_at', ascending: false);

    // Límite muy alto (hasta 1000 páginas × 100 por página). Supabase puede capar por "Max Rows" en proyecto.
    final lim = limit ?? 100000;
    if (offset != null && offset > 0) {
      query = query.range(offset, offset + lim - 1);
    } else {
      query = query.limit(lim);
    }

    final response = await query;
    return (response as List)
        .map((e) => AssistifyLead.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
