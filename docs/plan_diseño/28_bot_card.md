# 28 — Bot card

> Depende del archivo **00 — README · Visión y Sistema de Diseño**. Leerlo completo antes de ejecutar. Todos los valores se referencian **por token**.

---

## 1. Objetivo

Rediseñar `BotCard`: el ítem de la grilla de unidades del Dashboard, **la pieza con mayor factor WOW de la pantalla**. Hoy es un `AnimatedContainer` con un borde de vidrio y hover. Se eleva a una **tarjeta de unidad de hangar**: panel HUD con el avatar Rive sobre una textura de grid con glow del color del bot, status tag con dot, tag de ID, jerarquía tipográfica, hover rico con brackets que aparecen, press, entrada escalonada y un tratamiento desaturado para unidades suspendidas/offline.

---

## 2. Archivos

- **Modificar:** `lib/features/dashboard/presentation/widgets/bot_card.dart` — la clase `BotCard` y su `_BotCardState`. Conservar la lógica del `MouseRegion` (`_isHovered`, `_localMousePos`) que alimenta el eye-tracking de `RiveBotCardDisplay`.
- **Consumir (no crear):** `HoloPanel` (12), `HudCornerBrackets` / `HudStatusDot` / `HudIdTag` / `HudGridTexture` (06), `StatusTag` / `AppBadge` (11), `app_colors.dart` (01), `AppTextStyles` (02), `app_dimens.dart` (03), `app_motion.dart` (04).
- **Referenciar:** `RiveBotCardDisplay` (`lib/features/dashboard/presentation/widgets/rive_bot_card_display.dart`) — se mantiene; el eye-tracking se preserva.

---

## 3. Estado actual

`BotCard` es un `StatefulWidget`. `_BotCardState` deriva `statusColor`/`statusText` de `widget.bot.status` (`active` → `success`/"ACTIVE", `creditSuspended` → `#FF8800`/"SUSPENDED", resto → `error`/"OFFLINE"). Estructura: `MouseRegion` → `GestureDetector(onTap)` → `AnimatedContainer(200ms)`:

- `decoration`: `color: black@0.4`, `borderRadius: 20`, borde `bot.primaryColor@0.6` (hover) / `borderGlass`, `boxShadow` `bot.primaryColor@0.15 blur 20` en hover.
- `Stack`: gradiente sutil de fondo; `Padding(20)` → `Column`:
  - `Row(spaceBetween)`: `RiveBotCardDisplay` (avatar) + badge de estado (`Container` pill con `Icon(circle)` que parpadea + texto).
  - `Spacer()`; nombre (22 px bold), descripción (12 px, 2 líneas), `"ID: ..."` en `Courier` 9 px.

Problemas: color crudo `#FF8800`; radio/padding mágicos; sin `HoloPanel`; sin brackets de hover; sin textura de grid bajo el avatar; sin press; sin entrada escalonada; sin tratamiento desaturado para offline/suspendido; tipografía inline.

---

## 4. Visión del rediseño

Cada `BotCard` es una **unidad autónoma en su bahía**. Un panel HUD de vidrio con radio `radiusL`. La zona superior es un «retrato» del bot: el avatar Rive (que sigue al mouse) flota sobre una **textura de grid técnica** teñida con un **glow del color propio del bot** — cada unidad emite su luz. Arriba a la derecha, un `StatusTag` con `HudStatusDot` (verde activo / naranja suspendido / rojo offline). En una esquina, un `HudIdTag` mono con el ID corto de la unidad. El cuerpo: nombre prominente, descripción a dos líneas, una fila opcional de micro-métricas mono. En reposo la card es sobria (borde de vidrio); al hacer **hover** despierta: el borde toma el color del bot, sube la elevación y el glow, escala apenas a 1.02 y **aparecen brackets de esquina**. Al **presionar** baja a 0.97. Las cards entran escalonadas en la grilla. Una unidad **suspendida u offline** se ve apagada: avatar y card desaturados, sin glow propio, como una nave sin energía.

---

## 5. Especificación visual

### 5.1 Contenedor

- Base: `HoloPanel` (prompt 12), radio `radiusL`, `clipBehavior: Clip.antiAlias`.
- Fondo: `glassSurface` (glassmorphism). Aspect ratio de la card lo fija la grilla (1.4, prompt 24).
- Borde: reposo `glassBorder` 1 px; hover → color del bot (`bot.primaryColor`) 1.5 px (ver §6).
- Sombra: reposo `elev1`; hover `elev2` + `glowStatus(bot.primaryColor)`.
- Padding interno: `EdgeInsets.all(space20)`.
- Estructura: `Stack` (panel + ornamentos) → contenido en `Column(crossAxisAlignment: start)`.

### 5.2 Zona superior — retrato del bot

Un `SizedBox` de alto fijo (~40 % del alto de la card) que es un `Stack`:

