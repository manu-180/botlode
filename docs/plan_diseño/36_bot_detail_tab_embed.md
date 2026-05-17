# 36 — Bot Detail · Tab Embed (código de inserción)

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Es el contenido del **tab índice 4** definido por el prompt 30.

---

## 1. Objetivo

Rediseñar el tab Embed del detalle de unidad: el código de inserción y la URL del player (`botlode-player.vercel.app`) que el operario pega en su sitio. Hoy el embed se muestra en un diálogo modal con un bloque de texto plano. El rediseño lo convierte en un **panel terminal de despliegue**: bloque de código mono con números de línea, botón copiar con feedback, preview del player y campos de configuración.

---

## 2. Archivos

- **Crear:** `lib/features/dashboard/presentation/widgets/tabs/bot_embed_tab.dart` — el panel completo.
- **Crear:** `lib/features/dashboard/presentation/widgets/code_block_panel.dart` — bloque de código terminal reutilizable.
- **Modificar:** `lib/features/dashboard/presentation/views/bot_detail_view.dart` — `_selectedTab == 4` renderiza `BotEmbedTab`; eliminar `_showEmbedDialog` como modal (el código del embed string se conserva, ahora se muestra inline en este tab).

---

## 3. Estado actual

- `_showEmbedDialog(Bot bot)` arma un `embedCode` (iframe + hitzones + script, ~700 líneas de string) y lo muestra en un diálogo.
- El bloque de código no tiene números de línea, ni resaltado, ni estilo terminal HUD, ni un botón de copiado con feedback claro.
- La URL del player (`AppConfig.playerBaseUrl` = `https://botlode-player.vercel.app`) se concatena con `?botId=...`.
- No hay preview del player, ni campos para ajustar el embed.

---

## 4. Visión del rediseño

El tab Embed se lee como la **consola de despliegue de la unidad**: desde acá el operario "saca la unidad al mundo". Arriba, una tarjeta con la **URL directa del player** y un botón copiar. Debajo, el **bloque de código de inserción** dentro de un `HoloPanel` estilo terminal: fondo `surfaceHud`, una barra de título tipo terminal (semáforo HUD + ruta `// EMBED · iframe`), números de línea en una columna `mono` tenue, el código con sintaxis atenuada, y un botón `COPIAR` flotante arriba a la derecha. Al copiar, un toast HUD confirma. A un lado o debajo, un **preview** del player embebido (o un placeholder si no se puede renderizar) y campos para ajustar el embed (posición de la burbuja, tamaño). Todo se siente como una terminal de operaciones, no como un campo de texto.

---

## 5. Especificación visual

### 5.1 Layout del tab

- Raíz: `SingleChildScrollView` vertical.
- De arriba hacia abajo:
  1. `HudDivider` etiquetado `// DESPLIEGUE DE LA UNIDAD`.
  2. `space16`.
  3. **Tarjeta de URL del player** (ver §5.2).
  4. `space24`.
  5. `HudDivider` etiquetado `// CÓDIGO DE INSERCIÓN`.
  6. `space16`.
  7. **`CodeBlockPanel`** con el embed completo (ver §5.3).
  8. `space24`.
  9. `HudDivider` etiquetado `// VISTA PREVIA`.
  10. `space16`.
  11. **Preview del player** (ver §5.5).

### 5.2 Tarjeta de URL del player

- `HoloPanel` variante `flat`, padding `space16`, radio `radiusM`.
- `Row`: ícono `link` 18 px `cyan` + `Expanded` con la URL completa (`{playerBaseUrl}?botId={botId}`) en `mono` `textPrimary`, seleccionable, una sola línea con scroll horizontal si es larga + `AppIconButton` `copy` (`tooltip: "Copiar URL"`).
- Bajo la URL, `labelSmall` `textTertiary`: `Enlace directo a la unidad en el player.`

### 5.3 `CodeBlockPanel` — bloque de código terminal

- Contenedor: `HoloPanel` variante `hud`, fondo `surfaceHud`, radio `radiusL`, `chamfer` en 2 esquinas superiores, borde `borderDefault`.
- **Barra de título terminal** (arriba, alto 36 px, fondo un paso más oscuro que `surfaceHud`, borde inferior `borderSubtle`):
  - A la izquierda: tres puntos HUD (semáforo) 8 px en `textTertiary`/`danger`/`success` muy atenuados — decorativo.
  - Centro: ruta en `mono` `textTertiary` → `// EMBED · iframe + script`.
  - A la derecha: botón `COPIAR` (`AppButton` mini variante `ghost`, ícono `clipboard` + label `COPIAR` en `labelSmall`).
- **Cuerpo del código:**
  - `Row`: columna de **números de línea** (`mono` 12, `textTertiary` al 50 %, alineados a la derecha, fondo `surfaceHud` un tono, ancho fijo ~40 px, borde derecho `borderSubtle`) + el código.
  - Código en `mono` `textSecondary`, interlineado 1.5, padding `space16`.
  - **Sintaxis tenue:** no hace falta un highlighter completo; basta con diferenciar: etiquetas/tags HTML en `cyan` atenuado, atributos en `textTertiary`, strings en `gold` atenuado, comentarios en `textTertiary` itálica. Mantener todo sobrio (nada saturado).
  - Scroll vertical interno con altura máxima ~320 px; scroll horizontal si las líneas exceden el ancho. Scrollbar HUD fino.
- El bloque es de **solo lectura** (no editable); el texto es seleccionable.

### 5.4 Campos de configuración del embed

- Un `HoloPanel` variante `flat` con controles que ajustan el embed generado:
  - `Posición de la burbuja`: selector segmentado (abajo-derecha / abajo-izquierda).
  - `Tamaño de la burbuja`: un slider HUD pequeño (reusar el patrón de `_BubbleSizeSlider` ya existente, restilizado a tokens).
