# CLAUDE.md — contexto para asistentes (botslode)

Generado a partir del **código y configuración del repositorio**. Las reglas reflejan lo implementado; no se inventan prácticas que contradigan el código (p. ej. los tiempos de espera de la cola WhatsApp **no** son aleatorios).

---

## Resumen (3 líneas)

1. **botslode** es la app Flutter de escritorio **«BotLode Factory Terminal»**: panel para crear/gestionar bots, deuda y ciclos de facturación, chat de prueba contra el backend, tienda/plantillas y flujos de cobro con tarjeta (Mercado Pago) vía Supabase.
2. El backend principal es **Supabase** (auth, tablas `bots`, `transactions`, `user_billing`, `empresas_whatsapp_limit`, opcional `wpp_control`) y **varias Edge Functions** (`botlode-brain`, `process-payment`, `mp-payment-sync`, `create-mp-preference`).
3. Hay integración **WhatsApp por Twilio** (Content SIDs en `.env`), cola automática con **patrones de espera fijos** y límites persistidos (horario, cooldown, tope horario/diario).

---

## Stack tecnológico

| Área | Detalle (fuente: `pubspec.yaml`) |
|------|----------------------------------|
| Lenguaje / SDK | Dart `>=3.2.0 <4.0.0` |
| UI | Flutter, Material 3 (`useMaterialDesign`) |
| Estado | `flutter_riverpod` + `riverpod_annotation` / `riverpod_generator` (`.g.dart`) |
| Rutas | `go_router` ^13.x |
| Backend cliente | `supabase_flutter` ^2.5 |
| HTTP | `http` ^1.2 |
| Entorno local | `flutter_dotenv`; asset **`.env`** en `pubspec.yaml` |
| Escritorio | `window_manager` ^0.3.8 |
| Gráficos / motion | `rive`, `lottie`, `flutter_animate`, `fl_chart` |
| Tipografía / iconos | `google_fonts`, `font_awesome_flutter`; fuente **Oxanium** variable en `assets/fonts/` |
| Otros | `shared_preferences`, `url_launcher`, `uuid`, `intl`, `equatable`, `connectivity_plus`, `mask_text_input_formatter`, `flutter_colorpicker` |
| Calidad | `flutter_lints`, `custom_lint`, `riverpod_lint`, `json_annotation` / `json_serializable`, `build_runner` |
| Iconos de app | `flutter_launcher_icons` (web/windows/macos; colores en `pubspec.yaml`) |

---

## Arquitectura y patrones

### Carpetas

- **`lib/core/`**: `config/` (`app_config`, `restricted_bots_config`, `cycle_exempt_bots_config`, tema `theme/`), `router/app_router.dart`, `providers/` (`supabase_provider`, `auth_provider` como re-export, WhatsApp/límites), `services/whatsapp_api_service.dart`, `ui/widgets/`, `serpapi/`.
- **`lib/features/`** (cada uno con subcarpetas según el caso):
  - **`auth`**: login, repositorio Supabase auth.
  - **`billing`**: transacciones, tarjetas, checkout MP, autopago.
  - **`bot_engine`**: chat contra Edge Function, modelo `BotResponse`, consola UI.
  - **`bots_library`**: vista de plantillas.
  - **`dashboard`**: hangar, detalle de bot, tarjetas, modales, `bots_provider`, repositorio `bots`.
  - **`settings`**: ajustes y cambio de contraseña.
  - **`store`**: tienda (`StoreProduct`, catálogo vacío `catalog => []` en el modelo actual).

### Patrones

- **Feature + capas**: en varios features hay `domain/` (contratos, modelos), `data/` (impl. Supabase/HTTP), `presentation/` (vistas, widgets, providers).
- **Riverpod**: `Provider`, `StateNotifierProvider`, y clases con `@riverpod` + código generado `*.g.dart`.
- **Navegación**: `GoRouter` con `StatefulShellRoute.indexedStack` y `MainLayout`; redirección según sesión (`/login` ↔ shell autenticado).
- **Arranque** (`main.dart`): `runZonedGuarded` → `dotenv.load('.env')` → `Supabase.initialize` → `RiveFile.initialize` → `window_manager` (1280×720, mín. 1024×600, `TitleBarStyle.hidden`) → `ProviderScope` + `MaterialApp.router`.

---

## Archivos críticos (impacto alto si se rompen)

