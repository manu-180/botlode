# 56 — Billing · Proration Preview Modal

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.

---

## 1. Objetivo

Rediseñar `ProrationPreviewModal` para que el desglose de costo de un cambio de plan se sienta una **lectura de instrumento de facturación**: una «hoja de cálculo HUD» precisa, con el crédito por tiempo no usado, el cargo del nuevo plan y el total a cobrar hoy presentados con tipografía mono tabular, más una transición visual «antes → después» del plan. El usuario debe entender el número final de un vistazo y confiar en él antes de confirmar.

---

## 2. Archivos

- `lib/features/billing/presentation/widgets/proration_preview_modal.dart` — reescritura completa de la capa visual; se conserva la lógica (`previewProration`, `changePlan`, `idempotencyKey`, manejo de `BillingException`).

---

## 3. Estado actual

El modal abre como `Dialog` (≥600 px). Contenedor `_ModalContainer` con `Color(0xFF09090B)` hardcodeado, radio 20, borde `borderGlass`, padding 28. Header con ícono `swap_horiz` en círculo `primary@0.1`. Cuerpo: skeleton de 3 filas grises planas (`white@0.06`), o tabla de `_ProrationLineRow` (label + rango de fechas + monto en fuente `'Courier'`), `Divider`, `_TotalRow` con monto en `'Courier'` 16 px, fila de próximo período. Disclaimer en caja `white@0.03`. Acciones: `OutlinedButton` cancelar + `FilledButton` confirmar con `CircularProgressIndicator`. Problemas: hex sueltos, fuente `'Courier'` en vez del token mono, sin ornamento HUD, total poco jerárquico, sin visual de plan antes→después, skeleton sin shimmer.

---

## 4. Visión del rediseño

El modal es un **panel de cómputo de prorrateo**. Sobre `scrim` al 66 %, un `HoloPanel` en variante modal (vidrio `glassSurfaceStrong`, `radiusXL`, `elev3`, `HudCornerBrackets` finos en `borderGold`). El header lleva un ícono de intercambio dentro de un chip biselado. Debajo, una banda «antes → después» muestra las dos cápsulas de plan (origen apagada, destino emisiva en oro) unidas por una flecha animada. El corazón es la **hoja de cálculo HUD**: filas `label`/valor sobre fondo `surfaceHud`, cada monto en `hudReadout` mono con figuras tabulares, créditos en `success` y cargos en `warning`/`danger`. Un `HudDivider` separa las líneas del **total**, que se presenta grande en `numericTicker` con `HudTicker` (conteo animado). El factor WOW: el total «cuenta» hasta su valor cuando termina de cargar, comunicando «cálculo resuelto».

---

## 5. Especificación visual

### 5.1 Capas y contenedor

1. **Scrim** — `scrim`, fade-in `durBase`/`easeStandard`, `zOverlay`.
2. **Panel** (`HoloPanel` modal) — `maxWidth 560`, `glassSurfaceStrong` con blur 18, `radiusXL`, borde `glassBorder` con `glassHighlightTop` de 1 px arriba, `elev3`, `zModal`. Padding interno `space28` (usar `space24`+`space4` si `space28` no existe; preferir `space24`). `HudCornerBrackets` brazo 18 px en `borderGold`. `HudScanlines` opcional a `opacity 0.035`.

### 5.2 Header (alto ~48 px)

- Chip biselado 40×40 con `ChamferBorder` (`chamferM`), relleno `goldGlow`, ícono `swap_horiz` 22 px en `gold`.
- Gap `space12`. Columna: título «CAMBIO DE PLAN» en `titleL` `textPrimary` (`Semantics(header:true)`); subtítulo «Revisá el detalle antes de confirmar» en `bodyS` `textSecondary`.
- Botón cerrar `AppIconButton` (X) arriba a la derecha, deshabilitado mientras `_confirming`.

### 5.3 Banda antes → después (alto 56 px, debajo del header, gap `space20`)

- `Row` centrado: cápsula plan origen (pill `radiusPill`, borde `borderDefault`, texto `label` `textTertiary`, sin glow — «apagado»); flecha `arrow_forward` 18 px `cyan` con glow `glowCyan` tenue; cápsula plan destino (pill, borde `borderGold`, relleno `goldGlow@0.5`, texto `label` `gold`, `glowGold` suave — «energizado»).
- Fondo de la banda: `surfaceHud`, `radiusM`, padding `space12`.

### 5.4 Hoja de cálculo HUD (gap `space20`)

- Contenedor `surfaceHud`, `radiusM`, borde `borderSubtle`, padding `space16`.
- Cada `_ProrationLineRow`: `Row` con padding vertical `space8`.
  - Izquierda: `Column` — `line.description` en `bodyM` `textPrimary`; rango de fechas en `mono` `textTertiary`.
  - Derecha: monto en `hudReadout` (mono, figuras tabulares). Crédito (`amountCents < 0`) → `success`, prefijo `−`. Cargo → `warning`, prefijo `+`. Nunca color solo: prefijo `−`/`+` + ícono pequeño (`remove`/`add` 12 px) acompaña al monto.
- Entre filas: `HudDivider` hairline sin etiqueta.

### 5.5 Total (gap `space12`, separado por `HudDivider` con nodo brillante)

- `Row`: izquierda `label` «TOTAL A COBRAR HOY» en `label` `textSecondary`.
- Derecha: `HudTicker` en estilo `numericTicker` (JetBrains Mono, 28 px, 700, tabular). Color `gold` si el neto es cargo; `success` si es crédito a favor. `glowGold`/`successGlow` suave detrás del número.
- Debajo, fila de próximo período: ícono `calendar_today` 13 px `textTertiary` + «Próximo cobro completo: dd/MM/yyyy» en `bodyS` `textTertiary`.

