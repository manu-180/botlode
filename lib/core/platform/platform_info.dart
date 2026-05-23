// Archivo: lib/core/platform/platform_info.dart
//
// Helpers centralizados para detección de plataforma en tiempo de ejecución.
// Cualquier código que necesite tomar decisiones por plataforma (mostrar
// title bar custom, llamar a window_manager, usar APIs nativas vs web, etc.)
// debe ir por acá en lugar de chequear flags sueltos.

import 'package:flutter/foundation.dart';

/// Información de plataforma actual.
class PlatformInfo {
  const PlatformInfo._();

  /// True si la app corre en web (compilado a JS/WASM).
  static bool get isWeb => kIsWeb;

  /// True si la app corre en una plataforma desktop nativa
  /// (Windows, macOS o Linux). False en web y mobile.
  static bool get isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// True si la app corre en mobile nativo (Android o iOS).
  static bool get isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// True si la plataforma usa una window chrome custom (title bar HUD
  /// decorativa). Hoy sólo desktop nativo. La app es mobile-first; no
  /// hace falta `window_manager` porque ya no se controla la ventana.
  static bool get usesCustomTitleBar => isDesktop;

  /// True si la plataforma soporta `flutter_stripe` SDK nativo (Android/iOS).
  /// Web usa `flutter_stripe_web`; desktop no soporta Stripe.
  static bool get supportsNativeStripe => isMobile;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
}
