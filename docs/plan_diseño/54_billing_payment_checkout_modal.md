# 54 — Billing · Payment Checkout Modal

> Depende de **00_README_VISION_Y_SISTEMA_DE_DISENO.md**. Si algo contradice al 00, gana el 00.

---

## 1. Objetivo

Rediseñar `PaymentCheckoutModal` como el **terminal de transacción segura** del Hangar OS: un modal `HoloPanel` premium con el plan y el monto destacados (USD en ticker dorado + conversión a ARS en lectura mono), el subformulario de pasarela embebido, un botón «PAGAR» con atajo Enter, y estados success/failure de alta calidad.

---

## 2. Archivos

- **Modificar:** `lib/features/billing/presentation/widgets/payment_checkout_modal.dart`
- **Consumir (no modificar):** `lib/core/config/theme/` (01–04), `lib/core/ui/hud/` (06), `lib/core/ui/panels/holo_panel.dart` (12), `lib/core/ui/buttons/app_button.dart` (09), `lib/features/billing/presentation/widgets/stripe_elements_card_form.dart` y `mercadopago_brick_form.dart` (prompt 52).

---

## 3. Estado actual

`PaymentCheckoutModal` (ConsumerStatefulWidget) recibe `amount` (USD), `exchangeRate`, `planName`, `frequency`, `idempotencyKey`. Estado: `_pendingToken`, `_isMutating`, `_hasFailed`, `_hasSucceeded`, `_failureTitle/_failureMessage`. Subformulario llama `_onTokenReceived`/`_onSubformError`. `_onConfirmPay` llama `addPaymentMethod(setAsDefault: true)`; en éxito espera 2500 ms y cierra.

Presentación: `BackdropFilter` blur 12 + `Dialog`, un `AnimatedContainer` 480 px con borde-gradiente que cambia de color según estado, y dentro un `Container` `#09090B` radio 23. `_buildNormalState`: header (ícono `hub_rounded`, label «CHECKOUT» Courier, línea «plan · $X USD · frecuencia», píldora «≈ $ ARS»), subformulario por gateway, footer Cancelar/Pagar. Tiene `Shortcuts`/`Actions` con `Enter` → pagar. Success: círculo con check elástico + shimmer, título, mensaje, «cerrando…». Failure: círculo `gpp_bad`, título, panel de detalle, Cerrar/Reintentar.

Funcional y con atajo de teclado, pero contenedor con hex sueltos, monto sin la jerarquía «héroe», botones Material, sin ornamento HUD.

---

## 4. Visión del rediseño

El modal se siente como **autorizar una transacción en una terminal industrial**: serio, preciso, premium. `HoloPanel` biselado con `HudCornerBrackets`, sobre scrim desenfocado. El header anuncia el plan y el intervalo. El **bloque de monto** es el héroe: el total en USD en un `numericTicker` grande dorado, y debajo la conversión a ARS en una lectura `hudReadout` mono con la tasa explícita («≈ $ 1.240.000 ARS · TC 1240»). Un resumen breve de lo que se cobra. El subformulario de pasarela (prompt 52) embebido. El botón «PAGAR» es un `AppButton` primario con `glowGold`, atajo Enter, y estado loading. Success muestra un check en anillo `successGlow` con sensación de «recibo emitido»; failure, un panel `danger` con detalle y reintento. El borde del modal tiñe sutilmente según el estado (oro → verde → rojo).

---

## 5. Especificación visual

### 5.1 Presentación y contenedor

- Scrim `scrim` + `BackdropFilter` blur sigma 12. z-index `zModal`.
- Contenedor `HoloPanel` (prompt 12) con `ChamferBorder` (`chamferM`), relleno `glassSurfaceStrong`, radio `radiusXL` (28), sombra `elev3`, `HudCornerBrackets`.
- Ancho fijo 480 px (desktop). Padding interno `space32`.
- **Borde tintado por estado:** un borde de 1.5 px cuyo color cruza con `durSlow` — normal `borderGold`; success `success`; failure `danger`. La sombra/glow acompaña (`glowGold` → `successGlow` → `dangerGlow`).

### 5.2 Header (estado normal)

