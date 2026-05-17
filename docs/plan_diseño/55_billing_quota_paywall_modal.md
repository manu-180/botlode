# 55 — Billing · Quota Paywall Modal

> Depende de **00_README_VISION_Y_SISTEMA_DE_DISENO.md**. Si algo contradice al 00, gana el 00.

---

## 1. Objetivo

Rediseñar `QuotaPaywallModal` como el aviso del Hangar OS que aparece cuando se supera la cuota del plan: claro y firme pero **no alarmista**, con tono HUD, una comparativa visual plan actual vs siguiente y un CTA destacado para mejorar el plan. Desktop = `Dialog` (max-width 480–520); móvil = bottom sheet draggable.

---

## 2. Archivos

- **Modificar:** `lib/features/billing/presentation/widgets/quota_paywall_modal.dart`
- **Consumir (no modificar):** `lib/core/config/theme/` (01–04), `lib/core/ui/hud/` (06), `lib/core/ui/panels/holo_panel.dart` (12), `lib/core/ui/buttons/app_button.dart` (09).

---

## 3. Estado actual

`showQuotaPaywallModal` decide desktop (`width >= 600` → `Dialog` max-width 480) vs móvil (`DraggableScrollableSheet` 0.75 inicial). `_QuotaPaywallModal` recibe `quota`, `resource` (`bots`/`conversations`), `plans`, `currentPlanId`. Calcula `_nextPlan()` y `_currentPlan()`.

Renderiza dentro de `_ModalContainer` (`Container` `surface`, radio 20, borde `outlineVariant`): header (círculo `errorContainer` con `lock_outline` + título «Límite alcanzado»), copy del cuerpo, una `Table` comparativa de planes (header Plan/Bots/Convers., fila del plan actual resaltada, fila del siguiente con badge «Recomendado», o fila «Plan Enterprise / Contactar soporte»), y acciones (`FilledButton` «ver planes» que navega a `/billing`, `TextButton` «más tarde»).

Funcional y accesible, pero usa colores `errorContainer` (tono alarmista), contenedor Material plano, tabla genérica, sin ornamento HUD ni jerarquía premium.

---

## 4. Visión del rediseño

El modal informa con **claridad serena**: «alcanzaste el límite, hay un plan que te lo desbloquea». No es una alarma roja. `HoloPanel` con `HudCornerBrackets`. El header lleva un ícono de advertencia dentro de un **anillo HUD `warningGlow`** (warning, no danger — es un límite, no un fallo). Título y explicación claros. El núcleo es una **comparativa en dos columnas**: plan actual a la izquierda, plan siguiente a la derecha, con las capacidades enfrentadas y los features diferenciales del plan siguiente resaltados en oro. CTA «MEJORAR PLAN» como `AppButton` primario dorado destacado, y un botón secundario discreto para cerrar. Entra con scale+fade de resorte.

---

## 5. Especificación visual

### 5.1 Presentación

- Desktop (`width >= 600`): `showDialog` con scrim `scrim` + `BackdropFilter` blur; `ConstrainedBox` max-width **480–520**.
- Móvil (`< 600`): `showModalBottomSheet` con `DraggableScrollableSheet` (mantener `initialChildSize` 0.75, `minChildSize` 0.5, `maxChildSize` 0.92). En móvil, una «agarradera» (handle) `surfaceRaised` 36×4 px radio `radiusPill` centrada arriba.
- z-index `zModal`.

### 5.2 Contenedor — `HoloPanel`

- `_ModalContainer` se reconstruye sobre `HoloPanel` (prompt 12): relleno `glassSurfaceStrong`, radio `radiusXL` (28), sombra `elev3`, `HudCornerBrackets` `warning` (acento del modal).
- Padding interno `space28`.

### 5.3 Header

- Fila: ícono `Icons.lock_outline_rounded` (o `Icons.speed`) dentro de un **anillo HUD** — círculo borde `warning` 1.5 px, fondo `warning @ 0.1`, ~44 px, glow `warningGlow` suave. NO usar `errorContainer`/rojo.
- Columna a la derecha:
  - Micro-label `labelSmall` UPPERCASE `textTertiary` «// LÍMITE DE PLAN».
  - Título «LÍMITE ALCANZADO» en `titleM` (17/600) `textPrimary`.
