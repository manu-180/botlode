# 38 — Chat console · Panel terminal

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Rediseña `BotChatConsole`, la consola de chat de prueba.

---

## 1. Objetivo

Rediseñar `BotChatConsole`: la terminal de chat de prueba contra el backend (`botlode-brain`, con `saveToHistory:false`). Hoy es un contenedor semitransparente con borde glass y un input minimalista. El rediseño la convierte en una **terminal HUD de instrumentación** con barra de título, lista de mensajes sobre retícula, indicador "escribiendo" y barra de input premium.

---

## 2. Archivos

- **Modificar:** `lib/features/bot_engine/presentation/widgets/bot_chat_console.dart` — reescribir el contenedor, la barra superior, el área de mensajes y la barra de input.
- **Usar:** `chat_message_bubble.dart` rediseñado por el prompt 39 (la consola lo consume; hoy usa una `_ChatMessageBubble` privada que se elimina en favor del componente del prompt 39).
- **Usar:** el `StatusIndicator` rediseñado por el prompt 40.
- **No tocar:** `chat_provider.dart` ni la lógica de `sendMessage`/`sessionId`/`isTyping`.

---

## 3. Estado actual

- `Container` con `color: black @0.3`, `borderRadius circular(16)`, `border: borderGlass`.
- **Barra superior:** `Row` con ícono `terminal_rounded`, `SESSION ID: ...`, `// TARGET: <bot>` en `Courier` 10 px, y un `CircularProgressIndicator` 12 px cuando `isTyping`.
- **Área de chat:** `ListView.builder` con `_ChatMessageBubble`/`_SystemMessageBubble` privados; auto-scroll vía `ref.listen` + `Future.delayed`.
- **Input:** `Row` con un prompt `>_`, un `TextField` sin borde (placeholder `Ingresar comando...`) y un `IconButton` `send_rounded`.
- Sin tokens, sin `HoloPanel`, sin `HudGridTexture`, sin estados de vacío/error de envío, sin barra de input premium.

---

## 4. Visión del rediseño

La consola se lee como una **terminal de pruebas de la unidad**: el operario "habla" con el bot para verificar su comportamiento antes de desplegarlo. El contenedor es un `HoloPanel` estilo terminal con una **barra de título HUD** (ícono terminal + `TERMINAL DE CHAT // PRUEBA` + `StatusTag` + botón limpiar). El área de mensajes tiene fondo `surfaceHud` con una `HudGridTexture` tenue, scrollea solo, y los mensajes (prompt 39) entran desde abajo. Cuando el bot procesa, una burbuja "escribiendo" aparece. Abajo, una **barra de input** firme: un `AppTextField` ancho con prefijo de prompt y un `AppIconButton` de enviar que emite `glowGold`. Enter envía. Cuando no hay mensajes, un estado de bienvenida invita a probar la unidad.

---

## 5. Especificación visual

### 5.1 Contenedor

- `HoloPanel` (prompt 12) variante `hud`, radio `radiusL`, borde `borderDefault`, elevación `elev1`. `chamfer` opcional en 2 esquinas superiores para coherencia con la tab bar.
- `Column` de tres zonas: barra de título (alto fijo 44 px) · área de mensajes (`Expanded`) · barra de input (alto ~64 px).

### 5.2 Barra de título HUD

- Alto 44 px, fondo `surfaceHud`, borde inferior `borderSubtle`, padding `space16` horizontal.
- `Row`:
  1. Ícono `terminal` 16 px, color `gold` al 70 %.
  2. `SizedBox(width: space8)`.
  3. Título `TERMINAL DE CHAT` en `label` `textPrimary` + `SizedBox(width: space8)` + `// PRUEBA` en `mono` `textTertiary`.
  4. `SizedBox(width: space12)` + `SESSION ID: <8 chars>` en `mono` `textTertiary` (opcional, si cabe).
  5. `Spacer()`.
  6. `StatusTag` del chat (prompt 40) — refleja online / procesando / sin conexión.
  7. `SizedBox(width: space8)`.
  8. `AppIconButton` `eraser`/`trash` variante `ghost`, `tooltip: "Limpiar terminal"` — vacía la sesión de prueba.

