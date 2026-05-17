# 40 — Chat · Status indicator

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Rediseña `StatusIndicator`, el indicador de estado del chat.

---

## 1. Objetivo

Rediseñar `StatusIndicator`: la cápsula que muestra el estado operativo del bot en la terminal de chat (y reutilizable en el HUD de estado del prompt 31). Hoy es una cápsula biselada `#0A0A0A` con un reactor que aparece/desaparece y texto `Courier` 10 px. El rediseño la alinea al sistema HUD: cápsula biselada con tokens, `HudReactorBar` que late, texto `hudReadout`, y todas las variantes de estado y mood definidas con precisión.

---

## 2. Archivos

- **Modificar:** `lib/features/bot_engine/presentation/widgets/status_indicator.dart` — reescribir con tokens, `HudReactorBar` y `HudStatusDot`.
- **Opcional:** extraer una variante `StatusTag` compartida si el prompt 11 ya la define; en ese caso `StatusIndicator` puede ser una composición de `StatusTag` especializada para el chat. Alinear con lo que exista del prompt 11.

---

## 3. Estado actual

- `StatusIndicator` recibe `isLoading`, `isOnline`, `moodIndex`, `isDarkMode`.
- Calcula texto + color: `SIN CONEXIÓN` (`error`), `ESCRIBIENDO...` (`secondary`), o por mood (`ENOJADO` `#FF2A00`, `FELIZ` `#FF00D6`, `VENDEDOR` `#FFC000`, `CONFUNDIDO` `#7B00FF`, `TÉCNICO` `#00F0FF`, `EN LÍNEA` `#00FF94`).
- Contenedor: `ShapeDecoration` con `BeveledRectangleBorder` de radios mixtos (`0/10/4/4`), fondo `#0A0A0A @0.95`, sombra negra.
- Reactor: `Container` 4×14 con doble `BoxShadow`, animado con `flutter_animate` (`fadeIn`/`fadeOut` en bucle, ritmo distinto si `isOnline`).
- Hex sueltos, sin tokens de motion, sin reduced-motion, modo claro innecesario (la app es dark-only).

---

## 4. Visión del rediseño

El indicador es una **cápsula de instrumentación** compacta: lee el estado de la unidad de un vistazo. Forma biselada (`chamfer`), fondo `surfaceHud`, una `HudReactorBar` vertical que **late** con el ritmo según el estado, y un texto de estado en `hudReadout`. El color, el ícono y la velocidad del latido cambian según el estado: verde estable online, cyan rápido procesando, rojo sin latido offline, y un color por cada mood. Es la misma pieza de vocabulario que el HUD de estado del avatar (prompt 31) y la barra de título del chat (prompt 38). Sobrio, preciso, vivo.

---

## 5. Especificación visual

### 5.1 Cápsula

- Contenedor con `ShapeDecoration` + `ChamferBorder` (prompt 06) — esquinas biseladas a 45°, `chamferM` reducido (~8 px) para una cápsula pequeña.
- Fondo: `surfaceHud`. Borde: 1 px `borderDefault`.
- Elevación: `elev1`; opcionalmente `glowStatus(colorEstado)` muy sutil cuando el estado es activo.
- Padding: `space8` izquierda, `space12` derecha, `space8` vertical.
- Alto total ~28 px; se adapta al contenido.

### 5.2 Contenido (`Row`, `mainAxisSize: min`)

1. **`HudReactorBar`** (prompt 06): barra vertical fina, 4 px de ancho × 14 px de alto, radio `radiusXS`, color = color del estado, con glow del color (`glowStatus`). Late según §5.4.
2. `SizedBox(width: space8)`.
3. **Ícono de estado** opcional, 12 px, color del estado (refuerza el estado más allá del color — ver §5.3). Si el espacio es muy ajustado, el ícono puede omitirse y dejar que el `HudStatusDot` integrado en el reactor cumpla ese rol.
4. `SizedBox(width: space4)`.
5. **Texto de estado** en `hudReadout` (JetBrains Mono, 13/500/+0.5), color = `textPrimary` (no el color del estado, para legibilidad) — el color del estado vive en el reactor y el ícono. UPPERCASE.

### 5.3 Variantes de estado

| Estado | Texto | Color (token) | Ícono | Latido |
|---|---|---|---|---|
| Online (mood 0) | `EN LÍNEA` | `success` | `circle-dot` | lento (~1600 ms) |
| Procesando / escribiendo | `PROCESANDO...` / `ESCRIBIENDO...` | `cyan` | `loader`/`activity` | rápido (~900 ms) |
| Sin conexión | `SIN CONEXIÓN` | `danger` | `wifi-off` | **sin latido** (estático) |
| Mood angry (1) | `ENOJADO` | `danger` | `flame` | lento |
| Mood happy (2) | `FELIZ` | `accentMagenta` (agregar token si no existe) | `smile` | lento |
| Mood vendor (3) | `VENDEDOR` | `gold` | `tag` | lento |
| Mood confused (4) | `CONFUNDIDO` | `accentViolet` (agregar token si no existe) | `help-circle` | lento |
| Mood tech (5) | `TÉCNICO` | `cyan` | `cpu` | lento |

- **Prioridad de estado:** `sin conexión` > `procesando` > mood. Es decir: si no hay conexión, manda `SIN CONEXIÓN`; si hay conexión y el bot procesa, manda `PROCESANDO...`; si no, manda el mood actual.
- Los hex sueltos actuales (`#FF2A00`, `#FF00D6`, `#7B00FF`, etc.) se reemplazan por tokens (`danger`, `accentMagenta`, `accentViolet`, `cyan`, `gold`, `success`). Si `accentMagenta`/`accentViolet` no existen, agregarlos en `app_colors.dart` (prompt 01).

