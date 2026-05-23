// Archivo: lib/features/billing/data/repositories/tenant_fee_config_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:botslode/features/billing/domain/exceptions/billing_exception.dart';
import 'package:botslode/features/billing/domain/models/tenant_fee_config.dart';
import 'package:botslode/features/billing/domain/repositories/tenant_fee_config_repository.dart';

/// Implementación Supabase de [TenantFeeConfigRepository].
class TenantFeeConfigRepositoryImpl implements TenantFeeConfigRepository {
  final SupabaseClient _client;

  const TenantFeeConfigRepositoryImpl(this._client);

  @override
  Future<TenantFeeConfig?> getForTenant(String tenantId) async {
    try {
      final response = await _client
          .from('tenant_fee_config')
          .select()
          .eq('tenant_id', tenantId)
          .maybeSingle();

      if (response == null) return null;
      return TenantFeeConfig.fromJson(response);
    } catch (e) {
      throw BillingRepositoryException(
        code: 'tenant_fee_config_fetch_error',
        message:
            'Error al obtener tenant_fee_config para el tenant $tenantId: $e',
      );
    }
  }

  @override
  Future<double> getFeePercentFor(String tenantId) async {
    final config = await getForTenant(tenantId);
    if (config == null || !config.isActive) return 0.0;
    return config.marketplaceFeePercent;
  }
}
