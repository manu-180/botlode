# 31 — Bot Detail · RiveBotDisplay y HUD de estado

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Rediseña la **columna izquierda** definida por el prompt 30.

---

## 1. Objetivo

Rediseñar el marco del avatar Rive (`RiveBotDisplay`) y la consola de telemetría de estado que vive debajo. Hoy la Rive flota sin marco sobre un `SizedBox`; el rediseño la encierra en un `HoloPanel` con ornamento HUD completo y le añade una lectura de telemetría viva (estado, reactor, micro-datos) cuyo glow reacciona al mood de la unidad.

---

## 2. Archivos

- **Modificar:** `lib/features/bot_engine/presentation/widgets/rive_bot_display.dart` — conservar la máquina de estados, el eye-tracking y los inputs; solo cambia el contenedor visual y se vuelve parametrizable (`size`, `botColor`).
- **Crear:** `lib/features/dashboard/presentation/widgets/unit_avatar_panel.dart` — el `HoloPanel` que enmarca la Rive.
- **Crear:** `lib/features/dashboard/presentation/widgets/unit_telemetry_console.dart` — la consola de lecturas debajo del avatar.
- **Modificar:** `lib/features/dashboard/presentation/views/bot_detail_view.dart` — la columna izquierda compone `UnitAvatarPanel` + `UnitTelemetryConsole`.

---

## 3. Estado actual

- `RiveBotDisplay` es un `SizedBox(300×300)` con `RiveAnimation.direct` y nada más: sin marco, sin fondo, sin glow. La Rive "flota" suelta sobre la columna.
- El eye-tracking funciona vía `terminalPointerPositionProvider` con física híbrida (lerp 0.4 / 0.04) y los inputs `LookX`, `LookY`, `Mood`.
- El estado se muestra aparte con el `StatusIndicator` (cápsula biselada `#0A0A0A`, reactor bar animado, texto Courier 10 px) — hoy ubicado en otra parte de la vista.
- No hay panel contenedor, ni `HudCornerBrackets`, ni `HudScanlines`, ni `HudGridTexture`, ni glow del color del bot, ni lecturas de telemetría.

---

## 4. Visión del rediseño

La columna izquierda se lee como la **bahía de contención de la unidad**. Arriba, el avatar Catbot vive dentro de un `HoloPanel` con cantos biselados (`chamfer`), `HudCornerBrackets` dorados en las esquinas, una textura de retícula técnica de fondo (`HudGridTexture`) y un **glow radial ambiental del color del bot** detrás del personaje, como si la unidad emitiera energía. Unas `HudScanlines` sutilísimas recorren el panel. El eye-tracking se conserva intacto: el Catbot sigue al cursor.

Debajo, una **consola de telemetría** compacta: el `StatusTag` operativo, un `HudReactorBar` horizontal que **late al ritmo del mood**, y una grilla de micro-lecturas en `hudReadout` (mood actual, uptime, sesión, latencia ficticia/real). El glow del marco del avatar **cambia de color según el mood/estado**: dorado en venta, cyan en técnico, verde online, rojo offline, etc. Todo comunica que la unidad está viva y monitoreada.

---

## 5. Especificación visual

### 5.1 `UnitAvatarPanel` — marco del avatar

- Contenedor: `HoloPanel` (prompt 12) variante `hud`, radio `radiusL`, **con `chamfer`** (`ChamferBorder`, `chamferM`) en las 4 esquinas → forma de instrumento.
- Relleno: `gradPanel` (linear 160° `surfaceRaised`→`surface`).
- Borde: 1.5 px. Color base `borderDefault`; en estado activo el borde toma el **color de mood** (ver §5.3) al ~32 % de opacidad.
- Elevación: `elev1` + glow de estado (`glowStatus(moodColor)`, blur 18).
- Capas internas, de atrás hacia adelante (`Stack`):
  1. `HudGridTexture` (`opacity 0.04`) cubriendo el panel.
  2. **Glow radial del color del bot:** `RadialGradient` centrado, del color del bot al 22 % en el centro → transparente en los bordes; ocupa ~70 % del panel detrás del personaje.
  3. `RiveBotDisplay` centrado. Tamaño 280×280 (≥1440 px), 240×240 en breakpoint mínimo (parámetro `size`).
  4. `HudScanlines` (`opacity 0.035`, separación 3 px) — overlay no interactivo encima de todo.
  5. `HudCornerBrackets` en las 4 esquinas, brazo 20 px, grosor 1.5 px, color = color de mood al 60 %.
