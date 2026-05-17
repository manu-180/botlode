# 25 — Dashboard · Panel HUD de crédito

> Depende del archivo **00 — README · Visión y Sistema de Diseño**. Leerlo completo antes de ejecutar. Todos los valores se referencian **por token**.

---

## 1. Objetivo

Rediseñar el panel HUD de crédito del Dashboard: la pieza **WOW** de la «Bahía de Carga». Hoy es un `Container` negro con un ticker, una barra lisa de 4 px y un botón. Se transforma en un **instrumento de medición sci-fi**: un panel de vidrio biselado con brackets, scanlines, una cifra animada mono, una barra de progreso **segmentada tipo ecualizador** que cambia de color por estado, una barra-reactor lateral que late, y micro-lecturas mono. Debe leerse como el panel de combustible de una nave.

---

## 2. Archivos

- **Modificar:** `lib/features/dashboard/presentation/views/dashboard_view.dart` — el `Container` inline del panel de crédito (líneas del `Container` con `BoxShadow` `statusColor`). Extraer a un widget propio `_CreditHudPanel` en el mismo archivo o en `lib/features/dashboard/presentation/widgets/credit_hud_panel.dart`.
- **Consumir (no crear):** `HoloPanel` (12), `HudCornerBrackets` / `HudScanlines` / `HudTicker` / `HudReactorBar` / `HudGridTexture` / `ChamferBorder` (06), `app_colors.dart` (01), `AppTextStyles` (02), `app_dimens.dart` (03), `app_motion.dart` (04). El `AnimatedTicker` actual (`lib/core/ui/widgets/animated_ticker.dart`) queda **reemplazado** por `HudTicker` del prompt 06.
- **El botón de acción** que va integrado abajo lo especifica el **prompt 26**; aquí solo se reserva su slot.

---

## 3. Estado actual

Un `Container` con `padding: (h20, v12)`, `color: black@0.5`, `borderRadius: 16`, `border: statusColor@0.5`, `boxShadow: statusColor@0.1 blur 20`. Dentro un `Row`:

- `Column(crossAxisAlignment: end)`: label (`"USO DE CRÉDITO"` o `"!!! CRÉDITO AGOTADO !!!"` en crítico) 10 px; un `Row` con `AnimatedTicker(value: totalDebt, prefix: "$ ")` 24 px + `" / $limit"` en `textSecondary@0.5`; una `LinearProgressIndicator` de 150×4 px con `value: usagePercent`.
- `SizedBox(24)` + `_SmartActionButton`.

Datos disponibles desde `billingState`: `totalDebt`, `creditLimit`, `usagePercentage`, `statusColor`, `health` (`FinanceHealth.critical`), `primaryCard`.

Problemas: barra lisa sin carácter; color de estado aplicado a mano (`statusColor`); ticker en Oxanium (debería ser mono tabular); sin ornamento HUD; el panel no «late»; copy y glow no escalonan por umbral de forma sistemática.

---

## 4. Visión del rediseño

El panel de crédito es un **instrumento**, no una caja informativa. Vidrio esmerilado con cantos biselados (`chamfer`), brackets de esquina que lo enmarcan como hardware, una retícula técnica de fondo y scanlines microscópicas. La cifra de crédito es grande, mono, tabular, y **cuenta** hacia su valor al cargar. Debajo, una barra **segmentada** —decenas de segmentos finos verticales tipo ecualizador— se «llena» según el uso y cambia de color `success → warning → danger`. A un lado, una barra-reactor vertical late con glow indicando «sistema con energía». Tres lecturas mono pequeñas dan contexto («LÍMITE», «DISPONIBLE», «CICLO»). En estado crítico todo el instrumento vira a rojo, el copy grita «CRÉDITO AGOTADO» y el glow se intensifica. El botón de acción (prompt 26) vive integrado abajo, dentro del mismo panel.

---

## 5. Especificación visual

