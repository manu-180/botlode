// Archivo: lib/features/billing/presentation/widgets/stripe_elements_card_form.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/buttons/app_button.dart';

/// Devuelve true cuando la plataforma actual es escritorio nativo
/// (Windows, Linux, macOS). Retorna false en web y móvil.
bool get _isDesktop {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Widget que integra el formulario de tokenización de tarjetas con Stripe.
///
/// En plataformas soportadas (Android, iOS, web) renderiza [CardField] de
/// flutter_stripe y llama a [onToken] con el paymentMethodId resultante
/// (formato `pm_xxx`).
///
/// En plataformas de escritorio nativas (Windows, Linux, macOS) muestra
/// [_DesktopFallback] indicando que se requiere la app móvil.
///
/// Seguridad: nunca recibe ni registra el PAN (número de tarjeta) directamente.
class StripeElementsCardForm extends StatefulWidget {
  /// Llamado con el Stripe paymentMethodId ('pm_xxx') tras tokenización exitosa.
  final void Function(String paymentMethodId) onToken;

  /// Llamado con un mensaje de error legible si la tokenización falla.
  final void Function(String errorMessage)? onError;

  /// Inyección de dependencia para pruebas: si no es null, reemplaza la llamada
  /// real a [Stripe.instance.createPaymentMethod].
  final Future<PaymentMethod> Function(PaymentMethodParams)? createPaymentMethodOverride;

  const StripeElementsCardForm({
    super.key,
    required this.onToken,
    this.onError,
    this.createPaymentMethodOverride,
  });

  @override
  State<StripeElementsCardForm> createState() => _StripeElementsCardFormState();
}

class _StripeElementsCardFormState extends State<StripeElementsCardForm> {
  CardFieldInputDetails? _cardDetails;
  bool _isLoading = false;

  bool get _isFormComplete => _cardDetails?.complete == true;

  Future<void> _tokenize() async {
    setState(() => _isLoading = true);
    try {
      // Read email from Supabase session if available (billing detail — not PAN)
      final email = Supabase.instance.client.auth.currentUser?.email;
      final params = PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: BillingDetails(
            email: email,
          ),
        ),
      );
      final PaymentMethod pm = widget.createPaymentMethodOverride != null
          ? await widget.createPaymentMethodOverride!(params)
          : await Stripe.instance.createPaymentMethod(params: params);
      if (mounted) widget.onToken(pm.id);
    } on StripeException catch (e) {
      final msg = _mapStripeError(e);
      if (mounted) widget.onError?.call(msg);
    } catch (_) {
      if (mounted) widget.onError?.call('Error inesperado al tokenizar tarjeta.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Mapea errores de Stripe a mensajes en español.
  ///
  /// [FailureCode] en flutter_stripe 11.x sólo contiene los valores genéricos
  /// {Failed, Canceled, Timeout, Unknown}. Los detalles específicos de tarjeta
  /// viajan en [LocalizedErrorMessage.declineCode] y [LocalizedErrorMessage.stripeErrorCode].
  String _mapStripeError(StripeException e) {
    final declineCode = e.error.declineCode;
    final stripeCode = e.error.stripeErrorCode;

    if (declineCode != null) {
      return switch (declineCode) {
        'card_declined' => 'Tarjeta rechazada por el banco.',
        'insufficient_funds' => 'Fondos insuficientes.',
        'lost_card' => 'La tarjeta fue reportada como perdida.',
        'stolen_card' => 'La tarjeta fue reportada como robada.',
        'expired_card' => 'La tarjeta está vencida.',
        'incorrect_cvc' => 'Código de seguridad (CVV) incorrecto.',
        'processing_error' => 'Error de procesamiento. Intentá de nuevo.',
        _ => e.error.localizedMessage ?? e.error.message ?? 'Tarjeta rechazada.',
      };
    }

    if (stripeCode != null) {
      return switch (stripeCode) {
        'invalid_number' => 'Número de tarjeta inválido.',
        'invalid_expiry_month' || 'invalid_expiry_year' => 'Fecha de vencimiento inválida.',
        'invalid_cvc' => 'Código de seguridad (CVV) inválido.',
        'expired_card' => 'La tarjeta está vencida.',
        'card_declined' => 'Tarjeta rechazada por el banco.',
        _ => e.error.localizedMessage ?? e.error.message ?? 'Error al procesar la tarjeta.',
      };
    }

    return switch (e.error.code) {
      FailureCode.Canceled => 'Operación cancelada.',
      FailureCode.Timeout => 'Tiempo de espera agotado. Intentá de nuevo.',
      FailureCode.Failed || FailureCode.Unknown => e.error.localizedMessage ??
          e.error.message ??
          'Error al procesar la tarjeta.',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return const _DesktopFallback();
    }
    return _CardFormBody(
      cardDetails: _cardDetails,
      isLoading: _isLoading,
      isFormComplete: _isFormComplete,
      onCardChanged: (card) => setState(() => _cardDetails = card),
      onTokenize: _tokenize,
    );
  }
}

// ---------------------------------------------------------------------------
// Formulario con CardField (móvil / web)
// ---------------------------------------------------------------------------

class _CardFormBody extends StatelessWidget {
  final CardFieldInputDetails? cardDetails;
  final bool isLoading;
  final bool isFormComplete;
  final void Function(CardFieldInputDetails?) onCardChanged;
  final VoidCallback onTokenize;

  const _CardFormBody({
    required this.cardDetails,
    required this.isLoading,
    required this.isFormComplete,
    required this.onCardChanged,
    required this.onTokenize,
  });

  @override
  Widget build(BuildContext context) {
    return HoloPanel(
      padding: const EdgeInsets.all(AppDimens.space24),
      borderColor: AppColors.borderDefault,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado
          Row(
            children: [
              const Icon(
                Icons.credit_card_outlined,
                size: AppDimens.iconS,
                color: AppColors.gold,
              ),
              const SizedBox(width: AppDimens.space8),
              Text(
                'DATOS DE TARJETA',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          const HudDivider(),
          const SizedBox(height: AppDimens.space20),

          // Visible label for the card field (required for sighted users and a11y)
          Text(
            'Número, vencimiento y CVV',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.space8),

          // NOTE: Full a11y inside CardField is limited by Stripe's WebView —
          // the internal inputs are managed by Stripe Elements (WebView/native).
          // The Semantics wrapper below exposes the field group to Flutter's
          // accessibility tree; individual sub-field focus is handled by Stripe.
          Semantics(
            label: 'Formulario de tarjeta de crédito - campos gestionados por Stripe',
            hint: 'Ingrese número de tarjeta, fecha de vencimiento y CVV',
            child: CardField(
              onCardChanged: onCardChanged,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Oxanium',
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: AppDimens.brM,
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDimens.brM,
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppDimens.brM,
                  borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space24),

          // Botón de tokenización
          AppButton(
            label: isLoading ? 'PROCESANDO...' : 'VALIDAR TARJETA',
            onPressed: (isFormComplete && !isLoading) ? onTokenize : null,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.md,
            leadingIcon: isLoading ? null : Icons.lock_outline,
            loading: isLoading,
            expand: true,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fallback: escritorio nativo
// ---------------------------------------------------------------------------

class _DesktopFallback extends StatelessWidget {
  const _DesktopFallback();

  static const List<String> _instructions = [
    'Abrí BotLode en tu teléfono',
    'Entrá a Facturación',
    'Agregá la tarjeta',
  ];

  Widget _buildInstructions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_instructions.length, (i) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: i < _instructions.length - 1 ? AppDimens.space8 : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppDimens.space20,
                child: Text(
                  '${i + 1}.',
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _instructions[i],
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HoloPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space24,
        vertical: AppDimens.space32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HUD ring con ícono de smartphone
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceHud,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderGold,
                width: 1.5,
              ),
              boxShadow: AppDimens.glowGold,
            ),
            child: const Icon(
              Icons.phone_iphone,
              color: AppColors.gold,
              size: AppDimens.iconL,
            ),
          ),
          const SizedBox(height: AppDimens.space20),

          // Título
          Semantics(
            header: true,
            child: Text(
              'Continuá en la app móvil',
              style: AppTextStyles.titleM,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimens.space12),

          // Cuerpo descriptivo
          Text(
            'Stripe Elements se completa desde la app móvil de BotLode por seguridad en la tokenización.',
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.space20),

          // Instrucciones numeradas
          _buildInstructions(),
          const SizedBox(height: AppDimens.space20),

          // Nota de seguridad
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: AppDimens.iconXS,
                color: AppColors.success,
              ),
              const SizedBox(width: AppDimens.space4),
              Text(
                'Tokenización segura vía Stripe',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
