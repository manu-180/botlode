// Archivo: lib/features/billing/domain/repositories/tenant_fee_config_repository.dart

import 'package:botslode/features/billing/domain/models/tenant_fee_config.dart';

/// Contrato de solo-lectura para la configuración de comisiones del tenant.
///
/// La tabla `tenant_fee_config` tiene exactamente 1 fila por tenant, creada
/// automáticamente por trigger con `marketplace_fee_percent = 0`.
abstract class TenantFeeConfigRepository {
  /// Devuelve la configuración de comisión del tenant o `null` si no existe.
  ///
  /// En producción siempre debería existir (trigger la crea), pero el caller
  /// debe manejar el caso nulo defensivamente.
  Future<TenantFeeConfig?> getForTenant(String tenantId);

  /// Helper que devuelve el porcentaje de comisión vigente.
  ///
  /// Retorna `0.0` si no hay config o la comisión no está activa (expiró).
  Future<double> getFeePercentFor(String tenantId);
}