### 5.1 Contenedor

- Base: `HoloPanel` (prompt 12) con forma **biselada**: aplicar `ChamferBorder` (`chamferM = 12`, esquinas a 45°).
- Relleno: `glassSurface` con blur (glassmorphism del prompt 12); por encima, `HudGridTexture` (prompt 06) a `opacity 0.04`.
- Borde: 1 px. Color según estado (§6): `borderGold` (saludable) / `warning@0.5` (advertencia) / `danger@0.6` (crítico).
- Sombra: `elev1` + **un** glow de estado: `glowGold` / `glowStatus(warning)` / `glowStatus(danger)`. Nunca dos glows.
- `HudCornerBrackets` (06) en las cuatro esquinas, brazo 16 px, color = color de borde del estado.
- `HudScanlines` (06) overlay `opacity 0.035`, `IgnorePointer`.
- Padding interno: `EdgeInsets.all(space20)`.
- Ancho: en modo header ancho (prompt 24 §5.3), intrínseco ~360–420 px; en modo apilado, ancho completo de la banda.

### 5.2 Layout interno (`Row`)

`Row(crossAxisAlignment: stretch)`:

- **Izquierda — `HudReactorBar`** (06): barra vertical fina de ~6 px de ancho, alto = alto del contenido. Late (pulso de glow 0.6↔1.0 a ~1600 ms). Color = color del estado. `SizedBox(width: space16)` de separación.
- **Centro — columna de datos** (`Expanded`, `Column`, `crossAxisAlignment: start`):
  1. **Label de estado.** `Text` con estilo `AppTextStyles.label` (13 px, uppercase, tracking +1.4), color del estado. Copy: saludable/advertencia → `"USO DE CRÉDITO"`; crítico → `"!!! CRÉDITO AGOTADO !!!"`.
  2. `SizedBox(height: space8)`.
  3. **Cifra principal.** `HudTicker` (prompt 06): cuenta `totalDebt` con estilo `AppTextStyles.numericTicker` (28 px, JetBrains Mono, **figuras tabulares**, peso 700), color del estado, `prefix: "$ "`. A su derecha, en la misma línea (`Row`, `crossAxisAlignment: baseline`), el límite: `Text(" / $${creditLimit.toInt()}")` con estilo `hudReadout` color `textTertiary`. La cifra grande es el oro/valor: en estado saludable el color del estado es `gold`.
  4. `SizedBox(height: space12)`.
  5. **Barra segmentada (ecualizador).** Ver §5.3.
  6. `SizedBox(height: space12)`.
  7. **Micro-lecturas mono.** Un `Row(spaceBetween)` con tres mini-bloques, cada uno una `Column(crossAxisAlignment: start)`:
     - `LÍMITE` (label `labelSmall` `textTertiary`) + valor `$${creditLimit.toInt()}` (`hudReadout` `textSecondary`).
     - `DISPONIBLE` + valor `$${(creditLimit - totalDebt).clamp(0, …).toInt()}` (`hudReadout`, color del estado).
     - `USO` + valor `${(usagePercentage*100).round()}%` (`hudReadout` `textSecondary`).
  8. `SizedBox(height: space16)`.
  9. **Slot del botón de acción inteligente** — lo rinde el prompt 26 (`SmartActionButton`), ancho completo del panel, integrado como última fila de la columna.

### 5.3 Barra de progreso segmentada

No una `LinearProgressIndicator` lisa. Es un **ecualizador**:

