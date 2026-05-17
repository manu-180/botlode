# 42 — Blueprint Card · Ítem de plano de ingeniería

> Prompt ejecutable de la **Fase F**. Antes de tocar nada, leé `00_README_VISION_Y_SISTEMA_DE_DISENO.md` completo. Todos los valores se referencian por **nombre de token**.

---

## 1. Objetivo

Rediseñar `BlueprintCard`, la card que representa un prototipo de bot en la «Biblioteca de Planos». Debe sentirse como un **plano de ingeniería premium** desplegado sobre una mesa de luz: panel de vidrio con retícula técnica de fondo, marco HUD para el ícono, etiqueta de ID mono, lista de «especificaciones técnicas» en lectura mono, y un botón «ENSAMBLAR». El acento de cada card lo define su `techColor` (cyan por defecto en esta sección técnica).

---

## 2. Archivos

- **Modificar:** `lib/features/bots_library/presentation/widgets/blueprint_card.dart`
- **Consumir (no crear):** `HoloPanel` (prompt 12), `HudGridTexture`, `HudIdTag`, `HudCornerBrackets` (prompt 06), `AppButton` (prompt 09), tokens de glow (prompt 07).
- **Tokens:** `app_colors.dart`, `app_dimens.dart`, `app_motion.dart`.

El `_GridPainter` interno actual se **elimina**: se reemplaza por `HudGridTexture` de las primitivas HUD.

---

## 3. Estado actual

- `StatefulWidget` con `_isHovered`. `MouseRegion` + `GestureDetector`.
- `AnimatedContainer` `300 ms` / `Curves.easeOut`. Radio `16` hardcodeado.
- Fondo: `surface@0.4` reposo / `surface@0.8` hover. Borde `borderGlass` reposo / `techColor@0.8` hover, width `1`.
- Sombra hover: `techColor@0.15`, blur 20, spread 2.
- `_GridPainter` propio: retícula técnica, `step 20`, `color techColor@0.03` reposo / `@0.1` hover.
- `Padding 24`. Header: `Container` con `FaIcon` (icono FontAwesome del blueprint, 24 px, fondo `techColor@0.1`, radio 12, borde `techColor@0.3`) + badge de ID (`Text` con `fontFamily: 'Courier'`, 10 px, borde `textSecondary@0.3`, radio 4).
- Body: categoría (`techColor`, 10 px, letterSpacing 2), nombre (`titleLarge` Oxanium, 20 px), descripción (`bodyMedium`, 13 px, `maxLines 4`).
- Marca de agua diagonal «PROTOTIPO» rotada 45°, `techColor@0.15`.
- **No hay** lista de especificaciones técnicas, **no hay** botón «ENSAMBLAR» visible (la card entera es clickeable), **no hay** brackets de esquina, **no hay** escalonado de entrada.

---

## 4. Visión del rediseño

La card es un **plano técnico individual**. De afuera hacia adentro:

- Un `HoloPanel` con radio `radiusL`, relleno de vidrio sutil sobre fondo `surface`, y una capa de `HudGridTexture` (la retícula de plano) tintada con el `techColor` de la card a opacidad muy baja.
- El ornamento HUD aparece **en hover**: brackets de esquina (`HudCornerBrackets`) en `techColor`, glow `glowCyan` (o el glow del `techColor`), escala 1.02.
- El header lleva el ícono del blueprint dentro de un **marco HUD** (no un container redondeado genérico) y la `HudIdTag` con el ID del plano en mono.
- El cuerpo se ordena en jerarquía clara: categoría (micro-label de acento) → nombre del plano (`titleM`) → descripción (`bodyS`) → **lista de especificaciones técnicas** en `hudReadout` mono (filas label/valor).
- El footer es un botón `AppButton` «ENSAMBLAR» explícito (variante secondary tintada con `techColor`), además de que la card completa sigue siendo clickeable.

El factor WOW: la card se siente como un documento de ingeniería con instrumentación, no como una tarjeta de catálogo. La retícula, la `HudIdTag`, las specs mono y los brackets en hover construyen esa lectura.

---

## 5. Especificación visual

### 5.1 Contenedor

- Usar `HoloPanel` (prompt 12) como raíz, con:
  - `radius: radiusL` (= 20).
  - `padding: EdgeInsets.all(space20)`.
  - Relleno: vidrio sutil (`gradPanel`: `surfaceRaised` → `surface`).
  - Borde reposo: `borderDefault`, width 1.
  - Borde hover: `techColor@0.55`, width 1.5.
  - Elevación reposo: `elev1`. Hover: `elev2` + glow del `techColor` (`glowStatus(techColor)` o `glowCyan` si el techColor es cyan). **Una** sombra de elevación + **un** glow, nunca dos glows.
