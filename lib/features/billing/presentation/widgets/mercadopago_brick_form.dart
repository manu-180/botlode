// lib/features/billing/presentation/widgets/mercadopago_brick_form.dart
// MercadoPago Brick form widget.
// On mobile (Android/iOS): renders a WebView loading mp_brick.html and
// crossfades the skeleton out once the JS bridge sends 'ready'.
// On desktop/web (Windows, macOS, Linux, web): renders a browser fallback
// that opens fallbackCheckoutUrl via url_launcher.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/buttons/app_button.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

class MercadoPagoBrickForm extends StatefulWidget {
  final void Function(String token) onToken;
  final void Function(String message) onError;
  final int amountCents;
  final String mpPublicKey;
  final String? fallbackCheckoutUrl;

  const MercadoPagoBrickForm({
    super.key,
    required this.onToken,
    required this.onError,
    required this.amountCents,
    required this.mpPublicKey,
    this.fallbackCheckoutUrl,
  });

  @override
  State<MercadoPagoBrickForm> createState() => _MercadoPagoBrickFormState();
}

class _MercadoPagoBrickFormState extends State<MercadoPagoBrickForm> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isLaunching = false;
  String? _loadError;

  // Returns true only on Android/iOS — the only platforms where WebView works.
  bool get _webViewSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    if (_webViewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'MP_BRICK',
          onMessageReceived: _onBrickMessage,
        )
        ..setNavigationDelegate(NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _loadError = 'Error al cargar el formulario de pago.';
                _isLoading = false;
              });
            }
          },
        ))
        ..loadFlutterAsset('assets/billing/mp_brick.html');
    }
  }

  // ---- JS bridge ----------------------------------------------------------

  void _onBrickMessage(JavaScriptMessage message) {
    if (!mounted) return;
    final data = message.message;
    if (data == 'ready') {
      setState(() => _isLoading = false);
    } else if (data.startsWith('token:')) {
      final token = data.substring(6);
      if (token.isNotEmpty && token.length <= 256) {
        widget.onToken(token);
      }
    } else if (data.startsWith('error:')) {
      final rawCode = data.substring(6);
      widget.onError(_mapMpError(rawCode));
    }
  }

  // ---- Error mapping -------------------------------------------------------

  String _mapMpError(String code) {
    return switch (code) {
      'E301' => 'Número de tarjeta inválido.',
      'E302' => 'CVV inválido.',
      'invalidCardholderName' => 'Nombre del titular inválido.',
      'cardExpirationMonthError' => 'Mes de vencimiento inválido.',
      'cardExpirationYearError' => 'Año de vencimiento inválido.',
      'cc_rejected_bad_filled_card_number' => 'Número de tarjeta incorrecto.',
      'cc_rejected_bad_filled_date' => 'Fecha de vencimiento incorrecta.',
      'cc_rejected_bad_filled_cvv' => 'CVV incorrecto.',
      'cc_rejected_card_disabled' => 'Tarjeta deshabilitada.',
      'cc_rejected_insufficient_amount' => 'Fondos insuficientes.',
      'cc_rejected_high_risk' => 'Pago rechazado. Intentá con otra tarjeta.',
      _ => 'Error de Mercado Pago. Intentá de nuevo.',
    };
  }

  // ---- Amount formatter ---------------------------------------------------

  String _formatAmount(int cents) {
    final dollars = cents ~/ 100;
    final remainder = cents % 100;
    return 'USD \$${dollars.toString()}.${remainder.toString().padLeft(2, '0')}';
  }

  // ---- Browser launch -----------------------------------------------------

  Future<void> _launchBrowser() async {
    final url = widget.fallbackCheckoutUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      widget.onError('URL de pago malformada.');
      return;
    }
    if (mounted) setState(() => _isLaunching = true);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) widget.onError('No se pudo abrir el navegador.');
    } catch (_) {
      if (mounted) widget.onError('No se pudo abrir el navegador.');
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  // ---- Retry callback for ErrorFeedbackCard --------------------------------

  Future<void> _retryLoad() async {
    final controller = _controller;
    if (controller == null) return;
    if (mounted) {
      setState(() {
        _loadError = null;
        _isLoading = true;
      });
    }
    await controller.loadFlutterAsset('assets/billing/mp_brick.html');
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_webViewSupported) {
      return _BrowserFallback(
        fallbackCheckoutUrl: widget.fallbackCheckoutUrl,
        isLaunching: _isLaunching,
        onLaunch: _launchBrowser,
      );
    }

    final reduced = AppMotion.reduced(context);

    return HoloPanel(
      padding: const EdgeInsets.all(AppDimens.space24),
      borderColor: AppColors.borderDefault,
      child: _BrickBody(
        amountCents: widget.amountCents,
        formattedAmount: _formatAmount(widget.amountCents),
        controller: _controller!, // non-null: _webViewSupported guarantees initState set it
        isLoading: _isLoading,
        loadError: _loadError,
        reduced: reduced,
        onRetry: _retryLoad,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BrickBody — WebView content area
// ---------------------------------------------------------------------------

class _BrickBody extends StatelessWidget {
  final int amountCents;
  final String formattedAmount;
  final WebViewController controller;
  final bool isLoading;
  final String? loadError;
  final bool reduced;
  final Future<void> Function() onRetry;

  const _BrickBody({
    required this.amountCents,
    required this.formattedAmount,
    required this.controller,
    required this.isLoading,
    required this.loadError,
    required this.reduced,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount display — omitted when amountCents is 0.
        if (amountCents > 0) ...[
          Text(
            'TOTAL',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            formattedAmount,
            style: AppTextStyles.hudReadout.copyWith(
              color: AppColors.gold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.space16),
          const HudDivider(),
          const SizedBox(height: AppDimens.space16),
        ],

        // Error state or WebView + skeleton overlay.
        if (loadError != null)
          ErrorFeedbackCard(
            title: 'Error de carga',
            message: loadError!,
            onRetry: onRetry,
            variant: ErrorVariant.inline,
          )
        else
          Stack(
            children: [
              // WebView — fixed height to contain the Brick form.
              SizedBox(
                height: 280,
                child: ClipRRect(
                  borderRadius: AppDimens.brS,
                  child: Semantics(
                    label: 'Formulario de pago Mercado Pago',
                    hint: 'Complete los datos de su tarjeta',
                    child: WebViewWidget(controller: controller),
                  ),
                ),
              ),

              // Skeleton crossfades out when 'ready' arrives.
              AnimatedSwitcher(
                duration: reduced
                    ? AppMotion.durCrossfadeReduced
                    : AppMotion.durBase,
                child: isLoading
                    ? const SizedBox(
                        key: ValueKey('skeleton'),
                        height: 280,
                        child: _BrickSkeleton(),
                      )
                    : const SizedBox.shrink(key: ValueKey('webview')),
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _BrickSkeleton — shimmer placeholder while Brick loads
// ---------------------------------------------------------------------------

class _BrickSkeleton extends StatelessWidget {
  const _BrickSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card number field.
        SkeletonBase(height: 44, radius: AppDimens.radiusM),
        SizedBox(height: AppDimens.space12),

        // Expiry + CVV row.
        Row(
          children: [
            Expanded(
              child: SkeletonBase(height: 44, radius: AppDimens.radiusM),
            ),
            SizedBox(width: AppDimens.space12),
            Expanded(
              child: SkeletonBase(height: 44, radius: AppDimens.radiusM),
            ),
          ],
        ),
        SizedBox(height: AppDimens.space12),

        // Cardholder name field.
        SkeletonBase(height: 44, radius: AppDimens.radiusM),
        SizedBox(height: AppDimens.space20),

        // Pay button.
        SkeletonBase(height: 48, radius: AppDimens.radiusM),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _BrowserFallback — shown on Windows / macOS / Linux / web
// ---------------------------------------------------------------------------

class _BrowserFallback extends StatelessWidget {
  final String? fallbackCheckoutUrl;
  final bool isLaunching;
  final Future<void> Function() onLaunch;

  const _BrowserFallback({
    required this.fallbackCheckoutUrl,
    required this.isLaunching,
    required this.onLaunch,
  });

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
          // HUD ring with browser icon.
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
              Icons.open_in_browser,
              color: AppColors.gold,
              size: AppDimens.iconL,
            ),
          ),
          const SizedBox(height: AppDimens.space20),

          // Title.
          Semantics(
            header: true,
            child: Text(
              'Pago con Mercado Pago',
              style: AppTextStyles.titleM,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimens.space12),

          // Description.
          Text(
            'El pago se completa en el navegador a través de Mercado Pago.',
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.space20),

          // Launch button.
          AppButton(
            label: isLaunching ? 'ABRIENDO...' : 'ABRIR EN NAVEGADOR',
            onPressed: (fallbackCheckoutUrl != null && !isLaunching)
                ? () => onLaunch()
                : null,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.md,
            leadingIcon: Icons.open_in_browser,
            loading: isLaunching,
            expand: true,
          ),

          // No-URL hint.
          if (fallbackCheckoutUrl == null) ...[
            const SizedBox(height: AppDimens.space8),
            Text(
              'URL de pago no disponible. Contactá al soporte.',
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppDimens.space16),

          // Security notice.
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
                'Los datos de tu tarjeta se procesan directamente en Mercado Pago',
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
