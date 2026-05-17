# 58 — Billing · Auto-Pay Settings Card

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.

---

## 1. Objetivo

Rediseñar `AutoPaySettingsCard` para que el control de cobro automático se sienta un **interruptor de hardware de instrumento**: un `HoloPanel` con un toggle HUD premium custom (riel biselado, perilla con glow) en vez del `Switch` default de Material, más la explicación de la política de reintentos y mensajes condicionales inline. El estado del autopago debe leerse de un vistazo: ON = unidad energizada en oro; OFF = apagada.

---

## 2. Archivos

- `lib/features/billing/presentation/widgets/auto_pay_settings_card.dart` — reescritura visual; lógica conservada (`reactivateSubscription`/`cancelSubscription` en `_onToggle`, apertura de `ManageCardsModal`, `billingV2Provider`).

---

## 3. Estado actual

`Container` con `Color(0xFF0F0F13)` hardcodeado, `radius 16`, borde que cambia entre `primary@0.5` (autopago on + tarjeta) y `white@0.1`. Padding 20. Header: columna con título «Cobro automático» (`bold` 16) + descripción (`white@0.55` 12) y, a la derecha, un `Switch` Material default envuelto en `SizedBox` 48×48 con `Tooltip` y `Semantics`. Debajo: si hay tarjeta default, una fila clickeable «Se cobrará a •••• 1234» con ícono `credit_card`; si no, una fila de advertencia con ícono `warning_amber` en `warning`. Problemas: hex sueltos, `Switch` genérico sin identidad HUD, sin explicación de la política de reintentos, sin lenguaje HUD, opacidades de blanco crudas.

---

## 4. Visión del rediseño

El card es un **módulo de configuración de cobro**. `HoloPanel` con header propio. El protagonista es el **toggle HUD custom**: un riel biselado (`ChamferBorder`) con una perilla circular que se desliza; ON emite `glowGold` y la perilla brilla; OFF queda inerte en `surfaceHud`. Debajo del header, una sección explicativa de la **política de reintentos** («Si un cobro falla, reintentamos a las 24 h, 72 h y 7 días») en `bodyS`, presentada como nota técnica con `HudDivider`. Al pie, un banner inline condicional: confirmación tranquila de la tarjeta cuando todo está OK, o advertencia `warning` cuando falta método de pago. El borde del panel «responde» al estado: emisivo cuando el autopago está activo y configurado.

---

## 5. Especificación visual

### 5.1 Contenedor

`HoloPanel` estándar: relleno `gradPanel`, `radiusL`, borde que cambia con el estado:

- Autopago ON + tarjeta → `borderGold`, `glowGold` muy tenue.
- Autopago OFF o sin tarjeta → `borderDefault`, sin glow.

Padding `space20`. `margin top space20`. Opcional `HudCornerBrackets` finos solo si el panel está activo.

### 5.2 Header

- `Row`: a la izquierda `Column` con título «COBRO AUTOMÁTICO» en `titleM` `textPrimary` + subtítulo «Se renueva al final de cada período de facturación» en `bodyS` `textSecondary`.
- A la derecha, el **toggle HUD** (§5.4).
- Gap `space16`.

### 5.3 Política de reintentos

- `HudDivider` con etiqueta `// POLÍTICA DE REINTENTOS` debajo del header (gap `space16`).
- Texto en `bodyS` `textSecondary`: explica que ante un cobro fallido se reintenta automáticamente (24 h / 72 h / 7 días) y que tras agotar los reintentos la suscripción pasa a `past_due`.
- Opcional: tres mini-chips `labelSmall` «24H · 72H · 7D» en `surfaceHud` `radiusPill`, para hacerlo escaneable.

### 5.4 Toggle HUD custom (no `Switch` de Material)

- **Riel:** 52×28, `ChamferBorder` (`chamferM` reducido) o `radiusPill` biselado en los extremos. OFF: relleno `surfaceHud`, borde `borderDefault`. ON: relleno `goldDeep`→`gold` (`gradGold` tenue), borde `borderGold`, `glowGold`.
- **Perilla:** círculo 22 px. OFF: relleno `textTertiary`, a la izquierda, sin glow. ON: relleno `goldBright`, a la derecha, con halo `glowGold`.
- **Marcas del riel:** dos micro-líneas mono `I` / `O` (1 px, `textTertiary`) en los extremos, estilo interruptor de instrumento.
- Estado de carga: durante `_isMutating`, la perilla muestra un micro-spinner o un pulso; el toggle queda no interactivo.
- Estado deshabilitado: sin tarjeta default → toggle a `opacity 0.4`, no interactivo.

### 5.5 Banner inline condicional (pie del card, gap `space16`)