- Capa de fondo dentro del panel: `HudGridTexture` tintado con `techColor`, `opacity 0.04` reposo / `0.08` hover (animado con `durFast`). Reemplaza al `_GridPainter` local, que se borra.

### 5.2 Header (fila superior)

`Row` con `mainAxisAlignment: spaceBetween`:

- **Izquierda — marco HUD del ícono.** Un contenedor cuadrado de 48×48, esquinas con leve chaflán (`chamferM` aplicado vía `ChamferBorder` del prompt 06 — variante ligera), relleno `techColor@0.10`, borde `techColor@0.32`. Dentro, `FaIcon` con el `widget.blueprint.icon`, color `techColor`, size `22`.
- **Derecha — `HudIdTag`.** La primitiva del prompt 06: etiqueta mono pequeña tipo `UNIT-04F`, mostrando `widget.blueprint.id`. Tipografía `mono` (JetBrains Mono, no `'Courier'`), color `textSecondary`, borde `borderDefault`, radio `radiusXS`.

### 5.3 Cuerpo

`Column`, `crossAxisAlignment: start`, con `SizedBox`/`Spacer` según jerarquía:

1. **Categoría** — micro-label: tipografía `labelSmall` (UPPERCASE, Oxanium), color `techColor`. Gap `space4` hacia abajo.
2. **Nombre del plano** — `widget.blueprint.name`, tipografía `titleM` (Oxanium 17/600). Color `textPrimary` reposo → `textPrimary` brillante / blanco-cercano en hover (animado `durFast`). `maxLines 2`, `ellipsis`. Gap `space8`.
3. **Descripción** — `widget.blueprint.description`, tipografía `bodyS` (12.5/400), color `textSecondary`, `height 1.5`, `maxLines 3`, `ellipsis`. Gap `space16`.
4. **Especificaciones técnicas** — bloque `HudReadout`: un mini-panel con fondo `surfaceHud`, radio `radiusS`, padding `space12`, separado por un `HudDivider` arriba (prompt 06, opcionalmente con label `// SPECS`). Dentro, 2–3 filas label/valor:
   - Cada fila: `Row` con `mainAxisAlignment: spaceBetween`. Label a la izquierda en `labelSmall` `textTertiary`; valor a la derecha en `hudReadout` (JetBrains Mono 13/500) color `textSecondary`.
   - Las filas salen de los datos del blueprint (ej.: `CATEGORÍA`, `COMPLEJIDAD`, `MÓDULOS`). Si el modelo `BotBlueprint` no expone esos campos, usar los disponibles (categoría, id) y un valor fijo de placeholder coherente; no inventar campos en el modelo.
   - Gap `space4` entre filas.

### 5.4 Footer

- Separador `HudDivider` fino arriba del footer, `space12` de margen.
- Botón `AppButton` (prompt 09), variante **secondary** tintada con `techColor`, ancho completo (`double.infinity`), alto estándar de botón, label `"ENSAMBLAR"` en `label` (Oxanium UPPERCASE), ícono opcional de «encaje/ensamblaje» a la izquierda.
- `onPressed` dispara el mismo `widget.onTap` (abre `CreateBotModal`). La card completa sigue siendo clickeable vía `GestureDetector`/`InkWell`; el botón es el CTA explícito y accesible por teclado.

### 5.5 Ornamento HUD

- `HudCornerBrackets` (prompt 06) en las 4 esquinas, color `techColor`, brazos de 18 px, grosor 1.5 px. **Solo visibles en hover/focused** (opacidad animada 0 → 1 con `durFast`).
- Se elimina la marca de agua diagonal «PROTOTIPO» rotada: es ruido y compite con los brackets. Si se quiere conservar la idea de «prototipo», se reemplaza por una `HudIdTag` o un micro-label discreto, no por una banda diagonal.

### 5.6 Color

- Acento por instancia = `widget.blueprint.techColor`. Si ese valor es cyan, los glows son `glowCyan`; si fuera otro, `glowStatus(techColor)`.
- Cero hex sueltos, cero `'Courier'` (usar `mono`/`hudReadout`).

---

## 6. Estados e interacciones

Matriz §9 del archivo 00:

