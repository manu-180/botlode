# 21 — PageTitle · Encabezado de página HUD

> Fase C · Shell y navegación. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Antes de ejecutar este prompt, leer el archivo 00 completo. Si algo se contradice, gana el archivo 00.

---

## 1. Objetivo

Rediseñar el encabezado de página (`PageTitle`) y unificar sus tres estilos (`minimal`, `techBar`, `elegant`) bajo el sistema de diseño. El estilo `techBar` pasa a ser el principal de la app. Cada pantalla usa un `PageTitle` para anunciar su contexto; debe ser preciso, jerárquico y con una entrada animada elegante, además de un slot de acciones a la derecha.

---

## 2. Archivos

- **Modificar:** `lib/core/ui/widgets/page_title.dart` — reescritura completa de `PageTitle` y los tres builders de estilo.
- **Consumir:** `AppColors` (prompt 01), `AppTextStyles` (prompt 02), `AppDimens` (prompt 03), `AppMotion` (prompt 04), `HudDivider`, `HudStatusDot`, `HudIdTag` (prompt 06), `gradGold` / `gradGoldSheen` (prompt 01/07).

---

## 3. Estado actual

`PageTitle` es un `StatelessWidget` con un `enum PageTitleStyle { minimal, techBar, elegant }` y tres builders:

- `minimal`: título 28 px + barra horizontal de 60×3 con shimmer infinito + subtítulo opcional.
- `techBar`: `IntrinsicHeight` → `Row` con barra vertical de 4 px (gradiente `color → color@0.3`) con shimmer infinito + columna título/subtítulo.
- `elegant`: punto circular de 8 px con `boxShadow` + shimmer infinito + columna título/subtítulo.

Los tres usan `Colors.white` para el título, tamaño 28 hardcodeado, `Oxanium` literal, `AppColors.textSecondary.withOpacity(0.7)` para el subtítulo, opacidades y medidas sueltas, shimmer infinito permanente (ruido). No hay slot de acciones, no hay entrada animada, no hay `Semantics` de encabezado.

---

## 4. Visión del rediseño

Un encabezado de página que se lee como la cabecera de un panel de instrumento. Tres estilos, jerarquizados y con uso definido:

- **`techBar` (principal):** barra vertical dorada con shimmer + título grande + subtítulo. Es el encabezado por defecto de las pantallas principales (Hangar, Facturación, Tienda, Plantillas, Ajustes). Lleva opcionalmente un `HudIdTag` o un contador a la derecha y un slot de acciones.
- **`minimal`:** título + `HudDivider` debajo. Para encabezados secundarios, secciones internas de una pantalla, o modales donde el `techBar` sería demasiado.
- **`elegant`:** `HudStatusDot` + título + subtítulo. Para encabezados que comunican un **estado vivo** (p. ej. una sección que monitorea algo en tiempo real).

El título y el subtítulo **entran animados** de forma escalonada (fade + translateY) cuando la pantalla aparece — una micro-coreografía que da el toque premium sin ruido permanente. El shimmer infinito de la barra se conserva sólo en `techBar` y es lento y sutil; los demás estilos no tienen movimiento permanente.

---

## 5. Especificación visual

### 5.1 API del widget

`PageTitle` recibe:
- `title` (String, requerido).
- `subtitle` (String?, opcional).
- `style` (`PageTitleStyle`, default `techBar` — se cambia el default actual `minimal`).
- `trailing` (Widget?, opcional) — slot de acciones a la derecha (botones, filtros, contador, `HudIdTag`).
- `accentColor` (Color?, opcional, default `AppColors.gold`).

Layout raíz común: un `Row` con `crossAxisAlignment: center` (o `start` si hay subtítulo largo) — a la izquierda el bloque de título según el estilo dentro de un `Expanded`, a la derecha el `trailing` alineado verticalmente al centro del título.

### 5.2 Estilo `techBar` (principal)

