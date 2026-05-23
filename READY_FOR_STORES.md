# BotLode — Release readiness para Play Store y App Store

Estado al **2026-05-23** tras el pivot de desktop Windows-only → app mobile-first.

---

## Resumen ejecutivo

| Plataforma | Código listo | Build verificado | Falta para release |
|------------|--------------|-------------------|--------------------|
| **Android (Play Store)** | ✅ Sí | ✅ APK debug builds OK | Keystore real + Play Console |
| **iOS (App Store)** | ✅ Sí | ⚠️ No buildable en Windows | Compilar en macOS + Apple Developer |
| **Web** | ✅ Sí | ✅ Build OK | Deploy a HTTPS |
| **Windows (desktop)** | ✅ Sí | ✅ Funcional | Opcional, no requerido |
| **macOS (desktop)** | ✅ Sí | ⚠️ No buildable en Windows | Opcional, no requerido |

---

## Lo que ya está hecho (en el código)

### Cross-platform / arquitectura
- `window_manager` **eliminado** del pubspec — la app es mobile-first; ya no controla la ventana del SO.
- `lib/core/platform/platform_info.dart` centraliza la detección de plataforma.
- `lib/core/ui/responsive/breakpoints.dart` define mobile (< 600) / tablet / desktop.
- `MainLayout` se adapta: bottom nav en mobile, sidebar en tablet/desktop.
- Carpetas nativas creadas: `android/`, `ios/`, `macos/` con bundle ID `com.botslode.botslode`.
- `flutter_launcher_icons` configurado para Android/iOS/macOS/Web/Windows; íconos generados.

### Android
- `android/app/build.gradle.kts`:
  - `applicationId = "com.botslode.botslode"`
  - `compileSdk = 34`, `targetSdk = 34` (requerido por Play Store)
  - `minSdk = 23` (compatible con Stripe SDK)
  - Signing config con fallback: usa `android/key.properties` si existe, sino debug keys
  - `isMinifyEnabled = true` y `isShrinkResources = true` en release
- `android/app/src/main/AndroidManifest.xml`:
  - Permisos: `INTERNET`, `ACCESS_NETWORK_STATE`, `READ_MEDIA_*`, `CAMERA`, `RECORD_AUDIO`
  - `android:usesCleartextTraffic="false"` (sólo HTTPS)
  - Deep link `botslode://` para callbacks de pago / OAuth
  - Label `BotLode`, icono `@mipmap/ic_launcher`
- `android/build.gradle.kts` fuerza Kotlin language version 1.8 (workaround posthog_flutter 4.x).

### iOS
- `ios/Podfile` creado con `platform :ios, '13.0'` y post-install que setea `IPHONEOS_DEPLOYMENT_TARGET = 13.0`.
- `ios/Runner/Info.plist`:
  - `CFBundleDisplayName = BotLode`
  - `ITSAppUsesNonExemptEncryption = false` (evita prompt de exportación)
  - `NSAppTransportSecurity` con `NSAllowsArbitraryLoads = false`
  - Usage descriptions para cámara, fotos, micrófono (precargados con copys explicativos)
  - `CFBundleURLTypes` con scheme `botslode` para deep links
- `AppDelegate.swift` con plugin registrant (default Flutter).

### macOS (opcional, no requerido para mobile stores)
- Entitlements con `com.apple.security.network.client` en debug + release.

### Web
- `web/manifest.json` con name real, description, categories, theme color, orientation `any`.
- `web/index.html` con meta description, Open Graph, Twitter cards, theme-color.
- Íconos PWA generados.

### Seguridad / secretos
- `.env` está en `.gitignore`.
- `.gitignore` añadió `key.properties`, `*.jks`, `*.keystore`, `google-services.json`, `GoogleService-Info.plist`, `ios/Pods/`, `macos/Pods/`.

---

## Pasos manuales pendientes para release

### Android (Play Store)

1. **Generar keystore real (UNA SOLA VEZ — guardalo fuera del repo, en un sitio seguro):**
   ```bash
   keytool -genkey -v -keystore ~/botslode-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias botslode
   ```

2. **Crear `android/key.properties`** (copiar de `android/key.properties.example`) con los valores reales. Este archivo **NO** se commitea (ya está en `.gitignore`).

3. **Buildear App Bundle de release:**
   ```bash
   flutter build appbundle --release
   ```
   El AAB queda en `build/app/outputs/bundle/release/app-release.aab`.

4. **Crear ficha en Play Console** (https://play.google.com/console):
   - Subir el `.aab` a un closed test track primero
   - Completar: descripción, screenshots (mínimo 2 por dispositivo), policy de privacidad, content rating, target audience
   - Una vez aprobado en test → promote a production

5. **Privacy policy URL:** redactar y hostear (puede vivir en la web `botslode.app/privacy`).

### iOS (App Store)

⚠️ **Esto requiere una Mac.** Desde Windows no se puede compilar.

1. **En la Mac, clonar el repo y correr:**
   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   ```

2. **Crear App ID en Apple Developer** (https://developer.apple.com/account):
   - Bundle ID: `com.botslode.botslode`
   - Capabilities mínimas: ninguna obligatoria (agregar Push Notifications, Sign in with Apple, etc. si los activás)

3. **Crear provisioning profiles** (development + App Store distribution).

4. **Configurar code signing** en Xcode (`ios/Runner.xcworkspace`):
   - Seleccionar el equipo (Team)
   - Verificar Bundle Identifier
   - Automatic signing recomendado para empezar

5. **Buildear:**
   ```bash
   flutter build ipa --release
   ```
   El `.ipa` queda en `build/ios/ipa/`.

6. **Subir a App Store Connect** vía Transporter app o Xcode.

7. **Crear ficha en App Store Connect** (https://appstoreconnect.apple.com):
   - Subir el `.ipa`
   - Completar: descripción, screenshots (iPhone 6.7", iPhone 5.5", iPad), keywords, privacy policy URL, age rating
   - Submit for review

### Web

1. **Buildear:**
   ```bash
   flutter build web --release --no-tree-shake-icons
   ```

2. **Deployar** a Vercel/Netlify/Cloudflare Pages/etc. — apuntar al folder `build/web/`.

3. **Importante:** servir sobre HTTPS (requerido para PWA). El service worker y CORS de Supabase también lo requieren.

---

## Próximos pasos recomendados (no bloqueantes)

- **Mercado Pago deep link callback:** agregar route en `app_router.dart` que escuche `botslode://payment/success?...` y refresque `billingV2Provider`.
- **Edge function de Mercado Pago:** asegurar que la función `create-mp-preference` incluya `back_urls.success/failure` apuntando al deep link de la app + URL web para fallback.
- **OAuth:** si vas a soportar Sign in with Google/Apple, configurar redirect URIs en Supabase + agregar buttons en `LoginView`.
- **Push notifications:** integrar `firebase_messaging` + APNs.
- **Crashlytics / Sentry release:** la app ya inicializa Sentry; configurar source maps para producción.
- **Versionado automático:** script CI que incremente `version: X.Y.Z+N` en cada release.

---

## Nota sobre el archivo `.env`

El `.env` tenía BOM (UTF-8 BOM) y mezcla de CRLF/LF, lo que rompía a `flutter_dotenv` en Android. Se normalizó a ASCII puro LF. **Si edita el `.env` desde un editor de Windows, asegurarse de guardar como UTF-8 sin BOM y LF.**

Backup del `.env` original con BOM en `.env.backup-bom` (también ignorado por git).
