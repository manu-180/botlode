# 48 — Billing · Digital Card

> Depende de **00_README_VISION_Y_SISTEMA_DE_DISENO.md**. Si algo contradice al 00, gana el 00.

---

## 1. Objetivo

Rediseñar `DigitalCard` para que sea la **pieza WOW absoluta del área de billing**: una tarjeta de crédito física premium, metálica, con chip EMV, holograma HUD y un efecto de luz/tilt sutil al hover. Cuatro estados (Vacía, Válida, Vence pronto, Vencida) tratados con la misma calidad de acabado.

---

## 2. Archivos

- **Modificar:** `lib/features/billing/presentation/widgets/digital_card.dart`
- **Consumir (no modificar):** `lib/core/config/theme/` (01–04), `lib/core/ui/hud/` (06: `HudCornerBrackets`), `lib/features/billing/presentation/widgets/empty_state.dart` (estado vacío), `assets/billing/brands/*.svg` (logos de marca).
- Preservar (refactorizar internamente, no borrar) los `CustomPainter`: `_HexagonPainter`, `_ChipPainter`.

---

## 3. Estado actual

`DigitalCard` recibe un `PaymentMethod?` y un reloj inyectable `now`. Calcula `_isExpired` / `_isExpiringSoon` (≤30 días). Renderiza con `AspectRatio` 1.586:

- **Vacía** (`method == null`): `Container` `#080808`, radio 24, borde rojo translúcido, ícono `credit_card_off_rounded` rojo, texto «Sin tarjeta agregada», `TextButton` outlined dorado «Agregar tarjeta».
- **Con datos**: `Container` `#050505`, radio 24, sombra dorada translúcida, borde de color/grosor según estado. `Stack` con hexágono decorativo (`_HexagonPainter`), gradiente diagonal blanco→transparente→negro, contenido (header chip EMV + brand SVG, número enmascarado `•••• •••• ••••` + last4 en `AppColors.primary` con `Shadow`, footer «VENCE» + MM/YY), y badge de estado.

Es vistoso pero usa hex sueltos, no respeta tokens, el borde rojo en vacío se siente «de error» (debería ser elegante, no triste), no hay ornamento HUD coherente y no hay interacción de hover/tilt.

---

## 4. Visión del rediseño

La tarjeta se siente como una **pieza de hardware de la terminal** — una credencial física del Hangar OS. Fondo metálico oscuro con gradiente sutil de profundidad (no negro plano). Chip EMV mejorado con contactos definidos. Logo de marca SVG nítido. Número enmascarado con last4 en oro y glow mono. Holograma/ornamento HUD: un hexágono tenue + `HudCornerBrackets` finísimos. Al pasar el mouse, la tarjeta hace un **tilt 3D microscópico** y una **banda de luz (sheen)** barre la superficie — el efecto «caro» de inclinar una tarjeta a la luz. El estado Vacío es un placeholder elegante (no de error). Vence pronto y Vencida añaden borde + `StatusTag` sin romper la elegancia; Vencida además desatura la tarjeta.

---

## 5. Especificación visual

### 5.1 Caja base (estados Válida / Vence pronto / Vencida)

- `AspectRatio` 1.586 (sin cambios — proporción ISO de tarjeta).
- `Container` con `borderRadius` = `radiusXL` (28).
- **Fondo metálico:** `gradPanel` oscurecido — un `LinearGradient` 150° de `surfaceRaised` → `surface` → `voidBlack`, de modo que la esquina superior izquierda es más clara (luz) y la inferior derecha más profunda. Encima, el gradiente diagonal decorativo: `glassHighlightTop` (highlight superior izq) → transparente → `voidBlack@0.6` (sombra inferior der).
- **Sombra:** `elev2` (0 8 24 negro 0.5) + `glowGold` muy suave (blur reducido a ~18, spread 1) — la tarjeta «flota» y emite un halo dorado tenue.
- **Borde:** Válida → `borderGold` 1 px; Vence pronto → `warning` 2 px; Vencida → `danger` 2 px.
- `ClipRRect` con el mismo `radiusXL` para recortar las capas internas.