1. **Fondo de grid teñido.** `HudGridTexture` (prompt 06) a `opacity 0.05`, dentro de un `Container` con un `RadialGradient` suave centrado en el avatar: `[bot.primaryColor@0.18, transparent]` — el «glow del color del bot». En estado suspendido/offline este glow se apaga (ver §6).
2. **Avatar Rive.** `RiveBotCardDisplay` (sin cambios funcionales): recibe `primaryColor`, `cycleProgress` y `pointerLocalPos: _localMousePos`. El eye-tracking se conserva intacto. Ubicado arriba a la izquierda de la zona.
3. **`StatusTag`** (prompt 11) en la esquina superior **derecha**: un `Row` compacto con `HudStatusDot` (prompt 06) + label uppercase. Colores y copy: `active` → `success` / "ACTIVE"; `creditSuspended` → `warning` / "SUSPENDED"; offline/otros → `danger` / "OFFLINE". El color naranja crudo `#FF8800` se reemplaza por el token `warning`.
4. **`HudIdTag`** (prompt 06) en la esquina superior **izquierda** (o inferior izquierda de la zona superior, lo que no choque con el avatar): texto mono con el ID corto de la unidad — formatear como `UNIT-XXXX` usando los últimos caracteres de `bot.id` si el ID completo es largo; tipografía `labelSmall`/`mono`, fondo `surfaceHud`, borde `borderSubtle`, radio `radiusXS`.

### 5.3 Cuerpo

`Column` debajo de la zona superior, separado por `SizedBox(height: space16)`:

1. **Nombre.** `Text(bot.name)` estilo `AppTextStyles.titleM` (17 px / 600 / Oxanium), color `textPrimary`, `maxLines: 1`, `overflow: ellipsis`.
2. `SizedBox(height: space4)`.
3. **Descripción.** `Text(bot.description ?? "Unidad de propósito general.")` estilo `AppTextStyles.bodyS` (12.5 px / 400), color `textSecondary`, `maxLines: 2`, `overflow: ellipsis`.
4. `SizedBox(height: space12)`.
5. **Fila de micro-métricas (opcional).** Un `Row(spaceBetween)` con 2–3 micro-lecturas mono — p. ej. progreso de ciclo (`cycleProgress` como `%`), o un placeholder si no hay datos. Cada una: `labelSmall` `textTertiary` + valor `mono` `textSecondary`. Si no hay métricas significativas que mostrar, **omitir esta fila** antes que inventar datos falsos.

### 5.4 Ornamentos de hover

`HudCornerBrackets` (prompt 06) en las cuatro esquinas de la card, color = `bot.primaryColor`, brazo 14 px, grosor 1.5 px. **Solo visibles en hover** (opacidad 0 en reposo → 1 en hover, ver §7). Refuerzan la sensación de «unidad seleccionada».

---

## 6. Estados e interacciones (matriz — 00 §9)

| Estado | Qué cambia |
|---|---|
| `default` (activa) | Borde `glassBorder`, `elev1`, sin brackets, glow del color del bot tenue en la zona del avatar, avatar a todo color. |
| `hover` | Borde `bot.primaryColor` 1.5 px, `elev2` + `glowStatus(bot.primaryColor)`, escala 1.0→1.02, brackets de esquina aparecen, cursor pointer. `durFast`. |
| `pressed` | Escala 1.02→0.97 con `durInstant`; el glow se mantiene; al soltar dispara `onTap` (navega a `bot_detail`). |
| `focused` | Anillo de foco 2 px (`gold` o `cyan` según prompt 09/12) — la card es alcanzable por teclado y Enter equivale a tap. Nunca se elimina el indicador de foco. |
| `selected/active` | No hay selección persistente en la grilla; el estado «activa» de la unidad es el `default` con avatar a color. |
| `loading` | No aplica a la card individual: el estado de carga de la grilla es el skeleton del prompt 29. |
| `disabled` | No aplica como tal; la card siempre es navegable. |
| `suspended` (unidad `creditSuspended`) | **Tratamiento desaturado:** la card aplica un `ColorFiltered`/`saturation` reducido (~0.35) sobre el contenido visual (avatar + grid), el glow del color del bot se apaga, el borde se mantiene `glassBorder`. El `StatusTag` "SUSPENDED" en `warning` queda **a plena saturación** (es la información importante). Hover sigue funcionando pero el glow de hover es `glowStatus(warning)` atenuado. |
| `offline` (unidad offline/otros) | Igual tratamiento desaturado, glow apagado; `StatusTag` "OFFLINE" en `danger` a plena saturación. La unidad «no emite luz». |
| `error` | Si los datos del bot fallan, la card no se renderiza (lo gestiona la grilla); no hay estado de error por card individual. |

El estado de la unidad **nunca** se comunica solo por color: `StatusTag` lleva `HudStatusDot` (color) + label textual ("ACTIVE"/"SUSPENDED"/"OFFLINE"), y el tratamiento desaturado es un refuerzo adicional.

---

## 7. Animaciones

Tokens de motion (00 §7).

