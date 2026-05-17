# 33 — Bot Detail · Tab Config (formulario de configuración)

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Es el contenido del **tab índice 1** definido por el prompt 30.

---

## 1. Objetivo

Rediseñar el tab Config del detalle de unidad: el formulario que edita nombre, system prompt, color técnico (`tech_color`) y demás parámetros del bot. Hoy la edición está dispersa (nombre inline en el header, color en un diálogo aparte). El rediseño la unifica en **un formulario HUD seccionado** con campos `AppTextField`, selector de color como swatches + popover, y guardado explícito con feedback.

---

## 2. Archivos

- **Crear:** `lib/features/dashboard/presentation/widgets/tabs/bot_config_tab.dart` — el formulario completo.
- **Crear:** `lib/features/dashboard/presentation/widgets/color_swatch_picker.dart` — selector de color HUD.
- **Modificar:** `lib/features/dashboard/presentation/views/bot_detail_view.dart` — `_selectedTab == 1` renderiza `BotConfigTab`; eliminar la edición inline del header (`_EditableHeader` deja de editar) y dejar `edit_color_dialog.dart` solo si se reusa su `colorpicker` interno.
- **Reusar:** `flutter_colorpicker` (ya en `pubspec.yaml`).

---

## 3. Estado actual

- El nombre se edita inline en el header con `_EditableHeader` (un `TextField` que aparece al tocar).
- El color se edita en `edit_color_dialog.dart`, un diálogo separado con `flutter_colorpicker`.
- El system prompt y otros campos viven en formularios sueltos sin estilo unificado.
- No hay `AppTextField`, ni secciones con `HudDivider`, ni botón de guardado con estado loading, ni feedback de éxito coherente, ni validación visible.

---

## 4. Visión del rediseño

El tab Config se lee como la **hoja de parámetros de la unidad**. Un formulario vertical, seccionado por `HudDivider`s etiquetados (`// IDENTIDAD`, `// COMPORTAMIENTO`, `// APARIENCIA`). Cada campo es un `AppTextField` premium con label flotante y validación clara. El system prompt es un `AppTextField` multilínea grande tipo "consola de directivas". El color técnico se elige con una **fila de swatches HUD** (cuadrados biselados con glow del propio color) más un botón "personalizado" que abre `flutter_colorpicker` en un popover. Abajo, un botón `AppButton` primario "GUARDAR CONFIGURACIÓN" con estado loading; al guardar, un toast HUD confirma. Un borrador opcional se autoguarda para no perder cambios.

---

## 5. Especificación visual

### 5.1 Layout del formulario

- Raíz: `SingleChildScrollView` vertical + `Form`. Ancho del contenido acotado a `maxWidth 640` centrado (un formulario no debe estirarse infinitamente).
- Secciones de arriba hacia abajo, cada una precedida por un `HudDivider` etiquetado:
  1. **`// IDENTIDAD`**: campo `Nombre de la unidad`.
  2. **`// COMPORTAMIENTO`**: campo `System prompt` (multilínea grande), campo opcional `Mensaje de bienvenida`.
  3. **`// APARIENCIA`**: `ColorSwatchPicker` para `tech_color`.
- Gap entre campos `space20`; gap entre secciones `space32`.
- Al pie: barra de acciones con el botón guardar (ver §5.4).

### 5.2 Campos `AppTextField`

- Todos los campos usan `AppTextField` (prompt 10): contenedor `surfaceHud`, borde `borderDefault`, radio `radiusM`, label flotante en `labelSmall`, texto en `bodyM`.
- **Nombre de la unidad:** single-line, máximo ~40 caracteres, contador visible, `textInputAction: next`.
- **System prompt:** `AppTextField` multilínea, `minLines: 6`, `maxLines: 14`, fuente del texto en `mono` (es una directiva técnica), placeholder `Definí el comportamiento de la unidad...`, contador de caracteres en `mono` `textTertiary` abajo a la derecha. Borde superior con un mini-label `// DIRECTIVA PRINCIPAL`.
- **Mensaje de bienvenida:** single-line o 2 líneas, opcional.

### 5.3 `ColorSwatchPicker` — selector de color técnico

