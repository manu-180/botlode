# 07 — Primitivas de glow y glass

> Prompt de la **Fase A · Fundaciones**. Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md` y de los prompts **01, 03, 04, 06**.
> Lee el archivo 00 completo. Aplica §4.2 (vidrio), §6.4 (elevación/glow) y §3.1.3 («la luz tiene fuente»).

---

## 1. Objetivo

Crear los helpers reutilizables de **glassmorphism** y **glow** que dan profundidad y emisión a toda la app: una factory `GlassDecoration` para superficies de vidrio esmerilado, un widget `GlowBox` que envuelve cualquier hijo con un glow tokenizado, y la receta canónica del blur con `BackdropFilter`/`ImageFilter.blur`. Después de este prompt, ninguna pantalla improvisa un `BoxDecoration` de vidrio ni una sombra de glow.

---

## 2. Archivos

- **Crear:** `lib/core/ui/fx/glass_decoration.dart` — factory de `BoxDecoration` de vidrio.
- **Crear:** `lib/core/ui/fx/glow_box.dart` — widget `GlowBox`.
- **Crear:** `lib/core/ui/fx/frosted_blur.dart` — widget helper `FrostedBlur` que encapsula el `BackdropFilter`.
- **Crear (opcional):** `lib/core/ui/fx/fx.dart` — barrel file.

Cabecera `// Archivo: ...` en cada uno. Importan `app_colors.dart`, `app_dimens.dart`, `app_motion.dart` según necesiten, y `dart:ui` para `ImageFilter`.

---

## 3. Estado actual

No hay helpers de glass ni de glow. `AppColors` tiene `glassSurface` pero ningún componente lo usa con un blur real: hoy los «paneles de vidrio» son `Container` con color semitransparente y borde, sin `BackdropFilter`, así que no hay esmerilado verdadero. Los glows que existen están hechos a mano con `BoxShadow` sueltas en distintas vistas, sin coherencia. §3.1.3 («la luz tiene fuente») y la estética glassmorphism de §3 no se pueden cumplir sin estas primitivas.

---

## 4. Visión del rediseño

Tres piezas que combinan profundidad + emisión + esmerilado de forma coherente:

1. **`GlassDecoration`** — una factory estática que devuelve el `BoxDecoration` correcto para una superficie de vidrio: relleno semitransparente, borde hairline, highlight superior, radio. Dos variantes: panel normal y modal (más opaco).
2. **`GlowBox`** — envuelve un hijo y le aplica UN glow tokenizado (`glowGold`/`glowCyan`/`glowStatus`), opcionalmente combinado con UNA sombra de elevación. Hace cumplir por construcción la regla «una sombra + un glow máximo».
3. **`FrostedBlur`** — encapsula el `BackdropFilter` con el `sigma` recomendado y consideraciones de performance de desktop.

El ejecutor compone: `FrostedBlur(child: Container(decoration: GlassDecoration.panel()))` para un panel de vidrio, y `GlowBox(glow: AppGlow.gold, child: ...)` para algo que «emite».

---

## 5. Especificación visual

### 5.1 `GlassDecoration` (factory)

Clase `GlassDecoration` con constructor privado y **métodos factory estáticos** que devuelven `BoxDecoration`:

```dart
static BoxDecoration panel({
  double radius = AppDimens.radiusL,
  Color? fill,            // default AppColors.glassSurface
  Border? border,         // default borde hairline glassBorder
  List<BoxShadow>? shadow,// default AppDimens.elev1
});

static BoxDecoration modal({
  double radius = AppDimens.radiusXL,
  // fill default AppColors.glassSurfaceStrong, shadow default AppDimens.elev3
});

static BoxDecoration hud({
  double radius = AppDimens.radiusM,
  // fill AppColors.surfaceHud, para lecturas terminal
});
```

Cada `BoxDecoration` debe incluir:
- **Relleno:** `color` = `glassSurface` (panel) / `glassSurfaceStrong` (modal) / `surfaceHud` (hud). Como alternativa a color plano, `panel` puede usar `gradient: AppColors.gradPanel` para el sutil degradé de §4.6 — exponer un flag `bool gradientFill = false`.
- **Borde:** `Border.all(color: AppColors.glassBorder, width: 1)`.
- **Highlight superior:** simular el highlight de 1 px de `glassHighlightTop` (§4.2). Como `BoxDecoration` no soporta un borde por-lado con color distinto de forma directa, exponer también un widget helper `GlassHighlightLine` (un `Container` de 1 px de alto, `glassHighlightTop`, alineado arriba dentro de un `Stack`) **o** documentar que el highlight se logra con un `Border(top: BorderSide(color: glassHighlightTop, width: 1), ...)` combinado. El ejecutor elige; lo importante es que el borde superior se vea ~1 px más claro.
- **Radio:** `BorderRadius.circular(radius)`.
- **Sombra:** `boxShadow` = `elev1` (panel) / `elev3` (modal). Nunca un glow acá — el glow lo pone `GlowBox`.

