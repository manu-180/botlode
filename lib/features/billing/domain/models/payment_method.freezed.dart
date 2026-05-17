// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_method.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PaymentMethod _$PaymentMethodFromJson(Map<String, dynamic> json) {
  return _PaymentMethod.fromJson(json);
}

/// @nodoc
mixin _$PaymentMethod {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  PaymentGateway get gateway => throw _privateConstructorUsedError;

  /// PCI-sensitive — never log or expose this value directly.
  /// Use [PaymentMethodSafeDisplay.toSafeString] for display/logging.
  String get gatewayToken => throw _privateConstructorUsedError;
  String? get brand => throw _privateConstructorUsedError;
  String? get last4 => throw _privateConstructorUsedError;
  int? get expMonth => throw _privateConstructorUsedError;
  int? get expYear => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PaymentMethodCopyWith<PaymentMethod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentMethodCopyWith<$Res> {
  factory $PaymentMethodCopyWith(
          PaymentMethod value, $Res Function(PaymentMethod) then) =
      _$PaymentMethodCopyWithImpl<$Res, PaymentMethod>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      PaymentGateway gateway,
      String gatewayToken,
      String? brand,
      String? last4,
      int? expMonth,
      int? expYear,
      bool isDefault,
      DateTime createdAt,
      DateTime? deletedAt});
}

/// @nodoc
class _$PaymentMethodCopyWithImpl<$Res, $Val extends PaymentMethod>
    implements $PaymentMethodCopyWith<$Res> {
  _$PaymentMethodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? gateway = null,
    Object? gatewayToken = null,
    Object? brand = freezed,
    Object? last4 = freezed,
    Object? expMonth = freezed,
    Object? expYear = freezed,
    Object? isDefault = null,
    Object? createdAt = null,
    Object? deletedAt = freezed,
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
      gateway: null == gateway
          ? _value.gateway
          : gateway // ignore: cast_nullable_to_non_nullable
              as PaymentGateway,
      gatewayToken: null == gatewayToken
          ? _value.gatewayToken
          : gatewayToken // ignore: cast_nullable_to_non_nullable
              as String,
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      last4: freezed == last4
          ? _value.last4
          : last4 // ignore: cast_nullable_to_non_nullable
              as String?,
      expMonth: freezed == expMonth
          ? _value.expMonth
          : expMonth // ignore: cast_nullable_to_non_nullable
              as int?,
      expYear: freezed == expYear
          ? _value.expYear
          : expYear // ignore: cast_nullable_to_non_nullable
              as int?,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaymentMethodImplCopyWith<$Res>
    implements $PaymentMethodCopyWith<$Res> {
  factory _$$PaymentMethodImplCopyWith(
          _$PaymentMethodImpl value, $Res Function(_$PaymentMethodImpl) then) =
      __$$PaymentMethodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      PaymentGateway gateway,
      String gatewayToken,
      String? brand,
      String? last4,
      int? expMonth,
      int? expYear,
      bool isDefault,
      DateTime createdAt,
      DateTime? deletedAt});
}

/// @nodoc
class __$$PaymentMethodImplCopyWithImpl<$Res>
    extends _$PaymentMethodCopyWithImpl<$Res, _$PaymentMethodImpl>
    implements _$$PaymentMethodImplCopyWith<$Res> {
  __$$PaymentMethodImplCopyWithImpl(
      _$PaymentMethodImpl _value, $Res Function(_$PaymentMethodImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? gateway = null,
    Object? gatewayToken = null,
    Object? brand = freezed,
    Object? last4 = freezed,
    Object? expMonth = freezed,
    Object? expYear = freezed,
    Object? isDefault = null,
    Object? createdAt = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_$PaymentMethodImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      gateway: null == gateway
          ? _value.gateway
          : gateway // ignore: cast_nullable_to_non_nullable
              as PaymentGateway,
      gatewayToken: null == gatewayToken
          ? _value.gatewayToken
          : gatewayToken // ignore: cast_nullable_to_non_nullable
              as String,
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      last4: freezed == last4
          ? _value.last4
          : last4 // ignore: cast_nullable_to_non_nullable
              as String?,
      expMonth: freezed == expMonth
          ? _value.expMonth
          : expMonth // ignore: cast_nullable_to_non_nullable
              as int?,
      expYear: freezed == expYear
          ? _value.expYear
          : expYear // ignore: cast_nullable_to_non_nullable
              as int?,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentMethodImpl extends _PaymentMethod {
  const _$PaymentMethodImpl(
      {required this.id,
      required this.tenantId,
      required this.gateway,
      required this.gatewayToken,
      this.brand,
      this.last4,
      this.expMonth,
      this.expYear,
      this.isDefault = false,
      required this.createdAt,
      this.deletedAt})
      : super._();

  factory _$PaymentMethodImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentMethodImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final PaymentGateway gateway;

  /// PCI-sensitive — never log or expose this value directly.
  /// Use [PaymentMethodSafeDisplay.toSafeString] for display/logging.
  @override
  final String gatewayToken;
  @override
  final String? brand;
  @override
  final String? last4;
  @override
  final int? expMonth;
  @override
  final int? expYear;
  @override
  @JsonKey()
  final bool isDefault;
  @override
  final DateTime createdAt;
  @override
  final DateTime? deletedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentMethodImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.gateway, gateway) || other.gateway == gateway) &&
            (identical(other.gatewayToken, gatewayToken) ||
                other.gatewayToken == gatewayToken) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.last4, last4) || other.last4 == last4) &&
            (identical(other.expMonth, expMonth) ||
                other.expMonth == expMonth) &&
            (identical(other.expYear, expYear) || other.expYear == expYear) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      gateway,
      gatewayToken,
      brand,
      last4,
      expMonth,
      expYear,
      isDefault,
      createdAt,
      deletedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentMethodImplCopyWith<_$PaymentMethodImpl> get copyWith =>
      __$$PaymentMethodImplCopyWithImpl<_$PaymentMethodImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentMethodImplToJson(
      this,
    );
  }
}

abstract class _PaymentMethod extends PaymentMethod {
  const factory _PaymentMethod(
      {required final String id,
      required final String tenantId,
      required final PaymentGateway gateway,
      required final String gatewayToken,
      final String? brand,
      final String? last4,
      final int? expMonth,
      final int? expYear,
      final bool isDefault,
      required final DateTime createdAt,
      final DateTime? deletedAt}) = _$PaymentMethodImpl;
  const _PaymentMethod._() : super._();

  factory _PaymentMethod.fromJson(Map<String, dynamic> json) =
      _$PaymentMethodImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  PaymentGateway get gateway;
  @override

  /// PCI-sensitive — never log or expose this value directly.
  /// Use [PaymentMethodSafeDisplay.toSafeString] for display/logging.
  String get gatewayToken;
  @override
  String? get brand;
  @override
  String? get last4;
  @override
  int? get expMonth;
  @override
  int? get expYear;
  @override
  bool get isDefault;
  @override
  DateTime get createdAt;
  @override
  DateTime? get deletedAt;
  @override
  @JsonKey(ignore: true)
  _$$PaymentMethodImplCopyWith<_$PaymentMethodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
