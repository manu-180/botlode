// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BillingV2State {
  /// Suscripción activa del tenant (trialing, active o past_due).
  /// `null` si el tenant no tiene suscripción vigente.
  Subscription? get subscription => throw _privateConstructorUsedError;

  /// Lista de planes públicos disponibles ordenados por precio ascendente.
  List<Plan> get availablePlans => throw _privateConstructorUsedError;

  /// Métodos de pago activos del tenant (no eliminados).
  List<PaymentMethod> get paymentMethods => throw _privateConstructorUsedError;

  /// ID del método de pago marcado como predeterminado.
  String? get defaultPaymentMethodId => throw _privateConstructorUsedError;

  /// Página más reciente de facturas del tenant.
  List<Invoice> get invoices => throw _privateConstructorUsedError;

  /// Indica operación asíncrona optimista en curso (mutaciones).
  bool get isLoading => throw _privateConstructorUsedError;

  /// Código de error estructurado de [BillingRepositoryException] o stub.
  String? get errorCode => throw _privateConstructorUsedError;

  /// Mensaje legible del último error ocurrido.
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Preview de prorrateo generado localmente antes de confirmar cambio de plan.
  ProrationOutput? get pendingProration => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BillingV2StateCopyWith<BillingV2State> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BillingV2StateCopyWith<$Res> {
  factory $BillingV2StateCopyWith(
          BillingV2State value, $Res Function(BillingV2State) then) =
      _$BillingV2StateCopyWithImpl<$Res, BillingV2State>;
  @useResult
  $Res call(
      {Subscription? subscription,
      List<Plan> availablePlans,
      List<PaymentMethod> paymentMethods,
      String? defaultPaymentMethodId,
      List<Invoice> invoices,
      bool isLoading,
      String? errorCode,
      String? errorMessage,
      ProrationOutput? pendingProration});
}

