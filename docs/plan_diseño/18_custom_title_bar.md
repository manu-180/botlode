# 18 — Custom Title Bar · Barra de título de ventana HUD

> Fase C · Shell y navegación. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Antes de ejecutar este prompt, leer el archivo 00 completo. Si algo se contradice, gana el archivo 00.

---

## 1. Objetivo

Rediseñar la barra de título de la ventana de escritorio (`CustomTitleBar`) para convertirla en una franja HUD coherente: marca con micro-logo, breadcrumb de pantalla, indicador opcional de estado del sistema y tres controles de ventana rediseñados como botones HUD. La barra debe sentirse parte del instrumento, no un parche genérico de Windows.

---

## 2. Archivos

- **Modificar:** `lib/core/ui/widgets/custom_title_bar.dart` — reescritura completa del widget.
- **Eliminar / deprecar:** el `_CustomTitleBar` privado embebido en `lib/features/dashboard/presentation/views/main_layout.dart` (líneas 102–156). Se reemplaza por el `CustomTitleBar` público (ver prompt 20).
- **Consumir:** `AppColors` (prompt 01), `AppTextStyles` (prompt 02), `AppDimens` (prompt 03), `AppMotion` (prompt 04), `AppIcons` (prompt 05), `HudDivider` y `HudStatusDot` (prompt 06), `AppIconButton` (prompt 09).

---

## 3. Estado actual

Hoy existen dos implementaciones divergentes:

