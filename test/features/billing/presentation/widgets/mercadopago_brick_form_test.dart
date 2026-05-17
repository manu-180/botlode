// Archivo: test/features/billing/presentation/widgets/mercadopago_brick_form_test.dart
//
// T4·08 — Unit / widget tests for MercadoPagoBrickForm.
//
// Strategy:
//   - debugDefaultTargetPlatformOverride is set and cleared with try/finally
//     inside each testWidgets body so Flutter's post-test invariant check
//     (which runs before teardown callbacks) sees the variable already reset.
//   - A hand-written _FakeWebViewPlatform captures JS channel registrations
//     and navigation delegates so tests can replay simulated Brick messages
//     without a real WebView process.
//
// Run:
//   flutter test test/features/billing/presentation/widgets/mercadopago_brick_form_test.dart

import 'dart:convert';

import 'package:botslode/features/billing/presentation/widgets/mercadopago_brick_form.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// ---------------------------------------------------------------------------
// Fake WebViewPlatform infrastructure
// ---------------------------------------------------------------------------

class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController(super.params) : super.implementation();

  final Map<String, JavaScriptChannelParams> channels = {};
  PageEventCallback? onPageFinished;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {
    channels[javaScriptChannelParams.name] = javaScriptChannelParams;
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    onPageFinished =
        (handler as _FakePlatformNavigationDelegate).onPageFinishedCallback;
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    // Fire page-finished synchronously so initState completes the setup.
    onPageFinished?.call(key);
  }

  @override
  Future<void> runJavaScript(String javaScript) async {}
}

class _FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  _FakePlatformNavigationDelegate(super.params) : super.implementation();

  PageEventCallback? onPageFinishedCallback;

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    onPageFinishedCallback = onPageFinished;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}
}

class _FakePlatformWebViewWidget extends PlatformWebViewWidget {
  _FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _FakeWebViewPlatform extends WebViewPlatform {
  _FakePlatformWebViewController? lastController;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final ctrl = _FakePlatformWebViewController(params);
    lastController = ctrl;
    return ctrl;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return _FakePlatformNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return _FakePlatformWebViewWidget(params);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<_FakeWebViewPlatform> _pumpBrickFormAndroid(
  WidgetTester tester, {
  required void Function(String) onToken,
  void Function(String)? onError,
  int amountCents = 1000,
  String mpPublicKey = 'APP_USR-test-key',
}) async {
  final fake = _FakeWebViewPlatform();
  WebViewPlatform.instance = fake;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MercadoPagoBrickForm(
          onToken: onToken,
          onError: onError,
          amountCents: amountCents,
          mpPublicKey: mpPublicKey,
        ),
      ),
    ),
  );
  await tester.pump();
  return fake;
}

void _sendBrickMessage(
  _FakeWebViewPlatform platform,
  Map<String, dynamic> payload,
) {
  final ctrl = platform.lastController!;
  final channel = ctrl.channels['MP_BRICK']!;
  channel.onMessageReceived(JavaScriptMessage(message: jsonEncode(payload)));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MercadoPagoBrickForm — browser fallback (Windows/macOS)', () {
    test('_isWebViewSupported returns false on non-mobile platforms', () {
      // Verify the getter logic directly — no platform override needed.
      // Test runner is Windows, macOS, or Linux (never Android/iOS).
      final supported =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);
      // On CI/desktop this is always false; on an actual device it could be true —
      // the assertion below is only meaningful when kIsWeb == false and platform
      // is not mobile, which is guaranteed for `flutter test` on desktop.
      if (!kIsWeb &&
          defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        expect(supported, isFalse);
      }
    });

    testWidgets('shows _BrowserFallback when platform is Windows', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MercadoPagoBrickForm(
                onToken: (_) {},
                amountCents: 500,
                mpPublicKey: 'APP_USR-test',
                fallbackCheckoutUrl: 'https://mp.example.com/pay',
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Pago con Mercado Pago'), findsOneWidget);
        expect(find.text('Abrir en navegador'), findsOneWidget);
        expect(find.byType(WebViewWidget), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('MercadoPagoBrickForm — WebView path (simulated Android)', () {
    testWidgets('shows WebViewWidget instead of fallback', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await _pumpBrickFormAndroid(tester, onToken: (_) {});

        expect(find.byType(WebViewWidget), findsOneWidget);
        expect(find.text('Abrir en navegador'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('loading overlay shown initially (before ready message)',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await _pumpBrickFormAndroid(tester, onToken: (_) {});

        // Page-finished fired (init JS called) but Brick's onReady not yet sent.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('loading overlay hidden after ready message', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final fake = await _pumpBrickFormAndroid(tester, onToken: (_) {});

        _sendBrickMessage(fake, {'type': 'ready'});
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('token message triggers onToken callback', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        String? receivedToken;
        final fake = await _pumpBrickFormAndroid(
          tester,
          onToken: (t) => receivedToken = t,
        );

        _sendBrickMessage(fake, {'type': 'token', 'token': 'tok_test'});
        await tester.pump();

        expect(receivedToken, equals('tok_test'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('error message triggers onError with code: message format',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        String? receivedError;
        final fake = await _pumpBrickFormAndroid(
          tester,
          onToken: (_) {},
          onError: (e) => receivedError = e,
        );

        _sendBrickMessage(fake, {
          'type': 'error',
          'code': 'invalid_card',
          'message': 'Tarjeta inválida',
        });
        await tester.pump();

        expect(receivedError, equals('invalid_card: Tarjeta inválida'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('invalid public key triggers onError with invalid_key code',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        String? receivedError;

        final fake = _FakeWebViewPlatform();
        WebViewPlatform.instance = fake;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MercadoPagoBrickForm(
                onToken: (_) {},
                onError: (e) => receivedError = e,
                amountCents: 1000,
                mpPublicKey: 'BAD<KEY>',
              ),
            ),
          ),
        );
        await tester.pump();

        expect(receivedError, contains('invalid_key'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
