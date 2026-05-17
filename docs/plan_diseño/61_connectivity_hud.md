# 61 — Connectivity HUD

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.

---

## 1. Objetivo

Rediseñar el HUD de conectividad: los snackbars que `main_layout.dart` muestra cuando la conexión de red cambia. Deben convertirse en un **toast HUD especializado de estado de enlace** del «Hangar OS» — «CONEXIÓN RESTABLECIDA» / «SIN CONEXIÓN — MODO OFFLINE» — coherente con el sistema de toasts del prompt 17 pero con identidad propia: reactor bar, scanlines, íconos de wifi, y persistencia diferenciada (el de offline no se va hasta reconectar).

---

## 2. Archivos

- `lib/features/dashboard/presentation/views/main_layout.dart` — reescritura del método `_showTacticalSnackbar` y la decoración del snackbar; la lógica de escucha (`ref.listen(connectivityProvider)`, `_wasOffline`) se conserva.
- Opcional: extraer el toast a `lib/core/ui/hud/connectivity_hud.dart` si conviene reutilizarlo; mantener el patrón del prompt 17.

---

## 3. Estado actual

`_showTacticalSnackbar` crea un `SnackBar` transparente, sin elevación, con duración `Duration(days:1)` para error (persistente) y 4 s para éxito. Contenido: `Container` negro `black@0.9`, borde 2 px del color (`error`/`success`), `radius 8`, `boxShadow` glow. `Row` con ícono `wifi`/`wifi_off` que hace `.animate().shimmer()` con `Colors.white.withOpacity(0.5)` (API vieja) cada 2000 ms, y un `Text` en fuente `'Courier'` con `letterSpacing 2.0`. Problemas: hex/durations sueltos, `Courier` en vez del token mono, `.withOpacity` deprecado, sin posición controlada (queda abajo, no top-center), sin scanlines ni reactor bar, no respeta reduced-motion.

---

## 4. Visión del rediseño

El cambio de conectividad dispara un **toast HUD de estado de enlace** anclado **top-center**, flotando sobre todo el contenido (`zToast`). Es una cápsula de vidrio oscuro con `ChamferBorder` (bisel de hardware), un `HudReactorBar` lateral que late en el color de estado, scanlines sutilísimas, un ícono de wifi y un texto mono en mayúsculas. Dos variantes:

- **CONEXIÓN RESTABLECIDA** — `success`, ícono `wifi`, `HudReactorBar` verde. Auto-dismiss tras `durDeliberate`×N (≈4 s). Una breve celebración contenida: el reactor da un pulso al aparecer.
- **SIN CONEXIÓN — MODO OFFLINE** — `danger`, ícono `wifi_off`, `HudReactorBar` rojo latiendo lento. **Persistente**: no se va hasta que vuelve la conexión (entonces lo reemplaza el toast de éxito). Comunica un estado del sistema, no un evento puntual.

El factor WOW: se siente la telemetría de una nave perdiendo y recuperando enlace, sin estridencia.

---

## 5. Especificación visual

### 5.1 Posición y capa

- Anclado **top-center**: usar `behavior: SnackBarBehavior.floating` con `margin` que lo lleve al tope (o, preferido, un `OverlayEntry`/`showGeneralDialog`-like manejado por el sistema de toasts del prompt 17 que ya soporta posición). Z-index `zToast` (200), por encima de title bar y sidebar.
- Ancho: contenido + padding, `maxWidth` ~420 px, centrado horizontalmente.

### 5.2 Cápsula

- Fondo `surfaceHud` con blur sutil (vidrio oscuro), opacidad alta para legibilidad.
- `ChamferBorder` (`chamferM`) — bisel de hardware; borde 1.5 px en el color de estado.
- `elev3` + `glowStatus(color)` (un solo glow).
- `HudScanlines` overlay `opacity 0.035`.
- Padding `space12` vertical / `space20` horizontal.

### 5.3 Contenido (`Row`, gap `space16`)

- **Barra lateral** `HudReactorBar` vertical 3 px en el color de estado, pegada al borde izquierdo interno.
- **Ícono** wifi 20 px: `wifi` (éxito) / `wifi_off` (offline), en el color de estado.
- **Texto** en `hudReadout` o `mono` UPPERCASE, color de estado:
  - Éxito: «ENLACE RESTABLECIDO · SISTEMAS ONLINE».
  - Offline: «SIN CONEXIÓN · MODO OFFLINE ACTIVO».
