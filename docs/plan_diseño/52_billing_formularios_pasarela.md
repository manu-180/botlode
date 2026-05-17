# 52 — Billing · Formularios de pasarela (Stripe / MercadoPago)

> Depende de **00_README_VISION_Y_SISTEMA_DE_DISENO.md**. Si algo contradice al 00, gana el 00.

---

## 1. Objetivo

Rediseñar los dos subformularios de tokenización embebidos en los modales de billing: `StripeElementsCardForm` y `MercadoPagoBrickForm`. Incluye el fallback de desktop de Stripe (hoy un mensaje pobre), el `CardField` estilizado, el contenedor del Brick de MercadoPago con su loading skeleton, y todos sus estados.

---

## 2. Archivos

- **Modificar:** `lib/features/billing/presentation/widgets/stripe_elements_card_form.dart`
- **Modificar:** `lib/features/billing/presentation/widgets/mercadopago_brick_form.dart`
- **Consumir (no modificar):** `lib/core/config/theme/` (01–04), `lib/core/ui/hud/` (06), `lib/core/ui/panels/holo_panel.dart` (12), `lib/core/ui/buttons/app_button.dart` (09), `lib/core/ui/feedback/error_card.dart` (16), `lib/core/ui/skeletons/` (14).

---

## 3. Estado actual

### Stripe (`StripeElementsCardForm`)
Detecta desktop nativo. En desktop muestra `_DesktopFallback`: `Container` `surfaceContainerHighest`, ícono `phone_android_outlined`, título «Stripe requiere la app móvil» y un párrafo. En móvil/web muestra `_CardFormBody`: `Container` con header «DATOS DE TARJETA», label visible, `CardField` de flutter_stripe con `InputDecoration`, y un `FilledButton.icon` «VALIDAR TARJETA» / «PROCESANDO…» con candado/spinner. Mapea errores Stripe a español vía `_mapStripeError`.

### MercadoPago (`MercadoPagoBrickForm`)
Detecta soporte de WebView (solo Android/iOS). Con soporte: `WebViewController` que carga `assets/billing/mp_brick.html`, canal JS `MP_BRICK`, `Stack` con `WebViewWidget` + `CircularProgressIndicator` mientras `_isLoading`. Sin soporte: `_BrowserFallback` — `Container`, ícono `open_in_browser`, título, párrafo, `FilledButton` «Abrir en navegador», nota de seguridad.

Ambos funcionan y mapean errores, pero los contenedores son Material plano (`surfaceContainerHighest`), el fallback de desktop de Stripe se siente como un callejón sin salida, el loading del Brick es un spinner pelado y no hay ornamento HUD.

---

## 4. Visión del rediseño

Ambos formularios viven dentro de un `HoloPanel` interno coherente con el modal anfitrión (prompt 51/54). El **fallback de desktop de Stripe** deja de ser un mensaje de rechazo: se convierte en un panel informativo elegante — ícono en anillo HUD, instrucción clara y, si hay deep-link disponible, un QR/instrucción para continuar en el móvil; tono «esto se hace mejor en el móvil», no «no podés». El `CardField` se estiliza oscuro con header «DATOS DE TARJETA», borde HUD y foco `cyan`; el botón «VALIDAR TARJETA» es un `AppButton` con candado y spinner. El **Brick de MercadoPago** se enmarca en un `HoloPanel` con un loading skeleton que simula la forma del formulario mientras carga, un display del monto arriba, y manejo elegante del error de carga.

---

## 5. Especificación visual

### 5.1 Contenedor común

Ambos formularios (y los fallbacks) se renderizan dentro de un `HoloPanel` interno (prompt 12): relleno `surfaceHud`, borde `borderDefault`, radio `radiusM` (14), padding `space24`. Es un panel «embebido» — sin brackets de esquina (esos son del modal anfitrión), pero con un `HudDivider` bajo el header.

### 5.2 Stripe — `_CardFormBody` (móvil / web)

- Header: ícono `Icons.credit_card_outlined` 18 px `gold` + label «DATOS DE TARJETA» en `label` (13/600 UPPERCASE) `textSecondary`, tracking +1.4. `HudDivider` debajo.
- Label visible del campo: `bodyS` `textSecondary` «Número, vencimiento y CVV».
- **`CardField`** estilizado:
  - `InputDecoration` con `filled: true`, `fillColor` `surface`, borde `borderDefault` 1 px radio `radiusM`, `focusedBorder` `cyan` 1.5 px.
  - `style` del texto: familia Oxanium, color `textPrimary`, tamaño 15.
  - Mantener el wrapper `Semantics` actual (los campos internos son gestionados por Stripe).
