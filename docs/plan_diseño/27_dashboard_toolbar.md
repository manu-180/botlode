# 27 — Dashboard · Toolbar (búsqueda + filtros)

> Depende del archivo **00 — README · Visión y Sistema de Diseño**. Leerlo completo antes de ejecutar. Todos los valores se referencian **por token**.

---

## 1. Objetivo

Rediseñar el toolbar del Dashboard: la consola de búsqueda y filtrado de la «Bahía de Carga». Es el `DashboardToolbar` (`lib/features/dashboard/presentation/widgets/dashboard_toolbar.dart`) — campo de búsqueda + tres tabs de filtro con contadores. Se eleva a un **panel HUD compacto** con campo de búsqueda del sistema, un filtro segmentado de chips con indicador deslizante y `HudStatusDot` de color. Va montado como sliver sticky por el prompt 24.

---

## 2. Archivos

- **Modificar:** `lib/features/dashboard/presentation/widgets/dashboard_toolbar.dart` — toda la implementación visual del toolbar.
- **Consumir (no crear):** `HoloPanel` (12), `AppTextField` variante search (10), `AppBadge` / status tags (11), `HudStatusDot` (06), `app_colors.dart` (01), `AppTextStyles` (02), `app_dimens.dart` (03), `app_motion.dart` (04).
- **Estado:** el filtro y la query viven en `dashboardController` / `filteredBotsProvider` (ya existentes). Este prompt solo redibuja; no cambia la lógica de filtrado.

---

## 3. Estado actual

El `DashboardToolbar` provee un campo de búsqueda con placeholder `"BUSCAR UNIDAD..."` y tres tabs de filtro `TODOS` / `ACTIVOS` / `OFFLINE`, cada uno con un contador. El dashboard lo monta entre dos `SizedBox(24)` y **scrollea con la grilla** (no es sticky).

Problemas: el toolbar no es sticky (prompt 24 lo corrige montándolo como `SliverPersistentHeader`); búsqueda y tabs probablemente con estilos inline; sin indicador deslizante de selección; sin `HudStatusDot`; sin tratamiento de panel HUD; comportamiento al achicar la ventana no definido.

---

## 4. Visión del rediseño

El toolbar es una **consola de instrumentos fija**. Un panel HUD compacto, horizontal, de altura fija, que queda clavado bajo el header al scrollear. A la izquierda, un campo de búsqueda del sistema con ícono de lupa, ancho flexible. A la derecha, un **filtro segmentado**: tres chips dentro de un riel, con un **indicador deslizante** que se desliza al chip activo (no un cambio brusco de color). Cada chip lleva su `HudStatusDot` de color (neutro/verde/rojo) y un `AppBadge` con el conteo. Al achicar la ventana, el campo de búsqueda se encoge y los filtros mantienen su tamaño — la búsqueda cede espacio, los filtros no.

---

## 5. Especificación visual

### 5.1 Contenedor

- Base: `HoloPanel` (prompt 12) compacto, altura **fija 64 px** (la usa el `SliverPersistentHeader` del prompt 24 como `maxExtent`/`minExtent`).
- Fondo: `glassSurface` con blur (glassmorphism); cuando está pinned y hay scroll debajo, el prompt 24 le añade la sombra `elev1` de separación.
- Borde: `borderDefault` 1 px; radio `radiusL` (consistente con paneles).
- Padding interno: `EdgeInsets.symmetric(horizontal: space16, vertical: space12)`.
- Layout: `Row(crossAxisAlignment: center)` — izquierda flexible, derecha intrínseca.

### 5.2 Izquierda — campo de búsqueda

- `Expanded` (flexible) → `AppTextField` variante **search** (prompt 10):
  - `prefixIcon`: ícono de lupa del set (prompt 05).
  - `placeholder: "BUSCAR UNIDAD POR ID O NOMBRE..."` (estilo `bodyS` `textTertiary`).
  - Texto escrito: estilo `bodyM` `textPrimary`, o `mono` si se quiere acento terminal — usar `bodyM` para legibilidad.
  - `suffixIcon`: ícono de limpiar (×) que aparece solo cuando hay texto; al pulsarlo, vacía la query.
  - Alto del campo: 40 px (cabe holgado en los 64 px del toolbar con el padding `space12`).
  - Conecta `onChanged` a la query de `dashboardController`.