### 5.2 Capas del `Stack` (de atrás hacia adelante)

1. **Fondo metálico** (gradiente, §5.1) — `Positioned.fill`, `ExcludeSemantics`.
2. **Grid texture** (`HudGridTexture`, prompt 06) a `opacity 0.04` — `Positioned.fill`, decorativo.
3. **Holograma hexagonal:** `CustomPaint` con `_HexagonPainter` reescrito para usar `gold @ 0.06`, posicionado fuera del borde superior derecho (`right: -50, top: -24`), tamaño 300×300. Decorativo, `ExcludeSemantics`.
4. **Banda de luz (sheen):** una franja diagonal de `gradGoldSheen` (transparente → blanco 0.18 → transparente), ancho ~90 px, que en reposo está fuera del lienzo y barre la superficie en hover (ver §7). Decorativa.
5. **Contenido principal:** `Padding` `space24`, `Column` con `spaceBetween`: header / número / footer (§5.4–§5.6).
6. **`HudCornerBrackets`** (prompt 06) sobre las 4 esquinas internas, brazos de 14 px, grosor 1.5 px, color `borderGold` (Válida) / `warning` (Vence pronto) / `danger` (Vencida). Finísimos, decorativos.
7. **`StatusTag`** (prompt 11) en la esquina inferior izquierda cuando Vence pronto / Vencida (§5.7).
8. **`HudIdTag`** opcional en esquina superior izquierda interna: `mono` pequeño tipo `CARD · DEFAULT` si es la tarjeta predeterminada.

### 5.3 Tilt 3D / sheen (efecto WOW)

- Envolver toda la tarjeta en un `MouseRegion` + `AnimatedBuilder` que aplique un `Transform` con `Matrix4`:
  - En reposo: identidad.
  - En hover: rotación 3D según la posición del cursor dentro de la tarjeta — `rotateX` y `rotateY` máximo **±4°** (microscópico, premium, nunca exagerado). Añadir `..setEntry(3, 2, 0.0012)` para perspectiva. La tarjeta también sube `translateZ`/escala 1.015.
  - La banda de luz (capa 4) se desplaza en sentido contrario al tilt, reforzando la sensación de superficie reflectante.
- Transición de entrada/salida del tilt con `durFast` (160 ms) y curva `easeStandard`. El tilt vuelve a identidad al salir el mouse.
- Es un efecto de `Transform`/opacidad puro: nunca toca el layout.

### 5.4 Header

- Fila `spaceBetween`.
- **Chip EMV:** `Container` 46×36, radio `radiusXS` (6), gradiente metálico dorado (3 paradas: dorado claro → medio → brillo, 135°), sombra interna sutil. `CustomPaint` con `_ChipPainter` reescrito: contactos del chip dibujados con líneas a `voidBlack @ 0.25`, grosor 1 px (rejilla 3×2 de contactos).
- **Logo de marca:** `_BrandIcon` con `SvgPicture.asset` desde `assets/billing/brands/`, 52×34, mapeo de alias preservado, fallback `generic.svg`. En Vencida, el SVG va dentro de un `ColorFiltered` de saturación reducida (§5.8).

### 5.5 Número enmascarado

- Centrado, `FittedBox` para que nunca desborde.
- Prefijo `•••• •••• •••• ` en `mono` (JetBrains Mono 12) color `textTertiary`, tracking +2.
- `last4` en `numericTicker` (JetBrains Mono, tabular) tamaño ~20, peso 700, color `gold`, con `Shadow` de `goldGlow` blur 15 — el «glow mono» del last4.
- En Vencida, `last4` se desatura a `textSecondary` (sin glow).

### 5.6 Footer

- Fila alineada a la derecha.
- Micro-label «VENCE» en `labelSmall` (11/600 UPPERCASE) color `textTertiary` — corregir el contraste del actual `white24` (que falla AA): usar `textTertiary` que cumple ≥ 3:1 para glifos.
- Valor MM/YY debajo en `hudReadout` (JetBrains Mono 13, peso 500) color `textPrimary`, tracking +0.5.

