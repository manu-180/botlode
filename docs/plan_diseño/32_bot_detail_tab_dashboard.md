# 32 — Bot Detail · Tab Dashboard (métricas de la unidad)

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Es el contenido del **tab índice 0** definido por el prompt 30.

---

## 1. Objetivo

Rediseñar el tab Dashboard del detalle de unidad: el panel de métricas operativas del bot. Hoy las métricas son `_StatCard`s sueltas con relleno semitransparente y `LinearProgressIndicator`. El rediseño las convierte en una **grilla bento de tarjetas de telemetría** con tickers numéricos animados, micro-tendencias y un mini-chart `fl_chart` de uso.

---

## 2. Archivos

- **Crear:** `lib/features/dashboard/presentation/widgets/tabs/bot_dashboard_tab.dart` — el panel completo del tab.
- **Crear:** `lib/features/dashboard/presentation/widgets/metric_card.dart` — tarjeta de métrica reutilizable.
- **Crear:** `lib/features/dashboard/presentation/widgets/usage_chart.dart` — mini-chart de uso con `fl_chart`.
- **Modificar:** `lib/features/dashboard/presentation/views/bot_detail_view.dart` — eliminar `_StatCard` y `_MonitorPanel`; el `_selectedTab == 0` renderiza `BotDashboardTab`.

---

## 3. Estado actual

- `_StatCard` es un `Container` con `padding 24`, `borderRadius circular(24)`, relleno `surface` al 50 %, una `Row` ícono+título, un valor, un `subValue` y un `LinearProgressIndicator` de 6 px.
- Las métricas aparecen apiladas en `_MonitorPanel` dentro de una `Column`/`SingleChildScrollView`.
- Hay un `AnimatedTicker` (`animated_ticker.dart`) ya usado para cifras.
- No hay grilla bento, ni `HoloPanel`, ni micro-tendencias, ni charts, ni estados de carga/vacío diferenciados.

---

## 4. Visión del rediseño

El tab Dashboard se lee como el **tablero de instrumentos de la unidad**. Una grilla bento de tarjetas de telemetría: cada métrica es un `HoloPanel` pequeño con un label técnico, un **valor grande que cuenta** hacia su número (`HudTicker`), y una micro-tendencia (flecha + delta porcentual). Las tarjetas tienen tamaños distintos —algunas ocupan 1 celda, una ocupa 2— formando un mosaico equilibrado. Si hay datos de uso a lo largo del tiempo, una tarjeta ancha aloja un **mini-chart de área** con gradiente `gradCyanData`. Un `HudDivider` etiquetado (`// RENDIMIENTO`, `// ACTIVIDAD`) separa secciones. Todo respira, todo es preciso, nada es plano.

---

## 5. Especificación visual

### 5.1 Layout del tab

- Raíz: `SingleChildScrollView` vertical (la columna derecha del prompt 30 ya da el alto). Padding 0 (el padding lo da el contenedor del prompt 30).
- Secciones de arriba hacia abajo:
  1. `HudDivider` con label `// RENDIMIENTO`.
  2. `space16`.
  3. **Grilla bento de métricas** (ver §5.2).
  4. `space32`.
  5. `HudDivider` con label `// ACTIVIDAD`.
  6. `space16`.
  7. **Tarjeta de chart de uso** (ver §5.4).

### 5.2 Grilla bento

- `Wrap`/`StaggeredGrid`/`GridView` de 4 columnas lógicas, gap `space20` horizontal y vertical.
- Tarjetas y sus spans:
  - `MENSAJES HOY` — span 1×1.
  - `SESIONES` — span 1×1.
  - `TIEMPO ACTIVO` — span 1×1.
  - `ESTADO DE CICLO` — span 1×1.
  - Una tarjeta destacada (`CONSUMO DEL CICLO` con barra de progreso) — span 2×1.
- En breakpoint mínimo (1024–1179 px) la grilla colapsa a 2 columnas lógicas y los spans 2× se vuelven 2 (ancho completo de 2 celdas).