- `HudIdTag` opcional en la esquina superior izquierda interna con el ID corto.
- Padding interno del panel: `space20`. Alto del panel: el ancho de la columna − padding (cuadrado aprox.), tope `space24` de margen inferior antes de la consola.

### 5.2 `UnitTelemetryConsole` — consola de telemetría

- Contenedor: `HoloPanel` variante `flat`, relleno `surfaceHud`, radio `radiusM`, borde `borderDefault`, padding `space16`.
- Composición vertical:
  1. **Fila de estado:** `StatusTag` (prompt 11 / prompt 40) a la izquierda con el estado operativo + a la derecha un `labelSmall` `textTertiary` con `// TELEMETRÍA`.
  2. `HudDivider` horizontal sin etiqueta, `space12` de margen vertical.
  3. **`HudReactorBar` horizontal:** barra fina de 6 px de alto, ancho completo, color = color de mood, con glow. Late (pulso de opacidad) — ver §7. Representa "energía de la unidad".
  4. `space12`.
  5. **Grilla de micro-lecturas:** `Wrap`/`GridView` de 2 columnas, cada celda un par label+valor:
     - `MODO`: nombre del mood actual (`EN LÍNEA`, `VENDEDOR`, `TÉCNICO`, etc.).
     - `UPTIME`: tiempo desde `cycle_start_date` o valor real disponible, formato `mono`.
     - `SESIÓN`: ID corto de sesión de chat (`mono`).
     - `LATENCIA`: ms de la última respuesta del brain si está disponible; si no, `--`.
     - Label en `labelSmall` `textTertiary` UPPERCASE; valor en `hudReadout` `textPrimary` (los numéricos con figuras tabulares).
- Si una lectura no tiene dato real: mostrar `--` en `textTertiary`, nunca inventar números que parezcan reales sin marcarlos como placeholder.

### 5.3 Color de mood → color del marco/glow

El índice de mood (input `Mood` de la Rive, 0–5) mapea a un color de acento que tiñe borde, brackets, glow del avatar, `HudReactorBar` y `StatusTag`:

| Mood | Índice | Color de acento (token) |
|---|---|---|
| online | 0 | `success` |
| angry | 1 | `danger` |
| happy | 2 | un token de acento magenta — si no existe, **agregarlo** en `app_colors.dart` como `accentMagenta` antes de usarlo |
| vendor | 3 | `gold` |
| confused | 4 | un token de acento violeta — si no existe, **agregarlo** como `accentViolet` |
| tech | 5 | `cyan` |

Si la unidad está **offline** (sin conexión), el color de estado pasa a `danger` y el glow del avatar se atenúa al 40 % (la unidad "no emite").

### 5.4 Eye-tracking

- Se conserva intacto: máquina de estados `State Machine 1`/`State Machine`, inputs `LookX`/`LookY`/`Mood`, física híbrida lerp 0.4/0.04, `terminalPointerPositionProvider`.
- El `Ticker` y el `lerpDouble` no se tocan. Solo se parametriza el tamaño del `SizedBox` interno.

---

## 6. Estados e interacciones

Matriz §9 aplicada al panel del avatar y la consola:

| Estado | Apariencia |
|---|---|
| `default` (online) | Borde + brackets + glow en color de mood; reactor late lento; eye-tracking activo. |
| `hover` (sobre el panel) | El glow del avatar sube ~15 %; brackets aclaran; `durFast`. (El panel no es clickeable; el hover es solo respuesta de "vida".) |
| `loading` (Rive cargando) | Panel presente con `HudGridTexture` y brackets; en el centro un skeleton circular (prompt 14) en lugar del Catbot; reactor en cyan latido neutro; lecturas en `--`. |
| `processing` (bot escribiendo) | Color de estado pasa a `cyan`; reactor late más rápido; `StatusTag` muestra `PROCESANDO...`. |
| `error` (Rive falló al cargar) | Panel con ícono de error central (`alert-triangle`) `danger`, mensaje breve `bodyS`, brackets en `danger`; consola muestra `StatusTag` `OFFLINE`. |
| `offline` | Glow atenuado 40 %, color `danger`, reactor sin latido (estático), eye-tracking en reposo (mira al frente). |

Sin estados `pressed`/`selected`/`focused` (no es un control interactivo). El cambio de mood se enlaza desde el **tab Mood (prompt 35)**: al seleccionar un mood ahí, se actualiza `terminalBotMoodProvider`, la Rive recibe el nuevo `Mood` y este panel recolorea borde/glow/reactor.

---

## 7. Animaciones

