# 14 — Skeletons y estados de carga (`SkeletonBase` premium · `AppSpinner`)

> Prompt de la **Fase B — Componentes núcleo**. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Leé el archivo 00 completo antes de ejecutar. Todo valor se referencia por **nombre de token**.

---

## 1. Objetivo

Elevar `SkeletonBase` a nivel premium (shimmer diagonal con barrido de oro tenue) y definir el `AppSpinner` de marca, más los patrones compuestos de skeleton (card, lista, fila de tabla). Establece la regla de cuándo usar skeleton frente a spinner.

---

## 2. Archivos

- **Modificar** `lib/core/ui/widgets/skeleton_base.dart` — reescribir `SkeletonBase` con tokens.
- **Crear** `lib/core/ui/widgets/app_spinner.dart` — `AppSpinner`.
- **Crear** `lib/core/ui/widgets/skeleton_patterns.dart` — `SkeletonCard`, `SkeletonListRow`, `SkeletonTableRow`, `SkeletonGrid`.
- No crear subcarpetas.

---

## 3. Estado actual

`skeleton_base.dart` actual: `Container` con `color: AppColors.surface.withOpacity(0.5)`, borde `Colors.white.withOpacity(0.05)`, radio fijo 12, y `.shimmer(duration: 1500.ms, color: white@0.05, angle: 0.25)` de `flutter_animate`. Funciona pero: usa hex/opacidades sueltas, el shimmer es genérico (blanco, no el barrido dorado de marca), el radio es magic number, no respeta reduced-motion, y no hay patrones compuestos ni spinner de marca.

---

## 4. Visión del rediseño

El skeleton debe sentirse «el panel cargando datos», no un placeholder gris. Base `surfaceHud`, sobre la que cruza un **barrido diagonal de `gradGoldSheen` muy tenue** (un destello de oro que recorre la placa), en ciclo de ~2800 ms. El `AppSpinner` es un anillo con un arco `gold` girando — la firma de carga de la marca. Regla: skeleton para cargas de contenido estructurado >300 ms; spinner para acciones puntuales (botón enviando) o cargas indeterminadas cortas.

---

## 5. Especificación visual

### 5.1 `SkeletonBase`

```dart
SkeletonBase({
  double? width,
  double? height,
  double radius = radiusS,          // token, no magic number
  BoxShape shape = BoxShape.rectangle,
  EdgeInsetsGeometry? margin,
})
```

- Relleno base: `surfaceHud`.
- Borde: `borderSubtle` 1 px.
- Forma: `rectangle` con `radius` (token, default `radiusS`) o `circle`.
- **Shimmer**: barrido diagonal (ángulo ≈0.25 rad) de `gradGoldSheen` a opacidad muy baja (el sheen ya es translúcido; el efecto debe ser apenas perceptible, «caro y silencioso», no un flash). Ciclo definido por el token `durSkeletonCycle` ≈ 2800 ms (si no existe, agregarlo en `app_motion.dart` del prompt 04). Repetición infinita mientras el widget está montado.

### 5.2 `AppSpinner`

```dart
AppSpinner({
  double size = 20,
  Color? arcColor,                  // default: gold
  double strokeWidth = 2.5,
})
```

- Anillo circular: pista (track) en `borderDefault`, arco activo en `arcColor` (default `gold`) cubriendo ~80° del círculo, con extremos redondeados.
- Gira 360° de forma continua. Periodo ≈900 ms (`durTicker`-class; usar un token de motion o el más cercano disponible). Glow `glowGold` muy tenue alrededor del arco cuando `arcColor == gold`.
- Tamaños de uso típicos: 16 px (dentro de botones, prompt 09), 20 px (inline), 32 px (carga de sección).

### 5.3 Patrones compuestos (`skeleton_patterns.dart`)

- **`SkeletonCard`** — replica la silueta de una `HoloPanel` de contenido: un bloque rectángulo grande arriba (imagen/avatar), dos líneas de texto (ancho 100 % y 60 %), una pill pequeña. Todos `SkeletonBase` con los radios correctos.
- **`SkeletonListRow`** — fila: círculo (avatar) + dos líneas de texto apiladas + una pill al final. Altura ≈64 px.
- **`SkeletonTableRow`** — fila de tabla: N celdas rectangulares de anchos proporcionales a las columnas reales, altura ≈44 px.
- **`SkeletonGrid`** — grilla de N `SkeletonCard` (parámetro `count`, default 6) con el mismo gap `space20` que la grilla real.