### 5.3 `MetricCard`

- Contenedor: `HoloPanel` variante `default`, radio `radiusL`, borde `borderDefault`, padding `space20`, elevación `elev1`.
- Composición vertical:
  1. **Fila superior:** ícono 18 px (color de acento de la métrica) + `SizedBox(width: space8)` + label en `labelSmall` `textSecondary` UPPERCASE. A la derecha, opcional, un `HudIdTag` o nada.
  2. `space16`.
  3. **Valor:** `HudTicker` (prompt 06) en `numericTicker` `textPrimary`, figuras tabulares; cuenta hacia el valor con `durTicker`/`easeTicker`. Junto al valor, en línea base, una unidad pequeña en `bodyS` `textTertiary` (`msgs`, `min`, `%`).
  4. `space8`.
  5. **Micro-tendencia:** `Row` con ícono `trending-up`/`trending-down` 12 px + delta (`+12.4 %`) en `labelSmall`. Color `success` si sube, `danger` si baja, `textTertiary` si neutro/sin dato. Texto auxiliar `vs. ciclo previo` en `bodyS` `textTertiary`.
  - En la tarjeta destacada `CONSUMO DEL CICLO`: debajo del ticker, una barra de progreso fina (4 px, radio `radiusPill`) rellena con `gradGold`, fondo `surfaceHud`; el progreso = avance del ciclo (acotado a 1 ciclo, regla del modelo `Bot`).

### 5.4 `UsageChart` — tarjeta de chart

- Contenedor: `HoloPanel` ancho (ocupa todo el ancho del tab), padding `space24`, radio `radiusL`.
- Cabecera: label `// MENSAJES · ÚLTIMOS 14 DÍAS` en `labelSmall` `textSecondary` + a la derecha un `StatusTag`/chip pequeño con el total.
- Chart: `fl_chart` `LineChart` configurado como **área**:
  - Línea de 2 px color `cyan`.
  - Relleno bajo la línea con `gradCyanData` (linear `cyan` → `cyan` al 0 % alpha, vertical).
  - Sin grilla pesada: solo líneas horizontales hairline `borderSubtle` cada ~25 % del rango; sin bordes de caja.
  - Ejes: labels en `mono` `textTertiary`, mínimos (fechas abreviadas en X, valores en Y).
  - Punto activo al hover: dot `cyan` con glow + tooltip HUD (`HoloPanel` mini `surfaceRaised`, valor en `hudReadout`).
  - Curva suave (`isCurved: true`), sin puntos individuales salvo el activo.
- Seguir las reglas de charts del sistema: paleta de datos cyan/oro, nada de colores saturados extra, tooltips HUD coherentes.
- Altura del chart ~180 px.

---

## 6. Estados e interacciones

Matriz §9 aplicada al tab:

| Estado | Apariencia |
|---|---|
| `default` | Grilla con datos; tickers ya asentados en su valor final. |
| `hover` (sobre `MetricCard`) | Borde sube a `borderStrong`, elevación a `elev2`, glow suave de acento aparece; `durFast`. |
| `loading` | Cada `MetricCard` se reemplaza por un skeleton (prompt 14): bloque de label, bloque de valor grande, bloque de tendencia, todos con shimmer. El chart muestra un skeleton de área. La grilla mantiene la misma estructura para evitar salto de layout. |
| `empty` (sin datos de uso) | El chart se reemplaza por un `EmptyState` (prompt 15): ícono `bar-chart`, mensaje `Sin actividad registrada todavía`, sin CTA o con CTA `Ir a la terminal de prueba` que cambia al tab Dashboard→no aplica; las `MetricCard` muestran `0` con tendencia `--`. |
| `error` (fallo al cargar métricas) | `ErrorFeedbackCard` (prompt 16) ocupa el área del chart con mensaje y botón `Reintentar`; las tarjetas muestran `--`. |