- `HudDivider` debajo.

### 5.4 Copy del cuerpo

- Texto `bodyM` `textSecondary`, interlineado 1.5, tono informativo. Se preserva la lógica de `_bodyCopy()` (bots vs conversaciones, nombre del plan actual, `quota.limit`).
- Resaltar el dato clave (el límite numérico) en `hudReadout` `gold` inline.

### 5.5 Comparativa plan actual vs siguiente (dos columnas)

Reemplazar la `Table` por dos columnas enfrentadas dentro de un `HoloPanel` interno o un `Row`:

- **Columna izquierda — plan actual:** mini-panel `surfaceHud`, borde `borderDefault`. Header `label` `textSecondary` «PLAN ACTUAL» + nombre del plan. Lista de capacidades: «{maxBots} bots», «{maxConversations} conversaciones» en `bodyS` `textSecondary`, con la capacidad superada marcada con ícono `Icons.lock` `warning`.
- **Columna derecha — plan siguiente:** mini-panel con `ChamferBorder`, borde `borderGold`, glow `glowGold` suave, `StatusTag` «RECOMENDADO» (variante `gold`). Header `label` `gold` «MEJORAR A» + nombre del plan. Capacidades en `bodyS` `textPrimary`, con los **valores diferenciales resaltados** — la cifra que mejora va en `hudReadout` `gold` con un mini-ícono `Icons.arrow_upward` `success`.
- Separador vertical entre columnas: `HudDivider` vertical fino.
- Caso «sin plan siguiente» (usuario en el tier máximo): en lugar de la columna derecha, un panel «PLAN ENTERPRISE» con texto «Contactá a soporte para ampliar tus límites» y, opcionalmente, un `AppButton` secundario «CONTACTAR SOPORTE».
- Si `currentPlan == null` (sin suscripción), la columna izquierda muestra «SIN PLAN» y la derecha el primer plan disponible.

### 5.6 Acciones

