# 39 — Chat · Burbujas de mensaje

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Rediseña `ChatMessageBubble` y las burbujas de la consola.

---

## 1. Objetivo

Rediseñar las burbujas de mensaje del chat: mensaje del usuario, mensaje del bot, mensaje de sistema, burbuja "escribiendo" y estado de error. Hoy son contenedores con relleno semitransparente y radios sueltos. El rediseño las alinea al sistema HUD: el usuario emite oro, el bot vive en un `HoloPanel`, todo con avatares, timestamps `mono` y entrada animada.

---

## 2. Archivos

- **Modificar:** `lib/features/bot_engine/presentation/widgets/chat_message_bubble.dart` — reescribir como el componente canónico de burbuja, con variantes (`user`, `bot`, `system`, `typing`, `error`).
- **Eliminar:** la clase privada `_ChatMessageBubble` y `_SystemMessageBubble` de `bot_chat_console.dart` (prompt 38), reemplazadas por este componente.

---

## 3. Estado actual

- `ChatMessageBubble`: `Container` con `margin vertical 8`, `padding 16/12`, `maxWidth 400`, relleno `textSecondary @0.2` (usuario) o `botColor @0.15` (bot), radios asimétricos (`12` salvo la esquina "origen" en `2`), borde solo para el bot. Dentro, un label `OPERADOR`/`SISTEMA` 10 px y el texto (fuente `Courier` para el bot).
- En `bot_chat_console.dart` hay variantes privadas equivalentes y un `_SystemMessageBubble` centrado para mensajes de sistema/error.
- Sin avatar, sin timestamp, sin render markdown, sin animación de entrada, sin estado "escribiendo" ni estado de error de mensaje.

---

## 4. Visión del rediseño

Cada burbuja comunica claramente quién habla. El **mensaje del usuario** se alinea a la derecha: un relleno sutil con tinte oro (el operario "emite"), borde `borderGold`, texto `textPrimary`, una esquina con un pequeño chaflán que apunta al origen. El **mensaje del bot** se alinea a la izquierda dentro de un `HoloPanel` compacto, precedido por un **avatar circular** del color del bot con un `HudStatusDot`; el texto se renderiza con markdown ligero (negritas, ítems, código inline). Cada burbuja lleva un **timestamp `mono`** discreto. Las burbujas **entran animadas** desde abajo. Cuando el bot procesa, una **burbuja de escritura** con 3 puntos late. Si un mensaje falla, se marca con un estado de error y un botón reintentar.

---

## 5. Especificación visual

### 5.1 Mensaje del usuario (`user`)

- `Align` a la derecha. `Container`/`HoloPanel` con `constraints maxWidth` ~62 % del ancho de la consola.
- Relleno: `surfaceRaised` con un tinte oro muy sutil (un overlay `goldGlow` al ~8 %) **o** un `gradGold` muy atenuado; mantenerlo sobrio, no un bloque oro pleno.
- Borde: 1 px `borderGold`.
- Radio: `radiusM` en 3 esquinas; la **esquina inferior derecha** (origen) con un pequeño chaflán (`chamfer` reducido, ~8 px) o radio `radiusXS` para marcar el "puntero".
- Padding interno `space12` / `space16`.
- Composición (`Column`, `crossAxisAlignment: end`):
  1. Texto del mensaje en `bodyM` `textPrimary`, interlineado 1.5.
  2. `space4`.
  3. Timestamp en `mono` `textTertiary`, 11 px, alineado a la derecha.
- Avatar del operario: opcional; si se usa, un círculo 24 px con ícono `user` a la derecha de la burbuja.

### 5.2 Mensaje del bot (`bot`)

- `Align` a la izquierda. `Row`, `crossAxisAlignment: start`:
  1. **Avatar:** círculo 32 px, relleno `surfaceHud`, borde 1.5 px del color del bot, dentro un ícono o la inicial del bot; un `HudStatusDot` (prompt 06) pequeño en la esquina inferior del avatar indicando online/procesando. `SizedBox(width: space12)`.
  2. **Burbuja:** `HoloPanel` variante `default` compacto, `maxWidth` ~62 %, padding `space12`/`space16`, radio `radiusM` con la **esquina inferior izquierda** en chaflán reducido/`radiusXS`.
     - Mini-label `SISTEMA` o el nombre del bot en `labelSmall` color del bot, UPPERCASE.
     - `space4`.
     - Texto con **render markdown ligero**: negritas (`**`), itálicas, listas con viñeta, código inline en `mono` sobre fondo `surfaceHud`, saltos de línea. Cuerpo en `bodyM` `textSecondary`/`textPrimary`. Usar un parser markdown liviano o un `RichText` con reglas mínimas; no hace falta markdown completo.
     - `space4`.
     - Timestamp en `mono` `textTertiary` 11 px.

### 5.3 Mensaje de sistema (`system`)

- Centrado horizontal. Cápsula compacta: fondo `surfaceHud`, borde `borderSubtle`, radio `radiusS`, padding `space8`/`space12`.
- Ícono pequeño (`info`/`alert` 12 px) + texto en `mono` `labelSmall`, color `cyan` para info, `danger` para advertencia.
- Margen vertical `space12`.

### 5.4 Burbuja "escribiendo" (`typing`)

- Misma estructura que el mensaje del bot (avatar + `HoloPanel`), pero el contenido es **3 puntos animados**: tres círculos de ~6 px, color del bot, que suben/bajan o cambian de opacidad en secuencia (efecto "typing"). Sin texto, sin timestamp.
- `maxWidth` reducido (solo lo que ocupan los puntos + padding).

### 5.5 Estado de error de mensaje (`error`)