- Ícono `Icons.hub_rounded` 32 px `gold` centrado (decorativo, `ExcludeSemantics`).
- Label `labelSmall` UPPERCASE `textTertiary` «// CHECKOUT» (reemplaza el «CHECKOUT» Courier actual).
- Nombre del plan + intervalo: `titleM` `textPrimary`, ej. «Plan Starter · Mensual».
- `HudDivider` debajo.

### 5.3 Bloque de monto (héroe)

- Centrado, dentro de un mini-`HoloPanel` `surfaceHud` con padding `space20`:
  - Label `labelSmall` `textTertiary` «TOTAL A PAGAR».
  - **USD:** prefijo `$` (`titleM` `gold`) + monto en `numericTicker` (JetBrains Mono tabular, ~28, 700) `gold` + sufijo « USD» en `bodyS` `textSecondary`.
  - **ARS:** debajo, lectura `hudReadout` mono `textSecondary` «≈ $ {monto formateado} ARS» y, en `mono` `textTertiary` más chico, la tasa usada «TC {exchangeRate}». El formato de miles con puntos se preserva (`_formatARS`).
- El monto USD «cuenta» con ticker al abrir el modal.

### 5.4 Resumen de cobro

- Una o dos filas `bodyS` `textSecondary` con ícono `Icons.check` 14 px `success`: qué incluye el cobro (ej. «Acceso al Plan {nombre} por 1 {periodo}», «Renovación automática»). Es contexto breve, no una factura completa.

### 5.5 Subformulario de pasarela

- Se embebe el componente del prompt 52 (`StripeElementsCardForm` / `MercadoPagoBrickForm`) según `subscription.gateway`.
- Si `gateway == null`: panel de error «pasarela no configurada» reconstruido como `HoloPanel` interno borde `danger` (mismo contenido que el actual `_buildUnknownGatewayError`, con tokens). En ese caso el footer solo muestra «CANCELAR».

### 5.6 Footer

- Fila de 2 `AppButton` de igual ancho:
  - «CANCELAR» → variante secundaria/ghost con tinte `danger` sutil en el borde.
  - «PAGAR» → `AppButton` primario dorado con `glowGold`. Deshabilitado hasta `_pendingToken != null`. En `_isMutating`, spinner y deshabilitado.
- El atajo **Enter** dispara «PAGAR» (mantener `Shortcuts`/`Actions`); solo activo en estado normal y cuando el botón está habilitado.

### 5.7 Estado success

- Anillo HUD grande (~88 px) borde `success` 2 px, fondo `success @ 0.1`, glow `successGlow`, ícono `Icons.check_rounded` `success`.
- Título «PAGO CONFIRMADO» en `titleL` UPPERCASE `success`.
- Mensaje `bodyM` `textSecondary` (confirmación).
- Sensación de «recibo emitido»: opcionalmente una mini-línea `mono` `textTertiary` con un identificador de transacción ficticio/real y la línea de cierre «CERRANDO…» con anillo de progreso que se vacía en 2500 ms.

### 5.8 Estado failure

