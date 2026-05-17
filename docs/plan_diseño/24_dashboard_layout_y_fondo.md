# 24 — Dashboard · Layout general y fondo («Bahía de Carga»)

> Depende del archivo **00 — README · Visión y Sistema de Diseño**. Leerlo completo antes de ejecutar. Todos los valores se referencian **por token**.

---

## 1. Objetivo

Rediseñar la **estructura de layout y el fondo** del Dashboard `DashboardView` («BAHÍA DE CARGA»): la composición vertical (fondo → header → toolbar → grilla), el comportamiento responsive entre 1024 px y 1280 px+, el ancho máximo de contenido y el scroll con toolbar sticky. Este prompt **no** rediseña las piezas internas (panel de crédito → 25, botón inteligente → 26, toolbar → 27, bot card → 28, vacío/carga → 29): define el esqueleto que las contiene.

---

## 2. Archivos

- **Modificar:** `lib/features/dashboard/presentation/views/dashboard_view.dart` — el `Scaffold`, el `Stack` raíz, el `Container` de fondo radial, el `Padding(32)` y la `Column`. La grilla `GridView.builder` pasa a vivir dentro de un `CustomScrollView`/sliver.
- **Consumir (no crear):** `AppBackground` (prompt 08), `PageTitle` (prompt 21), `HoloPanel` (12), `app_dimens.dart` (03), `app_motion.dart` (04).
- **Referenciar (no implementar aquí):** prompts 25, 26, 27, 28, 29.

---

## 3. Estado actual

`Scaffold` → `Stack`:

1. `Positioned.fill` con un `Container` de `RadialGradient(center: (-0.8,-0.8), radius: 1.5, colors: [surface@0.8, background])` — fondo radial plano único.
2. `Padding(EdgeInsets.all(32))` → `Column(crossAxisAlignment: start)`:
   - **Header:** `Row(spaceBetween)` con `PageTitle(style: techBar)` "BAHÍA DE CARGA" + el panel de crédito (un `Container` inline con el ticker, barra y `_SmartActionButton`).
   - `SizedBox(24)` + `DashboardToolbar()` + `SizedBox(24)`.
   - `Expanded` con `botsAsync.when(...)`: `_DashboardSkeleton`, error, o `GridView.builder` (`maxCrossAxisExtent: 400`, `aspectRatio: 1.4`, spacing 20) / `_buildEmptyState`.

Problemas: fondo radial de una sola capa (no es el sistema `AppBackground`); el header mete header + panel de crédito en una sola fila sin plan responsive (en 1024 px el panel de crédito aprieta al título); la toolbar **no es sticky** — scrollea con la grilla; sin ancho máximo de contenido; padding mágico `32`.

---

## 4. Visión del rediseño

La «Bahía de Carga» es la **sala de control del hangar**. El fondo es el sistema `AppBackground` de capas (vacío + glow radial ambiental + grid técnico), nunca un gradiente plano. La pantalla se organiza en tres bandas verticales nítidas: **header** (identidad de pantalla + instrumento de crédito), **toolbar** (que queda *clavada* arriba al hacer scroll, como una consola fija) y **grilla scrollable** de unidades. El layout responde con elegancia: en pantallas anchas el panel de crédito va a la derecha del título; al angostarse, baja debajo del título a todo el ancho. El contenido tiene un ancho máximo para no estirarse infinitamente en monitores grandes. Las bandas entran escalonadas al cargar la pantalla.

---

## 5. Especificación visual

### 5.1 Capa de fondo

Reemplazar el `Container` con `RadialGradient` por **`AppBackground`** (prompt 08) en `Positioned.fill`: vacío base + glow radial ambiental (puede conservar el sesgo del glow hacia la esquina superior izquierda, `Alignment(-0.8,-0.8)`, ahora vía el token de glow del prompt 08) + textura de grid técnica sutil. Nada de fondo plano.

### 5.2 Contenedor de contenido