- **Barra vertical:** `Container` de **4 px** de ancho, alto = alto intrínseco del bloque título+subtítulo (`IntrinsicHeight`). Relleno con el gradiente `gradGold` (vertical, `topCenter`→`bottomCenter`). `borderRadius: AppDimens.radiusPill` en los extremos.
  - Shimmer: barrido de `gradGoldSheen` sobre la barra. Ciclo por token — usar el rango del archivo 00 §7.3 (2800–3400 ms); fijarlo en ~3200 ms. Sutil, lento. Se desactiva con reduced-motion.
- `SizedBox(width: AppDimens.space16)` (16 px) entre barra y texto.
- **Título:** `Text` con `AppTextStyles.displayM` (26/700, tracking +1.0, Oxanium), color `AppColors.textPrimary`. Reemplaza el `Colors.white` + 28 px hardcodeado.
- **Subtítulo** (si existe): `SizedBox(height: AppDimens.space8)` (8 px) + `Text` con `AppTextStyles.bodyS` (12.5/400), color `AppColors.textSecondary`.
- **Trailing:** a la derecha, alineado al centro vertical del título. Caso típico: un `HudIdTag` (`mono`, p. ej. `HANGAR-01`) o un contador (`HudReadout`/`labelSmall`, p. ej. `08 UNIDADES`), o un `Row` de botones/filtros.

### 5.3 Estilo `minimal`

- `Column(crossAxisAlignment: start)`:
  1. **Título:** `Text` con `AppTextStyles.displayM`, color `AppColors.textPrimary`.
  2. `SizedBox(height: AppDimens.space12)` (12 px).
  3. **`HudDivider`** horizontal: en vez de la barra de 60×3 con gradiente actual, usar la primitiva `HudDivider` (línea hairline `borderSubtle` con nodo central más brillante). Ancho: puede ser corto (~64 px) o full según el contexto; recomendado un `HudDivider` de ancho fijo 72 px para encabezados de sección, full-width para separadores de bloque.
  4. **Subtítulo** (si existe): `SizedBox(height: AppDimens.space12)` + `Text` `bodyS` `textSecondary`.
- Sin shimmer. Sin movimiento permanente.
- El `trailing` se coloca a la derecha del título, en el mismo eje.

### 5.4 Estilo `elegant`

- `Row(crossAxisAlignment: start)`:
  1. **`HudStatusDot`:** punto de estado del archivo 00 §8.7 — 8 px, color = `accentColor` (default `gold`) o el color de estado que corresponda, con halo de glow pulsante (latido 0.6↔1.0 ~1600 ms). Margen superior de `AppDimens.space8` para alinearlo con la primera línea del título.
  2. `SizedBox(width: AppDimens.space20)` (20 px).
  3. **Columna** título + subtítulo: título `displayM` `textPrimary`; subtítulo (si existe) `space8` + `bodyS` `textSecondary`.
- El único movimiento es el latido del `HudStatusDot` (porque comunica estado vivo — tiene causa). Sin shimmer.
- El `trailing` va a la derecha de la columna.

### 5.5 Cuándo usar cada estilo

| Estilo | Uso |
|---|---|
| `techBar` | Encabezado principal de pantallas (Hangar, Facturación, Tienda, Plantillas, Ajustes, Detalle de bot). Default. |
| `minimal` | Encabezados de sección dentro de una pantalla; títulos de modal; cualquier lugar donde el `techBar` recargaría. |
| `elegant` | Encabezados que reflejan un estado vivo/monitorizado (p. ej. una sección con datos en tiempo real). Usar con moderación. |

### 5.6 Slot de acciones (`trailing`)

- Siempre alineado al borde derecho del `PageTitle`, centrado verticalmente respecto al título.
- Contenido típico: 1–3 botones (`AppButton`/`AppIconButton` del prompt 09), un `HudIdTag`, un contador, o un grupo de filtros (chips del prompt 11).
- Separación entre el bloque de título y el `trailing`: el `Expanded` del título empuja; el `trailing` toma su tamaño intrínseco. Si hay varios elementos en el `trailing`, separarlos con `AppDimens.space8`.
- El `trailing` nunca debe envolver ni empujar el título fuera de pantalla: si el espacio es escaso, el título trunca con `ellipsis` antes que el `trailing` desaparezca.