- Anillo HUD borde `danger`, glow `dangerGlow`, ícono `Icons.gpp_bad_rounded` `danger`.
- Título del error (`_failureTitle`) en `titleL` UPPERCASE `danger`.
- Detalle en `HoloPanel` interno borde `danger @ 0.4`, fondo `danger @ 0.06`, texto `bodyM` `textPrimary`.
- Footer: `AppButton` «CERRAR» (secundario) + «REINTENTAR» (primario) — Reintentar vuelve al estado normal.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` (normal) | Header + monto + resumen + subformulario + footer. PAGAR deshabilitado sin token. |
| `hover` (botones) | Borde + glow suben `durFast`. |
| `pressed` | `AppButton` escala 0.97 `durInstant`. |
| `focused` | Foco 2 px `cyan` en cada control. Orden: subformulario → cancelar → pagar. |
| `loading` (`_isMutating`) | PAGAR con spinner, deshabilitado; modal no interactivo; no se puede cerrar; atajo Enter inactivo. |
| `disabled` | PAGAR deshabilitado sin token (label legible). |
| `selected` | Pasarela determinada por la suscripción; subformulario correspondiente montado. |
| `error` (failure) | Estado §5.8; borde del modal tinte `danger`; mensaje con `liveRegion`. |
| `success` | Estado §5.7; borde tinte `success`; cierre automático tras 2500 ms. |
| `empty` | El subformulario gestiona campos sin completar. |
| `gateway == null` | Panel de error de pasarela; solo «CANCELAR». |

---

## 7. Animaciones

- **Entrada del modal:** scrim fade-in `durBase`; panel scale 0.94 → 1.0 + fade con `springSoft`.
- **Salida:** scale + fade `durFast`, `easeExit`.
- **Monto USD:** `HudTicker` que cuenta de 0 al total en `durTicker` (900 ms) `easeTicker` al abrir.
- **Borde tintado:** el cruce de color del borde y el glow al cambiar de estado se anima con `durSlow` y `easeStandard`.
- **Cambio normal → success/failure:** crossfade del contenido `durBase`.
- **Success:** check entra con `scale` `Curves.elasticOut` `durDeliberate`; anillo de progreso de cierre se vacía en 2500 ms.
- **Failure:** ícono con micro-shake horizontal ≤ 4 px `durFast`, una sola vez.
- **Reduced motion:** sin scale en entrada (crossfade 120 ms), monto salta sin contar, sin elástico en success, sin shake en failure, sin shimmer.

---

## 8. Accesibilidad

- El modal atrapa el foco; al cerrar vuelve al disparador. Escape cierra (en estado normal). El scrim es descartable en estado normal; bloqueado durante `_isMutating`.
- Header con `Semantics(header: true)`.
- El bloque de monto con `Semantics(label: 'Total a pagar: $X USD, aproximadamente $Y ARS, plan {nombre} {intervalo}')`.
- Botón «PAGAR» con `Semantics` de botón, label que incluye el monto; `liveRegion` cuando pasa a loading («Procesando pago»).
- El atajo Enter no reemplaza al botón visible (el botón siempre está y es focuseable).
- Mensaje de error en failure con `Semantics(liveRegion: true)`.
- Contraste: monto `gold` ≥ 4.5:1; ARS `hudReadout` `textSecondary` ≥ 4.5:1; tasa `textTertiary` ≥ 3:1; títulos de estado ≥ 4.5:1 — verificar.
- Foco visible 2 px `cyan`; orden de foco = orden visual.
- Targets ≥ 44 px en botones.

---

## 9. Checklist de aceptación

- [ ] El modal se presenta sobre scrim + `BackdropFilter` blur.
- [ ] Contenedor `HoloPanel` biselado, `radiusXL`, `HudCornerBrackets`, borde tintado por estado.
- [ ] Header con label `// CHECKOUT` + plan + intervalo + `HudDivider`.
- [ ] Bloque de monto: USD en `numericTicker` `gold` (con ticker al abrir) + ARS en `hudReadout` mono + tasa explícita.
- [ ] Resumen de cobro breve con íconos de check.
- [ ] Subformulario de pasarela embebido (prompt 52); error de gateway nulo reconstruido.
- [ ] Footer con `AppButton` Cancelar/Pagar; Pagar con `glowGold`, deshabilitado sin token.
- [ ] Atajo Enter dispara «PAGAR» (solo en estado normal, botón habilitado).
- [ ] Estado success: anillo `successGlow` + check + sensación de recibo + cierre 2500 ms.
- [ ] Estado failure: anillo `danger` + título + panel de detalle + Cerrar/Reintentar.
- [ ] Cero hex sueltos, cero magic numbers: todo por token.
- [ ] Foco atrapado; Escape/scrim cierran en normal, bloqueados en loading.
- [ ] Reduced motion respetado (sin scale/ticker/elástico/shake).
- [ ] Se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (color: `glassSurfaceStrong`, `scrim`, `borderGold`, `glowGold`, `successGlow`, `dangerGlow`), 02 (tipografía: `titleL`, `titleM`, `numericTicker`, `hudReadout`, `mono`, `labelSmall`), 03 (dimensiones: `radiusXL`, `chamferM`, `elev3`, `zModal`), 04 (motion: `springSoft`, `durTicker`, `easeTicker`, `durDeliberate`), 05 (iconografía), 06 (`HudCornerBrackets`, `HudDivider`, `HudTicker`).
- **Componentes núcleo:** 09 (`AppButton`), 12 (`HoloPanel`).
- **Embebe:** 52 (formularios de pasarela).
- **Relacionado:** 49 (plan picker, que puede disparar el checkout), 56 (proration preview).