Cada patrón es solo composición de `SkeletonBase`; no introducen colores ni animación propia.

---

## 6. Estados e interacciones (matriz §9 del archivo 00)

Los skeletons y el spinner **no son interactivos**: representan el estado `loading` de otros componentes. No tienen `hover`/`pressed`/`focused`.

- `default`/`loading`: animación de shimmer (skeleton) o giro (spinner) activa.
- Cuando los datos llegan: el skeleton hace crossfade hacia el contenido real (`durBase`, `easeStandard`), nunca un corte brusco.
- `error`: si la carga falla, el skeleton es reemplazado por el patrón de error del prompt 16.
- `empty`: si la carga termina sin datos, el skeleton es reemplazado por el `EmptyState` del prompt 15.

**Regla de uso (obligatoria):** si una operación de carga puede superar **300 ms**, mostrar skeleton (contenido estructurado) o `AppSpinner` (acción puntual). Por debajo de 300 ms no mostrar nada (evita parpadeo).

---

## 7. Animaciones

| Animación | Token duración | Curva | Propiedad |
|---|---|---|---|
| Shimmer del skeleton | `durSkeletonCycle` ≈2800 ms | lineal, repeat infinito | barrido de `gradGoldSheen` (gradiente animado / `flutter_animate .shimmer`) |
| Giro del `AppSpinner` | ≈900 ms periodo | lineal, repeat infinito | rotación del arco |
| Crossfade skeleton→contenido | `durBase` | `easeStandard` | opacidad |

- **Reduced motion** (`AppMotion.reduced`): el skeleton **no** hace el barrido diagonal; en su lugar pulsa la opacidad de toda la placa entre ~0.6 y 1.0 de forma lenta y estática (sin movimiento de barrido). El `AppSpinner` mantiene el giro (es feedback funcional, no decoración) pero sin el glow pulsante.
- El shimmer nunca anima `width`/`height`; solo el gradiente/opacidad.

---

## 8. Accesibilidad

- Los skeletons son decorativos del estado de carga: envolverlos en `Semantics(label: 'Cargando', liveRegion: false)` a nivel del contenedor, o marcarlos `ExcludeSemantics` y que el contenedor anuncie «Cargando».
- El `AppSpinner` en un contexto de carga relevante debe ir acompañado de un texto «Cargando…»/«Procesando…» para lectores de pantalla, no solo el giro.
- El shimmer dorado es de muy baja intensidad para no provocar molestia visual; reduced-motion lo desactiva (§7).
- Contraste: el contenido de skeleton no transmite información, pero la placa `surfaceHud` + borde `borderSubtle` debe seguir siendo visible sobre el fondo.

---

## 9. Checklist de aceptación

- [ ] `skeleton_base.dart` reescrito: relleno `surfaceHud`, borde `borderSubtle`, radio por token, sin hex sueltos.
- [ ] El shimmer es un barrido diagonal de `gradGoldSheen` muy tenue, ciclo ≈2800 ms (`durSkeletonCycle`).
- [ ] Existe `AppSpinner` con anillo + arco `gold`, glow tenue, tamaños configurables.
- [ ] Existen `SkeletonCard`, `SkeletonListRow`, `SkeletonTableRow`, `SkeletonGrid` en `skeleton_patterns.dart`.
- [ ] Los patrones son pura composición de `SkeletonBase`.
- [ ] El crossfade skeleton→contenido usa `durBase`/`easeStandard`.
- [ ] Reduced-motion reemplaza el barrido por un pulso de opacidad estático.
- [ ] Regla de 300 ms documentada y aplicable.
- [ ] Cero hex sueltos / magic numbers; todo por token.
- [ ] `flutter analyze` sin warnings nuevos; compila en 1280×720 y 1024×600.

---

## 10. Dependencias

- **01** (color: `surfaceHud`, `borderSubtle`, `borderDefault`, `gold`, `gradGoldSheen`, `goldGlow`).
- **03** (dimensión: `space20`, `radiusS`, `glowGold`).
- **04** (motion: `durBase`, `durTicker`, `easeStandard`, token nuevo `durSkeletonCycle` ≈2800 ms, `AppMotion.reduced`).
- **12** (`HoloPanel` — `SkeletonCard` replica su silueta; `HoloPanel` en estado `loading` usa estos patrones).
