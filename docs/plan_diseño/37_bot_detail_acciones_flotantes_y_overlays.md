# 37 — Bot Detail · Acciones de unidad y overlays épicos

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Rediseña las acciones del detalle y las notificaciones "épicas".

---

## 1. Objetivo

Rediseñar las acciones de la unidad (Editar, Eliminar, Compartir) y los overlays de notificación "épicos" del detalle. Hoy las acciones son FABs sueltos y la notificación es un overlay con `elasticOut`. El rediseño agrupa las acciones en una **barra de comando HUD** en el header y convierte el overlay en una **transmisión del sistema** sobria y cinematográfica.

---

## 2. Archivos

- **Crear:** `lib/features/dashboard/presentation/widgets/unit_action_bar.dart` — barra de acciones del header.
- **Crear:** `lib/core/ui/widgets/system_broadcast_overlay.dart` — overlay de transmisión del sistema (reemplaza `_showEpicNotify`).
- **Modificar:** `lib/features/dashboard/presentation/views/bot_detail_view.dart` — eliminar los FABs sueltos y el `_showEpicNotify` inline; integrar `UnitActionBar` en `_UnitCommandHeader` (prompt 30) e invocar `SystemBroadcastOverlay`.
- **Reusar:** `delete_protocol_dialog.dart` para la confirmación de borrado.

---

## 3. Estado actual

- Las acciones Editar/Eliminar/Compartir están como **botones flotantes (FABs)** sueltos sobre la pantalla, sin agrupación ni jerarquía clara, y Eliminar no se distingue visualmente de las acciones neutras.
- `_showEpicNotify(String message)` crea un `OverlayEntry` posicionado al 40 % de alto, con `TweenAnimationBuilder` curva `Curves.elasticOut`, un `Container` negro al 95 %, borde `AppColors.primary` de 2 px, `boxShadow` dorado, ícono `terminal`, texto en `Courier` con `letterSpacing: 4` y un subtítulo `SISTEMA ACTUALIZADO`. Se autodescarta a los 2 s.
- El overlay no respeta reduced-motion, no tiene ornamento HUD coherente, usa hex/valores sueltos y el `elasticOut` es algo "rebotón" para el tono premium buscado.

---

## 4. Visión del rediseño

**Acciones:** las tres acciones dejan de flotar. Se agrupan en una **barra de comando** dentro del `_UnitCommandHeader` (prompt 30), a la derecha del `StatusTag`. Editar y Compartir son `AppIconButton`s neutros; Eliminar se separa del grupo con un `HudDivider` vertical y es claramente `danger`. Eliminar siempre pide confirmación.

**Overlay épico:** se transforma en una **transmisión del sistema**: un overlay centrado, modesto en tamaño, que se siente como un mensaje oficial de la terminal del hangar. `HoloPanel` con `chamfer`, `HudCornerBrackets` dorados, `HudScanlines` sutiles, un ícono de estado, y el texto que **se tipea** carácter a carácter como en una consola. Entra con un `easeEntrance` + escala contenida (sin rebote elástico), vive sobre todo lo demás en `zEpicNotification`, y se retira solo. Conserva el espíritu "épico terminal" pero con la sobriedad premium del sistema.

---

## 5. Especificación visual

### 5.1 `UnitActionBar` — barra de acciones del header

- Vive dentro de `_UnitCommandHeader` (prompt 30), alineada a la derecha, después del `StatusTag`.
- `Row`, `mainAxisSize: min`:
  1. `AppIconButton` **Editar** — ícono `pencil`/`edit`, variante `ghost`, `tooltip: "Editar unidad"`. Lleva al tab Config (prompt 33) o abre la edición del nombre.
  2. `SizedBox(width: space8)`.
  3. `AppIconButton` **Compartir** — ícono `share`/`upload`, variante `ghost`, `tooltip: "Compartir / código de inserción"`. Lleva al tab Embed (prompt 36).
  4. `SizedBox(width: space12)` + **`HudDivider` vertical** (1 px, hairline `borderSubtle`, alto 24 px) + `SizedBox(width: space12)` — separa visualmente la acción destructiva.
  5. `AppIconButton` **Eliminar** — ícono `trash`, variante `danger` (en reposo `textSecondary`, en hover toma `danger` + glow `dangerGlow`), `tooltip: "Eliminar unidad"`.