- `SizedBox(width: space20)` de separación con el filtro.
- **Ancho mínimo del campo:** `ConstrainedBox(minWidth: 180)`. Al achicar la ventana, el `Expanded` cede ancho hasta este mínimo; por debajo, el campo no se encoge más (los filtros mantienen su tamaño — ver §5.4).

### 5.3 Derecha — filtro segmentado

Un control segmentado de tres chips dentro de un riel:

- **Riel:** `Container` con fondo `surfaceHud`, borde `borderSubtle` 1 px, radio `radiusPill`, padding interno `space4`. Altura 36 px.
- **Indicador deslizante:** un `AnimatedPositioned`/`AnimatedAlign` dentro del riel — un `Container` con fondo de acento (`gold@0.16` o `borderGold` translúcido) y borde `borderGold`, radio `radiusPill`, que se ubica detrás del chip activo y **se desliza** al cambiar de selección.
- **Tres chips** (`TODOS` / `ACTIVOS` / `OFFLINE`), cada uno un `Row(mainAxisSize: min)` clickeable, padding `EdgeInsets.symmetric(horizontal: space12, vertical: space4)`:
  1. `HudStatusDot` (prompt 06): `TODOS` → punto neutro `textSecondary` (sin halo); `ACTIVOS` → `success` con halo de glow; `OFFLINE` → `danger` con halo.
  2. `SizedBox(width: space8)`.
  3. Label: estilo `AppTextStyles.label` (uppercase). Color: chip activo → `textPrimary` (más brillante); inactivo → `textSecondary`.
  4. `SizedBox(width: space8)`.
  5. `AppBadge` (prompt 11) con el conteo: chip activo → badge de acento (`gold`/`success`/`danger` según el chip); inactivo → badge neutro `surfaceRaised` con texto `textTertiary`.
- Gap entre chips: `space4` (los separa el padding del riel, no un `SizedBox` grande).

### 5.4 Comportamiento responsive

- El `Row` raíz: izquierda `Expanded` (búsqueda), derecha tamaño intrínseco (filtro).
- Al **angostarse** la ventana: el `Expanded` reduce el ancho del campo de búsqueda hasta su `minWidth: 180`. El filtro segmentado **nunca** se encoge ni se reordena.
- Si el ancho disponible es tan corto que ni con la búsqueda en 180 px entra el filtro completo, el campo de búsqueda puede colapsar a **modo ícono** (un `AppButton` icon de lupa que, al pulsarse, expande el campo sobre el toolbar) — solo si fuera necesario en el mínimo 1024 px. Verificar en 1024 px: con el panel de crédito apilado (prompt 24), el toolbar tiene ~960 px disponibles; búsqueda 180 px + filtro (~330 px) entra cómodo, así que el modo ícono normalmente **no** se activa. Documentarlo como salvaguarda.

---

## 6. Estados e interacciones (matriz — 00 §9)

### Campo de búsqueda

| Estado | Qué cambia |
|---|---|
| `default` | Placeholder visible, ícono de lupa `textTertiary`. |
| `hover` | Borde `borderStrong`, cursor texto. `durFast`. |
| `focused` | Anillo de foco 2 px (`cyan`/`gold` según prompt 10); ícono de lupa pasa a `textSecondary`. |
| `con texto` | Aparece el ícono de limpiar (×); el texto en `textPrimary`. |
| `disabled` | No aplica normalmente (la búsqueda siempre disponible). |

### Chip de filtro

| Estado | Qué cambia |
|---|---|
| `default` (inactivo) | Label `textSecondary`, badge neutro, `HudStatusDot` de su color en baja intensidad. |
| `hover` | Fondo del chip `surfaceRaised@0.5`, label sube a `textPrimary@0.85`. `durFast`. Cursor pointer. |
| `pressed` | Escala 0.97 `durInstant`. |
| `focused` | Anillo de foco 2 px alrededor del chip. |
| `selected/active` | El indicador deslizante está detrás de este chip; label `textPrimary`, badge de acento, `HudStatusDot` con halo de glow estable. |
| `disabled` | Si un filtro no tiene unidades, no se deshabilita: el chip sigue clickeable y su badge muestra `0` — filtrar a vacío es válido (lo gestiona el prompt 29). |

Interacción: al hacer click en un chip, el indicador se desliza, el filtro de `dashboardController` cambia y la grilla se reconstruye con su escalonado (prompt 28).