### 5.7 Estado Vence pronto / Vencida — `StatusTag`

- `StatusTag` (prompt 11) en esquina inferior izquierda interna, `space16` desde los bordes.
- Vence pronto: variante `warning`, ícono `Icons.schedule`, texto «VENCE PRONTO».
- Vencida: variante `danger`, ícono `Icons.error_outline`, texto «VENCIDA».
- El badge lleva ícono + texto + color (nunca solo color).

### 5.8 Estado Vencida — desaturación

- Toda la tarjeta (capa de contenido + brand SVG + número) se envuelve en un `ColorFiltered` con una `ColorFilter.matrix` de saturación ~0.35 — la tarjeta se ve «apagada», claramente fuera de servicio, pero sigue legible.
- El borde `danger` y el `StatusTag` quedan a saturación plena (fuera del filtro) para que la alerta destaque.
- Sin glow dorado, sin sheen, sin tilt en Vencida (la tarjeta «no emite»).

### 5.9 Estado Vacío (placeholder elegante)

- Mismo `AspectRatio` 1.586 y `radiusXL`.
- Fondo: `gradPanel` apagado (`surface` → `bgElevated01`), **sin** el rojo actual. Borde `borderSubtle` 1 px, dashed conceptualmente (línea continua hairline está OK; lo importante es que NO sea rojo de error).
- Centro: un `EmptyState` mini (prompt 15) — ícono `Icons.add_card` (no `credit_card_off`, que se ve negativo) en un círculo `surfaceHud` con borde `borderGold`, texto `titleM` «Sin método de pago», subtítulo `bodyS` `textSecondary` «Agregá una tarjeta para habilitar el cobro automático».
- Botón «AGREGAR TARJETA»: `AppButton` variante secundaria/ghost dorada (prompt 09), invoca `onAddCard`.
- `HudGridTexture` muy tenue de fondo para mantener la profundidad. Ornamento mínimo: brackets de esquina opcionales en `borderSubtle`.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `empty` | Placeholder elegante (§5.9), ícono `add_card`, CTA «AGREGAR TARJETA». NO rojo. |
| `default` (Válida) | Tarjeta metálica con glow dorado tenue, brackets `borderGold`. |
| `hover` (Válida) | Tilt 3D ±4°, escala 1.015, banda de luz barre la superficie, glow sube un paso. `durFast`. |
| `pressed` | Si la tarjeta es clickeable (abre `ManageCardsModal`): escala 0.97, `durInstant`. Si no, sin estado pressed. |
| `focused` | Anillo de foco 2 px `cyan` alrededor de la tarjeta cuando es focuseable. |
| `Vence pronto` | Borde `warning` 2 px, `StatusTag` «VENCE PRONTO», resto igual que Válida. |
| `Vencida` | Borde `danger` 2 px, `StatusTag` «VENCIDA», tarjeta desaturada, sin glow/sheen/tilt. |
| `loading` | Si el método aún no llegó: skeleton de tarjeta (rectángulo `radiusXL` con shimmer, prompt 14). |
| `disabled` | No aplica (la tarjeta es display; el botón de la vacía sí puede estar disabled si `onAddCard == null`). |
| `error` | El error de carga de billing lo maneja el shell (prompt 47), no la tarjeta. |

---

## 7. Animaciones

