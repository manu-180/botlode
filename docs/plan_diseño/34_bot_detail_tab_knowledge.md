# 34 — Bot Detail · Tab Knowledge (base de conocimiento)

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Es el contenido del **tab índice 2** definido por el prompt 30.

---

## 1. Objetivo

Rediseñar el tab Knowledge del detalle de unidad: la base de conocimiento que alimenta al bot. Hoy la edición es un bloque de texto suelto sin estructura. El rediseño la convierte en un **archivo de fragmentos de conocimiento** —filas dentro de `HoloPanel`s, con acciones por fragmento, un editor multilínea y estados claros.

---

## 2. Archivos

- **Crear:** `lib/features/dashboard/presentation/widgets/tabs/bot_knowledge_tab.dart` — el panel completo.
- **Crear:** `lib/features/dashboard/presentation/widgets/knowledge_fragment_row.dart` — fila de fragmento.
- **Crear:** `lib/features/dashboard/presentation/widgets/knowledge_editor_panel.dart` — editor de fragmento (alta/edición).
- **Modificar:** `lib/features/dashboard/presentation/widgets/knowledge_uploader.dart` — alinear con el nuevo estilo o reusar su lógica de carga.
- **Modificar:** `lib/features/dashboard/presentation/views/bot_detail_view.dart` — `_selectedTab == 2` renderiza `BotKnowledgeTab`.

---

## 3. Estado actual

- La base de conocimiento se gestiona con `knowledge_uploader.dart` y/o un campo de texto grande sin estilo HUD.
- No hay lista de fragmentos individuales, ni acciones por fragmento (editar/eliminar), ni confirmación de borrado, ni estado vacío diseñado, ni `AppTextField` multilínea coherente.

---

## 4. Visión del rediseño

El tab Knowledge se lee como el **archivo de memoria de la unidad**: el cuerpo de saber con el que el bot responde. Arriba, un encabezado con un `HudDivider` etiquetado y un botón prominente `AÑADIR CONOCIMIENTO`. Debajo, una **lista de fragmentos**: cada fragmento es una fila dentro de un `HoloPanel` compacto, con un ícono de tipo, un extracto del texto, un contador de caracteres y acciones (editar / eliminar). Editar o crear abre un `KnowledgeEditorPanel` con un `AppTextField` multilínea grande. Eliminar pide confirmación. Si no hay fragmentos, un `EmptyState` invita a cargar el primero. La interfaz se siente como administrar la memoria de un sistema, no como un campo de texto plano.

---

## 5. Especificación visual

### 5.1 Layout del tab

- Raíz: `Column` con `SingleChildScrollView` para la lista. Padding 0 (lo da el prompt 30).
- De arriba hacia abajo:
  1. **Encabezado:** `Row` con `HudDivider` etiquetado `// BASE DE CONOCIMIENTO` ocupando el ancho restante + a la derecha el botón `AÑADIR CONOCIMIENTO`.
  2. `space16`.
  3. **Resumen:** una línea `labelSmall` `textTertiary`: `N fragmentos · ~K caracteres totales`.
  4. `space16`.
  5. **Lista de fragmentos** (`Column` de `KnowledgeFragmentRow`, gap `space12`) o `EmptyState`.

### 5.2 Botón `AÑADIR CONOCIMIENTO`

- `AppButton` variante `secondary` (o `primary` si se quiere destacar), ícono `plus` a la izquierda, label `AÑADIR CONOCIMIENTO` en `label`.
- Al pulsarlo abre el `KnowledgeEditorPanel` en modo alta (inline expandible al tope de la lista, o en un modal/popover; preferir inline expandible para mantener contexto).

### 5.3 `KnowledgeFragmentRow`

- Contenedor: `HoloPanel` variante `default`, radio `radiusM`, borde `borderDefault`, padding `space16`, elevación `elev1`.
- Composición `Row`:
  1. **Ícono de tipo** (24 px, en un mini-cuadro `surfaceHud` biselado): `file-text` para texto, `link` para URL, `book-open` genérico. Color `cyan`.
  2. `SizedBox(width: space16)`.
  3. **Bloque central** (`Expanded`, `Column`):
     - Título/etiqueta del fragmento en `titleM` `textPrimary` (si el modelo no tiene título, usar las primeras palabras).
     - `space4`.
     - Extracto del texto en `bodyS` `textSecondary`, máximo 2 líneas con `TextOverflow.ellipsis`.
     - `space8`.
     - Metadato en `mono` `textTertiary`: `K caracteres · actualizado hace Ns`.
  4. **Acciones** (`Row`, alineadas a la derecha):
     - `AppIconButton` `edit` (variante `ghost`), `tooltip: "Editar fragmento"`.
     - `AppIconButton` `trash` (variante `ghost` con tinte `danger` en hover), `tooltip: "Eliminar fragmento"`.

### 5.4 `KnowledgeEditorPanel`

- Contenedor: `HoloPanel` variante `hud` con `HudCornerBrackets`, padding `space20`, fondo `surfaceRaised`.
- Cabecera: label `// NUEVO FRAGMENTO` o `// EDITANDO FRAGMENTO` en `labelSmall` `cyan`.
- Campo: `AppTextField` multilínea grande, `minLines: 5`, `maxLines: 12`, fuente `mono`, placeholder `Escribí o pegá el conocimiento de la unidad...`, contador de caracteres en `mono` `textTertiary`.
- Pie: `Row` a la derecha con `AppButton` `ghost` `CANCELAR` + `AppButton` `primary` `GUARDAR FRAGMENTO`.

### 5.5 Confirmación de borrado