### 5.7 Tokens — resumen

| Elemento | Token |
|---|---|
| Título | `AppTextStyles.displayM` · `AppColors.textPrimary` |
| Subtítulo | `AppTextStyles.bodyS` · `AppColors.textSecondary` |
| Barra vertical `techBar` | 4 px · `gradGold` · `radiusPill` |
| Shimmer `techBar` | `gradGoldSheen` · ciclo ~3200 ms |
| Divisor `minimal` | `HudDivider` · `borderSubtle` |
| Punto `elegant` | `HudStatusDot` · `accentColor` (default `gold`) |
| Gap barra↔texto (`techBar`) | `AppDimens.space16` |
| Gap punto↔texto (`elegant`) | `AppDimens.space20` |
| Gap título↔subtítulo | `AppDimens.space8` |
| Gap título↔divisor (`minimal`) | `AppDimens.space12` |
| Gap entre elementos del `trailing` | `AppDimens.space8` |

---

## 6. Estados e interacciones

`PageTitle` es mayormente presentacional (no interactivo). La matriz §9 del archivo 00 aplica de forma acotada:

| Estado | Qué cambia |
|---|---|
| `default` | Render normal según estilo. |
| `loading` | Si la pantalla aún no tiene datos, el `PageTitle` puede recibir un `title` placeholder o renderizarse como skeleton del prompt 14 (barra + bloques de texto en shimmer). El `trailing` que dependa de datos se oculta hasta que carguen. |
| `hover` / `pressed` / `focused` | No aplican al `PageTitle` en sí. Aplican a los widgets del `trailing`, que gestionan sus propios estados (prompt 09/11). |
| `disabled` / `error` / `empty` / `selected` | No aplican al encabezado; los gestiona el contenido de la pantalla. |

El `HudStatusDot` de `elegant` sí refleja un estado externo (online/procesando/offline): su color y latido cambian según el dato que reciba la pantalla, con transición `durBase` + `easeStandard`.

---

## 7. Animaciones

### 7.1 Entrada del encabezado

Al montarse el `PageTitle` (al aparecer la pantalla):

- **Título:** fade 0→1 + translateY de 8 px hacia arriba. Duración `AppMotion.durBase` (240 ms), curva `AppMotion.easeEntrance`.
- **Subtítulo:** la misma animación, **escalonada** 36 ms después del título (patrón de escalonado §7.3 archivo 00).
- **Barra vertical / `HudDivider` / `HudStatusDot`:** entra junto con el título (sin retardo) o 36 ms antes; un fade + ligera escala vertical (`scaleY` 0.6→1.0 para la barra de `techBar`, da sensación de «encenderse»).
- La entrada se dispara una vez por montaje; no se repite en cada rebuild.

### 7.2 Movimiento permanente

- **`techBar`:** shimmer de `gradGoldSheen` sobre la barra vertical, ciclo ~3200 ms. Único movimiento permanente, sutil.
- **`elegant`:** latido del `HudStatusDot` (~1600 ms). Tiene causa (estado vivo).
- **`minimal`:** sin movimiento permanente. Se elimina el shimmer infinito de la barra horizontal del estado actual.

### 7.3 Reduced-motion

Con `AppMotion.reduced` activo:
- Sin shimmer en `techBar`.
- Sin latido en `elegant` (`HudStatusDot` estático a opacidad plena).
- La entrada escalonada se reduce a un crossfade simple de 120 ms para todo el bloque (sin translateY, sin escalonado, sin `scaleY`).

Nunca animar `width`/`height`: la entrada usa `Opacity`/`Transform` (`AnimatedSlide`, `AnimatedOpacity`, `flutter_animate` con `.fadeIn().slideY()`).

---

## 8. Accesibilidad