- **Entrada en grilla:** cada card entra escalonada **36 ms** después de la anterior (`flutter_animate` `.fadeIn(durBase)` + `.moveY(begin: 12, end: 0)`, curva `easeEntrance`). Máximo ~10 cards escalonadas; a partir de la 11.ª entran sin delay adicional para no demorar.
- **Hover:** borde, elevación, glow y escala 1.0→1.02 suben con `durFast`, curva `easeStandard`. La escala usa `AnimatedScale`/`Transform.scale` (nunca `width`/`height`).
- **Brackets de esquina:** `AnimatedOpacity` 0→1 con `durFast` al entrar en hover; al salir, 1→0 en ~65 % de esa duración (regla de salida del 00 §7.1).
- **Press:** `AnimatedScale` a 0.97 con `durInstant`; vuelve a 1.02 (si sigue en hover) o 1.0 al soltar.
- **`HudStatusDot`:** el dot de una unidad **activa** late suavemente (patrón reactor, ~1600 ms). El dot de una unidad **suspendida/offline** no late (sin energía) o late muy lento — coherente con «no emite».
- **Eye-tracking del avatar:** `RiveBotCardDisplay` ya recibe `_localMousePos`; es interacción causal, se mantiene siempre (incluso con reduced-motion).
- **Transición de estado** (si una unidad pasa de activa a suspendida en vivo): el desaturado y el apagado del glow animan con `durBase` `easeStandard`.
- **Reduced motion:** sin entrada escalonada (las cards aparecen con un crossfade único de 120 ms); sin escala en hover (solo cambia borde + glow); sin latido del `HudStatusDot`; el eye-tracking se conserva.

---

## 8. Accesibilidad

- Contraste: `textPrimary` (nombre) y `textSecondary` (descripción) sobre `glassSurface` ≥ 4.5:1; verificar también sobre la zona con glow teñido del color del bot — la descripción no debe quedar sobre el área de mayor glow.
- En estado desaturado (suspendida/offline) el texto del cuerpo sigue cumpliendo contraste: la desaturación se aplica al avatar y al grid, no al texto del nombre/descripción (que se mantiene legible).
- El estado de la unidad se comunica con color + `HudStatusDot` + label textual + desaturado: cuádruple refuerzo, nunca solo color.
- La card completa es un control: `Semantics(button: true, label: 'Unidad ${bot.name}, estado ${statusText}')`, navegable por teclado, Enter = tap.
- Foco visible siempre; orden de foco = orden de lectura de la grilla.
- Área de hit: toda la card (sobradamente > 32×32 px).
- El `HudIdTag` y la fila de micro-métricas son refuerzo informativo, no controles; no necesitan foco propio.
- El latido del `HudStatusDot` respeta reduced-motion y no parpadea a frecuencia incómoda (período ≥ 1600 ms).

---

## 9. Checklist de aceptación

- [ ] `BotCard` es un `HoloPanel` radio `radiusL` con `glassSurface`; cero `color: black@0.4` ni radio mágico.
- [ ] La zona superior tiene `HudGridTexture` + glow radial del color del bot bajo el avatar.
- [ ] El avatar `RiveBotCardDisplay` conserva el eye-tracking (`_localMousePos`).
- [ ] `StatusTag` con `HudStatusDot` en la esquina superior derecha; el `#FF8800` fue reemplazado por el token `warning`.
- [ ] `HudIdTag` mono con el ID de la unidad (formato `UNIT-XXXX`) en una esquina.
- [ ] Cuerpo: nombre `titleM`, descripción `bodyS` truncada a 2 líneas; fila de micro-métricas mono (o se omite si no hay datos reales).
- [ ] Hover: borde del color del bot, `elev2` + `glowStatus`, escala 1.0→1.02, brackets de esquina que aparecen.
- [ ] Press: escala 0.97 con `durInstant`.
- [ ] Foco: anillo visible, navegable por teclado, Enter = tap.
- [ ] Estados `suspended`/`offline`: avatar y grid desaturados, glow apagado, `StatusTag` a plena saturación.
- [ ] Entrada en grilla escalonada 36 ms (`easeEntrance`), máx. ~10 cards.
- [ ] `HudStatusDot` late solo en unidades activas.
- [ ] Con reduced-motion: sin escalonado ni escala ni latido; eye-tracking conservado; crossfade 120 ms.
- [ ] `Semantics(button)` con label que incluye nombre y estado.
- [ ] Contraste de nombre y descripción verificado, incluido sobre la zona de glow.
- [ ] Cero hex crudo, cero `fontFamily: 'Courier'`, cero magic numbers.
- [ ] Se ve correcto en la grilla en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores — `success`/`warning`/`danger`, glows), 02 (tipografía `titleM`/`bodyS`/`mono`), 03 (dimensiones, `radiusL`, elevación, glows), 04 (motion), 05 (iconografía), 06 (`HudCornerBrackets`, `HudStatusDot`, `HudIdTag`, `HudGridTexture`).
- **Componentes núcleo:** 07 (glow/glass), 11 (`StatusTag` / `AppBadge`), 12 (`HoloPanel`).
- **Shell:** 24 (layout y grilla del dashboard — define el `SliverGrid` que monta estas cards).
- **Piezas relacionadas:** 27 (al cambiar el filtro/búsqueda la grilla se reconstruye y re-escalona), 29 (estados vacío/carga de la grilla), 30/31 (la card navega al bot detail).
