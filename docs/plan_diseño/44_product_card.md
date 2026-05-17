# 44 — Product Card · Ítem de producto de la tienda

> Prompt ejecutable de la **Fase F**. Antes de tocar nada, leé `00_README_VISION_Y_SISTEMA_DE_DISENO.md` completo. Todos los valores se referencian por **nombre de token**.

---

## 1. Objetivo

Rediseñar `ProductCard`, la card de un addon/módulo en la «Tienda». Debe sentirse como un **módulo de hardware premium** en vitrina: panel de vidrio con una zona de ilustración del producto arriba (fondo de retícula HUD + glow), nombre, categoría como status tag, precio en ticker mono dorado destacado, y un botón «ADQUIRIR». Estados completos para producto disponible, adquirido, próximamente y agotado.

---

## 2. Archivos

- **Modificar:** `lib/features/store/presentation/widgets/product_card.dart`
- **Consumir (no crear):** `HoloPanel` (12), `HudGridTexture`/`HudIdTag` (06), `StatusTag`/chips (11), `HudTicker`/`numericTicker` (06/02), `AppButton` (09), glow (07).
- **Tokens:** `app_colors.dart`, `app_dimens.dart`, `app_motion.dart`.

El `_GridPatternPainter` interno se elimina y se reemplaza por `HudGridTexture`.

---

## 3. Estado actual

- `StatefulWidget` con `_isHovered`. `MouseRegion` + `AnimatedContainer` `200 ms`.
- Hover: `Matrix4` translateY `-4`, borde `accentColor@0.4` width 1.5 (reposo `borderGlass` width 1), sombra `accentColor@0.15` blur 20 spread 2. Radio `16` hardcodeado.
- `Column` con 3 zonas:
  - `_buildHeader`: alto fijo `100`, gradiente `accentColor@0.1 → @0.05`, `_GridPatternPainter` propio, ícono `FaIcon` central dentro de círculo `surface@0.9` con borde + sombra. Badges condicionales «PRÓXIMAMENTE» (warning) / «ACTIVO» (success) arriba a la derecha.
  - Contenido (`Padding 16`): chip de categoría (`category.color`, 9 px), nombre (Oxanium 16, hardcodeado), descripción (`bodyMedium` 12, `maxLines 2`), `Spacer`, hasta 3 features con `Icons.check_circle`.
  - `_buildFooter`: `Padding 16`, fondo `background@0.5`, borde superior `borderGlass`. Precio (`formattedPrice`, 18, color condicional) + `'pago único'` + `ElevatedButton` («ABRIR»/«OBTENER»/«NOTIFICAR»).
- `_handleAction` muestra un `SnackBar` placeholder.
- **No usa** `HoloPanel`, ticker, ni componentes núcleo. Tipografía hardcodeada. Pero ya contempla `isAvailable`/`isOwned` — eso se conserva como base de la matriz de estados.

---

## 4. Visión del rediseño

La card es un **módulo en vitrina del hangar**. De afuera hacia adentro:

- `HoloPanel` radio `radiusL`, vidrio sutil, elevación que sube en hover con `glowGold`.
- **Zona de ilustración (arriba):** una franja superior con fondo `HudGridTexture` tintado con el `accentColor` del producto, un glow detrás del ícono, y el ícono del producto centrado en un marco circular HUD. Badges de estado HUD arriba a la derecha.
- **Cuerpo:** nombre del módulo (`titleM`), tipo/categoría como `StatusTag` (no un container plano), descripción (`bodyS`), features con ícono de check coherente.
- **Footer:** precio en `numericTicker` mono dorado destacado (la cifra «emite» — es valor/dinero, §3.2 archivo 00) + un `AppButton` primary «ADQUIRIR».
- Estado «agotado/no disponible»: card desaturada, sin glow, botón en su estado correspondiente.

El factor WOW: el precio como ticker dorado, la zona de ilustración con glow, y los status tags HUD hacen que la card se sienta como una vitrina de instrumentación, no como una tarjeta de e-commerce genérica.

---

## 5. Especificación visual

### 5.1 Contenedor

- Raíz: `HoloPanel` (prompt 12), `radius: radiusL`, sin padding propio (las zonas internas manejan su padding).
- Borde reposo `borderDefault` width 1; hover `accentColor@0.45` width 1.5.
- Elevación reposo `elev1`; hover `elev2` + `glowGold` (si el producto es destacado/precio>0) o `glowStatus(accentColor)` según el `accentColor`. **Una** sombra + **un** glow.
- `Column`, `crossAxisAlignment: stretch`: zona ilustración → cuerpo → footer.

