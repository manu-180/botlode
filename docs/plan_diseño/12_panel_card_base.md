# 12 — Panel / Card base (`HoloPanel`)

> Prompt de la **Fase B — Componentes núcleo**. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Leé el archivo 00 completo antes de ejecutar. Todo valor se referencia por **nombre de token**.

---

## 1. Objetivo

Crear `HoloPanel`: el contenedor de vidrio base que usa **toda** la app. Card de unidad, panel de crédito, modales, paneles de tabs, secciones de billing — todos se construyen sobre `HoloPanel`. Es la caja maestra; este prompt define su API completa y todas las combinaciones de ornamento.

---

## 2. Archivos

- **Crear** `lib/core/ui/widgets/holo_panel.dart` — `HoloPanel` + enum `HoloPanelShape` (`rounded`, `chamfer`).
- No crear subcarpetas. Todas las pantallas posteriores consumen este widget; no deben dibujar cajas de vidrio a mano.

---

## 3. Estado actual

No existe un contenedor base unificado. Cada pantalla arma sus cards con `Container` + `BoxDecoration` improvisados: radios distintos, bordes distintos, sombras inventadas, a veces sin glassmorphism. Esa inconsistencia es exactamente lo que el archivo 00 §3.1.6 marca como «mata el factor premium».

---

## 4. Visión del rediseño

`HoloPanel` es una placa de vidrio esmerilado flotando sobre el vacío: relleno `glassSurface` con blur, borde hairline `glassBorder`, una línea de highlight `glassHighlightTop` de 1 px en el canto superior (la luz que «pega» arriba), elevación `elev1` en reposo que sube a `elev2` en hover. Sobre esa base, ornamento HUD **opcional y jerárquico**: brackets de esquina, scanlines, header con título y divisor. La regla del archivo 00 §3.1.7: el ornamento subraya jerarquía, no se pone en cada caja.

---

## 5. Especificación visual

### 5.1 API del widget

```dart
HoloPanel({
  required Widget child,
  HoloPanelShape shape = HoloPanelShape.rounded,
  EdgeInsetsGeometry padding = const EdgeInsets.all(20),  // space20 por defecto
  bool cornerBrackets = false,        // dibuja HudCornerBrackets
  bool scanlines = false,             // overlay HudScanlines
  String? header,                     // si !=null, renderiza zona de encabezado
  List<Widget>? headerActions,        // slot de acciones a la derecha del header
  bool interactive = false,           // si true, habilita hover/press (cards clickeables)
  VoidCallback? onTap,                // si !=null implica interactive=true
  Widget? glowAccent,                 // color de glow ambiental opcional (estado activo)
})
```

### 5.2 Capas de la placa (de atrás hacia adelante)

1. **Sombra de elevación** — `elev1` en reposo (`elev2` si `interactive` + hover). Una sola sombra; opcionalmente un glow si `glowAccent != null`. Nunca dos glows.
2. **Forma + clip** — `rounded` usa `radiusL` (20); `chamfer` usa `ChamferBorder` (`chamferM` = 12) del prompt 06. El `child` se clipea a esta forma.
3. **Relleno de vidrio** — `BackdropFilter` con blur + color `glassSurface` (usar `GlassDecoration` del prompt 07). Modales que necesitan más legibilidad usan `glassSurfaceStrong` (controlado por quien lo instancia, no por defecto).
4. **Borde hairline** — `glassBorder`, 1 px (1.5 px en estado hover → `borderStrong`).
5. **Highlight superior** — línea de 1 px `glassHighlightTop` en el borde top (gradiente vertical sutil o `Border(top:)` aclarado).
6. **Scanlines** (si `scanlines == true`) — `HudScanlines` del prompt 06, overlay no interactivo.
7. **Corner brackets** (si `cornerBrackets == true`) — `HudCornerBrackets` del prompt 06, color `borderGold`, sobre las esquinas de la forma.
8. **Contenido** — header opcional + `child`, con `padding`.

### 5.3 Zona de header (si `header != null`)

- Fila superior: `Text(header)` en `titleM` (color `textPrimary`) a la izquierda + `Spacer` + `headerActions` (típicamente `AppIconButton`s) a la derecha.
- Debajo del header: `HudDivider` (prompt 06) a todo el ancho.
- El `child` va debajo del divisor con la separación `space16`.
- El padding del header respeta el `padding` del panel en horizontal.

### 5.4 Combinaciones canónicas (guía para quien lo usa)

| Uso | `shape` | `cornerBrackets` | `scanlines` | `header` | `interactive` |
|---|---|---|---|---|---|
| Card de contenido simple | `rounded` | false | false | opcional | false |
| Bot card (grilla) | `rounded` | false | false | no | true |
| Panel HUD de crédito | `chamfer` | true | true | sí | false |
| Modal | `rounded`/`chamfer` | opcional | false | sí | false |
| Panel de tab de detalle | `rounded` | false | false | sí | false |

---

## 6. Estados e interacciones (matriz §9 del archivo 00)

Si `interactive == false`, `HoloPanel` solo tiene `default` (es un contenedor pasivo).

Si `interactive == true` (o `onTap != null`):