- El título se marca con `Semantics(header: true)` para que sea reconocido como encabezado de la pantalla.
- El subtítulo es texto normal asociado visualmente; no necesita rol propio.
- Contraste: título `textPrimary` sobre el fondo de pantalla (`AppBackground`) ≥ 12:1; subtítulo `textSecondary` ≥ 4.5:1. Verificar ambos.
- El estado del `HudStatusDot` (estilo `elegant`) se comunica por **color + el texto del subtítulo**, nunca sólo por color (cumple §10) — el subtítulo debe describir el estado en palabras.
- La barra vertical, el divisor y el `HudStatusDot` son decorativos respecto al texto: marcarlos `ExcludeSemantics` para no duplicar lecturas (el `HudStatusDot` puede exponer su estado si aporta, pero sin ruido).
- El `trailing` mantiene su propio orden de foco, después del título; cada widget interactivo del `trailing` cumple su propia accesibilidad (prompt 09/11).
- Respetar `MediaQuery.disableAnimations` para shimmer, latido y entrada.
- Al completarse la transición de pantalla (prompt 20), el foco puede dirigirse al `PageTitle` como ancla de la pantalla.

---

## 9. Checklist de aceptación

- [ ] `PageTitle` mantiene el `enum` de 3 estilos; el default pasa a `techBar`.
- [ ] El título usa `AppTextStyles.displayM` y color `AppColors.textPrimary` (cero `Colors.white`, cero 28 px hardcodeado).
- [ ] El subtítulo usa `AppTextStyles.bodyS` y `AppColors.textSecondary` (cero opacidades sueltas).
- [ ] `techBar`: barra vertical 4 px con `gradGold` + shimmer `gradGoldSheen` ciclo ~3200 ms.
- [ ] `minimal`: usa la primitiva `HudDivider` (no la barra 60×3 con gradiente y shimmer).
- [ ] `elegant`: usa la primitiva `HudStatusDot` con latido (~1600 ms).
- [ ] `minimal` no tiene movimiento permanente; el shimmer infinito anterior fue eliminado.
- [ ] Existe el slot `trailing` alineado a la derecha, centrado verticalmente respecto al título.
- [ ] Si el espacio escasea, el título trunca con `ellipsis` antes de que el `trailing` desaparezca.
- [ ] Entrada animada: título fade+translateY 8 px `durBase`/`easeEntrance`; subtítulo escalonado 36 ms después.
- [ ] La entrada se dispara una vez por montaje, no en cada rebuild.
- [ ] El título se marca `Semantics(header: true)`.
- [ ] Ornamentos (barra, divisor, punto) marcados `ExcludeSemantics` para no duplicar lecturas.
- [ ] Reduced-motion: sin shimmer, sin latido, entrada reducida a crossfade 120 ms.
- [ ] Espaciados exactos según §5.7; cero magic numbers, cero hex sueltos.
- [ ] `flutter analyze` sin warnings nuevos; los 3 estilos se ven correctos en 1280×720 y en 1024×600.

---

## 10. Dependencias

Deben estar completados antes de ejecutar este prompt:

- **01** — Tokens de color (`textPrimary`, `textSecondary`, `gold`, `borderSubtle`, gradiente `gradGold`, `gradGoldSheen`).
- **02** — Sistema tipográfico (`AppTextStyles.displayM`, `bodyS`, `labelSmall`, `mono`, `hudReadout`).
- **03** — Tokens de dimensión (`AppDimens.space8/12/16/20`, `radiusPill`).
- **04** — Sistema de motion (`AppMotion`: `durBase`, `easeEntrance`, `easeStandard`, `reduced`).
- **06** — Primitivas HUD (`HudDivider`, `HudStatusDot`, `HudIdTag`).
- **07** — Primitivas de glow/glass (para el render del shimmer sobre la barra de `techBar`).
- **09** — Botones (para los widgets que viven en el slot `trailing`).
- **11** — Badges/chips (contadores y filtros del slot `trailing`).
- **14** — Skeletons (estado `loading` del encabezado).

Se integra con: **20** (MainLayout, que entrega el lienzo y dispara la transición tras la cual entra el `PageTitle`) y todas las pantallas de Fase D-G que consumen `PageTitle` como encabezado.