### 5.3 Área de mensajes

- `Expanded`. Fondo `surfaceHud`. Detrás, `HudGridTexture` (`opacity 0.04`); opcionalmente un glow radial muy tenue del color del bot en la parte superior.
- `ListView.builder` con `controller` propio, padding `space16` en todos los lados, `space12` de gap implícito por el margen de cada burbuja.
- Cada ítem es un `ChatMessageBubble` (prompt 39) — usuario, bot o mensaje de sistema.
- **Auto-scroll:** al llegar un mensaje nuevo, animar hasta `maxScrollExtent` con `durBase` curva `easeStandard` (conservar el patrón actual de `ref.listen` + post-frame, pero con tokens). Si el usuario scrolleó hacia arriba manualmente, NO forzar el scroll: mostrar un botón flotante `↓ Nuevos mensajes` (chip pequeño abajo a la derecha) que al pulsarse baja al final.
- **Scrollbar:** HUD fino, color `borderStrong`, aparece al hacer scroll.

### 5.4 Indicador "escribiendo"

- Cuando `isTyping` es true, al final de la lista aparece una **burbuja de escritura** (definida en el prompt 39): burbuja del bot con 3 puntos animados. La consola solo se encarga de insertarla como último ítem cuando `isTyping`.

### 5.5 Barra de input

- Alto ~64 px, fondo `surfaceHud` un tono distinto, borde superior `borderSubtle`, padding `space12` horizontal, `space12` vertical.
- `Row`:
  1. Prefijo de prompt: `>_` en `mono` `gold`, peso bold. `SizedBox(width: space12)`.
  2. `Expanded` → `AppTextField` (prompt 10) variante compacta, sin label flotante (placeholder `Escribí un mensaje de prueba...`), fuente `mono`, una línea pero `maxLines` ~3 para mensajes largos, fondo transparente o `surface`, borde `borderDefault` que pasa a `cyan` en foco.
  3. `SizedBox(width: space12)`.
  4. `AppIconButton` **enviar** — ícono `send`/`arrow-up`, variante `primary` (relleno `gradGold`, ícono `textOnGold`), con `glowGold`. 44×44.
- El envío se dispara con Enter (`onSubmitted`) o con el botón. Tras enviar, el campo se limpia y conserva el foco.

---

## 6. Estados e interacciones

Matriz §9 aplicada a la consola:

| Estado | Apariencia |
|---|---|
| `default` | Terminal con mensajes; input listo y enfocado. |
| `empty` (sin mensajes) | El área de mensajes muestra un **prompt de bienvenida** centrado: ícono `terminal` grande tenue, título `TERMINAL DE PRUEBA` en `label`, texto `bodyS` `textSecondary` (`Escribí un mensaje para probar cómo responde la unidad. Esta conversación no se guarda.`), opcional 2–3 chips de "sugerencias" de prompt clickeables que rellenan el input. |
| `hover` (botones / input) | Borde + glow suben `durFast`; cursor pointer/texto. |
| `focused` (input) | Borde del `AppTextField` `cyan` 2 px, glow `cyan` muy sutil; el caret `gold`. |
| `pressed` (botón enviar) | Escala 0.97, `durInstant`. |
| `sending` / `processing` | Tras enviar: el botón enviar muestra brevemente estado de carga (o se deshabilita hasta que el mensaje sale); el `StatusTag` pasa a `PROCESANDO...`; aparece la burbuja "escribiendo". El input sigue habilitado para escribir el siguiente mensaje. |
| `disabled` (botón enviar) | Cuando el input está vacío: botón enviar en opacidad 0.4, sin glow, no interactivo. |
| `error` (fallo de envío) | El mensaje del usuario que falló se marca con un estado de error (lo renderiza el prompt 39: borde `danger`, ícono, acción `Reintentar`); además un mensaje de sistema/`ErrorFeedbackCard` inline `No se pudo contactar la unidad`. El `StatusTag` puede ir a `SIN CONEXIÓN` si el fallo es de red. |

- **Limpiar terminal:** el botón de limpiar vacía los mensajes de la sesión de prueba; pedir confirmación ligera (toast con `Deshacer` o un mini-diálogo) solo si hay muchos mensajes.