- Aplica a un mensaje del **usuario** que no se pudo entregar.
- La burbuja del usuario toma borde `danger` (en lugar de `borderGold`), un ícono `alert-triangle` 12 px `danger` junto al timestamp, y debajo una fila con un mini-botón `Reintentar` (`AppButton` mini variante `ghost` con tinte `danger`).
- Texto auxiliar `mono` `textTertiary`: `No entregado`.

---

## 6. Estados e interacciones

Matriz §9 aplicada a las burbujas:

| Estado | Apariencia |
|---|---|
| `default` | Burbuja en reposo según su variante. |
| `hover` (sobre una burbuja) | El timestamp, que en reposo puede estar al 60 % de opacidad, sube a opacidad plena; opcional: aparece un mini-menú de acciones (copiar texto). `durFast`. |
| `pressed` | No aplica a burbujas estáticas; sí al botón `Reintentar` (escala 0.97, `durInstant`). |
| `focused` | Si la burbuja es enfocable para copiar: anillo `cyan` 2 px. El botón `Reintentar` siempre enfocable. |
| `typing` | Variante con 3 puntos animados (ver §5.4). |
| `error` | Variante con borde `danger` + ícono + `Reintentar` (ver §5.5). |
| `selected` | No aplica. |

- **Copiar texto:** al hover sobre una burbuja, un `AppIconButton` `copy` mini puede aparecer; al pulsarlo copia el texto y muestra un toast (prompt 17).
- **Reintentar:** el botón en una burbuja de error reintenta el envío vía `chat_provider`.

---

## 7. Animaciones

- **Entrada de cada burbuja:** fade (0→1) + translateY desde abajo (+12 px → 0), curva `easeEntrance`, `durBase`. Cada burbuja anima individualmente al insertarse en la lista.
- **Burbuja "escribiendo":** los 3 puntos animan en bucle — cada punto hace un ciclo de opacidad 0.3↔1.0 (o un translateY de −3 px) desfasado ~150 ms entre puntos; periodo total ~900 ms; curva `easeStandard`, `repeat`.
- **Aparición del avatar del bot:** el avatar entra con un micro fade + escala 0.9→1.0 junto a la burbuja, `durBase`.
- **Estado de error:** la transición de `borderGold`→`danger` cuando un mensaje falla anima con `durFast`; el botón `Reintentar` aparece con fade + translateY 6 px.
- **Hover del timestamp / acciones:** `durFast`.
- **Reduced motion** (`AppMotion.reduced`): las burbujas aparecen sin translateY (fade 120 ms); la burbuja "escribiendo" muestra 3 puntos estáticos (sin bucle) o un único cambio de opacidad muy lento; sin escala en avatar.

---

## 8. Accesibilidad

- Cada burbuja expone su contenido a accesibilidad con el rol claro: `Semantics(label: "Mensaje de <Operador|Unidad>, <hora>: <texto>")`.
- El último mensaje del bot se expone con `liveRegion: true` para que el lector lo lea al llegar (coordinado con la consola, prompt 38).
- La burbuja "escribiendo" se anuncia como `La unidad está escribiendo`.
- El estado de error se anuncia con `liveRegion`; el botón `Reintentar` tiene `Semantics`/`tooltip` descriptivo.
- El render markdown no debe romper la lectura: el texto plano subyacente queda accesible.
- El color nunca es el único indicador: el origen del mensaje se distingue por alineación + label + avatar, no solo por color; el error lleva ícono + texto `No entregado`.
- Contraste: texto del usuario `textPrimary` sobre el relleno con tinte oro ≥ 12:1; texto del bot `textSecondary`/`textPrimary` sobre `HoloPanel` ≥ 4.5:1; timestamps `mono` `textTertiary` ≥ 3:1; código inline sobre `surfaceHud` ≥ 4.5:1. Verificar.
- Targets: el botón `Reintentar` y el `copy` ≥ 32×32 px.

---

## 9. Checklist de aceptación

- [ ] El mensaje del usuario se alinea a la derecha, con relleno de tinte oro sutil, borde `borderGold` y esquina con chaflán.
- [ ] El mensaje del bot se alinea a la izquierda dentro de un `HoloPanel`, con avatar circular del color del bot + `HudStatusDot`.
- [ ] El texto del bot se renderiza con markdown ligero (negritas, listas, código inline).
- [ ] Cada burbuja muestra un timestamp en `mono` `textTertiary`.
- [ ] Existe la variante `system` centrada y la variante `typing` con 3 puntos animados.
- [ ] Un mensaje fallido se marca con borde `danger`, ícono, texto `No entregado` y botón `Reintentar`.
- [ ] Cada burbuja entra animada (fade + translateY desde abajo, `easeEntrance`).
- [ ] Se eliminaron las clases privadas `_ChatMessageBubble`/`_SystemMessageBubble` de la consola.
- [ ] Cero hex sueltos, cero magic numbers: todo por tokens.
- [ ] Reduced motion: burbujas sin translateY, "escribiendo" con puntos estáticos.
- [ ] Accesibilidad: roles, `liveRegion` en el último mensaje del bot, contraste verificado.
- [ ] Compila y se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores, `goldGlow`, `borderGold`), 02 (`bodyM`, `labelSmall`, `mono`), 03 (`space*`, `radius*`, `chamferM`), 04 (`dur*`, curvas, reduced-motion), 05 (iconografía), 06 (`HudStatusDot`, `ChamferBorder`).
- **Núcleo:** 09 (`AppButton`/`AppIconButton`), 12 (`HoloPanel`), 17 (toasts para "copiado").
- **Chat:** 38 (`BotChatConsole` que monta estas burbujas), 40 (`StatusIndicator`, comparte el vocabulario de estado).
- **Provider:** `chat_provider.dart` (reintento de mensaje; sin cambios de lógica).