| Ruta | Motivo |
|------|--------|
| `lib/main.dart` | Orden de inicialización; `DEPLOY_VERSION`; logs con `print` en arranque. |
| `lib/core/router/app_router.dart` | Auth guard, rutas `/dashboard`, `detail/:botId`, `/bots`, `/billing`, `/settings`, `/store`; `goNamed` y paths deben mantenerse alineados. |
| `lib/core/config/app_config.dart` | `SUPABASE_*` obligatorios; `brainFunctionUrl` = `{url}/functions/v1/botlode-brain`; `playerBaseUrl` y `fallbackBotId` fijos en código. |
| `lib/features/bot_engine/data/repositories/chat_repository_impl.dart` | POST al brain con `Authorization: Bearer` = anon key; cuerpo incluye `saveToHistory: false` (comportamiento de "terminal de prueba"). |
| `lib/features/dashboard/presentation/providers/bots_provider.dart` | Timer periódico, ciclo USD 20, suspensión por crédito, sync de cargas, autopago; depende de `useTurboTimerProvider` y `CycleExemptBotsConfig`. |
| `lib/features/dashboard/domain/models/bot.dart` | Ciclo 30 días vs turbo (30 s), deuda, clamps a un ciclo; mapeo snake_case Supabase. |
| `lib/features/billing/presentation/providers/billing_provider.dart` + `billing_repository_impl.dart` | Deuda, límite `bots × 60` USD, `process-payment`, `mp-payment-sync`, `create-mp-preference`, tokenización MP con `MP_PUBLIC_KEY`. |
| `lib/core/providers/shared_whatsapp_limit_provider.dart` | Tabla `empresas_whatsapp_limit`; límites y `messageIndex % 5` para rotar SIDs. |
| `lib/core/providers/whatsapp_auto_queue_provider.dart` | Cola Twilio feature `'empresas'`; `_cooldownPattern` fijo; no abre wa.me automático en fallos API. |
| `lib/core/services/whatsapp_api_service.dart` | Twilio REST, reintentos, `_envioDeshabilitado`, número `From` fijo en código. |
| `lib/core/providers/supabase_provider.dart` | `useTurboTimerProvider` ligado a un UUID concreto. |
| `lib/core/config/cycle_exempt_bots_config.dart` | Bots sin `cycle_charge` en la deuda agregada. |
| `lib/core/serpapi/serpapi_keys_config.dart` | Lista de claves SerpAPI **en el fuente** (rotación por orden). |

---

## Reglas estrictas (basadas en el código real)

1. **Credenciales Supabase / Twilio / MP en `.env`**: `AppConfig` exige `SUPABASE_URL` y `SUPABASE_ANON_KEY`; Twilio usa `API_KEY_SID`, `API_KEY_SECRET`, `ACCOUNT_SID`; MP usa `MP_PUBLIC_KEY` en `billing_repository_impl.dart`. El archivo **`.env` está en `.gitignore`**.
2. **No afirmar "delays aleatorios" para la cola WPP**: en `whatsapp_auto_queue_provider.dart`, `_cooldownPattern = [300, 360, 240]` (segundos, cíclico por índice). Reintentos Twilio: `Future.delayed(Duration(seconds: attempt * 2))` en `whatsapp_api_service.dart`.
3. **Horario de envíos WhatsApp (límite compartido)**: `WhatsAppLimitState.isWithinBusinessHours` → **hora local 8 ≤ hour < 19**.
4. **Cuotas en `shared_whatsapp_limit_provider.dart`**: `cooldownSeconds = 300`, `maxOpensPerHour = 20`, `maxDailyOpens = 200` (más ventana legacy `limit`/`windowMinutes` en el mismo estado).
5. **Edge Functions por nombre**: `botlode-brain` (URL derivada), `process-payment`, `mp-payment-sync`; además HTTP directo a `{supabaseUrl}/functions/v1/create-mp-preference` con Bearer de sesión + header `apikey` anon.
6. **Chat brain**: el cliente usa la **anon key** en el header; cambiar el esquema de auth del backend implica cambiar `chat_repository_impl.dart` y la función.
7. **Kill switch Twilio**: `WhatsAppApiService._envioDeshabilitado` (const en código); en `true` devuelve `WhatsAppSendResult.disabled`.
8. **SerpAPI**: claves en `serpapi_keys_config.dart` — riesgo de filtración y coste; no tratar como "config pública".
9. **Hardcodes admitidos hoy en código** (comentados o no): `playerBaseUrl`, `fallbackBotId`, sender Twilio `_fromNumber`, UUID turbo en `supabase_provider.dart`, `allowedUserIds` / `exemptBotIds` en configs. Cualquier migración a `.env` debe actualizar todos los usos.
10. **`registerCycleCharge`**: inserta en `transactions` con `type: 'cycle_charge'` y **no relanza** excepción si falla el insert (solo afecta trazabilidad).