- Al pulsar eliminar, abrir un diálogo de confirmación (patrón de `delete_protocol_dialog.dart` reusado o el diálogo estándar): título `¿Eliminar este fragmento?`, texto explicativo, botón `CANCELAR` (ghost) y `ELIMINAR` (variante `danger`). Nunca borrar sin confirmar.

---

## 6. Estados e interacciones

Matriz §9 aplicada:

| Estado | Apariencia |
|---|---|
| `default` | Lista de fragmentos con sus filas en reposo. |
| `hover` (fila) | Borde sube a `borderStrong`, elevación `elev2`, las acciones (editar/eliminar) ganan opacidad plena (en reposo pueden estar al 70 %); `durFast`. |
| `pressed` (fila/botón) | Escala 0.97, `durInstant`. |
| `focused` | Anillo `cyan` 2 px en la fila o el control enfocado. |
| `editing` | La fila se reemplaza/expande en `KnowledgeEditorPanel`; las demás filas bajan su opacidad ligeramente para enfocar el editor. |
| `loading` | Al guardar/eliminar: la fila o el editor muestran spinner; el botón correspondiente se deshabilita. Al cargar la lista inicial: skeletons de fila (prompt 14). |
| `empty` | `EmptyState` (prompt 15): ícono `book-open`, mensaje `La unidad todavía no tiene conocimiento cargado`, CTA `AÑADIR PRIMER FRAGMENTO`. |
| `error` | `ErrorFeedbackCard` (prompt 16) en lugar de la lista si falla la carga, con botón `Reintentar`. Si falla un guardado/borrado puntual: toast `danger` (prompt 17) y la fila vuelve a su estado anterior. |

- **Eliminar fragmento:** abre confirmación → al confirmar, la fila se anima saliendo y la lista se reordena.
- **Editar fragmento:** abre el editor con el contenido cargado; cancelar descarta sin guardar (confirmar si hubo cambios).

---

## 7. Animaciones

- **Entrada del tab:** las filas entran escalonadas (fade + translateY 12 px), 36 ms entre filas, máx ~10, `easeEntrance`, `durBase`.
- **Apertura del editor:** el `KnowledgeEditorPanel` se expande con altura animada (usar `AnimatedSize` o un `SizeTransition`) + fade, `durBase`, `easeEntrance`; los `HudCornerBrackets` se "dibujan" al entrar.
- **Eliminar fila:** la fila sale con fade + translateX 16 px + colapso de altura (`easeExit`, ~`durFast`·1.5); las filas siguientes se reacomodan con `durBase`.
- **Hover de fila:** elevación/borde/opacidad de acciones con `durFast`.
- **Spinner de guardado:** rotación estándar; cambio de label de botón con crossfade `durFast`.
- **Reduced motion** (`AppMotion.reduced`): sin escalonado (fade conjunto 120 ms); el editor aparece sin `AnimatedSize` (corte directo); eliminar fila hace fade simple sin slide ni colapso animado.

---

## 8. Accesibilidad

- Cada `KnowledgeFragmentRow` es un grupo semántico con label `"Fragmento: <título>, <K caracteres>"`; las acciones son botones con `tooltip` + `Semantics` (`Editar fragmento`, `Eliminar fragmento`).
- El `AppTextField` del editor tiene label, hint y contador vinculados; contador con figuras tabulares.
- El diálogo de confirmación de borrado atrapa el foco, tiene salida clara (cancelar) y el botón destructivo es claramente `danger` con ícono + texto, no solo color.
- Al abrir el editor, el foco salta al `AppTextField`.
- `EmptyState` y `ErrorFeedbackCard` exponen su mensaje; el error se anuncia con `liveRegion`.
- Contraste: `titleM` `textPrimary` ≥ 12:1; extracto `textSecondary` ≥ 4.5:1; metadato `textTertiary` ≥ 3:1. Verificar.
- Targets de las `AppIconButton` ≥ 32×32 px.

---

## 9. Checklist de aceptación

- [ ] La base de conocimiento se muestra como lista de `KnowledgeFragmentRow` dentro de `HoloPanel`s.
- [ ] Cada fila tiene ícono de tipo, título, extracto de 2 líneas, metadato `mono` y acciones editar/eliminar.
- [ ] Hay un botón `AÑADIR CONOCIMIENTO` que abre el `KnowledgeEditorPanel`.
- [ ] El editor usa un `AppTextField` multilínea grande en `mono` con contador.
- [ ] Eliminar un fragmento pide confirmación con un diálogo `danger`; nunca borra directo.
- [ ] Estado vacío muestra `EmptyState` con CTA para cargar el primer fragmento.
- [ ] Estados loading (skeletons / spinners) y error (`ErrorFeedbackCard` + toast) implementados.
- [ ] Cero hex sueltos, cero magic numbers: todo por tokens.
- [ ] Reduced motion respetado (sin escalonado, sin `AnimatedSize`, sin slide al borrar).
- [ ] Compila y se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores), 02 (`titleM`, `bodyS`, `labelSmall`, `mono`), 03 (`space*`, `radius*`, `elev*`), 04 (`dur*`, curvas, reduced-motion), 05 (iconografía), 06 (`HudDivider`, `HudCornerBrackets`).
- **Núcleo:** 09 (`AppButton`, `AppIconButton`), 10 (`AppTextField`), 12 (`HoloPanel`), 14 (skeletons), 15 (`EmptyState`), 16 (`ErrorFeedbackCard`), 17 (toasts).
- **Shell / detalle:** 30 (layout y tab bar). Patrón de diálogo destructivo reusado de `delete_protocol_dialog.dart`.
