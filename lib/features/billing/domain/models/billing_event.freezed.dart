// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BillingEvent _$BillingEventFromJson(Map<String, dynamic> json) {
  return _BillingEvent.fromJson(json);
}

/// @nodoc
mixin _$BillingEvent {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String? get subscriptionId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  PaymentGateway? get gateway => throw _privateConstructorUsedError;
  String? get gatewayEventId => throw _privateConstructorUsedError;
  String? get idempotencyKey => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  DateTime get occurredAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BillingEventCopyWith<BillingEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BillingEventCopyWith<$Res> {
  factory $BillingEventCopyWith(
          BillingEvent value, $Res Function(BillingEvent) then) =
      _$BillingEventCopyWithImpl<$Res, BillingEvent>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String? subscriptionId,
      String type,
      PaymentGateway? gateway,
      String? gatewayEventId,
      String? idempotencyKey,
      Map<String, dynamic> payload,
      DateTime occurredAt,
      DateTime createdAt});
}

/// @nodoc
class _$BillingEventCopyWithImpl<$Res, $Val extends BillingEvent>
    implements $BillingEventCopyWith<$Res> {
  _$BillingEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? subscriptionId = freezed,
    Object? type = null,
    Object? gateway = freezed,
    Object? gatewayEventId = freezed,
    Object? idempotencyKey = freezed,
    Object? payload = null,
    Object? occurredAt = null,
    Object? createdAt = null,
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
      subscriptionId: freezed == subscriptionId
          ? _value.subscriptionId
          : subscriptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      gateway: freezed == gateway
          ? _value.gateway
          : gateway // ignore: cast_nullable_to_non_nullable
              as PaymentGateway?,
      gatewayEventId: freezed == gatewayEventId
          ? _value.gatewayEventId
          : gatewayEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      idempotencyKey: freezed == idempotencyKey
          ? _value.idempotencyKey
          : idempotencyKey // ignore: cast_nullable_to_non_nullable
              as String?,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      occurredAt: null == occurredAt
          ? _value.occurredAt
          : occurredAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BillingEventImplCopyWith<$Res>
    implements $BillingEventCopyWith<$Res> {
  factory _$$BillingEventImplCopyWith(
          _$BillingEventImpl value, $Res Function(_$BillingEventImpl) then) =
      __$$BillingEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String? subscriptionId,
      String type,
      PaymentGateway? gateway,
      String? gatewayEventId,
      String? idempotencyKey,
      Map<String, dynamic> payload,
      DateTime occurredAt,
      DateTime createdAt});
}

/// @nodoc
class __$$BillingEventImplCopyWithImpl<$Res>
    extends _$BillingEventCopyWithImpl<$Res, _$BillingEventImpl>
    implements _$$BillingEventImplCopyWith<$Res> {
  __$$BillingEventImplCopyWithImpl(
      _$BillingEventImpl _value, $Res Function(_$BillingEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? subscriptionId = freezed,
    Object? type = null,
    Object? gateway = freezed,
    Object? gatewayEventId = freezed,
    Object? idempotencyKey = freezed,
    Object? payload = null,
    Object? occurredAt = null,
    Object? createdAt = null,
  }) {
    return _then(_$BillingEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionId: freezed == subscriptionId
          ? _value.subscriptionId
          : subscriptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      gateway: freezed == gateway
          ? _value.gateway
          : gateway // ignore: cast_nullable_to_non_nullable
              as PaymentGateway?,
      gatewayEventId: freezed == gatewayEventId
          ? _value.gatewayEventId
          : gatewayEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      idempotencyKey: freezed == idempotencyKey
          ? _value.idempotencyKey
          : idempotencyKey // ignore: cast_nullable_to_non_nullable
              as String?,
      payload: null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      occurredAt: null == occurredAt
          ? _value.occurredAt
          : occurredAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BillingEventImpl implements _BillingEvent {
  const _$BillingEventImpl(
      {required this.id,
      required this.tenantId,
      this.subscriptionId,
      required this.type,
      this.gateway,
      this.gatewayEventId,
      this.idempotencyKey,
      final Map<String, dynamic> payload = const <String, dynamic>{},
      required this.occurredAt,
      required this.createdAt})
      : _payload = payload;

  factory _$BillingEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$BillingEventImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String? subscriptionId;
  @override
  final String type;
  @override
  final PaymentGateway? gateway;
  @override
  final String? gatewayEventId;
  @override
  final String? idempotencyKey;
  final Map<String, dynamic> _payload;
  @override
  @JsonKey()
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  final DateTime occurredAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'BillingEvent(id: $id, tenantId: $tenantId, subscriptionId: $subscriptionId, type: $type, gateway: $gateway, gatewayEventId: $gatewayEventId, idempotencyKey: $idempotencyKey, payload: $payload, occurredAt: $occurredAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BillingEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.subscriptionId, subscriptionId) ||
                other.subscriptionId == subscriptionId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.gateway, gateway) || other.gateway == gateway) &&
            (identical(other.gatewayEventId, gatewayEventId) ||
                other.gatewayEventId == gatewayEventId) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.occurredAt, occurredAt) ||
                other.occurredAt == occurredAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      subscriptionId,
      type,
      gateway,
      gatewayEventId,
      idempotencyKey,
      const DeepCollectionEquality().hash(_payload),
      occurredAt,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BillingEventImplCopyWith<_$BillingEventImpl> get copyWith =>
      __$$BillingEventImplCopyWithImpl<_$BillingEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BillingEventImplToJson(
      this,
    );
  }
}

abstract class _BillingEvent implements BillingEvent {
  const factory _BillingEvent(
      {required final String id,
      required final String tenantId,
      final String? subscriptionId,
      required final String type,
      final PaymentGateway? gateway,
      final String? gatewayEventId,
      final String? idempotencyKey,
      final Map<String, dynamic> payload,
      required final DateTime occurredAt,
      required final DateTime createdAt}) = _$BillingEventImpl;

  factory _BillingEvent.fromJson(Map<String, dynamic> json) =
      _$BillingEventImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String? get subscriptionId;
  @override
  String get type;
  @override
  PaymentGateway? get gateway;
  @override
  String? get gatewayEventId;
  @override
  String? get idempotencyKey;
  @override
  Map<String, dynamic> get payload;
  @override
  DateTime get occurredAt;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$BillingEventImplCopyWith<_$BillingEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