- `AppButton` primario dorado «MEJORAR PLAN» con `glowGold`, ancho completo, alto 50, ícono `Icons.arrow_upward`. Preserva la `Key('ver_planes_btn')`. Al pulsarlo: cierra el modal y navega a `/billing` (preservar la lógica `router.go('/billing')`).
- Debajo, `AppButton` variante ghost/texto «MÁS TARDE», discreto, `textSecondary`. Preserva la `Key('mas_tarde_btn')`. Cierra el modal.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` | Header + copy + comparativa de 2 columnas + acciones. |
| `hover` (botones, columna recomendada) | Borde + glow suben `durFast`; la columna recomendada intensifica su glow. |
| `pressed` | `AppButton` escala 0.97 `durInstant`. |
| `focused` | Foco 2 px `cyan` en cada botón. Orden: MEJORAR PLAN → MÁS TARDE. |
| `selected/active` | La columna del plan siguiente es la destacada (chaflán + glow + `StatusTag`). |
| `loading` | No aplica (los datos llegan como parámetros, sin Riverpod). |
| `disabled` | No aplica. |
| `error` | No aplica (sin carga asíncrona). |
| `empty` | Caso «sin plan siguiente» → panel «PLAN ENTERPRISE / Contactar soporte». Caso `currentPlan == null` → columna izquierda «SIN PLAN». |

- Móvil: el bottom sheet es draggable (handle visible) y descartable arrastrando hacia abajo o tocando el scrim.
- Desktop: descartable tocando el scrim o con Escape.

---

## 7. Animaciones

- **Entrada (desktop):** scrim fade-in `durBase`; panel scale 0.94 → 1.0 + fade con `springSoft`.
- **Entrada (móvil):** el bottom sheet sube con la animación nativa del `DraggableScrollableSheet`; el contenido hace fade-in `durFast`.
- **Salida:** scale + fade `durFast` (desktop); deslizamiento hacia abajo (móvil).
- **Comparativa:** las dos columnas entran con un escalonado corto (la izquierda, luego la derecha 36 ms después), fade + `translateY` 8 px.
- **Columna recomendada en reposo:** glow dorado con un pulso muy suave de opacidad (1600 ms) o un shimmer lento cada ~3000 ms — sutil, solo esa columna.
- **Hover:** borde + glow `durFast`.
- **Reduced motion:** sin scale en entrada (crossfade 120 ms), sin escalonado de columnas, sin pulso/shimmer en la columna recomendada.

---

## 8. Accesibilidad

- El modal atrapa el foco; al cerrar vuelve al elemento disparador. Escape (desktop) y scrim cierran.
- Header con `Semantics(header: true)`.
- El copy del cuerpo lleva un `Semantics(label: ...)` con el mensaje completo del límite (preservar el `quotaMessage` actual).
- El estado «límite superado» se comunica por ícono + texto + color `warning` — nunca solo color.
- La comparativa: cada columna con `Semantics` que describe plan y capacidades; la cifra diferencial resaltada es legible por el lector.
- Botones con `Semantics` de botón y label descriptivo («Mejorar plan para desbloquear esta función», «Cerrar aviso de límite»). Preservar las `Key` de test.
- Contraste: título `textPrimary` ≥ 12:1; copy `textSecondary` ≥ 4.5:1; dato resaltado `gold` ≥ 4.5:1; micro-labels `textTertiary` ≥ 3:1 — verificar.
- Tono no alarmista: usar `warning` (no `danger`/rojo) en acentos e ícono.
- Foco visible 2 px `cyan`; orden de foco = orden visual.
- Targets ≥ 44 px en botones (uso táctil en móvil).

---

## 9. Checklist de aceptación

- [ ] Desktop = `Dialog` max-width 480–520 sobre scrim + blur; móvil = bottom sheet draggable con handle.
- [ ] Contenedor `HoloPanel` con `HudCornerBrackets` en `warning`.
- [ ] Header con ícono en anillo HUD `warningGlow` (warning, NO rojo/`errorContainer`).
- [ ] Copy del cuerpo informativo, con el límite numérico resaltado en `hudReadout` `gold`.
- [ ] Comparativa en dos columnas (actual vs siguiente), no una `Table` Material.
- [ ] Columna del plan siguiente destacada: `ChamferBorder`, `borderGold`, glow, `StatusTag` «RECOMENDADO».
- [ ] Capacidades diferenciales resaltadas con `hudReadout` `gold` + ícono `arrow_upward`.
- [ ] Caso «sin plan siguiente» → panel «PLAN ENTERPRISE / Contactar soporte».
- [ ] CTA «MEJORAR PLAN» como `AppButton` primario dorado con `glowGold`; navega a `/billing`.
- [ ] Botón «MÁS TARDE» ghost discreto; ambas `Key` de test preservadas.
- [ ] Tono no alarmista: acentos `warning`, nunca `danger`.
- [ ] Cero hex sueltos, cero magic numbers: todo por token.
- [ ] Foco atrapado; Escape/scrim cierran; semántica y `Key` correctas.
- [ ] Reduced motion respetado (sin scale, sin escalonado, sin pulso/shimmer).
- [ ] Se ve correcto en 1280×720, 1024×600 y en ancho móvil < 600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (color: `glassSurfaceStrong`, `scrim`, `warning`, `warningGlow`, `borderGold`, `glowGold`), 02 (tipografía: `titleM`, `bodyM`, `hudReadout`, `labelSmall`, `label`), 03 (dimensiones: `radiusXL`, `radiusPill`, `chamferM`, `elev3`, `zModal`), 04 (motion: `springSoft`), 05 (iconografía), 06 (`HudCornerBrackets`, `HudDivider`, `ChamferBorder`).
- **Componentes núcleo:** 09 (`AppButton`), 11 (`StatusTag`), 12 (`HoloPanel`).
- **Relacionado:** 49 (plan picker — destino del CTA «MEJORAR PLAN»), 47 (shell de billing).