- Sin botón de cierre (es estado de sistema; el offline se cierra solo al reconectar).

### 5.4 Variantes

| Variante | Color | Ícono | Reactor | Persistencia |
|---|---|---|---|---|
| Online | `success` | `wifi` | pulso único al aparecer | auto-dismiss ≈4 s |
| Offline | `danger` | `wifi_off` | latido lento continuo | persistente hasta reconectar |

---

## 6. Estados e interacciones (matriz §9)

| Estado | Qué cambia |
|---|---|
| `default` | Toast visible según la última transición de red. |
| `enter` | Slide-down + fade desde el tope. |
| `persistent` (offline) | Permanece indefinidamente; el reactor late lento. |
| `replace` | Al volver la conexión, el toast offline se descarta y entra el de online (la cola se limpia: conservar `hideCurrentSnackBar()`). |
| `exit` (online) | Auto-dismiss tras la duración; fade + slide-up. |
| `focused` | El toast no es interactivo; no requiere foco. Su contenido se anuncia por `liveRegion`. |
| reduced-motion | Sin slide ni latido; aparece/desaparece con crossfade 120 ms. |

> No tiene `hover`/`pressed`/`disabled`: es un indicador no interactivo.

---

## 7. Animaciones

- **Entrada:** translateY −16 px → 0 + fade, `durSlow`, `easeEntrance`.
- **Salida:** fade + slide-up, ~65 % de la entrada, `easeExit`, `durFast`.
- **Reactor (offline):** latido de opacidad 0.6↔1.0 a ~1600 ms, continuo.
- **Reactor (online):** un único pulso `durBase` al aparecer; sin repetición.
- **Ícono:** reemplazar el `.shimmer()` actual por un barrido `gradGoldSheen` opcional **solo en la variante online** cada ~3000 ms; nunca usar `.withOpacity` (usar `.withValues(alpha:)`).
- **Reduced motion:** sin slide, sin latido, sin shimmer/barrido — crossfade 120 ms de entrada y salida; el toast offline simplemente está presente sin animación.

---

## 8. Accesibilidad

- El toast lleva `Semantics(liveRegion:true)` para que el cambio de estado de red se anuncie inmediatamente.
- Estado comunicado por color + ícono de wifi + texto (nunca solo color).
- Contraste: `success`/`danger` del texto sobre `surfaceHud` ≥ 4.5:1; ícono ≥ 3:1 (verificar).
- No es interactivo: no roba foco ni requiere orden de foco.
- El toast offline persistente no debe tapar contenido crítico permanentemente — al estar top-center y ser compacto, dejar respiración con la title bar; verificar que no se solape con los botones de ventana.
- Reduced-motion respetado.

---

## 9. Checklist de aceptación

- [ ] Toast anclado top-center con z-index `zToast`.
- [ ] Cápsula con `ChamferBorder`, `HudReactorBar` lateral, `HudScanlines`, ícono de wifi.
- [ ] Dos variantes: online (`success`, auto-dismiss ≈4 s) y offline (`danger`, persistente hasta reconectar).
- [ ] Texto en token mono/`hudReadout`; fuente `'Courier'` eliminada.
- [ ] **Cero hex/durations sueltos**; `.withOpacity` reemplazado por `.withValues(alpha:)`.
- [ ] La cola se limpia entre transiciones (`hideCurrentSnackBar` conservado); offline → online reemplaza correctamente.
- [ ] `Semantics(liveRegion:true)` en el toast.
- [ ] Reduced-motion respetado (sin slide/latido/barrido).
- [ ] Contrastes verificados.
- [ ] `flutter analyze` sin warnings nuevos; se ve bien en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01–08 (color, tipografía + mono, dimensiones — `zToast`, motion — incluye reduced, iconos, HUD: reactor bar/scanlines/chamfer, glow/glass, fondo).
- **Componentes núcleo:** 17 (sistema de toasts/snackbars HUD — este toast es una especialización de ese sistema).
- **Shell:** 18 (title bar — verificar que el toast top-center no se solape), 20 (`MainLayout` shell, donde vive la escucha de conectividad).