- `HoloPanel` variante `flat`, padding `space16`.
- Label `// COLOR TÉCNICO` en `labelSmall` `textSecondary`.
- **Fila de swatches:** `Wrap` de ~8 colores predefinidos (los acentos del sistema: `gold`, `cyan`, `success`, `danger`, `warning`, `info`, `accentMagenta`, `accentViolet`). Cada swatch:
  - Cuadrado 36×36, esquinas biseladas (`ChamferBorder` pequeño o radio `radiusXS`).
  - Relleno del color, borde 1.5 px del mismo color al 50 %.
  - Glow del color (`glowStatus(color)`) cuando está seleccionado.
  - Seleccionado: anillo `textPrimary` 2 px + `HudCornerBrackets` mini.
- **Botón "PERSONALIZADO":** un swatch extra con ícono `eyedropper`/`palette`; al pulsarlo abre un **popover** (prompt 13) anclado debajo con `flutter_colorpicker` (`HueRingPicker` o `BlockPicker`), fondo `surfaceRaised`, borde `borderStrong`. Confirmar/cancelar dentro del popover.
- Preview: a la derecha de la fila, un círculo grande que muestra el color elegido con su glow, etiquetado con el hex en `mono` `textTertiary`.

### 5.4 Barra de acciones (pie del formulario)

- `Row` alineada a la derecha, separada del formulario por un `HudDivider` sin etiqueta.
- Botón secundario `DESCARTAR CAMBIOS` (`AppButton` variante `ghost`/`secondary`) — visible solo si el formulario está sucio (`dirty`).
- Botón primario `GUARDAR CONFIGURACIÓN` (`AppButton` variante `primary`, con `gradGold`, `glowGold`).
- Indicador de borrador: un `labelSmall` `textTertiary` a la izquierda (`Borrador guardado · hace Ns`) cuando hay autoguardado activo.

---

## 6. Estados e interacciones

Matriz §9 aplicada al formulario y sus controles:

| Estado | Apariencia |
|---|---|
| `default` (limpio) | Campos con sus valores actuales; botón guardar **disabled** (opacidad 0.4, sin glow) porque no hay cambios. |
| `dirty` (editado) | Botón guardar habilitado y emitiendo `glowGold`; aparece `DESCARTAR CAMBIOS`; indicador de borrador activo. |
| `hover` (campos/botones) | Campo: borde sube a `borderStrong`. Botón: elevación + glow `durFast`. |
| `focused` (campo activo) | Borde del campo `cyan` 2 px, label flotante arriba, glow `cyan` muy sutil. |
| `pressed` (botón) | Escala 0.97, color un paso más profundo, `durInstant`. |
| `loading` (guardando) | Botón guardar muestra spinner + texto `GUARDANDO...`; el formulario completo se deshabilita (no doble submit); campos en opacidad ligeramente reducida. |
| `success` (guardado OK) | Toast HUD (prompt 17) `CONFIGURACIÓN ACTUALIZADA` con ícono `check` `success`; el botón vuelve a `default`/disabled; el formulario se marca limpio. |
| `error` (campo inválido) | Campo con borde `danger`, ícono de error, mensaje `bodyS` `danger` debajo del campo con `role: alert`; el foco salta automáticamente al primer campo inválido al intentar guardar. |
| `error` (fallo de red al guardar) | Toast HUD `danger` `No se pudo guardar · reintentar`; el botón vuelve a habilitado para reintentar; los cambios NO se pierden. |

- **Validación:** nombre no vacío y ≤ límite; system prompt no vacío. Validar al perder foco y al enviar.
- **Autoguardado de borrador (opcional):** debounce de ~1200 ms tras el último cambio, persistir el borrador en `shared_preferences` por `botId`; al reabrir el tab, si hay borrador más nuevo que el dato remoto, ofrecer `Restaurar borrador` / `Descartar` con un banner sutil.
- **Cambio de color:** seleccionar un swatch o confirmar el popover marca el formulario `dirty` y actualiza el preview en vivo.

---

## 7. Animaciones

