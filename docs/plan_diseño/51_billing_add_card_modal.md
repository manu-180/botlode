# 51 — Billing · Add Card Modal

> Depende de **00_README_VISION_Y_SISTEMA_DE_DISENO.md**. Si algo contradice al 00, gana el 00.

---

## 1. Objetivo

Rediseñar `AddCardModal` como un **panel de alta segura de método de pago** del Hangar OS: modal `HoloPanel` biselado con scrim y brackets, header con ícono en anillo HUD y nota de seguridad, selector de pasarela segmentado, subformulario embebido (prompt 52), checkbox «predeterminada» rediseñado y los tres estados normal/success/failure tratados con la calidad de la app.

---

## 2. Archivos

- **Modificar:** `lib/features/billing/presentation/widgets/add_card_modal.dart`
- **Consumir (no modificar):** `lib/core/config/theme/` (01–04), `lib/core/ui/hud/` (06), `lib/core/ui/panels/holo_panel.dart` (12), `lib/core/ui/buttons/app_button.dart` (09), `lib/core/ui/inputs/` (10: checkbox), `lib/features/billing/presentation/widgets/stripe_elements_card_form.dart` y `mercadopago_brick_form.dart` (prompt 52).

---

## 3. Estado actual

`AddCardModal` (ConsumerStatefulWidget) se presenta como `showModalBottomSheet`. Estado interno: `_pendingToken`, `_setAsDefault`, `_isSaving`, `_hasSucceeded`, `_hasFailed`, `_failureTitle/_failureMessage`. El subformulario llama `_onTokenReceived`/`_onSubformError`. `_onSave` llama `addPaymentMethod` y, en éxito, espera 2000 ms y cierra.

El contenedor es un `Container` `#09090B`, radio 24, borde `borderGlass`, sombra negra. `_buildContent` ramifica a normal/success/failure. Normal: header (ícono `credit_card_outlined` + título + nota de seguridad con candado), subformulario por gateway (`StripeElementsCardForm` / `MercadoPagoBrickForm` / error de gateway no configurado), checkbox «Usar como predeterminada», footer Cancelar/Guardar. Success: círculo con check `elasticOut` + shimmer, título, mensaje, «cerrando…». Failure: círculo con `gpp_bad`, título, panel de detalle, Cerrar/Reintentar.

Funcional y completo en lógica, pero contenedor plano sin ornamento HUD, sin animación de entrada del modal, sin confirmación al descartar con datos, botones Material genéricos.

---

## 4. Visión del rediseño

El modal aparece sobre un **scrim** que oscurece y desenfoca el fondo. El contenedor es un `HoloPanel` con forma biselada (`chamfer`), `HudCornerBrackets` y radio `radiusXL` — se siente como una compuerta de la terminal abriéndose. El header lleva el ícono de tarjeta dentro de un **anillo HUD** y una nota de seguridad con candado. El selector de pasarela es un toggle segmentado HUD. El checkbox «predeterminada» es un control HUD con check dorado. Footer con `AppButton`s. El estado success muestra un check animado dentro de un anillo `successGlow` con cuenta regresiva de cierre; el failure, un panel `danger` con detalle y Reintentar. Entra con scale+fade de resorte. Si el usuario intenta cerrar con un token cargado o el subformulario tocado, se confirma antes de descartar.

---

## 5. Especificación visual

### 5.1 Presentación y scrim

- El modal se presenta centrado en desktop (`showDialog` o un overlay propio) — no un bottom sheet, que es patrón móvil. En anchos < 600 puede seguir como bottom sheet.
- Detrás, scrim `scrim` (rgba void 0.66) + `BackdropFilter` blur sigma 10–12.
- z-index `zModal` (110); scrim en `zOverlay` (100).

### 5.2 Contenedor — `HoloPanel`

- `HoloPanel` (prompt 12) con forma `ChamferBorder` (`chamferM` 12), relleno `glassSurfaceStrong` (vidrio de modal, más opaco para legibilidad), borde `glassBorder` + highlight superior `glassHighlightTop`.
- Radio `radiusXL` (28) en las esquinas no biseladas.
- Sombra `elev3` (modal). `HudCornerBrackets` en `borderGold`, brazos 18 px.
- Ancho máximo 480 px en desktop; padding interno `space28`.

### 5.3 Header

