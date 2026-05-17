# 49 — Billing · Plan Picker

> Depende de **00_README_VISION_Y_SISTEMA_DE_DISENO.md**. Si algo contradice al 00, gana el 00.

---

## 1. Objetivo

Rediseñar `PlanPicker` para que la selección de plan se sienta como elegir una **configuración de hardware** en la terminal: una fila de 3-4 paneles HUD comparables, con el plan recomendado destacado por chaflán + glow dorado, precios en ticker numérico, y un toggle mensual/anual con descuento.

---

## 2. Archivos

- **Modificar:** `lib/features/billing/presentation/widgets/plan_picker.dart`
- **Consumir (no modificar):** `lib/core/config/theme/` (01–04), `lib/core/ui/hud/` (06), `lib/core/ui/panels/holo_panel.dart` (prompt 12), `lib/core/ui/buttons/app_button.dart` (prompt 09), `lib/features/billing/presentation/widgets/empty_state.dart`.

---

## 3. Estado actual

`PlanPicker` (ConsumerStatefulWidget) lee `billingV2Provider`, mantiene `_selectedInterval`. Con `.when()`: loading → spinner; error → `_ErrorState`; data → `_PlanPickerContent`. Este filtra planes públicos no archivados por intervalo, los ordena por precio, y arma:

- Un `SegmentedButton` mensual/anual (`_IntervalToggle`).
- Un `_PlanGrid` responsive: 1 columna < 600, 2 < 900, 3 si más; `childAspectRatio` 0.55.
- Cada `_PlanCard` es un `Card` Material con borde de color (primary si actual, secondary si highlighted, outlineVariant si no), badges `_Badge` (ACTUAL/Recomendado), nombre `titleMedium`, precio `headlineSmall` primary, filas de capacidad (`_CapacityRow` bots/conversaciones), bullets de features con `check_circle_outline`, y un `_PlanCta` (`OutlinedButton` disabled si actual, `FilledButton` Upgrade/Downgrade).
- `_EmptyPlansState` y `_ErrorState` Material plano.

Funciona y es accesible, pero es Material genérico: cards planas, sin profundidad, sin ornamento HUD, precio sin protagonismo, el highlight no impacta.

---

## 4. Visión del rediseño

Una **fila de paneles HUD** alineados, cada uno una «ficha técnica» de plan. El plan recomendado se separa del resto: chaflán a 45° (`chamfer`), borde `borderGold`, `glowGold`, `HudCornerBrackets` y una escala ~1.04 mayor — el ojo va directo a él. El precio es el héroe de cada panel: un `numericTicker` grande en oro que cuenta al cambiar de intervalo. Las features se leen como una lista de instrumentación con checks. El toggle mensual/anual es un control segmentado HUD con una píldora «−X%» dorada cuando hay descuento anual. El plan actual lleva un `StatusTag` «ACTUAL» y su CTA queda deshabilitado pero legible.

---

## 5. Especificación visual

### 5.1 Layout

- Encabezado de sección (lo pone el shell, prompt 47): título `titleM` «PLANES DISPONIBLES» + `HudDivider`.
- **Toggle de intervalo** centrado, `space20` por arriba y por abajo.
- **Fila de planes:**
  - Desktop (≥ 1040 contenido): `Row` de 3-4 paneles, gap `space20`, todos a la misma altura (estirados verticalmente con `IntrinsicHeight`/`CrossAxisAlignment.stretch`).
  - Ancho intermedio (720–1040): 2 columnas en `Wrap`.
  - Angosto (< 720): 1 columna apilada, gap `space16`.
- El plan recomendado, en desktop, se renderiza con `Transform.scale(1.04)` y mayor z-index para que «sobresalga» de la fila.

### 5.2 Panel de plan — `HoloPanel`

Cada `_PlanCard` se reconstruye sobre `HoloPanel` (prompt 12):

- **Plan normal:** `HoloPanel` con relleno `gradPanel`, borde `borderDefault` 1 px, radio `radiusL` (20), sombra `elev1`.
- **Plan recomendado:** `HoloPanel` con forma `ChamferBorder` (`chamferM` 12) en lugar de radio redondeado, borde `borderGold` 2 px, sombra `elev2` + `glowGold`, `HudCornerBrackets` en `borderGold`, escala 1.04.
- **Plan actual:** borde `borderGold` 1 px (más sutil que el recomendado), `HudIdTag` `mono` en la esquina `// PLAN ACTIVO`.
- Padding interno `space24`.