- Cambiar un control **regenera el `embedCode`** mostrado en el `CodeBlockPanel` en vivo.

### 5.5 Preview del player

- `HoloPanel` con `HudCornerBrackets`, fondo `surfaceHud` + `HudGridTexture`, altura ~280 px.
- Dentro, una representación del player: si la app puede embeber una webview/iframe, mostrar el player real en pequeño; si no, un **placeholder** ilustrativo — un mock estático de la burbuja flotante del player en la esquina inferior derecha del panel, con un `labelSmall` `textTertiary` central `Vista previa del player`.
- No bloquear el tab si el preview no carga: degradar al placeholder.

---

## 6. Estados e interacciones

Matriz §9 aplicada:

| Estado | Apariencia |
|---|---|
| `default` | URL, código y preview visibles; botón `COPIAR` en reposo. |
| `hover` (botón copiar / `AppIconButton`) | Borde + glow suben con `durFast`; cursor pointer. |
| `pressed` | Escala 0.97, `durInstant`. |
| `focused` | Anillo `cyan` 2 px en el control enfocado. |
| `copied` (acción copiar) | El botón `COPIAR` cambia momentáneamente a `COPIADO ✓` con ícono `check` `success` durante ~1600 ms y luego vuelve; en paralelo aparece un **toast HUD** `CÓDIGO COPIADO AL PORTAPAPELES` (prompt 17). |
| `loading` (preview cargando) | El panel de preview muestra un skeleton (prompt 14) con shimmer. |
| `error` (preview no disponible) | El panel de preview cae al placeholder estático con mensaje `Vista previa no disponible` — no es un error bloqueante, no usa `ErrorFeedbackCard` rojo, solo el placeholder neutro. |
| `empty` | No aplica: siempre hay un embed que mostrar mientras exista el bot. |

- **Copiar:** usa `Clipboard.setData`; copia el `embedCode` completo (o la URL, según el botón).
- **Cambiar configuración del embed:** regenera el código y, sutilmente, resalta el `CodeBlockPanel` por un instante (borde `cyan` flash `durFast`) para indicar que se actualizó.

---

## 7. Animaciones

- **Entrada del tab:** las secciones (URL, código, config, preview) entran escalonadas (fade + translateY 12 px), 36 ms, `easeEntrance`, `durBase`.
- **Feedback de copiado:** el cambio de label `COPIAR`→`COPIADO ✓` con crossfade `durFast`; el toast entra con `easeEntrance` + escala 0.96→1.0 `durBase` (prompt 17).
- **Regeneración del código:** al cambiar un control, el `CodeBlockPanel` hace un flash de borde `cyan` (aparece y se desvanece, `durFast`); el texto del código se actualiza con un crossfade muy corto (`durInstant`).
- **Hover:** `durFast`.
- **Preview:** si se carga real, fade-in `durBase`; el skeleton hace shimmer estándar.
- **Reduced motion** (`AppMotion.reduced`): sin escalonado de secciones (fade conjunto 120 ms); sin flash de borde al regenerar; el feedback de copiado se reduce al cambio de label sin escala; toast con fade simple.

---

## 8. Accesibilidad

- El bloque de código es texto seleccionable; expone `Semantics(label: "Código de inserción del player, solo lectura")`.
- El botón `COPIAR` tiene `tooltip` y, al copiar, anuncia el éxito con `liveRegion` (`Código copiado`).
- La URL del player es seleccionable y su botón copiar tiene `tooltip` propio.
- Los números de línea son decorativos: marcarlos `excludeSemantics` para no ensuciar la lectura.
- Los controles de configuración (selector de posición, slider) tienen label y valor accesibles.
- Contraste: código `textSecondary` sobre `surfaceHud` ≥ 4.5:1; números de línea `textTertiary` ≥ 3:1; los colores de sintaxis atenuados deben igualmente cumplir ≥ 3:1 (verificar; si no llegan, subir su opacidad).
- Foco visible en todos los controles; orden de foco arriba→abajo.

---

## 9. Checklist de aceptación

- [ ] Hay una tarjeta con la URL directa del player (`playerBaseUrl?botId=...`) y botón copiar.
- [ ] El código de inserción se muestra en un `CodeBlockPanel` estilo terminal: barra de título, números de línea, sintaxis atenuada, fondo `surfaceHud`.
- [ ] El bloque de código es de solo lectura y seleccionable, con scroll vertical/horizontal interno.
- [ ] El botón `COPIAR` copia el embed y da feedback (`COPIADO ✓` + toast HUD).
- [ ] Hay campos de configuración (posición/tamaño de burbuja) que regeneran el código en vivo.
- [ ] Hay un preview del player o un placeholder neutro si no se puede renderizar.
- [ ] `HudDivider`s etiquetados separan las secciones.
- [ ] El preview no bloquea el tab si falla (degrada a placeholder, sin error rojo).
- [ ] Cero hex sueltos, cero magic numbers: todo por tokens.
- [ ] Reduced motion respetado (sin escalonado, sin flash, sin escala en copiado).
- [ ] Compila y se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores), 02 (`mono`, `labelSmall`), 03 (`space*`, `radius*`, `chamferM`), 04 (`dur*`, curvas, reduced-motion), 05 (iconografía), 06 (`HudDivider`, `HudCornerBrackets`, `HudGridTexture`, `ChamferBorder`).
- **Núcleo:** 09 (`AppButton`, `AppIconButton`), 12 (`HoloPanel`), 14 (skeletons), 17 (toasts).
- **Shell / detalle:** 30 (layout y tab bar).
- **Config:** `AppConfig.playerBaseUrl`. Reusa el patrón del slider de `_BubbleSizeSlider` existente.