/// @nodoc
class _$BillingV2StateCopyWithImpl<$Res, $Val extends BillingV2State>
    implements $BillingV2StateCopyWith<$Res> {
  _$BillingV2StateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subscription = freezed,
    Object? availablePlans = null,
    Object? paymentMethods = null,
    Object? defaultPaymentMethodId = freezed,
    Object? invoices = null,
    Object? isLoading = null,
    Object? errorCode = freezed,
    Object? errorMessage = freezed,
    Object? pendingProration = freezed,
  }) {
    return _then(_value.copyWith(
      subscription: freezed == subscription
          ? _value.subscription
          : subscription // ignore: cast_nullable_to_non_nullable
              as Subscription?,
      availablePlans: null == availablePlans
          ? _value.availablePlans
          : availablePlans // ignore: cast_nullable_to_non_nullable
              as List<Plan>,
      paymentMethods: null == paymentMethods
          ? _value.paymentMethods
          : paymentMethods // ignore: cast_nullable_to_non_nullable
              as List<PaymentMethod>,
      defaultPaymentMethodId: freezed == defaultPaymentMethodId
          ? _value.defaultPaymentMethodId
          : defaultPaymentMethodId // ignore: cast_nullable_to_non_nullable
              as String?,
      invoices: null == invoices
          ? _value.invoices
          : invoices // ignore: cast_nullable_to_non_nullable
              as List<Invoice>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      pendingProration: freezed == pendingProration
          ? _value.pendingProration
          : pendingProration // ignore: cast_nullable_to_non_nullable
              as ProrationOutput?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BillingV2StateImplCopyWith<$Res>
    implements $BillingV2StateCopyWith<$Res> {
  factory _$$BillingV2StateImplCopyWith(_$BillingV2StateImpl value,
          $Res Function(_$BillingV2StateImpl) then) =
      __$$BillingV2StateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Subscription? subscription,
      List<Plan> availablePlans,
      List<PaymentMethod> paymentMethods,
      String? defaultPaymentMethodId,
      List<Invoice> invoices,
      bool isLoading,
      String? errorCode,
      String? errorMessage,
      ProrationOutput? pendingProration});
}

/// @nodoc
class __$$BillingV2StateImplCopyWithImpl<$Res>
    extends _$BillingV2StateCopyWithImpl<$Res, _$BillingV2StateImpl>
    implements _$$BillingV2StateImplCopyWith<$Res> {
  __$$BillingV2StateImplCopyWithImpl(
      _$BillingV2StateImpl _value, $Res Function(_$BillingV2StateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subscription = freezed,
    Object? availablePlans = null,
    Object? paymentMethods = null,
    Object? defaultPaymentMethodId = freezed,
    Object? invoices = null,
    Object? isLoading = null,
    Object? errorCode = freezed,
    Object? errorMessage = freezed,
    Object? pendingProration = freezed,
  }) {
    return _then(_$BillingV2StateImpl(
      subscription: freezed == subscription
          ? _value.subscription
          : subscription // ignore: cast_nullable_to_non_nullable
              as Subscription?,
      availablePlans: null == availablePlans
          ? _value._availablePlans
          : availablePlans // ignore: cast_nullable_to_non_nullable
              as List<Plan>,
      paymentMethods: null == paymentMethods
          ? _value._paymentMethods
          : paymentMethods // ignore: cast_nullable_to_non_nullable
              as List<PaymentMethod>,
      defaultPaymentMethodId: freezed == defaultPaymentMethodId
          ? _value.defaultPaymentMethodId
          : defaultPaymentMethodId // ignore: cast_nullable_to_non_nullable
              as String?,
      invoices: null == invoices
          ? _value._invoices
          : invoices // ignore: cast_nullable_to_non_nullable
              as List<Invoice>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      pendingProration: freezed == pendingProration
          ? _value.pendingProration
          : pendingProration // ignore: cast_nullable_to_non_nullable
              as ProrationOutput?,
    ));
  }
}

/// @nodoc

class _$BillingV2StateImpl implements _BillingV2State {
  const _$BillingV2StateImpl(
      {this.subscription,
      final List<Plan> availablePlans = const <Plan>[],
      final List<PaymentMethod> paymentMethods = const <PaymentMethod>[],
      this.defaultPaymentMethodId,
      final List<Invoice> invoices = const <Invoice>[],
      this.isLoading = false,
      this.errorCode,
      this.errorMessage,
      this.pendingProration})
      : _availablePlans = availablePlans,
        _paymentMethods = paymentMethods,
        _invoices = invoices;

  /// Suscripción activa del tenant (trialing, active o past_due).
  /// `null` si el tenant no tiene suscripción vigente.
  @override
  final Subscription? subscription;

  /// Lista de planes públicos disponibles ordenados por precio ascendente.
  final List<Plan> _availablePlans;

  /// Lista de planes públicos disponibles ordenados por precio ascendente.
  @override
  @JsonKey()
  List<Plan> get availablePlans {
    if (_availablePlans is EqualUnmodifiableListView) return _availablePlans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availablePlans);
  }

  /// Métodos de pago activos del tenant (no eliminados).
  final List<PaymentMethod> _paymentMethods;

  /// Métodos de pago activos del tenant (no eliminados).
  @override
  @JsonKey()
  List<PaymentMethod> get paymentMethods {
    if (_paymentMethods is EqualUnmodifiableListView) return _paymentMethods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_paymentMethods);
  }

  /// ID del método de pago marcado como predeterminado.
  @override
  final String? defaultPaymentMethodId;

  /// Página más reciente de facturas del tenant.
  final List<Invoice> _invoices;

  /// Página más reciente de facturas del tenant.
  @override
  @JsonKey()
  List<Invoice> get invoices {
    if (_invoices is EqualUnmodifiableListView) return _invoices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_invoices);
  }

  /// Indica operación asíncrona optimista en curso (mutaciones).
  @override
  @JsonKey()
  final bool isLoading;

  /// Código de error estructurado de [BillingRepositoryException] o stub.
  @override
  final String? errorCode;

  /// Mensaje legible del último error ocurrido.
  @override
  final String? errorMessage;

  /// Preview de prorrateo generado localmente antes de confirmar cambio de plan.
  @override
  final ProrationOutput? pendingProration;

  @override
  String toString() {
    return 'BillingV2State(subscription: $subscription, availablePlans: $availablePlans, paymentMethods: $paymentMethods, defaultPaymentMethodId: $defaultPaymentMethodId, invoices: $invoices, isLoading: $isLoading, errorCode: $errorCode, errorMessage: $errorMessage, pendingProration: $pendingProration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BillingV2StateImpl &&
            (identical(other.subscription, subscription) ||
                other.subscription == subscription) &&
            const DeepCollectionEquality()
                .equals(other._availablePlans, _availablePlans) &&
            const DeepCollectionEquality()
                .equals(other._paymentMethods, _paymentMethods) &&
            (identical(other.defaultPaymentMethodId, defaultPaymentMethodId) ||
                other.defaultPaymentMethodId == defaultPaymentMethodId) &&
            const DeepCollectionEquality().equals(other._invoices, _invoices) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.pendingProration, pendingProration) ||
                other.pendingProration == pendingProration));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      subscription,
      const DeepCollectionEquality().hash(_availablePlans),
      const DeepCollectionEquality().hash(_paymentMethods),
      defaultPaymentMethodId,
      const DeepCollectionEquality().hash(_invoices),
      isLoading,
      errorCode,
      errorMessage,
      pendingProration);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BillingV2StateImplCopyWith<_$BillingV2StateImpl> get copyWith =>
      __$$BillingV2StateImplCopyWithImpl<_$BillingV2StateImpl>(
          this, _$identity);
}

abstract class _BillingV2State implements BillingV2State {
  const factory _BillingV2State(
      {final Subscription? subscription,
      final List<Plan> availablePlans,
      final List<PaymentMethod> paymentMethods,
      final String? defaultPaymentMethodId,
      final List<Invoice> invoices,
      final bool isLoading,
      final String? errorCode,
      final String? errorMessage,
      final ProrationOutput? pendingProration}) = _$BillingV2StateImpl;

  @override

  /// Suscripción activa del tenant (trialing, active o past_due).
  /// `null` si el tenant no tiene suscripción vigente.
  Subscription? get subscription;
  @override

  /// Lista de planes públicos disponibles ordenados por precio ascendente.
  List<Plan> get availablePlans;
  @override

  /// Métodos de pago activos del tenant (no eliminados).
  List<PaymentMethod> get paymentMethods;
  @override

  /// ID del método de pago marcado como predeterminado.
  String? get defaultPaymentMethodId;
  @override

  /// Página más reciente de facturas del tenant.
  List<Invoice> get invoices;
  @override

  /// Indica operación asíncrona optimista en curso (mutaciones).
  bool get isLoading;
  @override

  /// Código de error estructurado de [BillingRepositoryException] o stub.
  String? get errorCode;
  @override

  /// Mensaje legible del último error ocurrido.
  String? get errorMessage;
  @override

  /// Preview de prorrateo generado localmente antes de confirmar cambio de plan.
  ProrationOutput? get pendingProration;
  @override
  @JsonKey(ignore: true)
  _$$BillingV2StateImplCopyWith<_$BillingV2StateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