Regla documentada: `GlassDecoration` **no** aplica el blur. El blur lo hace `FrostedBlur` envolviendo el contenedor. Un panel de vidrio completo = `FrostedBlur` + `Container(decoration: GlassDecoration.panel())`.

### 5.2 `FrostedBlur` (widget)

```dart
class FrostedBlur extends StatelessWidget {
  final Widget child;
  final double sigma;       // default 14
  final BorderRadius? clip; // recorte para no derramar el blur
  const FrostedBlur({super.key, required this.child, this.sigma = 14, this.clip});
}
```

- **Implementación:** `ClipRRect(borderRadius: clip ?? AppDimens.brL)` envolviendo un `BackdropFilter(filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: child)`.
- **`sigma` recomendado:** **12–16** para paneles (default 14); **18–22** para el scrim de modales. Valores mayores degradan performance en desktop sin ganancia visual.
- **Performance (comentario obligatorio):** `BackdropFilter` es costoso. Reglas: (a) usar el menor `sigma` que se vea bien; (b) **no anidar** un `FrostedBlur` dentro de otro; (c) no usar `FrostedBlur` en ítems de listas largas que scrollean — ahí preferir `GlassDecoration` con color opaco sin blur real; (d) siempre recortar con `ClipRRect` para que el blur no se derrame fuera de la forma.
- El `clip` debe coincidir con el radio del `GlassDecoration` que se use dentro.

### 5.3 `GlowBox` (widget)

```dart
enum AppGlow { none, gold, cyan }

class GlowBox extends StatelessWidget {
  final Widget child;
  final AppGlow glow;            // glow predefinido
  final Color? statusColor;      // si != null, usa glowStatus(statusColor) e ignora `glow`
  final List<BoxShadow> elevation; // default AppDimens.elev0
  final BorderRadius? borderRadius;
  final bool animated;           // pulso suave del glow
  const GlowBox({ ... });
}
```

- **Implementación:** un `Container`/`DecoratedBox` cuyo `boxShadow` = `[...elevation, ...glowList]`, donde `glowList` se resuelve:
  - `statusColor != null` → `AppDimens.glowStatus(statusColor!)`.
  - `glow == AppGlow.gold` → `AppDimens.glowGold`.
  - `glow == AppGlow.cyan` → `AppDimens.glowCyan`.
  - `glow == AppGlow.none` → `[]`.
- **Regla de combinación (hace cumplir §6.4):** `elevation` debe ser una sola lista de la escala (`elev0..elev3`) y `glow*` aporta UN solo glow. `GlowBox` **no** acepta dos glows. Documentar y, si se quiere, hacer un `assert` de que `elevation` no contenga glows.
- **`animated`:** si `true` y `!AppMotion.reduced(context)`, anima la intensidad del glow (interpola el `blurRadius` / la opacidad del color del glow) con un `AnimationController` `repeat(reverse:true)`, período ~1600 ms, curva `easeStandard` — es el «latido» de §7.3 (P5). Con reduced-motion: glow fijo.
- `borderRadius` se aplica al `DecoratedBox` para que el glow siga la forma.

### 5.4 Combinación elevación + glow (regla canónica)

Documentar en los tres archivos y aquí: **un elemento usa exactamente una sombra de elevación + como máximo un glow.** Composiciones válidas:
- Card en reposo: `elev1`, sin glow.
- Card en hover: `elev2` + `glowGold` (vía `GlowBox`).
- Botón primario activo: `elev1` + `glowGold` animado.
- Modal: `GlassDecoration.modal()` (trae `elev3`), sin glow — el glow distraería del contenido.
Composiciones prohibidas: `glowGold` + `glowCyan` juntos; sombras fuera de `elev0..elev3`; glow sin que el elemento «tenga razón» para emitir (§3.1.3).

### 5.5 Receta de panel de vidrio completo (referencia para prompts posteriores)