Estructura interna del panel (Column, `crossAxisAlignment.start`, `mainAxisSize.min`):

1. **Fila de badges** (`Wrap`, gap `space4`): `StatusTag` «ACTUAL» (variante `gold`/`success`) si es el plan actual; `StatusTag` «RECOMENDADO» (variante `gold`) si es highlighted. Texto `labelSmall` UPPERCASE.
2. Gap `space12`.
3. **Nombre del plan:** `titleL` (21/600) `textPrimary`.
4. Gap `space8`.
5. **Bloque de precio:**
   - El número en `numericTicker` (JetBrains Mono tabular, ~28, 700) color `gold`. Prefijo `$` en `titleM` `gold` alineado al baseline.
   - Debajo o al lado, el periodo (`/mes` · `/año`) en `bodyS` `textSecondary`.
   - Si el intervalo es anual y hay descuento: una línea `hudReadout` `success` «−20% vs mensual» (o el porcentaje real calculado).
6. Gap `space16`. `HudDivider` interno corto.
7. **Capacidades** (`_CapacityRow`): fila ícono `Icons.smart_toy_outlined` 16 px `cyan` + «{maxBots} bots»; fila ícono `Icons.forum_outlined` + «{maxConversations} conversaciones». Texto `bodyM` `textSecondary`, los números en `hudReadout` `textPrimary`.
8. Gap `space12`.
9. **Features:** lista de bullets — ícono `Icons.check_circle` 16 px `gold` (relleno, no outline) + texto `bodyS` `textPrimary`, gap vertical `space4` entre bullets.
10. Gap `space20`.
11. **CTA del panel** (§5.4).

### 5.3 Toggle mensual/anual — `_IntervalToggle`

Reconstruir como un control segmentado HUD (no `SegmentedButton` Material plano):

- Pista `surfaceHud`, borde `borderDefault`, radio `radiusPill` (999), altura 40 px, padding `space4`.
- 2 segmentos: «MENSUAL» / «ANUAL», `label` (13/600 UPPERCASE).
- Indicador deslizante `gradGold` con `textOnGold`, radio `radiusPill`, sombra `glowGold` suave.
- Si hay descuento anual: a la derecha del segmento «ANUAL», una mini-píldora `success`/`gold` «AHORRÁ X%» en `labelSmall`.
- Al cambiar de segmento, el indicador se desliza con `durBase`/`easeStandard` y los precios de los paneles hacen ticker (§7).

### 5.4 CTA del panel — `_PlanCta`

- **Plan actual:** `AppButton` variante ghost/disabled, ancho completo, alto 48, texto «PLAN ACTUAL», ícono `Icons.check`. Deshabilitado pero con texto legible (no opacidad que rompa contraste del label).
- **Upgrade:** `AppButton` primario dorado (`gradGold` + `glowGold` en el panel recomendado), texto «MEJORAR» / «SELECCIONAR», ícono `Icons.arrow_upward`.
- **Downgrade:** `AppButton` secundario, texto «CAMBIAR A ESTE», ícono `Icons.arrow_downward`.
- Invoca `onPlanSelected(plan.id)` — el shell abre el modal de prorrateo (prompt 56).

### 5.5 Estados vacío / error