### 5.4 Latido del reactor

- **Latido lento** (estados online / mood): pulso de opacidad 0.6↔1.0, periodo ~1600 ms, curva `easeStandard`, `repeat(reverse: true)`.
- **Latido rápido** (procesando/escribiendo): mismo pulso, periodo ~900 ms.
- **Sin latido** (sin conexión): el reactor queda en opacidad fija 1.0 — un punto/barra estático, sin pulso (la unidad "no emite vida").
- El glow del reactor acompaña el latido (sube/baja con la opacidad).

---

## 6. Estados e interacciones

`StatusIndicator` es un indicador **informativo, no interactivo**. La matriz §9 se aplica de forma reducida:

| Estado | Apariencia |
|---|---|
| `default` | Cápsula con la variante de estado actual (color + ícono + texto + latido según §5.3/§5.4). |
| `transición de estado` | Cuando cambia el estado (online→procesando, etc.), el color del reactor/ícono y el texto hacen crossfade; el ritmo del latido cambia suavemente. |
| `loading` | No tiene estado de carga propio; "procesando" ya es su variante. |
| `disabled` | No aplica (siempre refleja un estado real). |
| `hover`/`pressed`/`focused` | No aplican: no es un control. |

- El indicador deriva su estado de los flags que recibe (`isOnline`, `isTyping`/`isLoading`, `moodIndex`); no tiene estado interno editable.

---

## 7. Animaciones

- **Latido del reactor:** según §5.4 — lento, rápido o sin latido. `AnimationController` con `repeat(reverse: true)`, curva `easeStandard`. Sustituir el `flutter_animate` `fadeIn/fadeOut` actual por un latido controlado por token de duración.
- **Cambio de estado:** al cambiar la variante, el color del reactor y del ícono transiciona con `durBase` `easeStandard`; el texto hace un crossfade `durFast`; el ritmo del latido se ajusta sin corte brusco.
- **Aparición:** al montar, la cápsula entra con fade `durFast`; el reactor hace un primer pulso un poco más marcado ("encendido").
- **Reduced motion** (`AppMotion.reduced`): **sin latido** — el reactor queda como un punto/barra estático en opacidad fija para todos los estados; el cambio de estado se reduce a un crossfade de 120 ms sin transición de ritmo; sin pulso de encendido. El estado sigue siendo legible por color + ícono + texto.

---

## 8. Accesibilidad

- El indicador expone `Semantics(label: "Estado de la unidad: <texto del estado>", liveRegion: true)` de modo que un cambio de estado se anuncie al lector de pantalla.
- El estado **nunca depende solo del color**: cada variante lleva color + ícono + texto. Esto es crítico aquí porque el indicador es pequeño.
- Contraste: el texto `hudReadout` `textPrimary` sobre `surfaceHud` debe cumplir ≥ 4.5:1 (verificar; el texto es chico). El reactor y el ícono de color cumplen ≥ 3:1 como glifos de UI.
- El latido es un refuerzo decorativo: si reduced-motion lo apaga, el estado sigue 100 % comunicado por color+ícono+texto.
- No es enfocable (no es interactivo); no introduce un nodo de foco vacío.
- Verificar que `accentMagenta` y `accentViolet` tengan contraste suficiente como glifo (≥ 3:1) sobre `surfaceHud`; si no, ajustar el token.

---

## 9. Checklist de aceptación

- [ ] La cápsula usa `ChamferBorder`, fondo `surfaceHud`, borde `borderDefault` y elevación `elev1` (sin hex sueltos, sin modo claro).
- [ ] Contiene un `HudReactorBar` vertical que late + ícono de estado + texto en `hudReadout`.
- [ ] Las 8 variantes de §5.3 están implementadas con su color (token), ícono y texto.
- [ ] El latido es lento online/mood, rápido en procesando, y **estático** sin conexión.
- [ ] La prioridad de estado es sin conexión > procesando > mood.
- [ ] Los hex sueltos (`#FF2A00`, `#FF00D6`, `#7B00FF`, etc.) se reemplazaron por tokens; `accentMagenta`/`accentViolet` existen.
- [ ] El texto del estado es `textPrimary` (legible); el color del estado vive en el reactor y el ícono.
- [ ] El cambio de estado transiciona suavemente (color `durBase`, texto crossfade `durFast`).
- [ ] El estado se comunica por color + ícono + texto, nunca solo color.
- [ ] Reduced motion: sin latido (reactor estático), cambio de estado en crossfade 120 ms.
- [ ] Accesibilidad: `Semantics` con `liveRegion`, contraste verificado.
- [ ] Compila y se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores: `success`, `cyan`, `danger`, `gold`, `accentMagenta`, `accentViolet`, `glowStatus`), 02 (`hudReadout`), 03 (`space*`, `radiusXS`, `chamferM`, `elev1`), 04 (`dur*`, `easeStandard`, reduced-motion), 05 (iconografía), 06 (`HudReactorBar`, `HudStatusDot`, `ChamferBorder`).
- **Núcleo:** 11 (`StatusTag` — si está definido, `StatusIndicator` se alinea/compone con él).
- **Chat / detalle:** 38 (`BotChatConsole` lo usa en la barra de título), 31 (HUD de estado del avatar lo reutiliza).