- Todos los botones 40×40 px de área, radio `radiusM`.
- También se puede ofrecer la acción de **encendido/energía** del bot (toggle de estado) como un `AppIconButton` adicional al inicio del grupo si la vista lo requiere (hoy `_handleEnergyToggle` existe); mantener su `tooltip` y su feedback de `CreditLimitReachedDialog`.

### 5.2 `SystemBroadcastOverlay` — transmisión del sistema

- Se inserta como `OverlayEntry` en `zEpicNotification` (z-index 300).
- Detrás, un `scrim` muy ligero opcional (`rgba(3,6,11,0.4)`) o ninguno — la transmisión no bloquea, es informativa; preferir **sin scrim** y permitir interacción con el resto (overlay no modal).
- **Panel central:** `HoloPanel` variante `hud`, `chamfer` en las 4 esquinas (`ChamferBorder`), fondo `glassSurfaceStrong` con blur, borde 1.5 px `borderGold`, elevación `elev3` + `glowGold` (blur 24).
  - Ancho ~420 px (no estirado de borde a borde como hoy), centrado horizontal y vertical (o ligeramente sobre el centro).
  - Padding `space24` vertical, `space32` horizontal.
- **Capas internas (`Stack`):**
  1. `HudGridTexture` tenue de fondo.
  2. `HudScanlines` (`opacity 0.035`).
  3. `HudCornerBrackets` en las 4 esquinas, color `gold`, brazo 20 px.
- **Contenido (`Column`, `mainAxisSize: min`):**
  1. Mini-cabecera: `labelSmall` `gold` UPPERCASE → `// TRANSMISIÓN DEL SISTEMA`.
  2. `space12`.
  3. Ícono de estado dentro de un cuadro biselado: `terminal`/`check`/`alert` 32 px según el tipo de mensaje (info `gold`, éxito `success`, error `danger`).
  4. `space16`.
  5. **Mensaje principal** en `titleM` `textPrimary`, centrado, que se **tipea** carácter a carácter (efecto máquina de escribir).
  6. `space8`.
  7. Línea de estado en `mono` `textTertiary` (ej. `OPERACIÓN COMPLETADA` / `ESTADO: OK`), también puede tener un cursor `_` parpadeante al final del tipeo.
- Variante por tipo: `info` (borde/glow `gold`), `success` (acento `success`), `error` (acento `danger`). El borde, brackets, glow e ícono toman el color del tipo.

---

## 6. Estados e interacciones

### 6.1 `UnitActionBar` — matriz §9 por `AppIconButton`

| Estado | Editar / Compartir | Eliminar |
|---|---|---|
| `default` | Ícono `textSecondary`, sin glow. | Ícono `textSecondary`, sin glow. |
| `hover` | Fondo `borderSubtle`, ícono `textPrimary`, glow suave neutro; `durFast`. | Fondo con tinte `danger`, ícono `danger`, glow `dangerGlow`; `durFast`. |
| `pressed` | Escala 0.97, `durInstant`. | Escala 0.97, `durInstant`. |
| `focused` | Anillo `cyan` 2 px. | Anillo `danger` 2 px (foco coherente con la naturaleza destructiva). |
| `disabled` | Opacidad 0.4, sin glow, no interactivo (ej. si la unidad está bloqueada). | Igual; además si la unidad no puede eliminarse. |

- **Eliminar:** al pulsar, abre `delete_protocol_dialog.dart` (confirmación). Solo tras confirmar se ejecuta el borrado. Tras éxito, navegar de vuelta al hangar y mostrar un toast (prompt 17) o un `SystemBroadcastOverlay` de éxito.

### 6.2 `SystemBroadcastOverlay` — ciclo de vida

| Estado | Comportamiento |
|---|---|
| `entering` | Aparece con fade + escala 0.92→1.0, `easeEntrance`, `durSlow`. Los `HudCornerBrackets` se "dibujan". |
| `typing` | El mensaje se revela carácter a carácter (~24–32 ms por carácter); cursor `_` parpadea. |
| `visible` | Se mantiene ~2000 ms tras terminar el tipeo. |
| `exiting` | Sale con fade + escala 1.0→0.96, `easeExit`, ~65 % de la duración de entrada (`durBase`). |
| (interrumpible) | Si llega otra transmisión, la actual sale rápido y la nueva entra; nunca se apilan dos. |

---

## 7. Animaciones

