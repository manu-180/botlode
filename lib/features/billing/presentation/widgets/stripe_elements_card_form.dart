// Archivo: lib/features/billing/presentation/widgets/stripe_elements_card_form.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void dispose() {
    _cardDetails = null;
    super.dispose();
  }

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado
          Row(
            children: [
              Icon(Icons.credit_card_outlined,
                  color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'DATOS DE TARJETA',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontFamily: 'Oxanium',
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visible label for the card field (required for sighted users and a11y)
          Text(
            'Datos de tu tarjeta',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // NOTE: Full a11y inside CardField is limited by Stripe's WebView —
          // the internal inputs are managed by Stripe Elements (WebView/native).
          // The Semantics wrapper below exposes the field group to Flutter's
          // accessibility tree; individual sub-field focus is handled by Stripe.
          Semantics(
            label: 'Formulario de tarjeta de crédito - campos gestionados por Stripe',
            hint: 'Ingrese número de tarjeta, fecha de vencimiento y CVV',
            child: CardField(
              onCardChanged: onCardChanged,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Oxanium',
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surface.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón de tokenización
          FilledButton.icon(
            onPressed: (isFormComplete && !isLoading) ? onTokenize : null,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_outline, size: 18),
            label: Text(
              isLoading ? 'PROCESANDO...' : 'VALIDAR TARJETA',
              style: const TextStyle(
                fontFamily: 'Oxanium',
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.phone_android_outlined,
            size: 52,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Stripe requiere la app móvil',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontFamily: 'Oxanium',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'La integración con Stripe Elements no está disponible en la '
            'versión de escritorio. Por favor, usá la aplicación móvil para '
            'agregar una tarjeta de crédito.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
