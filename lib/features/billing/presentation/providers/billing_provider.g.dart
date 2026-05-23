// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$billingHash() => r'12cdcc5256b9640868680cbf9f31e59cb46a1925';

/// See also [Billing].
@ProviderFor(Billing)
final billingProvider =
    AutoDisposeAsyncNotifierProvider<Billing, BillingState>.internal(
  Billing.new,
  name: r'billingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$billingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Billing = AutoDisposeAsyncNotifier<BillingState>;
String _$billingV2Hash() => r'c77f01fd1647e39f0231cec1d38c244f3ff9a588';

/// Notifier T4 que expone [BillingV2State] a la capa de presentación.
///
/// Usa los repositorios del dominio T3 (SubscriptionsRepository,
/// PlansRepository, PaymentMethodsRepository, InvoicesRepository) para todas
/// las lecturas. Las mutaciones que requieren Edge Functions están stubbed
/// hasta T5.
///
/// Copied from [BillingV2].
@ProviderFor(BillingV2)
final billingV2Provider =
    AutoDisposeAsyncNotifierProvider<BillingV2, BillingV2State>.internal(
  BillingV2.new,
  name: r'billingV2Provider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$billingV2Hash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BillingV2 = AutoDisposeAsyncNotifier<BillingV2State>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