---

## Convenciones de nombres y estructura

- Imports: `package:botslode/...`.
- Vistas: muchas definen `static const routeName` para `go_router`.
- Supabase: propiedades en mapas en **snake_case** (`system_prompt`, `tech_color`, `cycle_start_date`, etc.).
- Comentarios y strings de UI: predominantemente **español**.
- Archivos generados: `*.g.dart` al lado del provider anotado; tras cambios en `@riverpod`, ejecutar `build_runner`.
- Varios archivos empiezan con `// Archivo: ruta` (convención local).

---

## Cómo correr en local

1. Instalar Flutter compatible con el SDK del `pubspec.yaml`.
2. `cd` a la raíz de **botslode** → `flutter pub get`.
3. Copiar **`.env.example`** a **`.env`** y completar variables (el ejemplo documenta Supabase, MP, Twilio y `WPP_*_SID_*`).
4. Escritorio Windows (configuración actual): `flutter run -d windows`.
5. Si modificás anotaciones Riverpod / json_serializable: `dart run build_runner build --delete-conflicting-outputs`
6. Análisis estático: `flutter analyze` (reglas base: `package:flutter_lints/flutter.yaml` en `analysis_options.yaml`).

---

## Qué hacer / qué NO hacer al modificar

**Hacer**

- Añadir nuevos secretos vía `.env` y lectura con `dotenv` / `AppConfig` según el patrón existente.
- Coordinar cambios de payload o URL del brain con el despliegue de **`botlode-brain`**.
- Regenerar `.g.dart` cuando toques providers generados.
- Probar en conjunto **`bots_provider`** + **`billing_provider`** (ciclos, límite, autopago, exenciones).

**No hacer**

- Commitear `.env`.
- Cambiar `saveToHistory`, rutas de functions o nombres de tablas sin revisar Supabase y RLS.
- Asumir que en error Twilio/`noSid` se abre WhatsApp Web: la cola **marca fallido y continúa** (`whatsapp_auto_queue_provider.dart`).
- Ignorar `CycleExemptBotsConfig` o el UUID de turbo al tocar lógica de ciclo o billing.
- Quitar `utf8.decode(response.bodyBytes)` en el brain si se esperan respuestas con tildes/ñ.

**Nota:** `lib/core/config/restricted_bots_config.dart` existe para allowlist de bots/usuarios; en el árbol actual **no hay otros imports** de esa clase — al usarla en UI, mantener el patrón documentado en el propio archivo.

---

## Decisiones de diseño ya tomadas (no reabrir sin pedido explícito)

1. App **desktop** con barra de título del sistema **oculta** y tamaño mínimo forzado por `window_manager`.
2. Tema **oscuro único** (dorado/industrial, Oxanium) vía `AppTheme.darkTheme`.
3. Costo de ciclo por bot: **USD 20**; UI y modelo acotan progreso/deuda a **un ciclo**.
4. Límite de crédito: **60 USD × cantidad de filas en `bots`** (cálculo en `billing_provider`).
5. **Modo turbo** solo para el usuario cuyo ID coincide con `_turboTimerUserId` en `supabase_provider.dart` (ciclo 30 s, tick del timer 1 s vs 1 minuto en producción).
6. Lista fija de **bots exentos** de cobro de ciclo en `cycle_exempt_bots_config.dart`.
7. Player embebido: base **`https://botlode-player.vercel.app`**.
8. WhatsApp automático acoplado al feature **`'empresas'`** y rotación de hasta **5** Content SIDs (`getContentSid` con `% 5`).
9. `authProvider` es **alias** de `authStateProvider` para compatibilidad (`auth_provider.dart`).
10. Documentación en raíz: existen `ARCHITECTURE.md`, `REFACTORING_SUMMARY.md`, `TEST_MODE_README.md`, `DEPLOY_PAYMENT_FIX.md`; el **`README.md` sigue siendo el template por defecto de Flutter** ("Getting Started" genérico).

---

## Referencia rápida: tablas y endpoints usados en código

- **Tablas Supabase**: `bots`, `transactions`, `user_billing`, `empresas_whatsapp_limit`, opcional `wpp_control`.
- **Functions / HTTP**: `.../functions/v1/botlode-brain`, `process-payment`, `mp-payment-sync`, `create-mp-preference`; Twilio Messages API; Mercado Pago `v1/card_tokens`; tipo de cambio `dolarapi.com` con fallback **1240.0** en `getDolarBlueRate`.

---

*Actualizar este archivo cuando cambien contratos de backend, límites WPP o la lista de Edge Functions.*