- Las `MetricCard` no son clickeables (informativas); el hover es solo respuesta visual de profundidad.
- El chart sí es interactivo (hover sobre puntos).

---

## 7. Animaciones

- **Entrada del tab:** las `MetricCard` entran escalonadas (fade + translateY 12 px), 36 ms entre cada una, máximo ~10; curva `easeEntrance`, `durBase`. La tarjeta del chart entra última.
- **Tickers:** cada `HudTicker` cuenta desde 0 (o desde el valor previo) hacia el valor final con `durTicker` (900 ms) y `easeTicker` (`easeOutExpo`), figuras tabulares para no saltar layout.
- **Barra de progreso del ciclo:** se llena de 0 a su valor con `durSlow`, `easeStandard`.
- **Chart:** el área se "dibuja" con un reveal de izquierda a derecha (`ClipRect` animado) en `durDeliberate` (420 ms) `easeEntrance`; el relleno hace fade-in simultáneo.
- **Hover de card:** elevación/borde/glow con `durFast`.
- **Reduced motion** (`AppMotion.reduced`): sin escalonado (todas las tarjetas aparecen juntas con fade 120 ms); los tickers muestran el valor final directamente (sin conteo); el chart aparece sin reveal; la barra de progreso salta a su valor.

---

## 8. Accesibilidad

- Cada `MetricCard` es un `Semantics` con label compuesto: `"<label>: <valor> <unidad>, tendencia <delta>"`, de modo que el lector de pantalla lea el dato completo.
- El estado de tendencia (sube/baja) nunca depende solo del color: siempre ícono direccional + signo del delta.
- El chart expone un `Semantics(label: ...)` con un resumen textual (`Mensajes últimos 14 días, total N, pico el día X`) ya que el gráfico en sí no es accesible.
- Contraste: `numericTicker` `textPrimary` sobre el panel ≥ 12:1; labels `textSecondary` ≥ 4.5:1; deltas `success`/`danger` ≥ 3:1 sobre el panel. Verificar.
- Skeletons en `loading` se anuncian con `Semantics(label: "Cargando métricas")`.
- `ErrorFeedbackCard` en `error` con `liveRegion: true`.

---

## 9. Checklist de aceptación

- [ ] El tab usa una grilla bento de `MetricCard`s (`HoloPanel`) con spans mixtos 1× y 2×.
- [ ] Cada métrica muestra label, valor `HudTicker` animado y micro-tendencia con ícono + delta de color.
- [ ] La tarjeta `CONSUMO DEL CICLO` tiene barra de progreso `gradGold` acotada a 1 ciclo.
- [ ] Hay un mini-chart `fl_chart` de área con línea `cyan` y relleno `gradCyanData`, tooltips HUD.
- [ ] Hay `HudDivider`s etiquetados separando secciones.
- [ ] Estado loading muestra skeletons que conservan el layout.
- [ ] Estado empty muestra `EmptyState` en el área del chart y `0`/`--` en las tarjetas.
- [ ] Estado error muestra `ErrorFeedbackCard` con reintento.
- [ ] La grilla colapsa a 2 columnas en el breakpoint mínimo.
- [ ] Cero hex sueltos, cero magic numbers: todo por tokens.
- [ ] Reduced motion: sin escalonado, sin conteo de tickers, sin reveal de chart.
- [ ] Compila y se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores, `gradGold`, `gradCyanData`), 02 (`numericTicker`, `labelSmall`, `mono`, `bodyS`), 03 (`space*`, `radius*`, `elev*`), 04 (`dur*`, `easeTicker`, reduced-motion), 05 (iconografía), 06 (`HudDivider`, `HudTicker`, `HudIdTag`).
- **Núcleo:** 11 (`StatusTag`/chips), 12 (`HoloPanel`), 14 (skeletons), 15 (`EmptyState`), 16 (`ErrorFeedbackCard`).
- **Shell / detalle:** 30 (layout y tab bar que aloja este panel).
- **Librería externa:** `fl_chart` (ya en `pubspec.yaml`).