- **Latido del `HudReactorBar`:** pulso de opacidad 0.6↔1.0, periodo ~1600 ms en estado online; ~900 ms en `processing` (latido más rápido, color `cyan`); **sin latido** (opacidad fija 1.0) en `offline`/`error`. Curva `easeStandard`, `repeat(reverse: true)`.
- **Glow del avatar:** transición de color con `durBase` cuando cambia el mood; transición de intensidad con `durFast` en hover.
- **Shimmer de marco:** un barrido `gradGoldSheen` recorre el borde del panel cada ~3200 ms — **solo** cuando el mood es `vendor` (oro). En otros moods, sin shimmer.
- **Entrada:** el panel del avatar entra con fade + scale 0.96→1.0 (`easeEntrance`, `durSlow`); la consola entra +60 ms después con fade + translateY 12 px (`easeEntrance`, `durBase`). El Catbot "despierta": al montar, el reactor hace un pulso único más intenso.
- **Cambio de mood:** transición de color de borde/brackets/glow/reactor sincronizada, `durBase`, `easeStandard`.
- **Reduced motion** (`AppMotion.reduced`): sin latido del reactor (opacidad fija), sin shimmer, sin pulso de despertar; la entrada se reduce a fade de 120 ms; el eye-tracking se conserva (es funcional, no decorativo, pero su suavizado ya es físico y discreto).

---

## 8. Accesibilidad

- El panel del avatar es decorativo-funcional: exponer un `Semantics(label: "Avatar de la unidad ${nombre}, estado ${mood}")`, no enfocable.
- La consola de telemetría: cada par label+valor es legible por lector de pantalla con su label descriptivo; los valores numéricos con figuras tabulares.
- El estado de la unidad nunca se comunica solo por color: `StatusTag` siempre lleva ícono + texto además del color de mood.
- Contraste: `hudReadout` `textPrimary` sobre `surfaceHud` ≥ 12:1; labels `textTertiary` ≥ 3:1 (texto pequeño de metadato). Verificar.
- En `error` de carga de Rive, el mensaje se expone con `liveRegion: true` (role alert).
- El glow y el latido son refuerzos: si reduced-motion los apaga, el `StatusTag` con ícono+texto sigue comunicando todo el estado.

---

## 9. Checklist de aceptación

- [ ] La Rive vive dentro de un `HoloPanel` con `chamfer`, `HudCornerBrackets`, `HudScanlines` y `HudGridTexture`.
- [ ] Hay un glow radial del color del bot detrás del Catbot.
- [ ] El borde, los brackets, el glow y el `HudReactorBar` cambian de color según el mood (mapa §5.3).
- [ ] Los moods happy/confused tienen tokens de color definidos (`accentMagenta`/`accentViolet`) si no existían.
- [ ] El eye-tracking sigue funcionando idéntico (inputs `LookX`/`LookY`/`Mood`, física híbrida).
- [ ] La `UnitTelemetryConsole` muestra `StatusTag` + `HudReactorBar` latente + grilla de micro-lecturas en `hudReadout`.
- [ ] Las lecturas sin dato real muestran `--`, no números inventados.
- [ ] El reactor late lento online, rápido en `processing`, sin latido en `offline`.
- [ ] Estados loading (skeleton circular) y error (ícono `danger`) implementados.
- [ ] Cero hex sueltos, cero magic numbers: todo por tokens.
- [ ] Reduced motion: sin latido, sin shimmer, sin pulso; entrada en fade 120 ms; eye-tracking conservado.
- [ ] Compila y se ve correcto en 1280×720 y 1024×600 (avatar 240×240 en mínimo).
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores, posibles `accentMagenta`/`accentViolet`), 02 (`hudReadout`, `labelSmall`, `mono`), 03 (`radius*`, `chamferM`, `space*`, `elev*`, `glowStatus`), 04 (`dur*`, curvas, reduced-motion), 05 (iconografía), 06 (`HudCornerBrackets`, `HudScanlines`, `HudGridTexture`, `HudReactorBar`, `HudDivider`, `HudIdTag`, `ChamferBorder`), 07 (glow/glass), 08 (`AppBackground`).
- **Núcleo:** 11 (`StatusTag`), 12 (`HoloPanel`), 14 (skeleton), 16 (error feedback).
- **Shell:** 30 (layout de 2 columnas que coloca esta columna izquierda).
- **Relación:** 35 (tab Mood) escribe `terminalBotMoodProvider` y este panel reacciona; 40 (status indicator) comparte el `HudReactorBar` y el `StatusTag`.