- Botón «VALIDAR TARJETA»: `AppButton` primario (prompt 09), ícono `Icons.lock_outline`, ancho completo, alto 48. Deshabilitado hasta `isFormComplete`. En loading muestra spinner y texto «PROCESANDO…».

### 5.3 Stripe — `_DesktopFallback` (rediseño completo)

Panel informativo, no de error:

- Ícono `Icons.phone_iphone` (o `qr_code_2`) dentro de un **anillo HUD** — círculo borde `borderGold` 1.5 px, fondo `surfaceHud`, ~56 px, glow `glowGold` suave.
- Título `titleM` `textPrimary` «Continuá en la app móvil».
- Texto `bodyM` `textSecondary`, interlineado 1.5: explica que Stripe Elements se completa desde la app móvil de BotLode por seguridad de la tokenización.
- **QR / instrucción:** si existe un deep-link/URL para abrir el flujo en el móvil, mostrar un recuadro con un código QR generado (`CustomPaint` o paquete de QR) sobre fondo claro recortado en `radiusS`, con un `HudIdTag` `mono` debajo. Si no hay URL, mostrar una instrucción numerada en `bodyS` («1. Abrí BotLode en tu teléfono · 2. Entrá a Facturación · 3. Agregá la tarjeta»).
- Nota de seguridad: fila ícono `Icons.lock_outline` 14 px `success` + `bodyS` `textTertiary`.
- Es un estado terminal informativo: no hay botón de acción que falle; sí puede haber un `AppButton` ghost «ENTENDIDO» que cierra/retrocede en el modal anfitrión si aplica.

### 5.4 MercadoPago — Brick (con WebView)

- `HoloPanel` interno. Arriba, un **display de monto**: label `labelSmall` `textTertiary` «TOTAL» + monto en `hudReadout` mono `gold` (el `amountCents` formateado). Si `amountCents == 0` (flujo de vault), ocultar el display.
- El `WebViewWidget` ocupa el cuerpo, con esquinas recortadas a `radiusS`. Altura mínima razonable para que el Brick respire (definir un alto fijo o `AspectRatio` para evitar saltos).
- **Loading skeleton:** mientras `_isLoading` (antes del mensaje `ready` del Brick), en lugar del `CircularProgressIndicator` pelado, mostrar un skeleton (prompt 14) que simula la forma del Brick — 3-4 barras de campo rectangulares + un botón, todo con shimmer. El skeleton se superpone al WebView (`Stack`) y se desvanece con crossfade cuando llega `ready`.
- **Error de carga:** si `onWebResourceError` o un mensaje `error` del Brick: reemplazar el cuerpo por un `ErrorFeedbackCard` (prompt 16) con el mensaje mapeado y un `AppButton` «REINTENTAR» que recarga `loadFlutterAsset`.

### 5.5 MercadoPago — `_BrowserFallback` (desktop / no soportado)

- `HoloPanel` interno. Ícono `Icons.open_in_browser` en anillo HUD `borderGold`.
- Título `titleM` `textPrimary` «Pago con Mercado Pago».
- Texto `bodyM` `textSecondary` explicando que el pago se completa en el navegador.
- `AppButton` primario «ABRIR EN NAVEGADOR», ícono `Icons.open_in_browser`. Deshabilitado si no hay `fallbackCheckoutUrl`; en `_launching` muestra spinner. Si no hay URL, además mostrar un `bodyS` `textTertiary` explicando que falta configurar la URL.
- Nota de seguridad: fila ícono candado `success` + `bodyS` `textTertiary` «Los datos de tu tarjeta se procesan directamente en Mercado Pago».

### 5.6 Mensajes de error

Ambos formularios reportan errores hacia el modal anfitrión vía `onError` (que el modal muestra en su estado failure). Los mapeos a español ya existentes (`_mapStripeError`, los `code: message` del Brick) se preservan. Si un formulario muestra error inline (ej. campo de Stripe incompleto), usar texto `bodyS` `danger` con ícono `Icons.error_outline`, cerca del campo.

---

## 6. Estados e interacciones

| Estado | Stripe | MercadoPago |
|---|---|---|
| `default` | `CardField` vacío, botón deshabilitado | Brick cargando → skeleton |
| `hover` | Botón «VALIDAR» con borde/glow `durFast` | Botón fallback igual |
| `pressed` | `AppButton` escala 0.97 `durInstant` | igual |
| `focused` | `CardField` con borde `cyan` 1.5 px; botón con anillo `cyan` | Botón fallback con anillo `cyan` |
| `selected/active` | n/a | Brick listo (`ready`) → skeleton se desvanece |
| `loading` | Botón con spinner «PROCESANDO…», deshabilitado | Skeleton con shimmer sobre el WebView |
| `disabled` | Botón deshabilitado hasta `isFormComplete` | Botón fallback deshabilitado sin URL |
| `error` | Error mapeado vía `onError`; error inline `danger` si campo incompleto | `ErrorFeedbackCard` + Reintentar en error de carga |
| `empty` | `CardField` sin completar = estado base | Brick sin token aún = estado base |
| `desktop fallback` | Panel informativo §5.3 (no es error) | `_BrowserFallback` §5.5 |