- Fila: a la izquierda, el ícono `Icons.credit_card_outlined` dentro de un **anillo HUD** — un círculo de borde `borderGold` 1.5 px sobre fondo `surfaceHud`, diámetro ~44 px, con un glow `glowGold` muy suave.
- A la derecha del anillo, columna:
  - Título «AÑADIR MÉTODO DE PAGO» en `titleM` (17/600 UPPERCASE) `textPrimary`, tracking +0.5.
  - Nota de seguridad: fila con ícono `Icons.lock_outline` 12 px `success` + texto `bodyS` `textSecondary` «Tus datos se procesan de forma segura. Nunca almacenamos el número completo.».
- Botón de cierre `Icons.close` (icon button del prompt 09) en la esquina superior derecha, con tooltip «Cerrar».
- `HudDivider` debajo del header.

### 5.4 Selector de pasarela

- Toggle segmentado HUD (mismo lenguaje que el toggle del prompt 49): pista `surfaceHud`, indicador deslizante dorado, 2 segmentos «STRIPE» / «MERCADO PAGO», `label` UPPERCASE.
- Cada segmento con un mini-ícono/logo de la pasarela.
- El segmento activo determina qué subformulario se monta. Si la pasarela viene fijada por `subscription.gateway`, el toggle puede mostrarse deshabilitado en el valor correcto (informativo) en vez de oculto.

### 5.5 Subformulario embebido

- Se inserta el componente del prompt 52 (`StripeElementsCardForm` o `MercadoPagoBrickForm`) según la pasarela.
- Si `gateway == null`: panel de error «pasarela no configurada» — reconstruir como `HoloPanel` interno con borde `danger`, ícono `Icons.warning_amber` en `danger`, título y mensaje. Mismo contenido que el actual `_buildUnknownGatewayError`, con tokens.

### 5.6 Checkbox «Usar como predeterminada»

- Control HUD del prompt 10: una caja 20×20, radio `radiusXS`, borde `borderStrong` cuando vacía, relleno `gradGold` con check `textOnGold` cuando marcada, glow suave al marcar.
- Texto al lado `bodyM` `textPrimary` «Usar como tarjeta predeterminada».
- Toda la fila es clickeable (`InkWell`), `Semantics(checked: ...)`.

### 5.7 Footer

- Fila de 2 `AppButton` (prompt 09) de igual ancho:
  - «CANCELAR» → variante secundaria/ghost. Si hay token o subformulario tocado, dispara la confirmación de descarte (§6).
  - «GUARDAR» → variante primaria dorada. Deshabilitado hasta que `_pendingToken != null`. En `_isSaving`, muestra spinner y se deshabilita (sin doble submit).
- Si `gateway == null`, solo «CANCELAR» a ancho completo.

### 5.8 Estado success

- Anillo HUD grande (~84 px) con borde `success` 2 px, fondo `success @ 0.1`, glow `successGlow`, conteniendo el ícono `Icons.check_rounded` `success`.
- Título «MÉTODO AGREGADO» en `titleM` UPPERCASE `success`.
- Mensaje `bodyM` `textSecondary`.
- Línea de cierre: `mono` `success @ 0.6` con cuenta regresiva «CERRANDO EN 2…1…» o un anillo de progreso fino alrededor del check que se vacía en 2000 ms. El modal cierra solo al terminar.

### 5.9 Estado failure

