// Archivo: lib/features/billing/presentation/providers/billing_repository_provider.dart
//
// Providers de repositorios del módulo de facturación.
//
// COMPAT: billingRepositoryProvider se conserva para el legacy Billing notifier.
// Los nuevos providers T3 son usados por BillingV2Notifier (T4).

import 'package:botslode/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:botslode/features/billing/data/repositories/invoices_repository_impl.dart';
import 'package:botslode/features/billing/data/repositories/payment_methods_repository_impl.dart';
import 'package:botslode/features/billing/data/repositories/plans_repository_impl.dart';
import 'package:botslode/features/billing/data/repositories/subscriptions_repository_impl.dart';
import 'package:botslode/features/billing/domain/repositories/billing_repository.dart';
import 'package:botslode/features/billing/domain/repositories/invoices_repository.dart';
import 'package:botslode/features/billing/domain/repositories/payment_methods_repository.dart';
import 'package:botslode/features/billing/domain/repositories/plans_repository.dart';
import 'package:botslode/features/billing/domain/repositories/subscriptions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Legacy — usado por el Billing notifier existente (no tocar).
// ---------------------------------------------------------------------------

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// T3 repositories — usados por BillingV2Notifier.
// ---------------------------------------------------------------------------

/// Repositorio de suscripciones (T3).
/// Queries de solo-lectura; escrituras delegadas a Edge Functions (T5).
final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  return SubscriptionsRepositoryImpl(Supabase.instance.client);
});

/// Repositorio del catálogo de planes (T3) con caché en memoria (TTL 5 min).
final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepositoryImpl(Supabase.instance.client);
});

/// Repositorio de métodos de pago (T3).
/// Queries de solo-lectura; escrituras delegadas a Edge Functions (T5).
final paymentMethodsRepositoryProvider = Provider<PaymentMethodsRepository>((ref) {
  return PaymentMethodsRepositoryImpl(Supabase.instance.client);
});

/// Repositorio de facturas (T3) con paginación keyset.
final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepositoryImpl(Supabase.instance.client);
});
