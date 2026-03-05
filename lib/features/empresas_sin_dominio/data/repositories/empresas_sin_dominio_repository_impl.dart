import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/features/empresas_sin_dominio/domain/models/empresa_sin_dominio.dart';
import 'package:botslode/features/empresas_sin_dominio/domain/repositories/empresas_sin_dominio_repository.dart';

class EmpresasSinDominioRepositoryImpl implements EmpresasSinDominioRepository {
  final SupabaseClient _supabase;

  EmpresasSinDominioRepositoryImpl(this._supabase);

  @override
  Future<List<EmpresaSinDominio>> getAll({
    int? limit,
    int? offset,
    VerificationFilter filter = VerificationFilter.verifiedOnly,
  }) async {
    try {
      return await _queryWithFilter(limit: limit, offset: offset, filter: filter);
    } on PostgrestException catch (e) {
      if (e.code == '42703') {
        // Columna verification_status no existe aún — fallback sin filtro
        return await _queryWithFilter(limit: limit, offset: offset, filter: VerificationFilter.all);
      }
      rethrow;
    }
  }

  Future<List<EmpresaSinDominio>> _queryWithFilter({
    int? limit,
    int? offset,
    required VerificationFilter filter,
  }) async {
    var query = _supabase
        .from('empresas_sin_dominio')
        .select();

    // Solo empresas con teléfono (para contactar por WhatsApp)
    query = query.not('telefono', 'is', null);
    query = query.neq('telefono', '');

    switch (filter) {
      case VerificationFilter.verifiedOnly:
        query = query.inFilter('verification_status', ['verified_no_web', 'pending']);
      case VerificationFilter.verifiedAndPending:
        query = query.neq('verification_status', 'has_web');
      case VerificationFilter.all:
        break;
    }

    // Límite muy alto (hasta 1000 páginas × 100 por página). Supabase puede capar por "Max Rows" en proyecto.
    final lim = limit ?? 100000;
    final ordered = query.order('created_at', ascending: false);
    final PostgrestTransformBuilder<PostgrestList> limited;
    if (offset != null && offset > 0) {
      limited = ordered.range(offset, offset + lim - 1);
    } else {
      limited = ordered.limit(lim);
    }

    final response = await limited;
    return (response as List)
        .map((e) => EmpresaSinDominio.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