- Anillo HUD con borde `danger`, glow `dangerGlow`, ícono `Icons.gpp_bad_rounded` `danger`.
- Título del error (`_failureTitle`) en `titleM` UPPERCASE `danger`.
- Detalle en un `HoloPanel` interno con borde `danger @ 0.4`, fondo `danger @ 0.06`, texto `bodyM` `textPrimary`.
- Footer: `AppButton` «CERRAR» (secundario) + «REINTENTAR» (primario) — Reintentar vuelve al estado normal.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` (normal) | Header + selector + subformulario + checkbox + footer. GUARDAR deshabilitado sin token. |
| `hover` (botones, segmentos) | Borde + glow suben `durFast`. |
| `pressed` | `AppButton` escala 0.97, `durInstant`. |
| `focused` | Foco 2 px `cyan` en cada control. Orden: cierre → selector → subformulario → checkbox → cancelar → guardar. |
| `selected` | Segmento de pasarela activo con indicador deslizado; checkbox marcado con relleno dorado. |
| `loading` (`_isSaving`) | GUARDAR con spinner, deshabilitado; resto del modal no interactivo; no se puede cerrar mientras guarda. |
| `disabled` | GUARDAR deshabilitado sin token; sus tokens de color disabled (opacidad del relleno, label legible). |
| `error` (failure) | Estado §5.9 con `Semantics(liveRegion: true)` en el mensaje de error. |
| `empty` | El subformulario gestiona su propio estado vacío (campos sin completar). |
| Confirmar descarte | Si el usuario pulsa CANCELAR, cierra con el botón X, pulsa Escape o toca el scrim **y** hay token cargado o subformulario tocado: abrir un diálogo de confirmación «¿Descartar los datos ingresados?» con «SEGUIR EDITANDO» (foco por defecto) / «DESCARTAR» (`danger`). Si no hay datos, cierra directo. |

---

## 7. Animaciones

- **Entrada del modal:** scrim hace fade-in `durBase`; el panel entra con `scale` 0.94 → 1.0 + fade, usando `springSoft`.
- **Salida:** scale 1.0 → 0.96 + fade, `durFast` (~65 % de la entrada), `easeExit`.
- **Indicador del selector de pasarela:** desliza `durBase`/`easeStandard`.
- **Cambio de subformulario:** crossfade `durBase` al cambiar de pasarela.
- **Checkbox:** el check aparece con `scale` elástico corto `durFast`; glow al marcar.
- **Success:** el check entra con `scale` `Curves.elasticOut` `durDeliberate`; el anillo de progreso de cierre se vacía linealmente en 2000 ms.
- **Failure:** el ícono entra con un micro-shake horizontal de baja amplitud (≤ 4 px) `durFast`, una sola vez; nada de glitch agresivo.
- **Reduced motion:** entrada/salida del modal como crossfade 120 ms sin scale; success sin elástico (fade simple); failure sin shake; sin shimmer.

---

## 8. Accesibilidad

- El modal es una barrera de foco: el foco queda atrapado dentro hasta cerrar; al cerrar, vuelve al elemento que lo abrió.
- Header con `Semantics(header: true)`.
- Escape cierra el modal (con confirmación si hay datos). El scrim es descartable (con la misma confirmación).
- Nota de seguridad y mensajes de error con contraste ≥ 4.5:1.
- El mensaje de error en failure con `Semantics(liveRegion: true)` para que el lector lo anuncie.
- Checkbox: `Semantics(checked: _setAsDefault, label: 'Usar como tarjeta predeterminada')`.
- GUARDAR deshabilitado: el label mantiene contraste legible; `Semantics(enabled: false)`.
- Foco visible 2 px `cyan` en todos los controles; orden de foco = orden visual.
- Targets ≥ 44 px (el modal puede usarse en versión táctil) en botones y checkbox.
- El subformulario gestiona el foco al primer campo inválido en error (ver prompt 52).

---

## 9. Checklist de aceptación

- [ ] El modal se presenta sobre scrim + `BackdropFilter` blur.
- [ ] Contenedor es `HoloPanel` biselado (`chamferM`) con `HudCornerBrackets` y `radiusXL`.
- [ ] Header con ícono en anillo HUD + título UPPERCASE + nota de seguridad con candado.
- [ ] Selector de pasarela como toggle segmentado HUD con indicador deslizante.
- [ ] Panel de «pasarela no configurada» reconstruido con tokens y borde `danger`.
- [ ] Checkbox «predeterminada» rediseñado (caja HUD, check dorado, fila clickeable).
- [ ] Footer con `AppButton` Cancelar/Guardar; Guardar deshabilitado sin token.
- [ ] Estado success: anillo HUD `successGlow` + check + cuenta regresiva de cierre 2000 ms.
- [ ] Estado failure: anillo `danger` + título + panel de detalle + Cerrar/Reintentar.
- [ ] Confirmación antes de descartar si hay token cargado o subformulario tocado.
- [ ] Entrada scale+fade con `springSoft`; salida más rápida.
- [ ] Foco atrapado en el modal; Escape y scrim cierran (con confirmación).
- [ ] Cero hex sueltos, cero magic numbers: todo por token.
- [ ] Reduced motion respetado (crossfade, sin scale/elástico/shake).
- [ ] Se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (color: `glassSurfaceStrong`, `scrim`, `borderGold`, `successGlow`, `dangerGlow`), 02 (tipografía: `titleM`, `bodyM`, `mono`), 03 (dimensiones: `radiusXL`, `chamferM`, `elev3`, glows, `zModal`), 04 (motion: `springSoft`, `durDeliberate`), 05 (iconografía), 06 (`HudCornerBrackets`, `HudDivider`, `ChamferBorder`).
- **Componentes núcleo:** 09 (`AppButton`, icon button), 10 (checkbox HUD), 12 (`HoloPanel`), 13 (confirmación / diálogo).
- **Shell:** 47 (el modal se abre desde la tab «Métodos de Pago»). Embebe: 52 (formularios de pasarela).