- **Entrada del tab:** las secciones entran escalonadas (fade + translateY 12 px), 36 ms entre secciones, `easeEntrance`, `durBase`.
- **Label flotante de campo:** sube/baja con `durFast`, `easeStandard`.
- **Aparición del botón `DESCARTAR`:** fade + translateX 8 px cuando el form pasa a `dirty`, `durFast`.
- **Botón guardar:** transición de `disabled`→habilitado anima la aparición del `glowGold` con `durBase`.
- **Spinner de loading:** rotación continua estándar; el cambio de label `GUARDAR`→`GUARDANDO...` con crossfade `durFast`.
- **Toast de éxito/error:** entra con `easeEntrance` + escala 0.96→1.0, `durBase` (lo define el prompt 17).
- **Selección de swatch:** el anillo + brackets aparecen con `durFast` + escala 0.9→1.0 del swatch elegido; los demás pierden su anillo simultáneamente.
- **Popover de colorpicker:** entra con `easeEntrance` + escala desde el ancla, `durBase` (prompt 13).
- **Reduced motion** (`AppMotion.reduced`): sin escalonado de secciones (fade 120 ms conjunto); sin escala en swatches/botones; el popover aparece con fade simple.

---

## 8. Accesibilidad

- Cada `AppTextField` tiene label asociado, hint, contador y mensaje de error vinculados semánticamente.
- Al fallar la validación, el foco salta al primer campo inválido y el mensaje de error se anuncia (`liveRegion`).
- Los swatches de color son botones con `Semantics(label: "Color <nombre>, <seleccionado/no seleccionado>")`; el color nunca es el único indicador: el seleccionado lleva anillo + brackets visibles.
- El botón "personalizado" tiene `tooltip` descriptivo; el popover de `flutter_colorpicker` es enfocable, con salida clara (cancelar) y atrapa el foco mientras está abierto.
- Botón guardar `disabled` se marca semánticamente disabled; al estar `loading` no acepta doble submit.
- Confirmar antes de salir del tab/pantalla con cambios sin guardar (diálogo `¿Descartar cambios?`).
- Contraste: texto de campos `textPrimary` ≥ 12:1; labels `textSecondary` ≥ 4.5:1; mensajes de error `danger` ≥ 4.5:1. Verificar.

---

## 9. Checklist de aceptación

- [ ] El formulario está seccionado por `HudDivider`s etiquetados (`// IDENTIDAD`, `// COMPORTAMIENTO`, `// APARIENCIA`).
- [ ] Todos los campos usan `AppTextField`; el system prompt es multilínea grande en fuente `mono` con contador.
- [ ] El color se elige con `ColorSwatchPicker`: fila de swatches HUD + botón personalizado con popover `flutter_colorpicker`.
- [ ] El swatch seleccionado muestra glow + anillo `textPrimary` + `HudCornerBrackets`.
- [ ] El botón guardar está disabled en `default` y habilitado con `glowGold` en `dirty`.
- [ ] Estado loading deshabilita el formulario y muestra spinner; no permite doble submit.
- [ ] Guardar con éxito muestra toast HUD de confirmación; fallo de red muestra toast `danger` sin perder cambios.
- [ ] La validación marca campos con borde `danger` + mensaje + foco automático al primer inválido.
- [ ] El autoguardado de borrador funciona con debounce y ofrece restaurar al reabrir.
- [ ] Se confirma antes de descartar cambios sin guardar.
- [ ] Cero hex sueltos, cero magic numbers: todo por tokens.
- [ ] Reduced motion respetado en todas las animaciones.
- [ ] Compila y se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores, acentos), 02 (`labelSmall`, `bodyM`, `mono`, `bodyS`), 03 (`space*`, `radius*`, `chamferM`, `elev*`, `glowGold`), 04 (`dur*`, curvas, reduced-motion), 05 (iconografía), 06 (`HudDivider`, `HudCornerBrackets`, `ChamferBorder`).
- **Núcleo:** 09 (`AppButton`), 10 (`AppTextField`), 11 (chips), 12 (`HoloPanel`), 13 (popover), 16 (estados de error), 17 (toasts).
- **Shell / detalle:** 30 (layout y tab bar).
- **Librería externa:** `flutter_colorpicker`, `shared_preferences` (ambos en `pubspec.yaml`).