- **Con tarjeta default:** banda `surface`, `radiusS`, ícono `credit_card` 16 px `textSecondary` + `Text.rich` «Se cobrará a » `bodyS` `textSecondary` + «VISA •••• 4242» en `mono` `gold` (clickeable, subraya en hover, abre `ManageCardsModal`).
- **Sin tarjeta default:** banda inline `warning` — fondo `warningGlow@0.3`, borde `warning@0.35`, ícono `warning_amber` 16 px `warning` + texto «Agregá un método de pago para activar el cobro automático» en `bodyS` `warning`. `Semantics(liveRegion:true)`.
- **Autopago OFF (con o sin tarjeta):** banda inline `info` — ícono `info` `info` + texto «Tu suscripción se cancelará al final del período actual» en `bodyS` `info`.

---

## 6. Estados e interacciones (matriz §9)

| Estado | Qué cambia |
|---|---|
| `default` (ON + tarjeta) | Borde `borderGold`, `glowGold` tenue, toggle a la derecha emisivo, banner de tarjeta. |
| `default` (OFF + tarjeta) | Borde `borderDefault`, toggle a la izquierda apagado, banner `info` de cancelación. |
| `default` (sin tarjeta) | Borde `borderDefault`, toggle `disabled`, banner `warning`. |
| `hover` (toggle) | Borde del riel a `borderStrong`/`borderGold`, glow sube, cursor pointer, `durFast`. |
| `hover` (fila tarjeta) | Texto de tarjeta intensifica subrayado, `durFast`. |
| `pressed` (toggle) | Perilla escala 0.94 al presionar, `durInstant`. |
| `focused` | Anillo 2 px `gold` en el toggle; `cyan` en la fila de tarjeta. |
| `loading` (`_isMutating`) | Toggle con micro-spinner/pulso, no interactivo; sin doble submit. |
| `disabled` | Toggle `opacity 0.4`, sin glow, no interactivo (sin tarjeta default). |
| `error` | El error de mutación llega vía `SnackBar` HUD (prompt 17); el toggle vuelve a su estado real. |

> El card no se renderiza si `billingAsync` está en loading/error o no hay `subscription` (se conserva ese comportamiento con `SizedBox.shrink()`).

---

## 7. Animaciones

- **Entrada del card:** fade + translateY 12 px, `durBase`, `easeEntrance` (parte del escalonado de la tab de billing).
- **Toggle:** la perilla se desliza con `springSoft` (`durFast`); el relleno del riel hace crossfade `surfaceHud`↔`gradGold` en `durFast`; el `glowGold` aparece/desaparece con `durFast`.
- **Cambio de borde del panel:** crossfade `borderDefault`↔`borderGold` en `durBase`.
- **Banner condicional:** al cambiar de variante, crossfade `durFast`.
- **Reduced motion:** sin slide de entrada; el toggle conmuta sin deslizamiento (crossfade de posición 120 ms); sin pulso de loading (spinner estático).

---

## 8. Accesibilidad

- Toggle: `Semantics(label: 'Cobro automático {activado/desactivado}', toggled:, enabled:, button:true)`; `tooltip` explicativo se conserva.
- Estado del autopago comunicado por posición + color + glow + el banner de texto inferior (nunca solo color).
- Fila de tarjeta: `Semantics(button:true, label:, hint:'Toca para administrar tarjetas')`.
- Banner `warning`/`info` con `Semantics(liveRegion:true)`.
- Contraste: `gold` de la perilla y `warning`/`info` del banner sobre sus fondos ≥ 4.5:1 (texto) / ≥ 3:1 (glifos).
- Área de hit del toggle ≥ 32×32 px (envolver en `SizedBox` cómodo).
- Foco visible; orden: toggle → fila de tarjeta.

---

## 9. Checklist de aceptación

- [ ] Contenedor migrado a `HoloPanel`; `0xFF0F0F13` y opacidades de blanco crudas eliminados.
- [ ] Toggle HUD custom implementado (riel biselado + perilla con glow); `Switch` de Material eliminado.
- [ ] Sección de política de reintentos presente con `HudDivider` y texto en `bodyS`.
- [ ] Banner inline condicional con 3 variantes: tarjeta OK / sin tarjeta (`warning`) / autopago off (`info`).
- [ ] Borde del panel responde al estado (emisivo `borderGold` cuando ON + tarjeta).
- [ ] Todos los espaciados y radios son tokens; cero magic numbers.
- [ ] Matriz de estados completa (default×3, hover, pressed, focused, loading, disabled).
- [ ] Reduced-motion respetado en toggle, entrada y banner.
- [ ] Contrastes verificados.
- [ ] `flutter analyze` sin warnings nuevos; se ve bien en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01–08 (color, tipografía + mono, dimensiones, motion, iconos, HUD: divider/brackets/chamfer, glow/glass, fondo).
- **Componentes núcleo:** 11 (badges/chips para los chips de reintento; toggle base del sistema), 12 (`HoloPanel`), 16 (patrón de banner inline de error/warning), 17 (`SnackBar` HUD para errores de mutación).
- **Billing:** 47 (shell), 53 (`ManageCardsModal`, destino de la fila de tarjeta).
