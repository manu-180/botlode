import 'package:botslode/features/empresas_sin_dominio/domain/models/empresa_sin_dominio.dart';

/// Filtro de estado de verificación para la consulta.
enum VerificationFilter {
  /// Solo verificadas como "sin web" (más confiable).
  verifiedOnly,
  /// Verificadas + pendientes (puede incluir falsos positivos).
  verifiedAndPending,
  /// Todas (incluyendo descartadas con web encontrada).
  all,
}

/// Repositorio para empresas sin dominio (Hunter + Seeder).
abstract class EmpresasSinDominioRepository {
  /// Obtiene empresas sin dominio filtradas por estado de verificación.
  Future<List<EmpresaSinDominio>> getAll({
    int? limit,
    int? offset,
    VerificationFilter filter = VerificationFilter.verifiedOnly,
  });
}
