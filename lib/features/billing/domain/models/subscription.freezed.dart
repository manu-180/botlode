// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) {
  return _Subscription.fromJson(json);
}

/// @nodoc
mixin _$Subscription {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  SubscriptionStatus get status => throw _privateConstructorUsedError;
  DateTime? get currentPeriodStart => throw _privateConstructorUsedError;
  DateTime? get currentPeriodEnd => throw _privateConstructorUsedError;
  DateTime? get trialEnd => throw _privateConstructorUsedError;
  bool get cancelAtPeriodEnd => throw _privateConstructorUsedError;
  DateTime? get canceledAt => throw _privateConstructorUsedError;
  PaymentGateway? get gateway => throw _privateConstructorUsedError;
  String? get gatewaySubscriptionId => throw _privateConstructorUsedError;
  String? get gatewayCustomerId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SubscriptionCopyWith<Subscription> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionCopyWith<$Res> {
  factory $SubscriptionCopyWith(
          Subscription value, $Res Function(Subscription) then) =
      _$SubscriptionCopyWithImpl<$Res, Subscription>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String planId,
      SubscriptionStatus status,
      DateTime? currentPeriodStart,
      DateTime? currentPeriodEnd,
      DateTime? trialEnd,
      bool cancelAtPeriodEnd,
      DateTime? canceledAt,
      PaymentGateway? gateway,
      String? gatewaySubscriptionId,
      String? gatewayCustomerId,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$SubscriptionCopyWithImpl<$Res, $Val extends Subscription>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? planId = null,
    Object? status = null,
    Object? currentPeriodStart = freezed,
    Object? currentPeriodEnd = freezed,
    Object? trialEnd = freezed,
    Object? cancelAtPeriodEnd = null,
    Object? canceledAt = freezed,
    Object? gateway = freezed,
    Object? gatewaySubscriptionId = freezed,
    Object? gatewayCustomerId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SubscriptionStatus,
      currentPeriodStart: freezed == currentPeriodStart
          ? _value.currentPeriodStart
          : currentPeriodStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      currentPeriodEnd: freezed == currentPeriodEnd
          ? _value.currentPeriodEnd
          : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      trialEnd: freezed == trialEnd
          ? _value.trialEnd
          : trialEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelAtPeriodEnd: null == cancelAtPeriodEnd
          ? _value.cancelAtPeriodEnd
          : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      canceledAt: freezed == canceledAt
          ? _value.canceledAt
          : canceledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gateway: freezed == gateway
          ? _value.gateway
          : gateway // ignore: cast_nullable_to_non_nullable
              as PaymentGateway?,
      gatewaySubscriptionId: freezed == gatewaySubscriptionId
          ? _value.gatewaySubscriptionId
          : gatewaySubscriptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      gatewayCustomerId: freezed == gatewayCustomerId
          ? _value.gatewayCustomerId
          : gatewayCustomerId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubscriptionImplCopyWith<$Res>
    implements $SubscriptionCopyWith<$Res> {
  factory _$$SubscriptionImplCopyWith(
          _$SubscriptionImpl value, $Res Function(_$SubscriptionImpl) then) =
      __$$SubscriptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String planId,
      SubscriptionStatus status,
      DateTime? currentPeriodStart,
      DateTime? currentPeriodEnd,
      DateTime? trialEnd,
      bool cancelAtPeriodEnd,
      DateTime? canceledAt,
      PaymentGateway? gateway,
      String? gatewaySubscriptionId,
      String? gatewayCustomerId,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$SubscriptionImplCopyWithImpl<$Res>
    extends _$SubscriptionCopyWithImpl<$Res, _$SubscriptionImpl>
    implements _$$SubscriptionImplCopyWith<$Res> {
  __$$SubscriptionImplCopyWithImpl(
      _$SubscriptionImpl _value, $Res Function(_$SubscriptionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? planId = null,
    Object? status = null,
    Object? currentPeriodStart = freezed,
    Object? currentPeriodEnd = freezed,
    Object? trialEnd = freezed,
    Object? cancelAtPeriodEnd = null,
    Object? canceledAt = freezed,
    Object? gateway = freezed,
    Object? gatewaySubscriptionId = freezed,
    Object? gatewayCustomerId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$SubscriptionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SubscriptionStatus,
      currentPeriodStart: freezed == currentPeriodStart
          ? _value.currentPeriodStart
          : currentPeriodStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      currentPeriodEnd: freezed == currentPeriodEnd
          ? _value.currentPeriodEnd
          : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      trialEnd: freezed == trialEnd
          ? _value.trialEnd
          : trialEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelAtPeriodEnd: null == cancelAtPeriodEnd
          ? _value.cancelAtPeriodEnd
          : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      canceledAt: freezed == canceledAt
          ? _value.canceledAt
          : canceledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gateway: freezed == gateway
          ? _value.gateway
          : gateway // ignore: cast_nullable_to_non_nullable
              as PaymentGateway?,
      gatewaySubscriptionId: freezed == gatewaySubscriptionId
          ? _value.gatewaySubscriptionId
          : gatewaySubscriptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      gatewayCustomerId: freezed == gatewayCustomerId
          ? _value.gatewayCustomerId
          : gatewayCustomerId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionImpl implements _Subscription {
  const _$SubscriptionImpl(
      {required this.id,
      required this.tenantId,
      required this.planId,
      required this.status,
      this.currentPeriodStart,
      this.currentPeriodEnd,
      this.trialEnd,
      this.cancelAtPeriodEnd = false,
      this.canceledAt,
      this.gateway,
      this.gatewaySubscriptionId,
      this.gatewayCustomerId,
      required this.createdAt,
      required this.updatedAt});

  factory _$SubscriptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String planId;
  @override
  final SubscriptionStatus status;
  @override
  final DateTime? currentPeriodStart;
  @override
  final DateTime? currentPeriodEnd;
  @override
  final DateTime? trialEnd;
  @override
  @JsonKey()
  final bool cancelAtPeriodEnd;
  @override
  final DateTime? canceledAt;
  @override
  final PaymentGateway? gateway;
  @override
  final String? gatewaySubscriptionId;
  @override
  final String? gatewayCustomerId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Subscription(id: $id, tenantId: $tenantId, planId: $planId, status: $status, currentPeriodStart: $currentPeriodStart, currentPeriodEnd: $currentPeriodEnd, trialEnd: $trialEnd, cancelAtPeriodEnd: $cancelAtPeriodEnd, canceledAt: $canceledAt, gateway: $gateway, gatewaySubscriptionId: $gatewaySubscriptionId, gatewayCustomerId: $gatewayCustomerId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentPeriodStart, currentPeriodStart) ||
                other.currentPeriodStart == currentPeriodStart) &&
            (identical(other.currentPeriodEnd, currentPeriodEnd) ||
                other.currentPeriodEnd == currentPeriodEnd) &&
            (identical(other.trialEnd, trialEnd) ||
                other.trialEnd == trialEnd) &&
            (identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) ||
                other.cancelAtPeriodEnd == cancelAtPeriodEnd) &&
            (identical(other.canceledAt, canceledAt) ||
                other.canceledAt == canceledAt) &&
            (identical(other.gateway, gateway) || other.gateway == gateway) &&
            (identical(other.gatewaySubscriptionId, gatewaySubscriptionId) ||
                other.gatewaySubscriptionId == gatewaySubscriptionId) &&
            (identical(other.gatewayCustomerId, gatewayCustomerId) ||
                other.gatewayCustomerId == gatewayCustomerId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      planId,
      status,
      currentPeriodStart,
      currentPeriodEnd,
      trialEnd,
      cancelAtPeriodEnd,
      canceledAt,
      gateway,
      gatewaySubscriptionId,
      gatewayCustomerId,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      __$$SubscriptionImplCopyWithImpl<_$SubscriptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionImplToJson(
      this,
    );
  }
}

abstract class _Subscription implements Subscription {
  const factory _Subscription(
      {required final String id,
      required final String tenantId,
      required final String planId,
      required final SubscriptionStatus status,
      final DateTime? currentPeriodStart,
      final DateTime? currentPeriodEnd,
      final DateTime? trialEnd,
      final bool cancelAtPeriodEnd,
      final DateTime? canceledAt,
      final PaymentGateway? gateway,
      final String? gatewaySubscriptionId,
      final String? gatewayCustomerId,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$SubscriptionImpl;

  factory _Subscription.fromJson(Map<String, dynamic> json) =
      _$SubscriptionImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get planId;
  @override
  SubscriptionStatus get status;
  @override
  DateTime? get currentPeriodStart;
  @override
  DateTime? get currentPeriodEnd;
  @override
  DateTime? get trialEnd;
  @override
  bool get cancelAtPeriodEnd;
  @override
  DateTime? get canceledAt;
  @override
  PaymentGateway? get gateway;
  @override
  String? get gatewaySubscriptionId;
  @override
  String? get gatewayCustomerId;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