---

## 7. Animaciones

- **Entrada de cada formulario:** fade + `translateY` 8 px, `durFast`, `easeEntrance` (es un sub-bloque dentro de un modal que ya animó su entrada).
- **Botón «VALIDAR TARJETA» / «ABRIR EN NAVEGADOR»:** hover `durFast`, press escala 0.97 `durInstant`, spinner de loading estándar.
- **Skeleton del Brick:** shimmer estándar del prompt 14; al llegar `ready`, crossfade `durBase` del skeleton al WebView.
- **Cambio de subformulario** (al cambiar de pasarela en el modal): lo gestiona el modal anfitrión (crossfade).
- **Error inline:** aparece con fade + micro-`translateY` 4 px `durFast`.
- **Reduced motion:** sin shimmer en el skeleton del Brick (skeleton estático), crossfades a 120 ms, sin `translateY`.

---

## 8. Accesibilidad

- Stripe `CardField`: mantener el `Semantics` envolvente con `label` y `hint` (los campos internos los gestiona Stripe en WebView/nativo). Mantener el label visible del campo para usuarios videntes.
- Botones «VALIDAR TARJETA» / «ABRIR EN NAVEGADOR»: `Semantics` de botón, label descriptivo, `liveRegion` cuando pasan a loading.
- Fallback de desktop de Stripe: `Semantics(header: true)` en el título; el QR lleva un `Semantics(label: ...)` con texto alternativo de la instrucción.
- Brick de MercadoPago: el `WebViewWidget` mantiene el `Semantics(label/hint)` actual; la a11y interna del Brick la gestiona MP.
- Contraste: títulos `textPrimary` ≥ 12:1; cuerpo `textSecondary` ≥ 4.5:1; notas `textTertiary` ≥ 3:1; monto `gold` ≥ 4.5:1 — verificar.
- Errores: mensaje con ícono + texto + color; `liveRegion` para que el lector lo anuncie; foco al campo/zona del error.
- Foco visible 2 px `cyan`; orden de foco = orden visual.
- Targets ≥ 44 px en botones (uso táctil posible en móvil).

---

## 9. Checklist de aceptación

- [ ] Ambos formularios viven dentro de un `HoloPanel` interno coherente con `surfaceHud` + `HudDivider`.
- [ ] `CardField` de Stripe estilizado oscuro: relleno `surface`, borde `borderDefault`, foco `cyan`.
- [ ] Botón «VALIDAR TARJETA» es `AppButton` con candado y spinner de loading.
- [ ] Fallback de desktop de Stripe rediseñado: anillo HUD + título + QR/instrucción + nota de seguridad (no un mensaje de rechazo).
- [ ] Brick de MercadoPago enmarcado en `HoloPanel` con display de monto en `hudReadout` `gold`.
- [ ] Loading del Brick es un skeleton que simula la forma del formulario, no un spinner pelado.
- [ ] Error de carga del Brick muestra `ErrorFeedbackCard` + `AppButton` «REINTENTAR».
- [ ] `_BrowserFallback` reconstruido con anillo HUD, `AppButton` y nota de seguridad.
- [ ] Mapeos de error a español preservados; `onError` sigue notificando al modal anfitrión.
- [ ] Cero hex sueltos, cero magic numbers: todo por token.
- [ ] `Semantics` de `CardField` y WebView preservados; errores con `liveRegion`.
- [ ] Reduced motion respetado (sin shimmer, crossfades 120 ms).
- [ ] Se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (color: `surfaceHud`, `borderGold`, `glowGold`, semánticos), 02 (tipografía: `titleM`, `label`, `hudReadout`, `mono`), 03 (dimensiones: `radiusM`, `radiusS`), 04 (motion), 05 (iconografía), 06 (`HudDivider`, `HudIdTag`, anillo HUD).
- **Componentes núcleo:** 09 (`AppButton`), 12 (`HoloPanel`), 14 (skeletons), 16 (`ErrorFeedbackCard`).
- **Anfitriones:** 51 (Add Card Modal) y 54 (Payment Checkout Modal) embeben estos formularios.
