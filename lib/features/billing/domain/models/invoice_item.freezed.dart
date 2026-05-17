// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InvoiceItem _$InvoiceItemFromJson(Map<String, dynamic> json) {
  return _InvoiceItem.fromJson(json);
}

/// @nodoc
mixin _$InvoiceItem {
  String get id => throw _privateConstructorUsedError;
  String get invoiceId => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  int get unitPriceCents => throw _privateConstructorUsedError;
  int get amountCents => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  bool get proration => throw _privateConstructorUsedError;
  DateTime? get periodStart => throw _privateConstructorUsedError;
  DateTime? get periodEnd => throw _privateConstructorUsedError;
  String? get planId => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InvoiceItemCopyWith<InvoiceItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceItemCopyWith<$Res> {
  factory $InvoiceItemCopyWith(
          InvoiceItem value, $Res Function(InvoiceItem) then) =
      _$InvoiceItemCopyWithImpl<$Res, InvoiceItem>;
  @useResult
  $Res call(
      {String id,
      String invoiceId,
      String description,
      int quantity,
      int unitPriceCents,
      int amountCents,
      String currency,
      bool proration,
      DateTime? periodStart,
      DateTime? periodEnd,
      String? planId,
      Map<String, dynamic> metadata,
      DateTime createdAt});
}

/// @nodoc
class _$InvoiceItemCopyWithImpl<$Res, $Val extends InvoiceItem>
    implements $InvoiceItemCopyWith<$Res> {
  _$InvoiceItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? invoiceId = null,
    Object? description = null,
    Object? quantity = null,
    Object? unitPriceCents = null,
    Object? amountCents = null,
    Object? currency = null,
    Object? proration = null,
    Object? periodStart = freezed,
    Object? periodEnd = freezed,
    Object? planId = freezed,
    Object? metadata = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: null == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      unitPriceCents: null == unitPriceCents
          ? _value.unitPriceCents
          : unitPriceCents // ignore: cast_nullable_to_non_nullable
              as int,
      amountCents: null == amountCents
          ? _value.amountCents
          : amountCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      proration: null == proration
          ? _value.proration
          : proration // ignore: cast_nullable_to_non_nullable
              as bool,
      periodStart: freezed == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      periodEnd: freezed == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      planId: freezed == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InvoiceItemImplCopyWith<$Res>
    implements $InvoiceItemCopyWith<$Res> {
  factory _$$InvoiceItemImplCopyWith(
          _$InvoiceItemImpl value, $Res Function(_$InvoiceItemImpl) then) =
      __$$InvoiceItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String invoiceId,
      String description,
      int quantity,
      int unitPriceCents,
      int amountCents,
      String currency,
      bool proration,
      DateTime? periodStart,
      DateTime? periodEnd,
      String? planId,
      Map<String, dynamic> metadata,
      DateTime createdAt});
}

/// @nodoc
class __$$InvoiceItemImplCopyWithImpl<$Res>
    extends _$InvoiceItemCopyWithImpl<$Res, _$InvoiceItemImpl>
    implements _$$InvoiceItemImplCopyWith<$Res> {
  __$$InvoiceItemImplCopyWithImpl(
      _$InvoiceItemImpl _value, $Res Function(_$InvoiceItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? invoiceId = null,
    Object? description = null,
    Object? quantity = null,
    Object? unitPriceCents = null,
    Object? amountCents = null,
    Object? currency = null,
    Object? proration = null,
    Object? periodStart = freezed,
    Object? periodEnd = freezed,
    Object? planId = freezed,
    Object? metadata = null,
    Object? createdAt = null,
  }) {
    return _then(_$InvoiceItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: null == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      unitPriceCents: null == unitPriceCents
          ? _value.unitPriceCents
          : unitPriceCents // ignore: cast_nullable_to_non_nullable
              as int,
      amountCents: null == amountCents
          ? _value.amountCents
          : amountCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      proration: null == proration
          ? _value.proration
          : proration // ignore: cast_nullable_to_non_nullable
              as bool,
      periodStart: freezed == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      periodEnd: freezed == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      planId: freezed == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvoiceItemImpl implements _InvoiceItem {
  const _$InvoiceItemImpl(
      {required this.id,
      required this.invoiceId,
      required this.description,
      this.quantity = 1,
      required this.unitPriceCents,
      required this.amountCents,
      this.currency = 'USD',
      this.proration = false,
      this.periodStart,
      this.periodEnd,
      this.planId,
      final Map<String, dynamic> metadata = const <String, dynamic>{},
      required this.createdAt})
      : _metadata = metadata;

  factory _$InvoiceItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceItemImplFromJson(json);

  @override
  final String id;
  @override
  final String invoiceId;
  @override
  final String description;
  @override
  @JsonKey()
  final int quantity;
  @override
  final int unitPriceCents;
  @override
  final int amountCents;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey()
  final bool proration;
  @override
  final DateTime? periodStart;
  @override
  final DateTime? periodEnd;
  @override
  final String? planId;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'InvoiceItem(id: $id, invoiceId: $invoiceId, description: $description, quantity: $quantity, unitPriceCents: $unitPriceCents, amountCents: $amountCents, currency: $currency, proration: $proration, periodStart: $periodStart, periodEnd: $periodEnd, planId: $planId, metadata: $metadata, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.invoiceId, invoiceId) ||
                other.invoiceId == invoiceId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPriceCents, unitPriceCents) ||
                other.unitPriceCents == unitPriceCents) &&
            (identical(other.amountCents, amountCents) ||
                other.amountCents == amountCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.proration, proration) ||
                other.proration == proration) &&
            (identical(other.periodStart, periodStart) ||
                other.periodStart == periodStart) &&
            (identical(other.periodEnd, periodEnd) ||
                other.periodEnd == periodEnd) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      invoiceId,
      description,
      quantity,
      unitPriceCents,
      amountCents,
      currency,
      proration,
      periodStart,
      periodEnd,
      planId,
      const DeepCollectionEquality().hash(_metadata),
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceItemImplCopyWith<_$InvoiceItemImpl> get copyWith =>
      __$$InvoiceItemImplCopyWithImpl<_$InvoiceItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceItemImplToJson(
      this,
    );
  }
}

abstract class _InvoiceItem implements InvoiceItem {
  const factory _InvoiceItem(
      {required final String id,
      required final String invoiceId,
      required final String description,
      final int quantity,
      required final int unitPriceCents,
      required final int amountCents,
      final String currency,
      final bool proration,
      final DateTime? periodStart,
      final DateTime? periodEnd,
      final String? planId,
      final Map<String, dynamic> metadata,
      required final DateTime createdAt}) = _$InvoiceItemImpl;

  factory _InvoiceItem.fromJson(Map<String, dynamic> json) =
      _$InvoiceItemImpl.fromJson;

  @override
  String get id;
  @override
  String get invoiceId;
  @override
  String get description;
  @override
  int get quantity;
  @override
  int get unitPriceCents;
  @override
  int get amountCents;
  @override
  String get currency;
  @override
  bool get proration;
  @override
  DateTime? get periodStart;
  @override
  DateTime? get periodEnd;
  @override
  String? get planId;
  @override
  Map<String, dynamic> get metadata;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$InvoiceItemImplCopyWith<_$InvoiceItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