- **Entrada:** la tarjeta entra con fade + `scale` desde 0.96 a 1.0, `durBase` (240 ms), curva `easeEntrance`.
- **Tilt 3D:** seguimiento del cursor en hover, máximo ±4°, transición a/desde identidad con `durFast` + `easeStandard`.
- **Banda de luz (sheen):** en hover, la franja `gradGoldSheen` barre la tarjeta una vez (de esquina a esquina) en `durDeliberate` (~420 ms). Adicionalmente, en estado Válida y en reposo, un sheen muy lento opcional cada 3000–3400 ms (patrón shimmer del 00 §7.3) — solo en la tarjeta predeterminada, no si hay varias.
- **last4 glow:** estable (no pulsa); es un `Shadow`, no una animación.
- **Cambio de estado** (Válida → Vence pronto → Vencida): el borde y el `StatusTag` aparecen con crossfade `durBase`; la desaturación de Vencida se anima en `durBase`.
- **Reduced motion:** con `AppMotion.reduced`, sin tilt 3D (la tarjeta queda plana), sin sheen barrido, sin shimmer en reposo. La entrada se reduce a un fade de 120 ms. El cambio de estado es crossfade puro.

---

## 8. Accesibilidad

- Mantener el `Semantics` de nivel superior: «Tarjeta terminada en {last4}, {brand}, vence {MM/YY}{, vencida|, vence pronto}». Las capas internas siguen con `ExcludeSemantics` para no duplicar.
- Contraste: `last4` `gold` sobre fondo metálico oscuro ≥ 4.5:1; MM/YY `textPrimary` ≥ 12:1; prefijo `mono` `textTertiary` — al ser ≥ 3:1 es decorativo aceptable, pero el dato real (MM/YY, last4) cumple holgado. Corregir el micro-label «VENCE» a `textTertiary` (cumple ≥ 3:1).
- El `StatusTag` lleva ícono + texto, nunca solo color.
- Estado Vacío: el `EmptyState` expone título y CTA con `Semantics` de botón; el CTA con `Semantics(label: 'Agregar tarjeta de pago')`.
- Si la tarjeta es clickeable, área de hit completa, foco visible, tooltip.
- El tilt 3D no debe interferir con lectores de pantalla ni con el foco.

---

## 9. Checklist de aceptación

- [ ] `AspectRatio` 1.586 y `radiusXL` en los 4 estados.
- [ ] Fondo metálico con `gradPanel` oscurecido — nunca negro plano.
- [ ] Chip EMV con `_ChipPainter` reescrito (contactos definidos) y gradiente dorado.
- [ ] Logo de marca SVG desde `assets/billing/brands/` con fallback genérico.
- [ ] `last4` en `numericTicker` `gold` con glow; prefijo en `mono` `textTertiary`.
- [ ] MM/YY en `hudReadout`; micro-label «VENCE» corregido a `textTertiary` (no falla AA).
- [ ] `HudCornerBrackets` finos (1.5 px) en las 4 esquinas, color según estado.
- [ ] Holograma hexagonal con `_HexagonPainter` preservado, tinte `gold @ 0.06`.
- [ ] Efecto tilt 3D en hover (±4° máx, perspectiva, escala 1.015) + banda de luz que barre.
- [ ] Estado Vacío elegante: ícono `add_card`, NO rojo, `EmptyState` mini + CTA `AppButton`.
- [ ] Vence pronto: borde `warning` + `StatusTag`. Vencida: borde `danger` + `StatusTag` + desaturación.
- [ ] Sin glow/sheen/tilt en estado Vencida.
- [ ] Cero hex sueltos, cero magic numbers: todo por token.
- [ ] Reduced motion: sin tilt, sin sheen, fade de 120 ms.
- [ ] `Semantics` de nivel superior preservado; capas internas `ExcludeSemantics`.
- [ ] Se ve correcta en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (color: `gradPanel`, `goldGlow`, `borderGold`), 02 (tipografía: `numericTicker`, `hudReadout`, `mono`, `labelSmall`), 03 (dimensiones: `radiusXL`, `radiusXS`, `elev2`, `glowGold`), 04 (motion), 05 (iconografía), 06 (`HudCornerBrackets`, `HudGridTexture`, `HudIdTag`).
- **Componentes núcleo:** 09 (`AppButton`), 11 (`StatusTag`), 14 (skeleton), 15 (`EmptyState`).
- **Shell:** la digital card vive en la tab «Métodos de Pago» del shell (prompt 47).