---

## 7. Animaciones

Tokens de motion (00 §7).

- **Indicador deslizante:** al cambiar de chip, el indicador se mueve con `AnimatedAlign`/`AnimatedPositioned`, `durBase`, curva `easeEntrance` (el «expo-out» premium). No hay flash de color: la selección «viaja».
- **Hover de chip:** fondo + color de label suben con `durFast`.
- **Ícono de limpiar (×):** aparece/desaparece con `AnimatedSwitcher` fade+scale, `durFast`, según haya texto.
- **`HudStatusDot`:** el halo de glow del dot activo (ACTIVOS/OFFLINE) late suavemente (patrón reactor, ~1600 ms); el dot inactivo no late.
- **Entrada del toolbar:** con la banda 2 del prompt 24 (fade+`moveY`). Sin animación de entrada propia adicional.
- **Cambio de contador en los badges:** el `AppBadge` anima el cambio de número (crossfade corto `durFast`) si el conteo cambia (p. ej. al crear un bot).
- **Reduced motion:** el indicador no se desliza — cambia de posición instantáneo con un crossfade de color de 120 ms; sin latido del `HudStatusDot`; sin scale en el ícono de limpiar.

---

## 8. Accesibilidad

- Contraste: labels de chip (`textSecondary` inactivo, `textPrimary` activo) y placeholder (`textTertiary`) sobre `glassSurface`/`surfaceHud` — verificar ≥ 4.5:1 (≥ 3:1 para el placeholder, que es hint).
- El filtro segmentado expone semántica de grupo de radio: cada chip es un `Semantics(button: true, selected: …)` con label «Filtro: Todos / Activos / Offline». El conteo va incluido en el label semántico («Activos, 4 unidades»).
- El estado activo no se comunica solo por color: el indicador deslizante (posición), el label más brillante, el badge de acento y `selected: true` semántico lo refuerzan.
- Foco visible en el campo y en cada chip; orden de tab: campo de búsqueda → TODOS → ACTIVOS → OFFLINE.
- El ícono de lupa y el de limpiar llevan `tooltip` («Buscar», «Limpiar búsqueda»).
- Área de hit de cada chip ≥ 32×32 px (el padding del chip lo garantiza).
- El `HudStatusDot` es refuerzo, no el único portador: el label textual nombra el filtro.

---

## 9. Checklist de aceptación

- [ ] El toolbar es un `HoloPanel` compacto de altura fija 64 px (consumible como `SliverPersistentHeader` por el prompt 24).
- [ ] La búsqueda usa `AppTextField` variante search con placeholder "BUSCAR UNIDAD POR ID O NOMBRE..." y botón de limpiar.
- [ ] El filtro es un segmentado de 3 chips dentro de un riel `radiusPill`.
- [ ] Hay un indicador deslizante que se mueve al chip activo con `easeEntrance`, no un cambio brusco de color.
- [ ] Cada chip tiene `HudStatusDot` (neutro/`success`/`danger`) y un `AppBadge` con su conteo.
- [ ] Al achicar la ventana, la búsqueda se encoge hasta `minWidth 180`; los filtros no se encogen ni reordenan.
- [ ] Estados hover/pressed/focused/active del campo y de los chips implementados.
- [ ] Un filtro sin unidades muestra badge `0` y sigue clickeable (no se deshabilita).
- [ ] Con reduced-motion: el indicador no se desliza (crossfade 120 ms); sin latido del `HudStatusDot`.
- [ ] Semántica de grupo de radio en los chips, con conteo en el label semántico; foco en orden visual.
- [ ] Contraste de labels y placeholder verificado.
- [ ] Cero hex crudo, cero estilos inline mágicos.
- [ ] Se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores), 02 (tipografía `label`), 03 (dimensiones, `radiusPill`), 04 (motion), 05 (iconografía — lupa, limpiar), 06 (`HudStatusDot`).
- **Componentes núcleo:** 10 (`AppTextField` variante search), 11 (`AppBadge` / status tags), 12 (`HoloPanel`).
- **Shell:** 24 (layout del dashboard — monta el toolbar como sliver sticky y le aplica la sombra de scroll).
- **Pieza relacionada:** 28 (la bot card se reconstruye al cambiar el filtro), 29 (estado vacío por filtro/búsqueda).
