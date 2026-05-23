# Deploy a App Store — Guía paso a paso

> Generado el 21/05/2026 después del refactor de limpieza.
> Bundle ID actual: `com.botlode.botslode`
> Display Name: `BotLode`

---

## 0. Pre-requisitos (1 sola vez)

- [ ] **Apple Developer Account** activa ($99/año). Si no la tenés, comprar en https://developer.apple.com/programs/enroll/. Tarda 24-48 hs en activarse.
- [ ] **Xcode** instalado en la Mac (mínimo 15.x). Desde App Store, ~12 GB.
- [ ] **Flutter SDK** en la Mac. Recomendado: `brew install --cask flutter` o el zip oficial.
- [ ] **CocoaPods**: `sudo gem install cocoapods` (o `brew install cocoapods`).
- [ ] **Git** y `gh` CLI (opcional, para PRs).

Verificá:
```bash
flutter doctor
```
Debe estar todo en verde, incluyendo "Xcode" y "iOS toolchain".

---

## 1. Traer el código a la Mac

```bash
git clone https://github.com/manu-180/botlode.git
cd botlode
git checkout main
git pull
flutter pub get
```

Verificá que la base esté al día:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Probá que corre en local:
```bash
flutter run -d macos
```

---

## 2. macOS App Store — el camino corto

### 2.1 Crear el archivo `.env` en local

`.env` ya no se trackea en git. En la Mac:
```bash
cp .env.example .env
# Editar .env con los valores reales (Supabase URL+anon, MP_PUBLIC_KEY)
```

### 2.2 Instalar pods de macOS

```bash
cd macos && pod install && cd ..
```

### 2.3 Abrir el workspace en Xcode

```bash
open macos/Runner.xcworkspace
```

> **Importante**: abrir el `.xcworkspace`, NO el `.xcodeproj`.

### 2.4 Configurar Signing

En Xcode:
1. Click en `Runner` (carpeta superior, ícono azul) → Target `Runner`.
2. Tab **Signing & Capabilities**.
3. **Team**: seleccioná tu Apple Developer Team (vas a tener que loguearte con tu Apple ID + huella).
4. **Bundle Identifier**: ya está `com.botlode.botslode`. Si querés algo más limpio (ej. `com.botlode.app`), cambialo acá y también en `macos/Runner/Configs/AppInfo.xcconfig`. **Hacelo AHORA antes de crear la app en App Store Connect** — después es un infierno cambiarlo.
5. Marcá **Automatically manage signing** (Apple genera certificados solo).

### 2.5 Verificar entitlements

Ya configuré `com.apple.security.network.client` (necesario para Supabase). Verificá en Xcode que esté:
- Tab **Signing & Capabilities** → debe aparecer **App Sandbox** con "Outgoing Connections (Client)" tildado.

### 2.6 Build local de prueba

En terminal:
```bash
flutter build macos --release
```

Si compila limpio, encontrás el .app en:
```
build/macos/Build/Products/Release/BotLode.app
```

Doble click para probarlo. Si abre y funciona, andás bien.

### 2.7 Archive + Upload con Xcode

En Xcode con el target Runner seleccionado:
1. Menu **Product → Archive** (espera 2-5 minutos).
2. Cuando termina abre Organizer. Click **Distribute App**.
3. Elegí **App Store Connect** → **Upload** → seguí los pasos.
4. Xcode te pide validar con la huella varias veces.

El build aparece en App Store Connect en ~15 minutos (después de "processing").

---

## 3. App Store Connect — crear la app

### 3.1 Crear la entrada en https://appstoreconnect.apple.com

1. **My Apps** → **+** → **New App**.
2. **Platforms**: macOS.
3. **Name**: `BotLode` (lo que se ve en la tienda — podés cambiarlo después).
4. **Primary language**: Spanish (Argentina).
5. **Bundle ID**: seleccionar `com.botlode.botslode` (te aparece después de hacer el primer Archive desde Xcode, que registra el bundle automáticamente).
6. **SKU**: cualquier string único interno, ej. `BOTLODE_MACOS_001`.
7. **User Access**: Full Access.

### 3.2 Completar metadata

