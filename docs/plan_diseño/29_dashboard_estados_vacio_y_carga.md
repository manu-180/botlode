# 29 — Dashboard · Estados vacío y de carga de la grilla

> Depende del archivo **00 — README · Visión y Sistema de Diseño**. Leerlo completo antes de ejecutar. Todos los valores se referencian **por token**.

---

## 1. Objetivo

Rediseñar los estados **de carga** y **vacíos** de la grilla del Dashboard. Hoy hay un `_DashboardSkeleton` con 6 contenedores grises hechos a mano y un `_buildEmptyState` único (`Icons.search_off`) que no distingue «no hay unidades» de «la búsqueda no encontró nada». Se eleva a: un skeleton de grilla que usa el patrón premium del prompt 14, y **dos** estados vacíos diferenciados con el `EmptyState` del prompt 15. La transición de skeleton a contenido es un crossfade.

---

## 2. Archivos

- **Modificar:** `lib/features/dashboard/presentation/views/dashboard_view.dart` — la clase `_DashboardSkeleton` (se reescribe sobre el prompt 14) y `_buildEmptyState` (se divide en dos casos sobre el prompt 15). Extraer ambos a `lib/features/dashboard/presentation/widgets/` (`dashboard_grid_skeleton.dart`, `dashboard_empty_states.dart`) si conviene.
- **Consumir (no crear):** `SkeletonBase` / skeleton de card (prompt 14), `EmptyState` (prompt 15), `AppButton` (09), `HudGridTexture` (06), `app_colors.dart` (01), `AppTextStyles` (02), `app_dimens.dart` (03), `app_motion.dart` (04), iconografía (05).
- **Contexto:** estos estados se rinden como slivers dentro del `CustomScrollView` del prompt 24, según `botsAsync.when(...)` y si la búsqueda/filtro está activa.

---

## 3. Estado actual

- **Carga:** `_DashboardSkeleton` es un `GridView.builder` (`NeverScrollableScrollPhysics`, mismo delegate que la grilla real) con 6 ítems; cada ítem un `Container` `black@0.2` radio 20 borde `white@0.05` con `SkeletonBase` para la cabeza, badge, nombre, descripción e ID.
- **Vacío:** `_buildEmptyState` es un `Center` → `Column` con `Icon(Icons.search_off_rounded)` 64 px `textSecondary@0.3` + texto `"NO SE ENCONTRARON UNIDADES"`.

Problemas: el skeleton replica el layout viejo de card (debe seguir el del prompt 28); colores y radios mágicos; un único estado vacío que mezcla dos situaciones distintas (cuenta de bots = 0 real vs. filtro/búsqueda sin resultados); sin acción sugerida; sin transición skeleton→contenido.

---

## 4. Visión del rediseño

Mientras la bahía carga, el usuario ve **la silueta de la grilla** poblándose: 6–8 skeletons de bot card con shimmer, idénticos en layout a la `BotCard` real (prompt 28), de modo que el contenido «se materializa» en su lugar sin reflow. Cuando la carga termina hay un **crossfade** del skeleton al contenido real.

Si no hay unidades, la bahía se ve **deliberadamente vacía pero invitante**: un `EmptyState` con un ícono de hangar vacío, copy de bienvenida y un CTA para ensamblar la primera unidad. Si hay unidades pero la búsqueda/filtro no encontró ninguna, un `EmptyState` distinto: ícono de lupa, copy de «sin coincidencias» y un CTA para limpiar la búsqueda. Dos situaciones, dos mensajes, dos acciones — nunca un mensaje genérico ambiguo.

---

## 5. Especificación visual

### 5.1 Estado de carga — skeleton de grilla

- Mismo `SliverGrid` / delegate que la grilla real (prompt 24: `maxCrossAxisExtent: 400`, `childAspectRatio: 1.4`, spacing `space20`).
- **6–8 ítems** skeleton (usar 8 si la mayoría de pantallas muestra ≥ 8 cards; 6 es aceptable). Cada ítem es el **skeleton de card del prompt 14**, configurado para replicar el layout de `BotCard` (prompt 28):
  - Contenedor: forma de `HoloPanel`, radio `radiusL`, fondo `glassSurface` tenue, borde `glassBorder`. Cero `black@0.2` mágico.
  - Zona superior: un bloque skeleton para el avatar (cuadrado/círculo ~54×54) arriba a la izquierda + un bloque skeleton pequeño tipo pill para el `StatusTag` arriba a la derecha.
  - Cuerpo: una barra skeleton ancha (nombre, ~150×18), dos barras finas (descripción, ancho completo + ~70 %), y una barra corta (ID, ~100×10).
  - **Shimmer:** el barrido del prompt 14 (`gradGoldSheen`), período 2800–3400 ms, recorriendo cada skeleton.
