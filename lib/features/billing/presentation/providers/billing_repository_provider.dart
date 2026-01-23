// Archivo: lib/features/billing/presentation/providers/billing_repository_provider.dart
import 'package:botslode/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:botslode/features/billing/domain/repositories/billing_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl(Supabase.instance.client);
});