- Una fila horizontal de **N segmentos** finos verticales (`N` fijo, p. ej. 28 segmentos). Cada segmento: ancho ~4 px, alto 10 px, separación 3 px, esquinas `radiusXS` muy ligeras. Implementar con un `Row` de N `Container`, o un `CustomPainter` (preferible para rendimiento si N es alto).
- Cantidad de segmentos «encendidos» = `round(usagePercentage * N)`.
- Segmento encendido: color del estado, con un glow leve (`glowStatus`); segmento apagado: `surfaceHud` con borde `borderSubtle`.
- El color de los segmentos encendidos se calcula por **umbral de uso**, independiente de `statusColor` heredado, para que la barra cuente su propia historia: `usagePercentage ≤ 0.70` → `success`; `0.70 < usagePercentage < 1.0` → `warning`; `≥ 1.0` (agotado) → `danger`. Los últimos segmentos hacia el extremo derecho pueden teñirse de `warning`/`danger` aun cuando el global sea `success` (zona de «reserva»), efecto ecualizador.
- Animación de llenado: al montar/actualizar, los segmentos se encienden secuencialmente de izquierda a derecha (ver §7).

### 5.4 Tipografía mono

Toda lectura numérica (cifra grande, límite, micro-lecturas) usa **JetBrains Mono con figuras tabulares** (`numericTicker` / `hudReadout` / `mono` del prompt 02). Cero números en Oxanium en este panel — es un instrumento de datos.

---

## 6. Estados e interacciones (matriz — 00 §9)

El panel tiene tres estados de **salud financiera** (derivados de `billingState.health` y `usagePercentage`):

| Estado | Disparador | Color | Borde | Glow | Copy del label | Reactor |
|---|---|---|---|---|---|---|
| **Saludable** | `usagePercentage ≤ 0.70` | `gold` (cifra/segmentos vía `success` en barra) | `borderGold` | `glowGold` suave | `"USO DE CRÉDITO"` | late lento (~1800 ms) |
| **Advertencia** | `0.70 < usagePercentage < 1.0` | `warning` | `warning@0.5` | `glowStatus(warning)` | `"USO DE CRÉDITO"` (label en `warning`) | late medio (~1600 ms) |
| **Crítico** | `health == FinanceHealth.critical` o `usagePercentage ≥ 1.0` | `danger` | `danger@0.6` | `glowStatus(danger)` más intenso | `"!!! CRÉDITO AGOTADO !!!"` | late rápido (~1100 ms) |

Otros estados de §9:

| Estado | Comportamiento |
|---|---|
| `loading` (billing aún sin valor) | El panel muestra una versión skeleton: contenedor presente, cifra y barra como `SkeletonBase` (prompt 14). No mostrar `$0` falso. |
| `hover` | El panel no es clickeable como un todo; solo el botón interno reacciona. Sin hover de panel. |
| `focused` | El foco entra al botón de acción interno (prompt 26). El panel en sí no toma foco. |
| `error` (billing falla) | Mostrar el patrón de error del prompt 16 en el slot, con copy «No se pudo leer el estado de crédito» y acción de reintento. |

El panel **nunca comunica el estado solo por color**: siempre cambia también el copy del label y, en crítico, los signos `!!!`.

---

## 7. Animaciones

Tokens de motion (00 §7).

- **Entrada del panel:** con la banda header del prompt 24 (fade + `moveY` `easeEntrance`).
- **Conteo de la cifra:** `HudTicker` cuenta de 0 (o del valor previo) a `totalDebt` en `durTicker` (900 ms) con curva `easeTicker` (`easeOutExpo`). Figuras tabulares evitan saltos de ancho.
- **Llenado de la barra segmentada:** al montar o al cambiar `usagePercentage`, los segmentos se encienden de izquierda a derecha, 14 ms entre segmentos, cada uno con un fade-in `durFast`. Total acotado: si N=28 → ~390 ms.
- **Transición entre estados de salud:** al cambiar de saludable→advertencia→crítico, el color de borde, glow, segmentos y label hacen `crossfade`/`AnimatedContainer` con `durBase`, curva `easeStandard`. Sin salto brusco de color.
- **Reactor lateral (`HudReactorBar`):** latido de opacidad 0.6↔1.0; el período depende del estado (1800 / 1600 / 1100 ms — más rápido = más urgente).
- **Crítico:** además del latido del reactor, el borde del panel puede tener un pulso muy sutil de glow `danger` (no un flash agresivo: 0.30↔0.45 de opacidad del glow, `durSlow` ida y vuelta). El pulso de **urgencia fuerte** vive en el botón (prompt 26), no en el panel.
- **Reduced motion:** la cifra aparece directa en su valor final (sin conteo); la barra se pinta llena de una sola vez; sin latido del reactor; sin pulso de glow crítico. La transición de estado se reduce a crossfade 120 ms.

