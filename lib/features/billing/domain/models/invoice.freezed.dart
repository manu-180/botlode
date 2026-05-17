// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Invoice _$InvoiceFromJson(Map<String, dynamic> json) {
  return _Invoice.fromJson(json);
}

/// @nodoc
mixin _$Invoice {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String? get subscriptionId => throw _privateConstructorUsedError;
  String get number => throw _privateConstructorUsedError;
  int get totalCents => throw _privateConstructorUsedError;
  int get subtotalCents => throw _privateConstructorUsedError;
  int get taxCents => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  InvoiceStatus get status => throw _privateConstructorUsedError;
  DateTime? get periodStart => throw _privateConstructorUsedError;
  DateTime? get periodEnd => throw _privateConstructorUsedError;
  DateTime? get dueAt => throw _privateConstructorUsedError;
  DateTime? get paidAt => throw _privateConstructorUsedError;
  String? get pdfUrl => throw _privateConstructorUsedError;
  PaymentGateway? get gateway => throw _privateConstructorUsedError;
  String? get gatewayInvoiceId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InvoiceCopyWith<Invoice> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceCopyWith<$Res> {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) then) =
      _$InvoiceCopyWithImpl<$Res, Invoice>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String? subscriptionId,
      String number,
      int totalCents,
      int subtotalCents,
      int taxCents,
      String currency,
      InvoiceStatus status,
      DateTime? periodStart,
      DateTime? periodEnd,
      DateTime? dueAt,
      DateTime? paidAt,
      String? pdfUrl,
      PaymentGateway? gateway,
      String? gatewayInvoiceId,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$InvoiceCopyWithImpl<$Res, $Val extends Invoice>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._value, this._then);

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
    Object? number = null,
    Object? totalCents = null,
    Object? subtotalCents = null,
    Object? taxCents = null,
    Object? currency = null,
    Object? status = null,
    Object? periodStart = freezed,
    Object? periodEnd = freezed,
    Object? dueAt = freezed,
    Object? paidAt = freezed,
    Object? pdfUrl = freezed,
    Object? gateway = freezed,
    Object? gatewayInvoiceId = freezed,
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
      subscriptionId: freezed == subscriptionId
          ? _value.subscriptionId
          : subscriptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      totalCents: null == totalCents
          ? _value.totalCents
          : totalCents // ignore: cast_nullable_to_non_nullable
              as int,
      subtotalCents: null == subtotalCents
          ? _value.subtotalCents
          : subtotalCents // ignore: cast_nullable_to_non_nullable
              as int,
      taxCents: null == taxCents
          ? _value.taxCents
          : taxCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as InvoiceStatus,
      periodStart: freezed == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      periodEnd: freezed == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueAt: freezed == dueAt
          ? _value.dueAt
          : dueAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      paidAt: freezed == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pdfUrl: freezed == pdfUrl
          ? _value.pdfUrl
          : pdfUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      gateway: freezed == gateway
          ? _value.gateway
          : gateway // ignore: cast_nullable_to_non_nullable
              as PaymentGateway?,
      gatewayInvoiceId: freezed == gatewayInvoiceId
          ? _value.gatewayInvoiceId
          : gatewayInvoiceId // ignore: cast_nullable_to_non_nullable
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
abstract class _$$InvoiceImplCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$$InvoiceImplCopyWith(
          _$InvoiceImpl value, $Res Function(_$InvoiceImpl) then) =
      __$$InvoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String? subscriptionId,
      String number,
      int totalCents,
      int subtotalCents,
      int taxCents,
      String currency,
      InvoiceStatus status,
      DateTime? periodStart,
      DateTime? periodEnd,
      DateTime? dueAt,
      DateTime? paidAt,
      String? pdfUrl,
      PaymentGateway? gateway,
      String? gatewayInvoiceId,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$InvoiceImplCopyWithImpl<$Res>
    extends _$InvoiceCopyWithImpl<$Res, _$InvoiceImpl>
    implements _$$InvoiceImplCopyWith<$Res> {
  __$$InvoiceImplCopyWithImpl(
      _$InvoiceImpl _value, $Res Function(_$InvoiceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? subscriptionId = freezed,
    Object? number = null,
    Object? totalCents = null,
    Object? subtotalCents = null,
    Object? taxCents = null,
    Object? currency = null,
    Object? status = null,
    Object? periodStart = freezed,
    Object? periodEnd = freezed,
    Object? dueAt = freezed,
    Object? paidAt = freezed,
    Object? pdfUrl = freezed,
    Object? gateway = freezed,
    Object? gatewayInvoiceId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$InvoiceImpl(
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
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      totalCents: null == totalCents
          ? _value.totalCents
          : totalCents // ignore: cast_nullable_to_non_nullable
              as int,
      subtotalCents: null == subtotalCents
          ? _value.subtotalCents
          : subtotalCents // ignore: cast_nullable_to_non_nullable
              as int,
      taxCents: null == taxCents
          ? _value.taxCents
          : taxCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as InvoiceStatus,
      periodStart: freezed == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      periodEnd: freezed == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueAt: freezed == dueAt
          ? _value.dueAt
          : dueAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      paidAt: freezed == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pdfUrl: freezed == pdfUrl
          ? _value.pdfUrl
          : pdfUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      gateway: freezed == gateway
          ? _value.gateway
          : gateway // ignore: cast_nullable_to_non_nullable
              as PaymentGateway?,
      gatewayInvoiceId: freezed == gatewayInvoiceId
          ? _value.gatewayInvoiceId
          : gatewayInvoiceId // ignore: cast_nullable_to_non_nullable
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
class _$InvoiceImpl implements _Invoice {
  const _$InvoiceImpl(
      {required this.id,
      required this.tenantId,
      this.subscriptionId,
      required this.number,
      required this.totalCents,
      this.subtotalCents = 0,
      this.taxCents = 0,
      this.currency = 'USD',
      required this.status,
      this.periodStart,
      this.periodEnd,
      this.dueAt,
      this.paidAt,
      this.pdfUrl,
      this.gateway,
      this.gatewayInvoiceId,
      required this.createdAt,
      required this.updatedAt});

  factory _$InvoiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String? subscriptionId;
  @override
  final String number;
  @override
  final int totalCents;
  @override
  @JsonKey()
  final int subtotalCents;
  @override
  @JsonKey()
  final int taxCents;
  @override
  @JsonKey()
  final String currency;
  @override
  final InvoiceStatus status;
  @override
  final DateTime? periodStart;
  @override
  final DateTime? periodEnd;
  @override
  final DateTime? dueAt;
  @override
  final DateTime? paidAt;
  @override
  final String? pdfUrl;
  @override
  final PaymentGateway? gateway;
  @override
  final String? gatewayInvoiceId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Invoice(id: $id, tenantId: $tenantId, subscriptionId: $subscriptionId, number: $number, totalCents: $totalCents, subtotalCents: $subtotalCents, taxCents: $taxCents, currency: $currency, status: $status, periodStart: $periodStart, periodEnd: $periodEnd, dueAt: $dueAt, paidAt: $paidAt, pdfUrl: $pdfUrl, gateway: $gateway, gatewayInvoiceId: $gatewayInvoiceId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.subscriptionId, subscriptionId) ||
                other.subscriptionId == subscriptionId) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.totalCents, totalCents) ||
                other.totalCents == totalCents) &&
            (identical(other.subtotalCents, subtotalCents) ||
                other.subtotalCents == subtotalCents) &&
            (identical(other.taxCents, taxCents) ||
                other.taxCents == taxCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.periodStart, periodStart) ||
                other.periodStart == periodStart) &&
            (identical(other.periodEnd, periodEnd) ||
                other.periodEnd == periodEnd) &&
            (identical(other.dueAt, dueAt) || other.dueAt == dueAt) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl) &&
            (identical(other.gateway, gateway) || other.gateway == gateway) &&
            (identical(other.gatewayInvoiceId, gatewayInvoiceId) ||
                other.gatewayInvoiceId == gatewayInvoiceId) &&
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
      subscriptionId,
      number,
      totalCents,
      subtotalCents,
      taxCents,
      currency,
      status,
      periodStart,
      periodEnd,
      dueAt,
      paidAt,
      pdfUrl,
      gateway,
      gatewayInvoiceId,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      __$$InvoiceImplCopyWithImpl<_$InvoiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceImplToJson(
      this,
    );
  }
}

abstract class _Invoice implements Invoice {
  const factory _Invoice(
      {required final String id,
      required final String tenantId,
      final String? subscriptionId,
      required final String number,
      required final int totalCents,
      final int subtotalCents,
      final int taxCents,
      final String currency,
      required final InvoiceStatus status,
      final DateTime? periodStart,
      final DateTime? periodEnd,
      final DateTime? dueAt,
      final DateTime? paidAt,
      final String? pdfUrl,
      final PaymentGateway? gateway,
      final String? gatewayInvoiceId,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$InvoiceImpl;

  factory _Invoice.fromJson(Map<String, dynamic> json) = _$InvoiceImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String? get subscriptionId;
  @override
  String get number;
  @override
  int get totalCents;
  @override
  int get subtotalCents;
  @override
  int get taxCents;
  @override
  String get currency;
  @override
  InvoiceStatus get status;
  @override
  DateTime? get periodStart;
  @override
  DateTime? get periodEnd;
  @override
  DateTime? get dueAt;
  @override
  DateTime? get paidAt;
  @override
  String? get pdfUrl;
  @override
  PaymentGateway? get gateway;
  @override
  String? get gatewayInvoiceId;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