- `custom_title_bar.dart`: `Container` de **40 px**, fondo `AppColors.background`, `DragToMoveArea` con `RichText` («BOTSLODE» en `primary` + « // FACTORY TERMINAL v1.0» en `Courier` `textSecondary@0.5`). Tres `_WindowButton` de 46 px con hover plano (`white@0.1`, rojo `error` en el de cerrar).
- `main_layout.dart` `_CustomTitleBar`: `Container` de **32 px** transparente, `GestureDetector` con `onPanStart` → `startDragging`, texto único `Courier` 10 px, tres `IconButton` Material de 14 px.

Problemas: dos fuentes de verdad, alturas distintas (32 vs 40), `Courier` en vez de la fuente mono del sistema (`mono`), hex y opacidades sueltas, hover plano sin tokens, sin breadcrumb, sin indicador de estado, hit areas inconsistentes, sin foco de teclado, sin `Semantics`.

---

## 4. Visión del rediseño

Una franja de **36 px** de alto, fina y precisa, que ocupa el borde superior del área de contenido (a la derecha del sidebar). Lectura de izquierda a derecha como un instrumento:

- **Izquierda:** micro-logo 16×16 + marca «BOTSLODE» en mayúsculas + `HudDivider` vertical fino + breadcrumb de la pantalla actual (`mono`, `textTertiary`). El conjunto comunica «dónde estoy».
- **Centro (opcional):** indicador de estado del sistema — `HudStatusDot` + texto «SISTEMA OPERATIVO». Discreto, centrado, refuerza la metáfora de terminal.
- **Derecha:** tres controles de ventana rediseñados como `AppIconButton` HUD — minimizar, maximizar/restaurar, cerrar. Hover sutil; el de cerrar vira a `danger` en hover.

Toda la franja (salvo las zonas interactivas) es arrastrable para mover la ventana. Una hairline `borderSubtle` cierra la barra por abajo y la separa del contenido. Sin emojis, sin `Courier`, sin hex sueltos.

---

## 5. Especificación visual

### 5.1 Contenedor raíz

- Widget: `SizedBox(height: 36)` envolviendo un `DecoratedBox`.
- Altura: **36 px** exactos (constante; si se agrega token, `AppDimens.titleBarHeight = 36`).
- Fondo: `AppColors.background` (continuidad con el sidebar y el contenido). Sin gradiente.
- Borde inferior: hairline de **1 px** color `AppColors.borderSubtle` (vía `Border(bottom: BorderSide(...))`). Ningún otro borde.
- Padding horizontal interno: `AppDimens.space12` (12 px) a izquierda; los controles de ventana llegan hasta el borde derecho sin padding (hit area pegada a la esquina).
- Estructura: `Row` con `crossAxisAlignment: center`.

### 5.2 Zona izquierda — marca + breadcrumb

Orden de hijos dentro del `Row`:

1. **Micro-logo:** `SizedBox(16×16)` con `Image.asset('assets/icon/botlode_logo.png', fit: BoxFit.contain)`. Render crisp; no aplicar glow.
2. `SizedBox(width: AppDimens.space8)` (8 px).
3. **Marca:** `Text("BOTSLODE")` con `AppTextStyles.labelSmall` (11/600, tracking +1.6, UPPERCASE), color `AppColors.textSecondary`. Es texto de marca, no `gold` (el oro se gana — §4.2 archivo 00).
4. `SizedBox(width: AppDimens.space12)` (12 px).
5. **`HudDivider` vertical:** variante vertical del divisor HUD, alto 14 px, 1 px de grosor, color `AppColors.borderSubtle`, sin etiqueta. Si el `HudDivider` del prompt 06 sólo expone orientación horizontal, usar un `Container(width: 1, height: 14, color: AppColors.borderSubtle)` como sustituto equivalente.
6. `SizedBox(width: AppDimens.space12)` (12 px).
7. **Breadcrumb (opcional):** `Text` con `AppTextStyles.mono` (12/JetBrains Mono), color `AppColors.textTertiary`, formato `// {PANTALLA}` en mayúsculas — p. ej. `// HANGAR`, `// FACTURACIÓN`, `// HANGAR / UNIT-04F`. La cadena la provee `MainLayout` (prompt 20) según la ruta activa de `go_router`. Si no se provee breadcrumb, se omite junto con su `HudDivider` y su gap.

Toda la zona izquierda va envuelta en el área arrastrable (ver §5.6). El texto no debe truncar de forma fea: aplicar `overflow: TextOverflow.ellipsis` y `maxLines: 1` al breadcrumb.

### 5.3 Zona central — indicador de estado del sistema (opcional)

- Se renderiza con `Expanded` que aloja un `Center`. Si el indicador está desactivado, el `Expanded` queda como espaciador arrastrable puro.
- Contenido cuando está activo: `Row(mainAxisSize: min)` con:
  1. `HudStatusDot` en estado `online` — punto de 6 px color `AppColors.success` con halo `successGlow` pulsante (latido 0.6↔1.0 cada ~1600 ms; desactivado con reduced-motion).
  2. `SizedBox(width: AppDimens.space8)`.
  3. `Text("SISTEMA OPERATIVO")` con `AppTextStyles.labelSmall`, color `AppColors.textTertiary`.
- El estado del punto puede mapearse a conectividad: `online` → `success`; `offline` → `danger` con texto «SIN ENLACE». Esto lo decide `MainLayout`; el `CustomTitleBar` recibe un `enum SystemStatus { operational, offline, syncing }` opcional.
- El indicador es decorativo-informativo: nunca interactivo, nunca roba foco.

### 5.4 Zona derecha — controles de ventana

Tres botones, en este orden: minimizar, maximizar/restaurar, cerrar.

- Cada control es un `AppIconButton` en variante HUD (prompt 09), tamaño compacto.
- **Hit area:** cada botón ocupa **46 px de ancho × 36 px de alto** (alto completo de la barra). Es desktop con mouse; 46×36 supera el mínimo de 32×32 del archivo 00 §10.
- **Ícono:** 16 px, del set `AppIcons` (prompt 05):
  - Minimizar → `AppIcons.windowMinimize` (línea horizontal inferior).
  - Maximizar → `AppIcons.windowMaximize`; Restaurar → `AppIcons.windowRestore` (dos cuadros solapados). El ícono cambia según `windowManager.isMaximized()`.
  - Cerrar → `AppIcons.windowClose` (cruz).
- **Colores por defecto:** ícono `AppColors.textTertiary`, fondo `transparent`.
- Sin separadores entre botones. El de cerrar es el último, pegado a la esquina superior derecha de la ventana.

### 5.5 Tokens — resumen

| Elemento | Token |
|---|---|
| Altura barra | 36 px |
| Fondo | `AppColors.background` |
| Hairline inferior | `AppColors.borderSubtle`, 1 px |
| Marca «BOTSLODE» | `AppTextStyles.labelSmall` · `AppColors.textSecondary` |
| Breadcrumb | `AppTextStyles.mono` · `AppColors.textTertiary` |
| Divisor vertical | `HudDivider` vertical · `AppColors.borderSubtle` |
| Texto «SISTEMA OPERATIVO» | `AppTextStyles.labelSmall` · `AppColors.textTertiary` |
| Punto de estado | `HudStatusDot` · `success` / `danger` |
| Ícono control ventana | `AppColors.textTertiary` (default) |
| Hover control neutro | fondo `AppColors.borderSubtle`, ícono `AppColors.textPrimary` |
| Hover control cerrar | fondo `AppColors.danger`, ícono `AppColors.textPrimary` |
| Press | escala 0.97, fondo un paso más profundo |
| Padding izquierdo | `AppDimens.space12` |

### 5.6 Zona arrastrable

- Toda la franja **excepto** los tres controles de ventana es arrastrable.
- Implementación: envolver la zona izquierda + el `Expanded` central en un `DragToMoveArea` (de `window_manager`). Los `AppIconButton` quedan FUERA del `DragToMoveArea` para que reciban clics sin iniciar el arrastre.
- No usar el patrón `GestureDetector(onPanStart: startDragging)` del `main_layout.dart` actual: `DragToMoveArea` es el mecanismo correcto y respeta el doble-clic para maximizar.
- El micro-logo, la marca, el divisor, el breadcrumb y el indicador central NO interceptan punteros (deben dejar pasar el drag): no envolverlos en `MouseRegion`/`GestureDetector` propios.

---

## 6. Estados e interacciones

Matriz §9 del archivo 00 aplicada a los tres controles de ventana (`AppIconButton`).

| Estado | Minimizar / Maximizar | Cerrar |
|---|---|---|
| `default` | Fondo `transparent`, ícono `textTertiary`. | Igual. |
| `hover` | Fondo `borderSubtle`, ícono `textPrimary`. Cursor `SystemMouseCursors.click`. Transición `durInstant` (90 ms). | Fondo `AppColors.danger`, ícono `textPrimary`. Misma transición. |
| `pressed` | Escala 0.97 (`AnimatedScale`, `durInstant`), fondo un paso más profundo (`borderDefault`). | Escala 0.97, fondo `goldDeep`-equivalente del rojo: usar `danger` con `withValues(alpha:` superior o el token `dangerDeep` si existe; si no, `danger` sólido. |
| `focused` | Anillo de foco 2 px `AppColors.cyan` por dentro del hit area (`FocusableActionDetector` + pintura de borde). No se elimina sin reemplazo. | Anillo de foco 2 px `AppColors.cyan` (no rojo, para no confundir foco con peligro). |
| `disabled` | No aplica: los controles de ventana siempre están disponibles. | No aplica. |
| `loading` / `error` / `empty` / `selected` | No aplican a controles de ventana. | — |

Indicador de estado del sistema (§5.3): no es interactivo; sólo refleja `SystemStatus`. Transición de color del punto entre estados: `durBase` (240 ms), curva `easeStandard`.

Maximizar/restaurar: al pulsar, consultar `windowManager.isMaximized()` y alternar `maximize()` / `restore()`; intercambiar el ícono (`windowMaximize` ↔ `windowRestore`) con un crossfade `durFast` (160 ms).

---

## 7. Animaciones

- **Aparición de la barra al arrancar:** la barra no anima por sí sola; entra junto al shell (ver prompt 20). El `CustomTitleBar` no debe disparar animaciones de entrada propias.
- **Hover de controles:** cambio de fondo e ícono con `durInstant` (90 ms), curva `easeStandard`. Sólo `color`/`opacity` — nunca `width`/`height`.
- **Press:** `AnimatedScale` a 0.97 con `durInstant`; vuelve a 1.0 al soltar.
- **Punto de estado del sistema:** latido de opacidad 0.6↔1.0 cada ~1600 ms (el `HudStatusDot` ya lo encapsula). Con reduced-motion: punto estático a opacidad 1.0, sin halo pulsante.
- **Cambio de ícono maximizar↔restaurar:** crossfade `durFast` (160 ms), curva `easeStandard`.
- **Reduced-motion (`AppMotion.reduced`):** sin latido, sin shimmer; los hovers se mantienen (son micro-cambios de color de 90 ms, no molestan) pero pueden reducirse a cambio instantáneo. El crossfade de ícono se vuelve instantáneo.

---

## 8. Accesibilidad

- Cada control de ventana lleva `Semantics` + `tooltip` HUD (prompt 13): «Minimizar ventana», «Maximizar ventana» / «Restaurar ventana», «Cerrar aplicación».
- Foco visible siempre: anillo 2 px `cyan` en los tres controles. Orden de foco: minimizar → maximizar → cerrar (coincide con orden visual izquierda-a-derecha).
- El control de cerrar comunica peligro por **color + ícono + tooltip**, nunca sólo color (cumple §10).
- Contraste: ícono `textTertiary` sobre `background` ≥ 3:1 (glifo de UI); en hover el ícono pasa a `textPrimary` (≥ 12:1). Texto de marca `textSecondary` ≥ 4.5:1.
- Hit area de cada control ≥ 32×32 px (acá 46×36).
- El indicador de estado no es foco-able ni anuncia cambios ruidosos; si vira a `offline`, el anuncio sonoro lo maneja el Connectivity HUD (prompt 61), no esta barra.
- Respetar `MediaQuery.disableAnimations` para el latido del punto.

---

## 9. Checklist de aceptación

- [ ] Existe una única implementación pública `CustomTitleBar`; el `_CustomTitleBar` privado de `main_layout.dart` fue eliminado.
- [ ] La barra mide exactamente 36 px de alto.
- [ ] Fondo `AppColors.background`; hairline inferior de 1 px `AppColors.borderSubtle`.
- [ ] Zona izquierda: micro-logo 16×16 + «BOTSLODE» (`labelSmall`) + divisor vertical + breadcrumb opcional (`mono`, `textTertiary`).
- [ ] Centro: indicador opcional `HudStatusDot` + «SISTEMA OPERATIVO» (`labelSmall`, `textTertiary`).
- [ ] Tres controles de ventana: `AppIconButton` HUD, 46×36 px de hit area, íconos 16 px del set `AppIcons`.
- [ ] Hover neutro: fondo `borderSubtle`, ícono `textPrimary`. Hover cerrar: fondo `danger`, ícono `textPrimary`.
- [ ] Press: escala 0.97 con `durInstant`.
- [ ] Foco visible 2 px `cyan` en los tres controles; orden de foco izquierda-a-derecha.
- [ ] Toda la franja salvo los controles es arrastrable vía `DragToMoveArea`; los controles reciben clic sin iniciar drag.
- [ ] El ícono de maximizar alterna a restaurar según `windowManager.isMaximized()` con crossfade `durFast`.
- [ ] Cada control tiene `Semantics`/`tooltip` descriptivo en español.
- [ ] Cero `Courier`, cero hex sueltos, cero magic numbers: sólo tokens del archivo 00.
- [ ] Reduced-motion respetado (sin latido, sin shimmer).
- [ ] `flutter analyze` sin warnings nuevos; se ve correcto en 1280×720 y en 1024×600.

---

## 10. Dependencias

Deben estar completados antes de ejecutar este prompt:

- **01** — Tokens de color (`AppColors`: `background`, `borderSubtle`, `textTertiary`, `textSecondary`, `textPrimary`, `danger`, `success`, `cyan`).
- **02** — Sistema tipográfico (`AppTextStyles.labelSmall`, `AppTextStyles.mono`).
- **03** — Tokens de dimensión (`AppDimens.space8`, `space12`, altura de barra).
- **04** — Sistema de motion (`AppMotion`: `durInstant`, `durFast`, `durBase`, `easeStandard`, `reduced`).
- **05** — Iconografía (`AppIcons.windowMinimize`, `windowMaximize`, `windowRestore`, `windowClose`).
- **06** — Primitivas HUD (`HudDivider` vertical, `HudStatusDot`).
- **09** — Botones (`AppIconButton` variante HUD).
- **13** — Tooltips HUD.

Se integra con: **20** (MainLayout shell, que provee el breadcrumb y el `SystemStatus`) y **61** (Connectivity HUD, que comparte la señal de estado online/offline).
