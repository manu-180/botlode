// lib/features/billing/domain/models/subscription.dart

enum PaymentGateway { stripe, mp }

extension PaymentGatewayX on PaymentGateway {
  static PaymentGateway? fromString(String? value) {
    return switch (value) {
      'stripe' => PaymentGateway.stripe,
      'mp'     => PaymentGateway.mp,
      _        => null,
    };
  }
}

enum SubscriptionStatus {
  active,
  trialing,
  pastDue,
  canceled,
  incomplete,
}

extension SubscriptionStatusX on SubscriptionStatus {
  static SubscriptionStatus fromString(String value) {
    return switch (value) {
      'active'     => SubscriptionStatus.active,
      'trialing'   => SubscriptionStatus.trialing,
      'past_due'   => SubscriptionStatus.pastDue,
      'canceled'   => SubscriptionStatus.canceled,
      _            => SubscriptionStatus.incomplete,
    };
  }
}

class Subscription {
  final String id;
  final String planId;
  final SubscriptionStatus status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final PaymentGateway? gateway;

  const Subscription({
    required this.id,
    required this.planId,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.gateway,
  });

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id']?.toString() ?? '',
      planId: map['plan_id']?.toString() ?? '',
      status: SubscriptionStatusX.fromString(map['status']?.toString() ?? ''),
      currentPeriodStart: map['current_period_start'] != null
          ? DateTime.tryParse(map['current_period_start'].toString())
          : null,
      currentPeriodEnd: map['current_period_end'] != null
          ? DateTime.tryParse(map['current_period_end'].toString())
          : null,
      cancelAtPeriodEnd: map['cancel_at_period_end'] as bool? ?? false,
      gateway: PaymentGatewayX.fromString(map['gateway']?.toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'plan_id': planId,
        'status': status.name,
        'current_period_start': currentPeriodStart?.toIso8601String(),
        'current_period_end': currentPeriodEnd?.toIso8601String(),
        'cancel_at_period_end': cancelAtPeriodEnd,
        'gateway': gateway?.name,
      };
}