- Padding de pantalla: `EdgeInsets.symmetric(horizontal: space32, vertical: space32)` (token, no `32` mágico).
- **Ancho máximo de contenido:** envolver el contenido en un `Center` → `ConstrainedBox(maxWidth: 1600)`. En monitores ultra-anchos el contenido no se estira infinito; entre 1024 y 1600 px ocupa todo el ancho disponible menos el padding.
- El contenido es un `CustomScrollView` (ver §5.5) para soportar el toolbar sticky.

### 5.3 Banda 1 — Header

Un `LayoutBuilder` decide el arreglo según el ancho disponible (`constraints.maxWidth`, ya descontado el padding):

- **Modo ancho (≥ 1180 px disponible):** `Row(mainAxisAlignment: spaceBetween, crossAxisAlignment: start)`:
  - Izquierda: `PageTitle(title: "BAHÍA DE CARGA", subtitle: "Gestión operativa de unidades autónomas", style: PageTitleStyle.techBar)`.
  - Derecha: el **panel HUD de crédito** (prompt 25), con un ancho intrínseco de ~360–420 px.
- **Modo angosto (< 1180 px disponible — incluye el rango ~1024 px):** `Column(crossAxisAlignment: start)`:
  - `PageTitle` arriba.
  - `SizedBox(height: space20)`.
  - El panel de crédito **a todo el ancho** debajo.
- El umbral 1180 px se elige para que a 1024 px de ventana (≈ 960 px disponibles tras padding) el panel de crédito siempre vaya apilado y nunca aplaste al título.

### 5.4 Banda 2 — Toolbar sticky

- `SizedBox(height: space24)` entre header y toolbar.
- La `DashboardToolbar` (prompt 27) se monta como **sliver sticky**: un `SliverPersistentHeader(pinned: true)` cuyo `delegate` rinde el toolbar a una altura fija (la define el prompt 27, ~64 px). Queda clavado en `z` = `zSticky` al scrollear la grilla.
- El toolbar sticky, al estar pinned, dibuja una sombra/gradiente de separación cuando hay contenido scrolleado por debajo: un `elev1` suave en el borde inferior del toolbar que aparece solo cuando `shrinkOffset > 0`, para despegarlo visualmente de la grilla.

### 5.5 Banda 3 — Grilla scrollable

- `SizedBox`/spacing `space24` entre toolbar y grilla (gestionado dentro del `CustomScrollView` como `SliverPadding`).
- La grilla es un `SliverGrid` con `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 400, childAspectRatio: 1.4, crossAxisSpacing: space20, mainAxisSpacing: space20)` (valores actuales, ahora por token de espaciado).
- `botsAsync.when(...)` decide el sliver: `SliverGrid` de `BotCard` (prompt 28), o el sliver de skeleton/empty del prompt 29. El estado `error` usa el patrón de error del prompt 16 dentro de un `SliverFillRemaining`.
- Estructura del `CustomScrollView`:
  1. `SliverToBoxAdapter` → header (banda 1).
  2. `SliverToBoxAdapter` → `SizedBox(space24)`.
  3. `SliverPersistentHeader(pinned: true)` → toolbar (banda 2).
  4. `SliverPadding(top: space24)` envolviendo el `SliverGrid` (banda 3).