| Estado | Borde | Elevación | Glow | Otros |
|---|---|---|---|---|
| `default` | `glassBorder` 1 px | `elev1` | `glowAccent` si se pasó | — |
| `hover` | `borderStrong` 1.5 px | `elev2` | glow suave aparece/intensifica | cursor `click` |
| `pressed` | `borderStrong` 1.5 px | `elev1` | — | escala 0.97 |
| `focused` | + anillo `cyan` 2 px externo | igual | — | navegable por teclado |
| `disabled` | `borderSubtle` | `elev0` | ninguno | opacidad 0.4, no interactivo |
| `loading` | — | — | — | el `child` se reemplaza por skeleton (prompt 14); el panel no se vuelve clickeable |
| `error` | borde `danger` | — | `glowStatus(danger)` tenue | el `child` muestra el patrón de error del prompt 16 |
| `empty` | `glassBorder` | `elev1` | — | el `child` muestra `EmptyState` del prompt 15 |

- `loading`/`error`/`empty` no son props directas del panel: son responsabilidad de quien decide qué `child` pasar. Este prompt solo documenta que `HoloPanel` es el marco de esos tres estados.

---

## 7. Animaciones

| Interacción | Token duración | Token curva | Propiedad |
|---|---|---|---|
| Hover (borde + elevación + glow) | `durFast` | `easeStandard` | `AnimatedContainer` (boxShadow, border) |
| Press | `durInstant` | `easeStandard` | `AnimatedScale` 1.0→0.97 |
| Release | `durFast` | `easeStandard` | `AnimatedScale` 0.97→1.0 |
| Entrada del panel (cuando aparece) | `durBase` | `easeEntrance` | fade + translateY 12 px |
| Entrada en grilla (varios paneles) | escalonado 36 ms entre ítems, máx ~10 | `easeEntrance` | fade + translateY 12 px |

- **Reduced motion**: sin escalonado de entrada (todos aparecen con un crossfade 120 ms simultáneo); press no escala (solo cambia el borde); sin shimmer.
- El panel nunca anima `width`/`height`; el contenido cambia de tamaño con `AnimatedSize` si hace falta.

---

## 8. Accesibilidad

- Contraste del contenido sobre `glassSurface` verificado: `textPrimary` ≥ 12:1, `textSecondary` ≥ 4.5:1. El blur no debe reducir el contraste por debajo de mínimos — si una pantalla muy clara queda detrás, usar `glassSurfaceStrong`.
- Si `interactive`, el panel completo es un objetivo de foco: `Semantics(button: true)`, anillo `cyan` 2 px visible, activable con `Enter`/`Space`, área de hit = toda la placa.
- `disabled` reportado a accesibilidad (`Semantics(enabled: false)`).
- El ornamento (brackets, scanlines, grid) es decorativo: marcarlo `ExcludeSemantics` para que no contamine el árbol de accesibilidad.

---

## 9. Checklist de aceptación

- [ ] Existe `holo_panel.dart` en `lib/core/ui/widgets/` con `HoloPanel` y `HoloPanelShape`.
- [ ] Soporta todas las props de §5.1: `shape`, `padding`, `cornerBrackets`, `scanlines`, `header`, `headerActions`, `interactive`, `onTap`, `glowAccent`.
- [ ] La placa tiene las 8 capas de §5.2 (sombra, forma, vidrio con blur, borde, highlight superior, scanlines, brackets, contenido).
- [ ] `rounded` usa `radiusL`; `chamfer` usa `ChamferBorder`/`chamferM`.
- [ ] El header renderiza título `titleM` + acciones + `HudDivider` debajo.
- [ ] En modo `interactive` implementa la matriz de §6 (hover/pressed/focused/disabled).
- [ ] Hover sube a `elev2` + `borderStrong`; press escala a 0.97.
- [ ] Una sola sombra de elevación + máximo un glow.
- [ ] El ornamento decorativo está envuelto en `ExcludeSemantics`.
- [ ] Cero hex sueltos / magic numbers; todo por token.
- [ ] Respeta reduced-motion según §7.
- [ ] `flutter analyze` sin warnings nuevos; compila en 1280×720 y 1024×600.

---

## 10. Dependencias

- **01** (color: `glassSurface`, `glassSurfaceStrong`, `glassBorder`, `glassHighlightTop`, `borderStrong`, `borderSubtle`, `borderGold`, `cyan`, `danger`, `textPrimary`).
- **02** (tipografía: `titleM`).
- **03** (dimensión: `space16`, `space20`, `radiusL`, `chamferM`, `elev0/1/2`, `glowStatus`).
- **04** (motion: `durInstant`, `durFast`, `durBase`, `easeStandard`, `easeEntrance`, `AppMotion.reduced`).
- **06** (primitivas HUD: `HudCornerBrackets`, `HudScanlines`, `HudDivider`, `ChamferBorder`).
- **07** (`GlassDecoration` — relleno de vidrio con blur).
- **14**/**15**/**16** se apoyan en este panel para sus estados `loading`/`empty`/`error` (dependencia inversa: este prompt no los requiere, pero los menciona).