Bloque de comentario `/// PANEL DE VIDRIO ESTÁNDAR:` con el patrón que el prompt 12 (`HoloPanel`) y los prompts de modal usarán:
```
FrostedBlur(
  sigma: 14,
  clip: AppDimens.brL,
  child: Container(
    decoration: GlassDecoration.panel(gradientFill: true),
    child: ...,  // contenido
  ),
)
// + opcionalmente HudCornerBrackets alrededor (prompt 06) para paneles jerárquicos.
```

---

## 6. Estados e interacciones

- `GlassDecoration` es estática: los estados los aplica el componente consumidor pasando distintos `fill`/`border`/`shadow` (p. ej. `border` a `borderStrong` en hover).
- `GlowBox` representa el estado «emite / no emite»: `AppGlow.none` para reposo apagado, glow activo para foco/estado. El componente consumidor cambia el `glow` según su estado de §9.
- `FrostedBlur` no tiene estados.
Documentar que estas primitivas no capturan puntero ni gestionan su propio estado: lo hace el widget de pantalla.

---

## 7. Animaciones

- `GlowBox(animated:true)`: latido del glow, ~1600 ms, `easeStandard`, gateado por `AppMotion.reduced`.
- Las transiciones de estado (aparición/desaparición del glow al hacer hover) las maneja el componente consumidor con `AnimatedContainer`/`AnimatedSwitcher` y `durFast` — `GlowBox` puede recibir un `glow` distinto y, si se envuelve en `AnimatedSwitcher`/`TweenAnimationBuilder`, transicionar suave.
- `FrostedBlur`: no anima el `sigma` (animar blur es muy costoso). Si una pantalla necesita «aparecer» un panel de vidrio, anima opacidad/escala del conjunto, no el sigma.

---

## 8. Accesibilidad

- El vidrio **no** debe reducir el contraste del texto: por eso `glassSurfaceStrong` (modal) es más opaco — garantizar que el texto sobre vidrio mantenga ≥4.5:1. Si un panel de vidrio queda sobre un fondo muy claro localmente, subir la opacidad del `fill`.
- El glow es decorativo: no porta información por sí solo (el estado siempre lleva ícono + texto, §10).
- `FrostedBlur` y `GlowBox` decorativos van con `ExcludeSemantics` donde corresponda; no roban foco.
- Con `AppMotion.reduced`: sin latido de glow.
- Performance: en 1024×600 (mínimo) y 1280×720, los paneles con `FrostedBlur` deben mantener fluidez; si se detecta jank, bajar `sigma` o usar relleno opaco.

---

## 9. Checklist de aceptación

- [ ] Existen `glass_decoration.dart`, `glow_box.dart`, `frosted_blur.dart` en `lib/core/ui/fx/` (+ barrel opcional).
- [ ] `GlassDecoration` tiene factories `panel()`, `modal()`, `hud()` que devuelven `BoxDecoration` con relleno, borde `glassBorder`, radio y sombra de la escala correctos.
- [ ] `GlassDecoration.panel` soporta `gradientFill` con `AppColors.gradPanel`.
- [ ] El highlight superior (`glassHighlightTop`) está resuelto (borde superior más claro o `GlassHighlightLine`).
- [ ] `FrostedBlur` envuelve `BackdropFilter` + `ImageFilter.blur` con `sigma` default 14, recortado con `ClipRRect`.
- [ ] `FrostedBlur` documenta las 4 reglas de performance (sigma mínimo, no anidar, no en listas largas, recortar).
- [ ] `GlowBox` resuelve el glow desde `AppGlow`/`statusColor` y combina con UNA `elevation` de la escala.
- [ ] `GlowBox` no permite dos glows (documentado / `assert`).
- [ ] `GlowBox(animated:true)` late ~1600 ms y respeta `AppMotion.reduced`.
- [ ] El bloque «PANEL DE VIDRIO ESTÁNDAR» y la regla «una sombra + un glow» están documentados.
- [ ] Cero color/dimensión/duración crudos: todo desde tokens.
- [ ] La app compila; los paneles de vidrio se ven esmerilados; `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Previo:** 01 (tokens de vidrio y `*Glow`), 03 (`elev*`, `glow*`, radios), 04 (`AppMotion.reduced` y latido), 06 (las primitivas HUD se componen con glass/glow; `HudCornerBrackets` rodea paneles de vidrio).
- **Habilita:** 08 (`AppBackground` usa glows ambientales), 12 (`HoloPanel` = `FrostedBlur` + `GlassDecoration` + brackets), todos los modales de billing (51–56) y los prompts de pantalla que usen profundidad/emisión.