En la sección **App Information**:
- **Category Primary**: Productivity (recomendado) o Developer Tools.
- **Privacy Policy URL**: necesitás **hostear** `PRIVACY.md` en algún lado. Opciones:
  - GitHub Pages: subí `PRIVACY.md` como `docs/privacy.html` y activá Pages → URL tipo `https://manu-180.github.io/botlode/privacy.html`.
  - Tu propio dominio: `https://getbotlode.com/privacy` (si tenés ese dominio configurado).
- **Support URL**: cualquier URL donde te puedan contactar (página simple o tu email mailto).

En la sección **Version (1.0.0)**:
- **Description**: descripción breve. Te dejo un draft:

> BotLode es una fábrica de chatbots de IA que se embeben en cualquier sitio web. Diseñá tu bot con un prompt personalizado, ajustá su personalidad y apariencia, y obtené un script listo para pegar en tu HTML. Cada bot tiene su propia configuración, historial de conversaciones y métricas. Ideal para soporte, ventas o asistencia automatizada.

- **Keywords**: `chatbot,IA,AI,bot,asistente,soporte,web,widget,GPT,Claude,Anthropic` (máximo 100 chars).
- **Promotional Text** (opcional, 170 chars): "Creá chatbots de IA personalizados y embebelos en tu web en minutos."
- **What's New**: "Versión inicial 1.0.0."
- **Screenshots**: necesitás capturas de la app en macOS (ver sección 3.3).

### 3.3 Screenshots requeridos

Para Mac App Store: 1-10 capturas a **2880x1800** o **2560x1600**.

Desde la Mac con la app abierta:
```bash
# Cmd+Shift+5 → Capture entire screen → save
```

Sugerencias de qué capturar:
1. Dashboard con bots creados.
2. Vista de detalle de un bot (con el chat embebido).
3. Tienda / plantillas.
4. Billing / pagos.
5. Settings.

### 3.4 App Review Information

- **Sign-In info**: si requiere login (Supabase Auth), creá una cuenta de prueba y dejá las credenciales en el formulario.
- **Contact Information**: tu nombre, email, teléfono. Apple llama si tiene dudas.
- **Notes**: una explicación breve. Sugerencia:

> BotLode es una plataforma SaaS para crear chatbots embebibles en sitios web. La autenticación es vía email + password (Supabase). Los pagos opcionales se procesan vía Mercado Pago para suscripciones de ciclos de bots. No requiere ningún hardware especial ni servicios adicionales.

### 3.5 Privacy Questionnaire

Apple te va a preguntar qué datos recopilás. Basado en `PRIVACY.md`:

| Data Type | Recolectado | Linked to User | Used for Tracking |
|---|---|---|---|
| Email | ✅ | ✅ | ❌ |
| Name | ❌ | - | - |
| Phone | ❌ | - | - |
| User Content (bots, messages) | ✅ | ✅ | ❌ |
| Identifiers (User ID) | ✅ | ✅ | ❌ |
| Usage Data | ✅ | ✅ | ❌ |
| Diagnostics | ✅ | ❌ | ❌ |
| Purchase History | ✅ | ✅ | ❌ |
| Financial Info (card) | ❌ (procesado por MP, no almacenado) | - | - |

### 3.6 Submit for Review

Una vez completo todo, **Add for Review** → **Submit to App Review**.

Tiempo de review: 24-72 hs típicamente. Si te rechazan, leés el motivo y respondes.

---

## 4. iOS — TODO antes de poder publicar

### ⚠️ Problema actual: `window_manager` bloquea el build iOS

La app usa el paquete `window_manager` (en `pubspec.yaml`) que **solo soporta plataformas desktop** (Windows, macOS, Linux). Al intentar `flutter build ios` vas a obtener errores del estilo:

```
Error: window_manager doesn't support iOS
```

### Cómo arreglarlo (en la Mac, antes del primer build iOS)

**Opción A — Wrapping seguro con `Platform.isXXX` (recomendado)**

Hacé un servicio wrapper que solo usa `windowManager` en desktop:

`lib/core/services/window_service.dart`:
```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

class WindowService {
  static Future<void> initialize() async {
    if (!_isDesktop) return;
    // Importación condicional acá usando deferred loading o stub pattern
  }
  // ... etc
}
```

**Opción B — Conditional import por library (más complejo)**

