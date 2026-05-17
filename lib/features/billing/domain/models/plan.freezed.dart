// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Plan _$PlanFromJson(Map<String, dynamic> json) {
  return _Plan.fromJson(json);
}

/// @nodoc
mixin _$Plan {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get priceCents => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  BillingInterval get interval => throw _privateConstructorUsedError;
  int get maxBots => throw _privateConstructorUsedError;
  int get maxConversations => throw _privateConstructorUsedError;
  Map<String, dynamic> get features => throw _privateConstructorUsedError;
  bool get public => throw _privateConstructorUsedError;
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlanCopyWith<Plan> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlanCopyWith<$Res> {
  factory $PlanCopyWith(Plan value, $Res Function(Plan) then) =
      _$PlanCopyWithImpl<$Res, Plan>;
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      int priceCents,
      String currency,
      BillingInterval interval,
      int maxBots,
      int maxConversations,
      Map<String, dynamic> features,
      bool public,
      DateTime? archivedAt,
      DateTime createdAt});
}

/// @nodoc
class _$PlanCopyWithImpl<$Res, $Val extends Plan>
    implements $PlanCopyWith<$Res> {
  _$PlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? priceCents = null,
    Object? currency = null,
    Object? interval = null,
    Object? maxBots = null,
    Object? maxConversations = null,
    Object? features = null,
    Object? public = null,
    Object? archivedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      priceCents: null == priceCents
          ? _value.priceCents
          : priceCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      interval: null == interval
          ? _value.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as BillingInterval,
      maxBots: null == maxBots
          ? _value.maxBots
          : maxBots // ignore: cast_nullable_to_non_nullable
              as int,
      maxConversations: null == maxConversations
          ? _value.maxConversations
          : maxConversations // ignore: cast_nullable_to_non_nullable
              as int,
      features: null == features
          ? _value.features
          : features // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      public: null == public
          ? _value.public
          : public // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlanImplCopyWith<$Res> implements $PlanCopyWith<$Res> {
  factory _$$PlanImplCopyWith(
          _$PlanImpl value, $Res Function(_$PlanImpl) then) =
      __$$PlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      int priceCents,
      String currency,
      BillingInterval interval,
      int maxBots,
      int maxConversations,
      Map<String, dynamic> features,
      bool public,
      DateTime? archivedAt,
      DateTime createdAt});
}

/// @nodoc
class __$$PlanImplCopyWithImpl<$Res>
    extends _$PlanCopyWithImpl<$Res, _$PlanImpl>
    implements _$$PlanImplCopyWith<$Res> {
  __$$PlanImplCopyWithImpl(_$PlanImpl _value, $Res Function(_$PlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? priceCents = null,
    Object? currency = null,
    Object? interval = null,
    Object? maxBots = null,
    Object? maxConversations = null,
    Object? features = null,
    Object? public = null,
    Object? archivedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$PlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      priceCents: null == priceCents
          ? _value.priceCents
          : priceCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      interval: null == interval
          ? _value.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as BillingInterval,
      maxBots: null == maxBots
          ? _value.maxBots
          : maxBots // ignore: cast_nullable_to_non_nullable
              as int,
      maxConversations: null == maxConversations
          ? _value.maxConversations
          : maxConversations // ignore: cast_nullable_to_non_nullable
              as int,
      features: null == features
          ? _value._features
          : features // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      public: null == public
          ? _value.public
          : public // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlanImpl implements _Plan {
  const _$PlanImpl(
      {required this.id,
      required this.code,
      required this.name,
      required this.priceCents,
      this.currency = 'USD',
      required this.interval,
      required this.maxBots,
      required this.maxConversations,
      final Map<String, dynamic> features = const <String, dynamic>{},
      this.public = true,
      this.archivedAt,
      required this.createdAt})
      : _features = features;

  factory _$PlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlanImplFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final int priceCents;
  @override
  @JsonKey()
  final String currency;
  @override
  final BillingInterval interval;
  @override
  final int maxBots;
  @override
  final int maxConversations;
  final Map<String, dynamic> _features;
  @override
  @JsonKey()
  Map<String, dynamic> get features {
    if (_features is EqualUnmodifiableMapView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_features);
  }

  @override
  @JsonKey()
  final bool public;
  @override
  final DateTime? archivedAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Plan(id: $id, code: $code, name: $name, priceCents: $priceCents, currency: $currency, interval: $interval, maxBots: $maxBots, maxConversations: $maxConversations, features: $features, public: $public, archivedAt: $archivedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.priceCents, priceCents) ||
                other.priceCents == priceCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
            (identical(other.maxBots, maxBots) || other.maxBots == maxBots) &&
            (identical(other.maxConversations, maxConversations) ||
                other.maxConversations == maxConversations) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            (identical(other.public, public) || other.public == public) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      code,
      name,
      priceCents,
      currency,
      interval,
      maxBots,
      maxConversations,
      const DeepCollectionEquality().hash(_features),
      public,
      archivedAt,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlanImplCopyWith<_$PlanImpl> get copyWith =>
      __$$PlanImplCopyWithImpl<_$PlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlanImplToJson(
      this,
    );
  }
}

abstract class _Plan implements Plan {
  const factory _Plan(
      {required final String id,
      required final String code,
      required final String name,
      required final int priceCents,
      final String currency,
      required final BillingInterval interval,
      required final int maxBots,
      required final int maxConversations,
      final Map<String, dynamic> features,
      final bool public,
      final DateTime? archivedAt,
      required final DateTime createdAt}) = _$PlanImpl;

  factory _Plan.fromJson(Map<String, dynamic> json) = _$PlanImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  String get name;
  @override
  int get priceCents;
  @override
  String get currency;
  @override
  BillingInterval get interval;
  @override
  int get maxBots;
  @override
  int get maxConversations;
  @override
  Map<String, dynamic> get features;
  @override
  bool get public;
  @override
  DateTime? get archivedAt;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$PlanImplCopyWith<_$PlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