### 5.6 Disclaimer y errores

- Disclaimer: banda inline `surface`, `radiusS`, borde `borderSubtle`, ícono `info` 15 px `textTertiary` + texto `bodyS` `textTertiary`.
- Error de preview: `ErrorFeedbackCard` (prompt 16) — borde `danger`, ícono, mensaje, botón «Reintentar» que llama `_loadPreview`.
- Error de mutación: banda inline `danger` (borde `danger@0.3`, fondo `dangerGlow@0.3`), ícono `warning` + mensaje, `Semantics(liveRegion:true)`.

### 5.7 Acciones (gap `space24`)

- `Row` de dos `Expanded`: izquierda `AppButton` variante `ghost` «CANCELAR»; derecha `AppButton` variante `primary` «CONFIRMAR CAMBIO», con `gradGold`, `textOnGold`, `glowGold` en hover. En `_confirming` muestra spinner mono.

---

## 6. Estados e interacciones (matriz §9)

| Estado | Comportamiento |
|---|---|
| `default` | Panel cargado, hoja de cálculo y total visibles, confirmar habilitado. |
| `loading` (preview) | Skeleton: 3 `SkeletonBase` (prompt 14) de fila con shimmer; banda antes→después como skeleton de cápsulas; total como bloque skeleton. Confirmar y cancelar: cancelar habilitado, confirmar deshabilitado. |
| `hover` (botones/cerrar) | Borde `borderStrong`/`borderGold`, +elevación, glow suave, `durFast`. |
| `pressed` | Escala 0.97, `durInstant`. |
| `focused` | Anillo 2 px `cyan` en cancelar/cerrar, `gold` en confirmar. |
| `loading` (confirm) | Botón confirmar con spinner, ambos botones y cerrar deshabilitados; sin doble submit. |
| `disabled` (confirm) | Opacidad 0.4, sin glow, mientras no haya preview válido. |
| `error` (preview) | `ErrorFeedbackCard` reemplaza la hoja; confirmar deshabilitado. |
| `error` (mutación) | Banda `danger` con `liveRegion`; confirmar vuelve a habilitarse para reintento. |

---

## 7. Animaciones

- **Entrada del modal:** scrim fade `durBase`; panel fade + scale 0.96→1.0 con `springSoft`, `easeEntrance`.
- **Salida:** ~65 % de la entrada, `easeExit`, `durFast`.
- **Skeleton:** shimmer `gradGoldSheen` cada ~3000 ms.
- **Total ticker:** al pasar de `loading` a `default`, el `HudTicker` cuenta de 0 al valor en `durTicker` con `easeTicker`.
- **Banda antes→después:** la cápsula destino enciende su glow con un pulso único `durBase` al revelarse; la flecha hace un micro-deslizamiento de 4 px (`durFast`, `easeStandard`).
- **Filas de la hoja:** escalonado de 36 ms por fila al revelar (fade + translateY 12 px).
- **Reduced motion:** sin shimmer, sin pulso de glow ni deslizamiento; el `HudTicker` muestra el valor final directo; entrada/salida = crossfade 120 ms.

---

## 8. Accesibilidad

- Título con `Semantics(header:true)`.
- La hoja de cálculo conserva el `Semantics(label:)` descriptivo que arma la frase «se acreditarán X, se cobrarán Y, total Z».
- Botón cerrar: `Semantics`/`tooltip` «Cerrar».
- Errores con `Semantics(liveRegion:true)`.
- Contraste: `success`/`warning`/`gold` sobre `surfaceHud` ≥ 4.5:1 para los montos (verificar; usar variante de texto más clara si no llega).
- Estado de cada monto = color + prefijo `±` + ícono.
- Foco visible siempre; orden: cerrar → cancelar → confirmar.
- Barrier no descartable mientras `_confirming`; cerrar y cancelar siempre disponibles fuera de ese estado.

---

## 9. Checklist de aceptación

- [ ] Contenedor migrado a `HoloPanel` modal; cero hex sueltos (`0xFF09090B` eliminado).
- [ ] Todos los espaciados son tokens de `app_dimens.dart`; cero magic numbers.
- [ ] Montos en `hudReadout` mono con `FontFeature.tabularFigures()`; fuente `'Courier'` eliminada.
- [ ] Total con `HudTicker` en estilo `numericTicker`; anima el conteo al cargar.
- [ ] Banda «antes → después» presente con cápsula destino emisiva.
- [ ] `HudCornerBrackets` y `HudDivider` aplicados según jerarquía.
- [ ] Skeleton con shimmer; estados loading/listo/error de preview y error de mutación implementados.
- [ ] Reduced-motion respetado en ticker, shimmer y entrada.
- [ ] Contrastes verificados ≥ 4.5:1.
- [ ] `flutter analyze` sin warnings nuevos; se ve bien en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01 (color), 02 (tipografía + mono), 03 (dimensiones), 04 (motion), 05 (iconografía), 06 (HUD: brackets, scanlines, divider, ticker, chamfer), 07 (glow/glass), 08 (fondo).
- **Componentes núcleo:** 09 (`AppButton`, `AppIconButton`), 12 (`HoloPanel`), 14 (`SkeletonBase`), 16 (`ErrorFeedbackCard`).
- **Billing:** 47 (shell de billing), 49 (plan picker — provee identidad visual de las cápsulas de plan).