Crear dos archivos `window_helpers_stub.dart` y `window_helpers_desktop.dart` y usar:
```dart
import 'window_helpers_stub.dart'
  if (dart.library.io) 'window_helpers_desktop.dart';
```

⚠️ Esto NO discrimina iOS de macOS (los dos son `dart.library.io`). Necesitás combinarlo con `Platform.isXXX` en runtime.

**Opción C — Refactor UI mobile completo**

La forma "correcta" pero más larga: hacer una UI mobile-first desde cero (sin custom title bar, layouts adaptativos, gestos touch). Trabajo de varios días.

### Pasos cuando lo arregles

```bash
cd ios && pod install && cd ..
flutter build ios --release
open ios/Runner.xcworkspace
# Signing & Capabilities → tu team Apple
# Product → Archive → Distribute App → App Store Connect
```

Y en App Store Connect: crear **otra app** (o agregar plataforma iOS a la existente).

---

## 5. Notas adicionales

### Bundle ID — ¿cambiarlo a `com.botlode.app`?

El bundle actual es `com.botlode.botslode` (Flutter agregó el nombre del paquete del pubspec). Si te molesta la "s" extra, cambialo **antes** de crear la app en App Store Connect:

1. `macos/Runner/Configs/AppInfo.xcconfig`: `PRODUCT_BUNDLE_IDENTIFIER = com.botlode.app`
2. `ios/Runner.xcodeproj/project.pbxproj`: buscar `PRODUCT_BUNDLE_IDENTIFIER` y cambiar.
3. Commit y rehacer Archive.

Después de subir a App Store Connect, **no se puede cambiar más**.

### Supabase: tablas WhatsApp residuales

Las tablas `wpp_control`, `wpp_inbox`, `empresas_whatsapp_limit`, etc. siguen existiendo en tu base de Supabase aunque borramos los archivos de migración. **No molestan para que la app funcione**, pero ocupan espacio.

Para limpiarlas, en tu Supabase SQL Editor:
```sql
DROP TABLE IF EXISTS wpp_inbox CASCADE;
DROP TABLE IF EXISTS wpp_control CASCADE;
DROP TABLE IF EXISTS empresas_whatsapp_limit CASCADE;
ALTER TABLE bots DROP COLUMN IF EXISTS wpp;
ALTER TABLE bots DROP COLUMN IF EXISTS telefono;
-- Si tenés columnas de whatsapp_totals en alguna tabla, también dropearlas
```

### Versionado

Cada vez que subís un nuevo build, **incrementá** en `pubspec.yaml`:
```yaml
version: 1.0.0+1   # antes
version: 1.0.1+2   # después de un fix menor
```

El `+N` es el build number — debe ser único en cada upload, Apple lo exige.

### Crash de hot-reload tras tocar entitlements

Si tras compilar Release y volver a Debug ves crashes raros, ejecutá:
```bash
flutter clean
flutter pub get
cd macos && pod install && cd ..
```

---

## 6. Si algo se cae — diagnóstico rápido

| Síntoma | Probable causa | Fix |
|---|---|---|
| `flutter build macos` falla con CocoaPods | Pods desactualizados | `cd macos && pod repo update && pod install` |
| Supabase no conecta en macOS Release | Falta `network.client` entitlement | Verificar `macos/Runner/Release.entitlements` |
| "No provisioning profile" en Xcode | Signing mal configurado | Signing & Capabilities → marcar Automatic + seleccionar Team |
| `flutter build ios` falla con `window_manager` | window_manager no soporta iOS | Ver sección 4 |
| Apple rechaza con guideline 5.1.1 (privacy) | Privacy URL inválida | Hostear PRIVACY.md públicamente y poner URL correcta |
| Apple rechaza con 2.1 (info insuficiente) | Faltó cuenta demo en App Review Info | Agregar credenciales de test con bots de ejemplo |

---

## 7. Contacto y soporte

Si tenés dudas durante el deploy podés:
- Forums de Apple Developer: https://developer.apple.com/forums/
- Documentación Flutter Apple: https://docs.flutter.dev/deployment/ios y https://docs.flutter.dev/deployment/macos
- Tu próxima sesión con Claude — abrí Claude Code en la Mac y pegás esta guía.

---

**Generado por refactor automatizado el 21/05/2026.**