### 5.2 Zona de ilustración (header)

- Alto fijo `120` (un poco más que el `100` actual, para respiro).
- Fondo: `gradPanel`/`surfaceHud` + capa `HudGridTexture` tintada con `accentColor` a `opacity 0.05`. Reemplaza al `_GridPatternPainter` local (se borra).
- Detrás del ícono, un glow radial difuso del `accentColor` (blur amplio, baja opacidad) — da el «brillo de vitrina».
- Ícono central: `FaIcon` del producto, size `30`, dentro de un marco **circular** HUD: círculo `surface@0.9`, borde `accentColor@0.32` width 2, glow `glowStatus(accentColor)` tenue.
- **Badges de estado** arriba-derecha (`Positioned`), usando `StatusTag` del prompt 11 (no `Container` plano):
  - `isOwned` → `StatusTag` success «ACTIVO» con ícono de check.
  - `!isAvailable` → `StatusTag` warning «PRÓXIMAMENTE».
  - producto agotado (si el modelo lo soporta) → `StatusTag` danger «AGOTADO».
- Esquina superior izquierda opcional: `HudIdTag` con un código del producto si el modelo lo expone.

### 5.3 Cuerpo

`Padding(EdgeInsets.all(space16))`, `Column` `crossAxisAlignment: start`:

1. **Tipo/categoría** — `StatusTag`/chip pequeño (prompt 11) con `product.category.displayName`, tinte `product.category.color`, tipografía `labelSmall`. Reemplaza el `Container` plano actual.
2. Gap `space12`.
3. **Nombre** — `product.name`, tipografía `titleM` (Oxanium 17/600), `textPrimary`, `maxLines 1`, `ellipsis`.
4. Gap `space8`.
5. **Descripción** — `product.description`, `bodyS` (12.5/400), `textSecondary`, `height 1.4`, `maxLines 2`, `ellipsis`.
6. `Spacer()`.
7. **Features** — hasta 3 filas: ícono de check (Lucide/FontAwesome coherente, no `Icons.check_circle` Material si el set unificado del prompt 05 dice otra cosa), color `accentColor@0.7`, size 12, + texto `bodyS`/`labelSmall` `textTertiary`, `maxLines 1`. Gap `space4` entre filas.

### 5.4 Footer

`Container` con fondo `surfaceHud`, borde superior `borderSubtle`, `padding EdgeInsets.all(space16)`, esquinas inferiores con radio `radiusL` (heredado del panel). `Row`:

- **Izquierda — precio:**
  - Si `priceDefined` y `price > 0`: cifra en `numericTicker` (JetBrains Mono, 28/700, **figuras tabulares**), color `gold`. Animar el conteo con `HudTicker` (`durTicker`, `easeTicker`) en la entrada de la card. Debajo, `labelSmall` `textTertiary` `"PAGO ÚNICO"`.
  - Si `price == 0`: texto `"GRATIS"` en `numericTicker` color `success`.
  - Si `!priceDefined`: texto `"—"` o `"A DEFINIR"` en `hudReadout` `textSecondary`.
- **Spacer.**
- **Derecha — botón `AppButton`:**
  - `isOwned` → variante secondary success, label `"ABRIR"`.
  - `isAvailable && !isOwned` → variante **primary** (dorada), label `"ADQUIRIR"`.
  - `!isAvailable` → variante ghost, label `"NOTIFICAR"`, o deshabilitado según diseño del prompt 09.
  - producto agotado → `AppButton` deshabilitado, label `"AGOTADO"`.
- `onPressed` conserva el flujo actual (`_handleAction` / `SnackBar` placeholder) hasta que exista lógica de compra real.

### 5.5 Color y tipografía

- Acento por instancia = `product.accentColor`. El oro se reserva para el **precio** (valor/dinero) y para el botón primary; el resto de la card usa el `accentColor` y grises técnicos.
- Cero hex sueltos, cero `fontFamily`/tamaños hardcodeados.

---

## 6. Estados e interacciones

Matriz §9 del archivo 00:

| Estado | Qué cambia |
|---|---|
| `default` | `HoloPanel` borde `borderDefault`, `elev1`, sin glow, sin badge. |
| `hover` | Borde `accentColor@0.45` width 1.5, `elev2` + glow, translateY `-4` px **+ escala 1.02**, ícono/glow de ilustración más intensos. Cursor pointer. `durFast`. |
| `pressed` | Escala 0.98, relleno un paso más profundo. `durInstant`. |
| `focused` | Anillo de foco 2 px `gold` alrededor del panel. |
| `selected/active` (`isOwned`) | Badge `StatusTag` success «ACTIVO», botón «ABRIR» success, borde con tinte success suave. |
| `disabled` / `próximamente` (`!isAvailable`) | Card **desaturada**: contenido a opacidad ~0.55, sin glow en hover, badge warning «PRÓXIMAMENTE», botón «NOTIFICAR» o deshabilitado. |
| `agotado` | Card desaturada (opacidad ~0.45), badge danger «AGOTADO», botón deshabilitado «AGOTADO», sin hover de elevación. |
| `loading` | No aplica a la card individual; los skeletons viven en la grilla (prompt 43). |