- El skeleton de grilla **no scrollea** independientemente: vive dentro del `CustomScrollView` del prompt 24 como un `SliverGrid`.

### 5.2 Estado vacío A — sin unidades en la bahía

Se muestra cuando `botsAsync` resolvió con **lista vacía y no hay búsqueda/filtro activo** (la cuenta real de bots es 0).

- Un `SliverFillRemaining(hasScrollExtent: false)` con el `EmptyState` del prompt 15, centrado:
  - **Ícono:** hangar/bahía vacía — un glifo de hangar o contenedor del set (prompt 05), ~64 px, color `textTertiary`, con un sutil `HudGridTexture` o brackets detrás (lo provee el `EmptyState` del prompt 15 como variante «escénica»).
  - **Título:** `"NO HAY UNIDADES EN LA BAHÍA"`, estilo `AppTextStyles.titleM`/`label` (uppercase), color `textSecondary`.
  - **Descripción:** una línea de apoyo, estilo `bodyS` `textTertiary`: «Ensamblá tu primera unidad autónoma para comenzar a operar.»
  - **Acción:** `AppButton` primary `"ENSAMBLAR PRIMERA UNIDAD"`, con `glowGold`, ícono de ensamblaje (prompt 05); `onPressed` abre `CreateBotModal` (mismo callback que `onAssemble`).

### 5.3 Estado vacío B — búsqueda/filtro sin resultados

Se muestra cuando `botsAsync` resolvió con datos pero **el filtro o la query dejan la lista filtrada vacía** (hay bots, pero ninguno coincide).

- `SliverFillRemaining` con el `EmptyState` del prompt 15, variante distinta:
  - **Ícono:** lupa con un signo de «sin resultados» (lupa tachada o lupa + guion), del set (prompt 05), ~64 px, `textTertiary`.
  - **Título:** `"SIN COINCIDENCIAS"`, `titleM`/`label`, `textSecondary`.
  - **Descripción:** `bodyS` `textTertiary`: «Ninguna unidad coincide con el filtro o la búsqueda actual.» Si hay una query de texto, puede incluirla entre comillas mono (`"…"`).
  - **Acción:** `AppButton` secundario/ghost `"LIMPIAR BÚSQUEDA"` con ícono de limpiar; `onPressed` resetea la query y el filtro a `TODOS` en `dashboardController`.

### 5.4 Diferenciación de los dos casos

La vista decide cuál mostrar:

```
final allBots = ...;            // lista completa antes de filtrar
final filtered = ...;           // filteredBotsProvider
final hasQueryOrFilter = query.isNotEmpty || filter != Filter.todos;

if (filtered.isEmpty) {
  if (allBots.isEmpty && !hasQueryOrFilter) -> EmptyState A
  else -> EmptyState B
}
```

Si `filteredBotsProvider` no expone la lista sin filtrar, leer el provider de bots crudo además del filtrado para distinguir los casos. No mostrar el genérico actual.

---

## 6. Estados e interacciones (matriz — 00 §9)

| Estado de la grilla | Qué se muestra |
|---|---|
| `loading` | Skeleton de grilla (§5.1): 6–8 skeleton cards con shimmer. La toolbar y el header ya están activos. |
| `empty` — sin unidades | `EmptyState` A (§5.2) con CTA "ENSAMBLAR PRIMERA UNIDAD". |
| `empty` — sin resultados | `EmptyState` B (§5.3) con CTA "LIMPIAR BÚSQUEDA". |
| `data` (con cards) | La grilla real de `BotCard` (prompt 28). |
| `error` | Patrón de error del prompt 16 (no es alcance de este prompt, pero el mismo `SliverFillRemaining` lo aloja). |

Interacciones de los `EmptyState`:

- El `AppButton` de cada estado vacío sigue la matriz §9 completa del prompt 09: hover (borde/elevación/glow `durFast`), pressed (escala 0.97), focused (anillo de foco), disabled (no aplica aquí).
- El skeleton **no es interactivo**: no responde a hover ni a tap; no tiene foco.

---

## 7. Animaciones

Tokens de motion (00 §7).

