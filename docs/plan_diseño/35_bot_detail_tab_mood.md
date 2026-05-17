# 35 — Bot Detail · Tab Mood (selector de personalidad)

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Es el contenido del **tab índice 3** definido por el prompt 30.

---

## 1. Objetivo

Rediseñar el tab Mood del detalle de unidad: el selector de personalidad/mood del bot (los 6 moods: online, angry, happy, vendor, confused, tech). El rediseño lo convierte en una **grilla de tarjetas de mood seleccionables**, cada una con su color de acento, que al elegirse ilumina la tarjeta y hace reaccionar al avatar Rive de la columna izquierda en vivo.

---

## 2. Archivos

- **Crear:** `lib/features/dashboard/presentation/widgets/tabs/bot_mood_tab.dart` — el panel completo.
- **Crear:** `lib/features/dashboard/presentation/widgets/mood_card.dart` — tarjeta de mood seleccionable.
- **Modificar:** `lib/features/dashboard/presentation/views/bot_detail_view.dart` — `_selectedTab == 3` renderiza `BotMoodTab`.
- **Usar (no modificar la lógica):** `bot_mood_provider.dart` → `terminalBotMoodProvider` para escribir el mood activo.

---

## 3. Estado actual

- El mood se gobierna por `terminalBotMoodProvider` (índices 0–5) y lo consume la Rive vía el input `Mood`.
- El `StatusIndicator` ya mapea índices a etiquetas (`EN LÍNEA`, `ENOJADO`, `FELIZ`, `VENDEDOR`, `CONFUNDIDO`, `TÉCNICO`) y colores.
- No existe una pantalla dedicada para elegir el mood: no hay grilla de tarjetas, ni descripción de cada personalidad, ni feedback de selección.

---

## 4. Visión del rediseño

El tab Mood se lee como el **panel de calibración de personalidad** de la unidad. Una grilla de 6 tarjetas, una por mood. Cada tarjeta tiene un ícono expresivo, el nombre del mood, una descripción corta de cómo se comporta el bot en ese modo, y un **color de acento propio**. La tarjeta del mood activo se **ilumina con su glow**, gana `HudCornerBrackets` y un borde de acento; el resto queda en reposo neutro. Al seleccionar una tarjeta, el `RiveBotDisplay` de la columna izquierda (prompt 31) **cambia de expresión en vivo** —el Catbot se enoja, sonríe, etc.— y el HUD de estado recolorea. Elegir el mood se siente como calibrar el carácter de una criatura, con respuesta inmediata y satisfactoria.

---

## 5. Especificación visual

### 5.1 Layout del tab

- Raíz: `SingleChildScrollView` vertical.
- De arriba hacia abajo:
  1. `HudDivider` etiquetado `// PERSONALIDAD DE LA UNIDAD`.
  2. `space8`. Texto guía en `bodyS` `textSecondary`: `Elegí cómo se comporta y se expresa la unidad. El avatar reflejará el cambio.`
  3. `space20`.
  4. **Grilla de `MoodCard`** (`GridView`/`Wrap`, 3 columnas, gap `space20`; 2 columnas en breakpoint mínimo).

### 5.2 Los 6 moods

| Índice | Nombre | Ícono (set prompt 05) | Color de acento | Descripción corta |
|---|---|---|---|---|
| 0 | EN LÍNEA | `circle-dot` / `wifi` | `success` | Tono neutro y servicial. Estado por defecto. |
| 1 | ENOJADO | `flame` / `frown` | `danger` | Respuestas cortantes y directas. |
| 2 | FELIZ | `smile` / `sparkles` | `accentMagenta` (agregar token si no existe) | Entusiasta y cálido. |
| 3 | VENDEDOR | `tag` / `trending-up` | `gold` | Persuasivo, orientado a conversión. |
| 4 | CONFUNDIDO | `help-circle` | `accentViolet` (agregar token si no existe) | Dubitativo, pregunta para aclarar. |
| 5 | TÉCNICO | `cpu` / `terminal` | `cyan` | Preciso, detallado, lenguaje técnico. |

Los textos exactos de descripción pueden ajustarse, pero deben ser cortos (1 línea, ≤ ~60 caracteres) y vivir en `AppStrings` (i18n ya preparado en el proyecto).

### 5.3 `MoodCard`

- Contenedor: `HoloPanel` variante `default`, radio `radiusL`, padding `space20`, elevación `elev1`. Forma con `chamfer` opcional en 2 esquinas para dar carácter "instrumento".
- Composición `Column`, `crossAxisAlignment: start`:
  1. **Ícono** dentro de un cuadro 44×44 `surfaceHud` con esquinas biseladas; ícono 22 px en el color de acento del mood. En estado seleccionado, el cuadro gana glow del color.
  2. `space16`.
  3. **Nombre del mood** en `titleM` `textPrimary` UPPERCASE.
  4. `space8`.
  5. **Descripción** en `bodyS` `textSecondary`, hasta 2 líneas.
  6. `space16`.
  7. **Indicador inferior:** una línea fina (`HudReactorBar` mini horizontal o un divisor) del color de acento; en estado seleccionado late suavemente.
- **Tarjeta seleccionada (activa):**
  - Borde 1.5 px del color de acento del mood.
  - `glowStatus(colorMood)` (blur 18) alrededor de la tarjeta.
  - `HudCornerBrackets` en las 4 esquinas, color del mood.
  - Una insignia `SELECCIONADO` (chip `labelSmall`, prompt 11) en la esquina superior derecha, con el color del mood.
  - El nombre del mood sube su brillo (peso/colores ya `textPrimary`, el ícono y el reactor toman el color pleno).

---

## 6. Estados e interacciones

Matriz §9 aplicada a `MoodCard`:

| Estado | Apariencia |
|---|---|
| `default` (no seleccionado) | Borde `borderDefault`, sin glow, ícono en color de acento al ~70 %, reactor inferior tenue y estático. |
| `hover` | Borde sube a `borderStrong` con tinte del color del mood, elevación `elev2`, aparece un glow suave del color del mood; el ícono va a opacidad plena; cursor pointer. `durFast`. |
| `pressed` | Escala 0.97, `durInstant`. |
| `focused` (teclado) | Anillo de foco 2 px `cyan` insertado, radio `radiusM`. |
| `selected/active` | Borde + glow + `HudCornerBrackets` + chip `SELECCIONADO` del color del mood; reactor inferior late. |
| `loading` | Si persistir el mood implica una llamada async: la tarjeta recién pulsada muestra un mini-spinner sobre el ícono y se deshabilita la grilla brevemente. |
| `disabled` | No aplica normalmente; si la unidad está suspendida y no admite cambios, las tarjetas van a opacidad 0.4 sin interacción. |

- **Selección:** al pulsar una `MoodCard`, escribir el índice en `terminalBotMoodProvider`. Esto dispara:
  1. La Rive de la columna izquierda recibe el nuevo input `Mood` y cambia de expresión (el `ref.listen(terminalBotMoodProvider, ...)` de `RiveBotDisplay` ya lo hace).
  2. El `UnitAvatarPanel` y la `UnitTelemetryConsole` (prompt 31) recolorean borde/glow/reactor según el mapa de color de mood.
  3. El `StatusTag` del HUD y del chat (prompts 31/40) actualizan su etiqueta.
- **Persistencia:** si el mood se guarda en backend, persistir tras la selección (debounce corto) y mostrar feedback (toast HUD `MODO ACTUALIZADO`, prompt 17). Si solo es estado de sesión, no hace falta toast.

---

## 7. Animaciones

- **Entrada del tab:** las 6 tarjetas entran escalonadas (fade + translateY 12 px), 36 ms entre tarjetas, `easeEntrance`, `durBase`.
- **Selección de mood:** la tarjeta elegida hace un micro-pulso de escala 1.0→1.03→1.0 (`springSoft`); su glow y `HudCornerBrackets` aparecen con `durBase`; la tarjeta antes seleccionada pierde su glow/brackets simultáneamente con `durFast`.
- **Reactor inferior:** late (opacidad 0.6↔1.0, ~1600 ms) solo en la tarjeta seleccionada.
- **Enganche con la Rive:** el cambio de expresión del Catbot lo gestiona la máquina de estados de Rive; este prompt solo garantiza que la escritura del provider es inmediata al `tap` (sin debounce visual).
- **Hover:** borde/glow/elevación con `durFast`.
- **Reduced motion** (`AppMotion.reduced`): sin escalonado (fade conjunto 120 ms); sin micro-pulso de escala en la selección (corte directo de glow/brackets); sin latido del reactor (estático). El cambio de la Rive se mantiene (es la función central del tab).

---

## 8. Accesibilidad

- Cada `MoodCard` es un control seleccionable: `Semantics(label: "Modo <nombre>: <descripción>", selected: esActivo, button: true)`, en un grupo `radiogroup` (solo uno activo).
- La selección no depende solo del color: el mood activo lleva chip `SELECCIONADO` con texto + `HudCornerBrackets` visibles.
- Navegación por teclado: flechas mueven el foco entre tarjetas; `Enter`/`Espacio` selecciona; foco visible `cyan`.
- Contraste: `titleM` `textPrimary` ≥ 12:1; descripción `textSecondary` ≥ 4.5:1; íconos/colores de acento ≥ 3:1 sobre el panel. Verificar especialmente `accentMagenta` y `accentViolet`.
- Si se persiste con error, toast `danger` anunciado con `liveRegion`.
- Targets de tarjeta ≥ 32 px de alto, cómodamente clickeables.

---

## 9. Checklist de aceptación

- [ ] El tab muestra una grilla de 6 `MoodCard`, una por mood (online·angry·happy·vendor·confused·tech).
- [ ] Cada tarjeta tiene ícono, nombre, descripción corta y un color de acento propio.
- [ ] La tarjeta seleccionada se ilumina con glow + `HudCornerBrackets` + borde de acento + chip `SELECCIONADO`.
- [ ] Seleccionar una tarjeta escribe `terminalBotMoodProvider` y el avatar Rive de la izquierda cambia de expresión en vivo.
- [ ] El HUD de estado (prompt 31) y el `StatusTag` recolorean al cambiar de mood.
- [ ] Los moods happy/confused tienen tokens de color (`accentMagenta`/`accentViolet`) si no existían.
- [ ] La selección tiene micro-pulso de escala y la tarjeta previa pierde su glow.
- [ ] La grilla colapsa a 2 columnas en breakpoint mínimo.
- [ ] Cero hex sueltos, cero magic numbers: todo por tokens.
- [ ] Reduced motion respetado (sin escalonado, sin pulso, sin latido).
- [ ] Compila y se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores, acentos `accentMagenta`/`accentViolet`), 02 (`titleM`, `bodyS`, `labelSmall`), 03 (`space*`, `radius*`, `chamferM`, `elev*`, `glowStatus`), 04 (`dur*`, `springSoft`, reduced-motion), 05 (iconografía), 06 (`HudDivider`, `HudCornerBrackets`, `HudReactorBar`).
- **Núcleo:** 11 (chips/`StatusTag`), 12 (`HoloPanel`), 17 (toasts).
- **Shell / detalle:** 30 (layout y tab bar), 31 (`RiveBotDisplay` + HUD que reaccionan al mood).
- **Provider:** `bot_mood_provider.dart` (`terminalBotMoodProvider`).