- El scroll vertical es del `CustomScrollView` completo: el header scrollea fuera de vista, el toolbar queda pinned, la grilla scrollea bajo él.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` | Tres bandas visibles; toolbar pinned. |
| `loading` (bots) | La grilla muestra el sliver de skeleton del prompt 29; header y toolbar ya visibles e interactivos. |
| `empty` | La grilla muestra el `EmptyState` del prompt 29 (sin unidades o sin resultados de búsqueda). |
| `error` (bots) | `SliverFillRemaining` con el patrón de error del prompt 16; header y toolbar siguen presentes. |
| `scrolled` | Toolbar pinned con sombra de separación `elev1` visible; header fuera de vista. |
| `hover`/`pressed`/`focused`/`disabled` | No aplican al layout en sí; los gestionan las piezas internas. |
| Responsive ancho↔angosto | Al cruzar el umbral 1180 px el header conmuta `Row`↔`Column` con una transición de `durBase` (sin salto brusco). |

---

## 7. Animaciones

Tokens de motion (00 §7).

- **Entrada de pantalla:** al montar `DashboardView`, las tres bandas entran escalonadas: header (delay 0), toolbar (delay 80 ms), grilla (delay 160 ms). Cada banda: `.fadeIn(durBase)` + `.moveY(begin: 12, end: 0)`, curva `easeEntrance`. La grilla, además, escalona sus cards (eso lo define el prompt 28: 36 ms entre cards).
- **Conmutación responsive del header:** al cruzar el umbral, animar el cambio `Row`↔`Column` con `AnimatedSize` + crossfade `durBase`, curva `easeStandard`.
- **Sombra del toolbar sticky:** `AnimatedOpacity` de la sombra `elev1`, `durFast`, según `shrinkOffset > 0`.
- **Transición de entrada/salida de la pantalla** (al venir del login o navegar entre secciones): la provee el shell del prompt 20.
- **Reduced motion:** sin escalonado de bandas — crossfade único de 120 ms; la conmutación responsive es instantánea; sin sombra animada (la sombra aparece/desaparece sin transición).

---

## 8. Accesibilidad

- El fondo `AppBackground` mantiene contraste suficiente para todo el contenido (verificado en el prompt 08).
- Orden de foco lógico: header (panel de crédito → su botón) → toolbar (search → tabs) → grilla (cards en orden de lectura). El `CustomScrollView` debe permitir que el foco de teclado siga el orden visual.
- El toolbar pinned no debe atrapar el foco ni tapar contenido enfocado: al tabular hacia una card que queda bajo el toolbar, el scroll debe ajustar para que la card enfocada sea visible.
- Reduced motion respetado (§7).
- Targets de las piezas internas: definidos en sus prompts; el layout solo garantiza que el padding `space32` no recorte áreas de hit.
- En 1024×600 todo el contenido es accesible vía scroll; nada queda cortado fuera de viewport sin posibilidad de alcanzarlo.

---

## 9. Checklist de aceptación

- [ ] El fondo es `AppBackground` (prompt 08), no un `RadialGradient` plano.
- [ ] El contenido vive dentro de un `ConstrainedBox(maxWidth: 1600)` centrado.
- [ ] Padding de pantalla `space32` por token (cero `32` mágico).
- [ ] El header conmuta `Row` (≥1180 px disp.) ↔ `Column` (<1180 px) sin que el panel de crédito aplaste al título en 1024 px.
- [ ] La toolbar es un `SliverPersistentHeader(pinned: true)` en `zSticky`: queda clavada arriba al scrollear.
- [ ] El toolbar pinned muestra una sombra `elev1` de separación solo cuando hay contenido scrolleado debajo.
- [ ] La grilla es un `SliverGrid` (`maxCrossAxisExtent: 400`, `aspectRatio: 1.4`, spacing `space20`).
- [ ] `loading`/`empty`/`error` se resuelven con los slivers/patrones de los prompts 29 y 16.
- [ ] Las tres bandas entran escalonadas (`easeEntrance`); con reduced-motion, crossfade 120 ms.
- [ ] Orden de foco header → toolbar → grilla; el toolbar pinned no tapa contenido enfocado.
- [ ] Se ve correcto y todo es alcanzable en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 03 (dimensiones — `space*`, `zSticky`, `elev1`), 04 (motion), 08 (`AppBackground`).
- **Componentes núcleo:** 12 (`HoloPanel` — base del panel de crédito y toolbar), 16 (patrón de error).
- **Shell:** 20 (transición de ruta), 21 (`PageTitle` `techBar`).
- **Piezas internas (ejecutar después de este esqueleto):** 25 (panel de crédito), 26 (botón inteligente), 27 (toolbar), 28 (bot card), 29 (vacío/carga).