---

## 7. Animaciones

- **Entrada de la consola:** fade + translateY 12 px, `easeEntrance`, `durBase` (escalonada con el resto del tab por el prompt 30).
- **Entrada de cada mensaje:** lo define el prompt 39 (fade + translateY desde abajo, `easeEntrance`).
- **Auto-scroll:** animación a `maxScrollExtent` con `durBase`, `easeStandard`.
- **Indicador "escribiendo":** los 3 puntos animan en bucle (lo define el prompt 39).
- **Botón enviar:** al habilitarse (input deja de estar vacío) el `glowGold` aparece con `durFast`; press con escala `durInstant`.
- **Botón `↓ Nuevos mensajes`:** entra con fade + translateY 8 px `durFast` cuando hay mensajes no vistos.
- **Reduced motion** (`AppMotion.reduced`): el auto-scroll salta sin animar (`jumpTo`); las burbujas aparecen sin translate (fade 120 ms); el indicador de escritura usa puntos estáticos con un cambio de opacidad lento o ninguno; sin glow animado en el botón (el glow queda estático).

---

## 8. Accesibilidad

- La consola es una región con `Semantics(label: "Terminal de chat de prueba")`.
- El `AppTextField` de input tiene label/hint accesible; el botón enviar tiene `tooltip` (`Enviar mensaje`) y se marca disabled cuando el input está vacío.
- El botón limpiar tiene `tooltip` (`Limpiar terminal`).
- Los mensajes nuevos se anuncian: el último mensaje del bot se expone con `liveRegion: true` para que el lector lo lea al llegar.
- El indicador "escribiendo" se anuncia como `La unidad está escribiendo`.
- El estado de error de envío se anuncia con `liveRegion`.
- Foco: el caret va al input al abrir; el orden de tabulación es título → lista → input → enviar.
- Contraste: texto de mensajes y del título `textPrimary`/`textSecondary` sobre `surfaceHud` cumple ≥ 4.5:1; metadatos `mono` `textTertiary` ≥ 3:1. Verificar.

---

## 9. Checklist de aceptación

- [ ] La consola es un `HoloPanel` estilo terminal con barra de título, área de mensajes y barra de input.
- [ ] La barra de título tiene ícono terminal + `TERMINAL DE CHAT // PRUEBA` + `StatusTag` + botón limpiar.
- [ ] El área de mensajes tiene fondo `surfaceHud` con `HudGridTexture` tenue y auto-scroll.
- [ ] Si el usuario scrolleó arriba, no se fuerza el scroll y aparece el botón `↓ Nuevos mensajes`.
- [ ] La barra de input tiene prefijo `>_`, `AppTextField` ancho en `mono` y `AppIconButton` enviar con `glowGold`.
- [ ] Enter envía; el botón enviar está disabled con el input vacío.
- [ ] El estado vacío muestra un prompt de bienvenida con sugerencias opcionales.
- [ ] El estado `processing` muestra `StatusTag` `PROCESANDO...` y burbuja "escribiendo".
- [ ] El error de envío marca el mensaje fallido (prompt 39) y muestra feedback inline.
- [ ] Cero hex sueltos, cero magic numbers: todo por tokens.
- [ ] Reduced motion: auto-scroll sin animar, burbujas sin translate, sin glow animado.
- [ ] Compila y se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores, `goldGlow`), 02 (`label`, `mono`, `bodyS`), 03 (`space*`, `radius*`, `chamferM`, `elev*`, `glowGold`), 04 (`dur*`, curvas, reduced-motion), 05 (iconografía), 06 (`HudGridTexture`, `ChamferBorder`).
- **Núcleo:** 09 (`AppIconButton`), 10 (`AppTextField`), 11 (`StatusTag`/chips), 12 (`HoloPanel`), 15 (`EmptyState` como base del prompt de bienvenida), 16 (`ErrorFeedbackCard`).
- **Chat:** 39 (`ChatMessageBubble` + burbuja "escribiendo"), 40 (`StatusIndicator`).
- **Provider:** `chat_provider.dart` (sin cambios de lógica).