| Estado | Qué cambia |
|---|---|
| `default` | `HoloPanel` con borde `borderDefault`, `elev1`, grid `@0.04`, sin brackets, sin glow. |
| `hover` | Borde `techColor@0.55` width 1.5, `elev2` + glow del techColor, brackets visibles, grid `@0.08`, nombre más brillante, escala **1.02**. Cursor pointer. Transición `durFast`. |
| `pressed` | Escala baja a **0.98** (desde 1.02), relleno un paso más profundo. `durInstant`. |
| `focused` | Anillo de foco de 2 px `cyan` alrededor del panel + brackets visibles. Nunca se elimina sin reemplazo. |
| `loading` | No aplica a la card individual; el estado de carga vive en la grilla (prompt 41, skeletons). |
| `disabled` | Si un plano no estuviera disponible: opacidad 0.4, sin glow, sin hover, botón `AppButton` deshabilitado, cursor por defecto. |

---

## 7. Animaciones

Curvas/duraciones por token de §7 del archivo 00.

- **Entrada escalonada:** la card recibe un `staggerIndex` (int) desde la grilla del prompt 41. Entra con fade + translateY 12 px, `easeEntrance`, `durBase`, con delay `staggerIndex * 36 ms` (tope ~10). Implementar con `flutter_animate` (`.animate().fadeIn().slideY()`).
- **Hover:** borde, elevación, glow, brackets y grid suben con `durFast`, curva `easeStandard`. La escala 1.0 → 1.02 usa `AnimatedScale` con `durFast`.
- **Press:** `AnimatedScale` a 0.98 con `durInstant`, vuelve al soltar.
- **Sin shimmer ni latido** en esta card (el shimmer se reserva para elementos clave activos, §7.3 archivo 00).
- **Reduced motion:** sin escalonado (aparece directo), sin translateY, sin escala en hover (solo cambio de borde/color con crossfade 120 ms). Respetar `AppMotion.reduced`.

---

## 8. Accesibilidad

- La card es un control: envolver en `Semantics(button: true, label: 'Plano <nombre>')`.
- El `AppButton` «ENSAMBLAR» es alcanzable por teclado y activa el mismo flujo; foco visible.
- Contraste: nombre `titleM` `textPrimary` ≥ 12:1; descripción `textSecondary` ≥ 4.5:1; valores de specs `hudReadout` `textSecondary` ≥ 4.5:1; labels `labelSmall` `textTertiary` ≥ 3:1 (texto pequeño UPPERCASE — verificar).
- El estado no se comunica solo por color: el botón lleva texto, la `HudIdTag` lleva texto, la categoría lleva texto.
- Glifo del ícono `FaIcon` con `techColor` ≥ 3:1 sobre su marco.
- Área de hit del botón ≥ 32×32 px.

---

## 9. Checklist de aceptación

- [ ] La raíz es `HoloPanel` con `radiusL`; el radio `16` hardcodeado fue eliminado.
- [ ] El `_GridPainter` local fue borrado y reemplazado por `HudGridTexture` tintado con `techColor`.
- [ ] El header usa marco HUD (chaflán ligero) para el ícono y `HudIdTag` para el ID.
- [ ] Ningún `fontFamily: 'Courier'` queda en el archivo; los IDs/valores usan `mono`/`hudReadout`.
- [ ] El cuerpo muestra categoría (`labelSmall`), nombre (`titleM`), descripción (`bodyS`) y bloque de specs en `hudReadout`.
- [ ] Hay un footer con `AppButton` «ENSAMBLAR» que dispara `onTap`; la card completa sigue clickeable.
- [ ] `HudCornerBrackets` aparecen solo en hover/focused.
- [ ] La marca de agua diagonal «PROTOTIPO» fue eliminada.
- [ ] Hover: borde `techColor`, `elev2` + glow, escala 1.02, `durFast`. Press: escala 0.98, `durInstant`.
- [ ] Estado `focused` con anillo `cyan` de 2 px; estado `disabled` con opacidad 0.4 sin glow.
- [ ] Entrada escalonada con `staggerIndex` recibido desde la grilla.
- [ ] `reduced-motion` desactiva escalonado, translateY y escala de hover.
- [ ] Cero hex sueltos, cero magic numbers de espaciado.
- [ ] `flutter analyze` sin warnings nuevos; se ve correcto en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01 (color), 02 (tipografía: `titleM`, `bodyS`, `hudReadout`, `mono`, `labelSmall`), 03 (dimensiones, chaflán), 04 (motion), 06 (HUD: `HudGridTexture`, `HudIdTag`, `HudCornerBrackets`, `HudDivider`, `ChamferBorder`), 07 (glow).
- **Componentes núcleo:** 09 (`AppButton`), 12 (`HoloPanel`).
- **Mismo grupo:** 41 (`BotsLibraryView`) le pasa el `staggerIndex` y lo coloca en la grilla.