- **Shimmer del skeleton:** barrido `gradGoldSheen` cada 2800–3400 ms (patrón del prompt 14). Todos los skeletons comparten fase o se desfasan ligeramente entre sí (un offset pequeño por índice da un efecto de «escaneo» más vivo).
- **Transición skeleton → contenido:** al pasar `botsAsync` de `loading` a `data`, **crossfade** entre el `SliverGrid` de skeletons y el `SliverGrid` real, `durBase`, curva `easeStandard`. Inmediatamente después, las `BotCard` reales aplican su entrada escalonada (prompt 28: 36 ms entre cards). El skeleton se desvanece mientras las cards reales entran — sin parpadeo de fondo.
- **Transición a estado vacío:** al pasar de `loading` a `empty`, el `EmptyState` entra con `.fadeIn(durBase)` + `.moveY(begin: 12, end: 0)`, `easeEntrance`. El ícono puede entrar con un `.scale(begin: 0.9, end: 1.0)` `durBase`.
- **Cambio entre Empty A y Empty B:** si el usuario escribe una búsqueda que vacía la grilla, el `EmptyState` hace crossfade entre variantes con `durBase`.
- **Reduced motion:** sin shimmer (el skeleton se ve como bloques estáticos `surfaceHud`); las transiciones skeleton→contenido y →vacío se reducen a crossfade de 120 ms; sin scale del ícono.

---

## 8. Accesibilidad

- El skeleton es decorativo/temporal: marcarlo con `Semantics(label: 'Cargando unidades…')` o un `liveRegion` que anuncie el estado de carga; sus bloques internos van en `ExcludeSemantics`.
- Los `EmptyState` exponen su texto a lectores de pantalla; el título y la descripción son legibles y el CTA es un botón con label claro.
- Contraste: títulos `textSecondary` y descripciones `textTertiary` sobre `AppBackground` — verificar ≥ 4.5:1 para el título y ≥ 3:1 para la descripción (texto de apoyo). Si `textTertiary` no alcanza para la descripción, subir a `textSecondary`.
- Los dos estados vacíos tienen **mensajes y acciones distintas**: el usuario nunca recibe un mensaje ambiguo. Siempre hay una salida/acción clara (ensamblar o limpiar búsqueda).
- El CTA de cada estado vacío es alcanzable por teclado, con foco visible; al aparecer el `EmptyState`, el foco puede moverse al CTA (sin robar foco de forma molesta — solo si la grilla tenía el foco).
- El skeleton no atrapa foco de teclado.
- Reduced motion respetado (§7).

---

## 9. Checklist de aceptación

- [ ] El skeleton de carga usa el patrón del prompt 14; cada ítem replica el layout de `BotCard` (prompt 28); cero `black@0.2` ni radios mágicos.
- [ ] El skeleton se rinde como `SliverGrid` (6–8 ítems) dentro del `CustomScrollView` del prompt 24.
- [ ] El shimmer recorre los skeletons (2800–3400 ms); con reduced-motion son bloques estáticos.
- [ ] Existen **dos** estados vacíos diferenciados, no uno genérico.
- [ ] Empty A (sin unidades): ícono de hangar, "NO HAY UNIDADES EN LA BAHÍA", CTA "ENSAMBLAR PRIMERA UNIDAD" (abre `CreateBotModal`).
- [ ] Empty B (sin resultados): ícono de lupa, "SIN COINCIDENCIAS", CTA "LIMPIAR BÚSQUEDA" (resetea query + filtro a TODOS).
- [ ] La vista distingue correctamente A de B (lista cruda vacía + sin query/filtro → A; resto → B).
- [ ] La transición de skeleton a contenido real es un crossfade `durBase`; las cards reales entran escalonadas después.
- [ ] Los `EmptyState` usan el componente del prompt 15 y sus CTA usan `AppButton` con la matriz de estados del prompt 09.
- [ ] El skeleton no es interactivo ni captura foco; lleva `Semantics`/`liveRegion` de «cargando».
- [ ] Contraste de títulos y descripciones verificado.
- [ ] Cero hex crudo, cero magic numbers.
- [ ] Se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores), 02 (tipografía), 03 (dimensiones), 04 (motion), 05 (iconografía — hangar, lupa, ensamblaje, limpiar), 06 (`HudGridTexture` para el fondo escénico del `EmptyState`).
- **Componentes núcleo:** 09 (`AppButton` para los CTA), 12 (`HoloPanel` — forma del skeleton card), 14 (skeleton premium + shimmer), 15 (`EmptyState`), 16 (patrón de error, alojado en el mismo `SliverFillRemaining`).
- **Shell:** 24 (layout del dashboard — el `CustomScrollView` que aloja estos slivers).
- **Piezas relacionadas:** 28 (`BotCard` — el skeleton replica su layout y la transición desemboca en su entrada escalonada), 27 (la query/filtro del toolbar dispara el estado Empty B).