- **Acciones del header:** hover/press con `durFast`/`durInstant` (matriz §9). Sin animaciones decorativas.
- **Overlay — entrada:** `Transform.scale` 0.92→1.0 + `Opacity` 0→1, curva `easeEntrance`, `durSlow` (320 ms). **Nada de `elasticOut`** — el rebote elástico se elimina por ser poco premium.
- **Overlay — tipeo:** efecto máquina de escribir sobre el mensaje principal; ~24–32 ms por carácter; cursor parpadeante a ~600 ms.
- **Overlay — `HudCornerBrackets`:** se trazan con un pequeño reveal (largo de brazo 0→20 px) durante la entrada, `durBase`.
- **Overlay — salida:** fade + escala 1.0→0.96, `easeExit`, `durBase`.
- **Glow:** el `glowGold` (o del tipo) hace un único pulso suave al aparecer y luego queda estable.
- **Reduced motion** (`AppMotion.reduced`): el overlay aparece con fade simple de 120 ms, **sin escala**, **sin tipeo** (el mensaje se muestra completo de una), **sin reveal de brackets**, sin pulso de glow; la salida es fade de 120 ms. Las acciones del header conservan solo cambios de color (sin escala de press si reduced-motion lo pide).

---

## 8. Accesibilidad

- Cada `AppIconButton` de la barra de acciones tiene `tooltip` + `Semantics(label: ...)` descriptivo (`Editar unidad`, `Compartir unidad`, `Eliminar unidad`).
- La acción Eliminar es destructiva: se distingue por posición (separada por divisor), color `danger` y confirmación obligatoria; nunca se ejecuta sin el diálogo.
- El `delete_protocol_dialog.dart` atrapa el foco, tiene salida clara (cancelar) y su botón destructivo lleva ícono + texto.
- El `SystemBroadcastOverlay` se anuncia con `liveRegion: true` para que el lector de pantalla lea el mensaje completo (no el tipeo carácter a carácter — exponer el texto final completo a semántica desde el inicio).
- El overlay no atrapa el foco ni bloquea la navegación (no es modal); tiene autodescarte y no requiere acción del usuario.
- Contraste: mensaje `textPrimary` sobre `glassSurfaceStrong` ≥ 12:1; mini-cabecera `gold` y línea de estado `textTertiary` ≥ 3:1. Verificar.
- Foco visible en las acciones; el anillo de foco de Eliminar usa `danger` para reforzar su naturaleza.

---

## 9. Checklist de aceptación

- [ ] Las acciones Editar/Compartir/Eliminar están en una `UnitActionBar` dentro del header, no como FABs sueltos.
- [ ] Eliminar está separada por un `HudDivider` vertical y es claramente `danger` (color + glow en hover).
- [ ] Eliminar abre `delete_protocol_dialog.dart` y solo borra tras confirmar.
- [ ] El overlay épico se reemplaza por `SystemBroadcastOverlay`: panel centrado ~420 px con `chamfer`, `HudCornerBrackets`, `HudScanlines`.
- [ ] El overlay entra con `easeEntrance` + escala contenida (sin `elasticOut`) y el mensaje se tipea carácter a carácter.
- [ ] El overlay vive en `zEpicNotification`, no es modal, y se autodescarta.
- [ ] El overlay tiene variantes info/éxito/error con su color de acento.
- [ ] Cero hex sueltos, cero magic numbers: todo por tokens.
- [ ] Reduced motion: overlay con fade 120 ms sin escala ni tipeo ni reveal de brackets.
- [ ] Accesibilidad: tooltips en acciones, `liveRegion` en el overlay, foco visible.
- [ ] Compila y se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores, `goldGlow`, `dangerGlow`), 02 (`titleM`, `labelSmall`, `mono`), 03 (`space*`, `radius*`, `chamferM`, `elev*`, `glowGold`, `zEpicNotification`), 04 (`dur*`, `easeEntrance`/`easeExit`, reduced-motion), 05 (iconografía), 06 (`HudCornerBrackets`, `HudScanlines`, `HudGridTexture`, `HudDivider`, `ChamferBorder`).
- **Núcleo:** 09 (`AppIconButton`), 12 (`HoloPanel`), 17 (toasts, como complemento del overlay).
- **Shell / detalle:** 30 (`_UnitCommandHeader` que aloja la `UnitActionBar`).
- **Reusa:** `delete_protocol_dialog.dart`; `CreditLimitReachedDialog` para el toggle de energía.