---

## 8. Accesibilidad

- Contraste: la cifra grande y el label sobre `glassSurface` ≥ 4.5:1 en los tres colores de estado; verificar `warning` y `danger` sobre vidrio (ajustar opacidad del vidrio si hace falta).
- El estado **nunca** depende solo del color: label textual (`"USO DE CRÉDITO"` vs `"!!! CRÉDITO AGOTADO !!!"`), porcentaje numérico explícito y, en crítico, signos `!!!`.
- `Semantics` del panel: un label que resuma «Crédito usado: $X de $Y, estado: saludable/advertencia/crítico», como `liveRegion` para que un cambio a crítico se anuncie.
- La barra segmentada no es solo decorativa: su valor también se expresa en la micro-lectura `USO %` y en el `Semantics`.
- El reactor que late respeta reduced-motion; el latido nunca supera frecuencias incómodas (período mínimo 1100 ms — sin parpadeo rápido que pueda molestar).
- El botón interno mantiene su propio foco/área de hit (prompt 26).

---

## 9. Checklist de aceptación

- [ ] El panel es un `HoloPanel` con `ChamferBorder` (`chamferM`), `HudCornerBrackets`, `HudScanlines` y `HudGridTexture`.
- [ ] La cifra de crédito usa `HudTicker` en `numericTicker` (JetBrains Mono, figuras tabulares); cuenta al cargar en `durTicker`.
- [ ] El `AnimatedTicker` anterior ya no se usa en este panel.
- [ ] La barra de progreso es **segmentada** (ecualizador de ~28 segmentos finos), no una barra lisa.
- [ ] Los segmentos cambian de color por umbral de uso: `≤0.70` `success`, `<1.0` `warning`, `≥1.0` `danger`.
- [ ] Hay un `HudReactorBar` lateral que late, con período según estado.
- [ ] Tres micro-lecturas mono: LÍMITE / DISPONIBLE / USO.
- [ ] Tres estados de salud (saludable/advertencia/crítico) cambian color, borde, glow y **copy**; el copy crítico es "!!! CRÉDITO AGOTADO !!!".
- [ ] El slot del botón de acción inteligente (prompt 26) está integrado abajo, ancho completo.
- [ ] Estado `loading`: skeleton del prompt 14; nunca `$0` falso. Estado `error`: patrón del prompt 16.
- [ ] El llenado de la barra y las transiciones de estado animan con tokens; reduced-motion pinta todo estático y la cifra directa.
- [ ] `Semantics` con `liveRegion` resume el estado de crédito.
- [ ] Cero hex crudo, cero números en Oxanium, cero magic numbers.
- [ ] Se ve correcto en 1280×720 y 1024×600 (en este último, apilado bajo el título — ver prompt 24).
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores), 02 (tipografía mono), 03 (dimensiones, `chamferM`, elevación, glows), 04 (motion), 06 (primitivas HUD: brackets, scanlines, `HudTicker`, `HudReactorBar`, `HudGridTexture`, `ChamferBorder`).
- **Componentes núcleo:** 07 (glow/glass), 12 (`HoloPanel`), 14 (skeleton del estado loading), 16 (patrón de error).
- **Shell:** 24 (layout del dashboard — define dónde y cómo se ubica este panel).
- **Pieza acoplada:** 26 (botón de acción inteligente — vive dentro de este panel).