---

## 7. Animaciones

- **Entrada escalonada:** `staggerIndex` recibido desde la grilla del prompt 43. Fade + translateY 12 px, `easeEntrance`, `durBase`, delay `staggerIndex * 36 ms`, tope ~10.
- **Ticker de precio:** la cifra cuenta hacia su valor con `HudTicker` (`durTicker` = 900 ms, `easeTicker`) al entrar la card. Solo una vez por aparición.
- **Hover:** borde, elevación, glow, translateY y escala `1.0→1.02` con `durFast`, `easeStandard`.
- **Press:** `AnimatedScale` a 0.98 con `durInstant`.
- **Sin shimmer ni latido** salvo, opcionalmente, un shimmer muy espaciado en el botón primary si el prompt 09 lo define para su variante destacada.
- **Reduced motion:** sin escalonado, sin conteo de ticker (la cifra aparece final directa), sin translateY/escala en hover (solo cambio de borde/color, crossfade 120 ms). Respetar `AppMotion.reduced`.

---

## 8. Accesibilidad

- La card es un control: `Semantics(button: true, label: 'Producto <nombre>, <precio>')`.
- El `AppButton` del footer es alcanzable por teclado; foco visible.
- Contraste: nombre `titleM` `textPrimary` ≥ 12:1; descripción/features `textSecondary`/`textTertiary` verificar ≥ 4.5:1 / ≥ 3:1; precio `numericTicker` `gold` ≥ 4.5:1 sobre `surfaceHud`.
- El estado no se comunica solo por color: los badges llevan ícono + texto («ACTIVO», «PRÓXIMAMENTE», «AGOTADO»); el botón lleva texto.
- En estado desaturado/agotado, mantener el contraste mínimo del texto legible aun con la opacidad reducida (no bajar el texto por debajo de 4.5:1 — desaturar afecta más al fondo/ícono que al texto crítico).
- Área de hit del botón ≥ 32×32 px.

---

## 9. Checklist de aceptación

- [ ] La raíz es `HoloPanel` con `radiusL`; el radio `16` hardcodeado fue eliminado.
- [ ] El `_GridPatternPainter` local fue borrado y reemplazado por `HudGridTexture` tintado con `accentColor`.
- [ ] La zona de ilustración tiene glow detrás del ícono y marco circular HUD.
- [ ] Los badges de estado usan `StatusTag` del prompt 11 (no `Container` plano).
- [ ] La categoría se muestra como `StatusTag`/chip, no como container plano hardcodeado.
- [ ] El nombre usa `titleM`, descripción `bodyS`; cero tipografía hardcodeada.
- [ ] El precio se muestra en `numericTicker` mono dorado con figuras tabulares y cuenta con `HudTicker` al entrar.
- [ ] El footer usa `AppButton` con variantes por estado (`ADQUIRIR`/`ABRIR`/`NOTIFICAR`/`AGOTADO`).
- [ ] Hover: borde `accentColor`, `elev2` + glow, translateY `-4` + escala 1.02, `durFast`. Press: escala 0.98.
- [ ] Estados `isOwned` (activo/success), `!isAvailable` (desaturado/warning) y `agotado` (desaturado/danger) implementados.
- [ ] Estado `focused` con anillo `gold` de 2 px.
- [ ] Entrada escalonada con `staggerIndex`.
- [ ] `reduced-motion` desactiva escalonado, conteo de ticker, translateY y escala.
- [ ] Cero hex sueltos, cero magic numbers de espaciado.
- [ ] `flutter analyze` sin warnings nuevos; se ve correcto en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01, 02 (`titleM`, `bodyS`, `numericTicker`, `labelSmall`, `mono`), 03, 04, 05 (iconografía: ícono de check), 06 (`HudGridTexture`, `HudIdTag`, `HudTicker`), 07 (glow).
- **Componentes núcleo:** 09 (`AppButton`), 11 (`StatusTag`/chips), 12 (`HoloPanel`).
- **Mismo grupo:** 43 (`StoreView`) le pasa el `staggerIndex` y lo coloca en la grilla.