- Vacío (`filteredPlans` vacío): `EmptyState` (prompt 15) con ícono `Icons.workspace_premium_outlined` en anillo HUD, título «Sin planes disponibles», subtítulo y `AppButton` secundario «CONTACTAR SOPORTE».
- Error: `ErrorFeedbackCard` (prompt 16) con el mensaje y reintento.
- Loading: 3 skeletons de panel de plan (prompt 14) en fila.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` | Panel en reposo. Recomendado siempre con chaflán + glow. |
| `hover` (panel) | Borde sube a `borderStrong` (normal) o `goldBright` (recomendado), elevación +1 nivel, glow suave aparece, escala +0.01. `durFast`. Cursor pointer si el CTA está habilitado. |
| `pressed` (CTA) | Botón a escala 0.97, relleno un paso más profundo. `durInstant`. |
| `focused` | Panel/CTA con anillo de foco 2 px `cyan`. Orden de foco izquierda→derecha. |
| `selected/current` | Plan actual: borde `borderGold`, `StatusTag` «ACTUAL», CTA deshabilitado. |
| `loading` | 3 skeletons de panel; toggle deshabilitado. |
| `disabled` | CTA del plan actual deshabilitado (texto legible). |
| `error` | `ErrorFeedbackCard` en lugar de la fila de planes. |
| `empty` | `EmptyState` «Sin planes disponibles». |

---

## 7. Animaciones

- **Entrada de la fila:** los paneles entran escalonados — cada uno 36 ms después del anterior, fade + `translateY` 12 px, curva `easeEntrance`, `durBase`.
- **Cambio de intervalo:** el indicador del toggle se desliza `durBase`/`easeStandard`; los precios de todos los paneles hacen un `HudTicker` que cuenta del precio viejo al nuevo en `durTicker` (900 ms) con `easeTicker`.
- **Hover de panel:** borde + glow + escala suben con `durFast`.
- **Recomendado en reposo:** shimmer dorado muy lento (`gradGoldSheen`) cada ~3000 ms sobre el panel recomendado — solo ese.
- **CTA press:** escala 0.97 `durInstant`.
- **Reduced motion:** sin escalonado (los paneles aparecen juntos con fade 120 ms), el precio salta al nuevo valor sin contar, sin shimmer en el recomendado, el toggle salta sin deslizar.

---

## 8. Accesibilidad

- Cada panel: `Semantics(label: 'Plan {nombre}, {precio} por {periodo}', selected: isCurrent, button: true)`.
- El plan actual y el recomendado se identifican por **texto** (`StatusTag` «ACTUAL» / «RECOMENDADO») además del color/borde — nunca solo color.
- Contraste: nombre `titleL` `textPrimary` ≥ 12:1; precio `gold` sobre `gradPanel` ≥ 4.5:1; features `bodyS` `textPrimary` ≥ 4.5:1; periodo `textSecondary` ≥ 4.5:1 — verificar todos.
- CTA del plan actual: aunque deshabilitado, su label debe mantener contraste legible (no usar opacidad 0.4 sobre el texto del label; deshabilitar la interacción, no destruir la lectura).
- Foco visible 2 px `cyan` en paneles y CTAs; orden de foco = orden visual.
- Toggle: `Semantics` de grupo con label «Intervalo de facturación»; cada segmento anuncia su estado seleccionado.
- Targets ≥ 48 px de alto en CTAs y segmentos del toggle.

---

## 9. Checklist de aceptación

- [ ] Cada plan se renderiza sobre `HoloPanel` (prompt 12), no `Card` Material.
- [ ] El plan recomendado usa `ChamferBorder`, `borderGold` 2 px, `glowGold`, `HudCornerBrackets` y escala 1.04.
- [ ] El plan actual lleva `StatusTag` «ACTUAL» + `HudIdTag` y CTA deshabilitado legible.
- [ ] El precio se muestra en `numericTicker` `gold` y hace ticker al cambiar de intervalo.
- [ ] El toggle mensual/anual es un segmentado HUD con indicador deslizante e incluye píldora de descuento anual.
- [ ] Features con `Icons.check_circle` `gold`; capacidades con números en `hudReadout`.
- [ ] CTAs usan `AppButton` (primario dorado para upgrade, secundario para downgrade, ghost para actual).
- [ ] Entrada de la fila escalonada (36 ms/ítem); reduced motion la desactiva.
- [ ] Estados vacío (`EmptyState`), error (`ErrorFeedbackCard`) y loading (3 skeletons) implementados.
- [ ] Layout responsive: 3-4 en fila ≥ 1040, 2 entre 720–1040, 1 < 720.
- [ ] Cero hex sueltos, cero magic numbers: todo por token.
- [ ] Cada panel con `Semantics` correcto; estado por texto + color.
- [ ] Reduced motion respetado (sin escalonado, sin ticker, sin shimmer).
- [ ] Se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (color: `gradGold`, `gradPanel`, `borderGold`, `glowGold`), 02 (tipografía: `titleL`, `numericTicker`, `hudReadout`, `labelSmall`), 03 (dimensiones: `radiusL`, `radiusPill`, `chamferM`, `elev1/2`), 04 (motion: `durTicker`, `easeTicker`), 05 (iconografía), 06 (`HudCornerBrackets`, `HudDivider`, `HudTicker`, `HudIdTag`, `ChamferBorder`).
- **Componentes núcleo:** 09 (`AppButton`), 11 (`StatusTag`), 12 (`HoloPanel`), 14 (skeleton), 15 (`EmptyState`), 16 (`ErrorFeedbackCard`).
- **Shell:** 47 (tab «Plan» del shell de billing). Relacionado: 56 (modal de prorrateo, abierto por el CTA).
