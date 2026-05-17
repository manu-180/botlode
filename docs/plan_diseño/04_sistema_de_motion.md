# 04 — Sistema de motion

> Prompt de la **Fase A · Fundaciones**. Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Lee el archivo 00 completo. Los valores son los de **§7** del archivo 00.

---

## 1. Objetivo

Crear `lib/core/config/theme/app_motion.dart`, la fuente única de verdad de **duraciones, curvas, física de resorte y reduced-motion**. Después de este prompt ningún widget de la app puede usar una `Duration` mágica ni una curva inventada: toda animación de los prompts 05–65 referencia un token de `AppMotion`. También documenta los patrones de motion (escalonado, press, shimmer, latido, transición de pantalla) que los prompts posteriores aplican literalmente.

---

## 2. Archivos

- **Crear:** `lib/core/config/theme/app_motion.dart`
- **No tocar:** ningún otro archivo. Los prompts de pantalla consumen estos tokens.

---

## 3. Estado actual

No existe archivo de motion. Hoy las animaciones están dispersas y sin sistema: `animated_ticker.dart` usa `Duration(seconds: 2)` y `Curves.easeOutExpo` hardcodeados; `skeleton_base.dart` usa `1500.ms` de `flutter_animate`. No hay tokens de duración, ni curvas nombradas, ni una `SpringDescription` compartida, ni soporte de reduced-motion en ninguna parte. El principio §3.1.4 del archivo 00 («el movimiento tiene causa») no se puede cumplir sin un sistema central.

---

## 4. Visión del rediseño

Una clase `AppMotion` con: constantes `Duration` por velocidad, constantes `Curve`/`Cubic` por intención, una `SpringDescription` para física de resorte, y el helper estático `AppMotion.reduced(BuildContext)` que detecta accesibilidad del SO. Además, el archivo documenta —como comentarios estructurados que los prompts posteriores citan— los patrones de §7.3: escalonado de listas, press, hover, shimmer, latido de reactor y transición de pantalla. El ejecutor de cualquier prompt que anime algo encuentra acá el token exacto y la receta del patrón.

---

## 5. Especificación visual

Crear `lib/core/config/theme/app_motion.dart` con cabecera `// Archivo: lib/core/config/theme/app_motion.dart`. Importa `package:flutter/material.dart` y `package:flutter/physics.dart` (para `SpringDescription`). Clase `AppMotion` con constructor privado `AppMotion._();`.

### 5.1 Duraciones (§7.1)

Bloque `// --- DURACIONES ---`:

```dart
static const Duration durInstant    = Duration(milliseconds: 90);   // color en hover/press
static const Duration durFast       = Duration(milliseconds: 160);  // micro-interacciones, hover de card
static const Duration durBase       = Duration(milliseconds: 240);  // transiciones estándar (paneles, tabs)
static const Duration durSlow       = Duration(milliseconds: 320);  // entrada de modal, transición de pantalla
static const Duration durDeliberate = Duration(milliseconds: 420);  // reveals escénicos (TOPE de UI)
static const Duration durTicker     = Duration(milliseconds: 900);  // conteo de cifras numéricas
```

Helper para duración de salida (~65 % de la de entrada, regla §7.1):
```dart
static Duration exitOf(Duration entrance) =>
    Duration(milliseconds: (entrance.inMilliseconds * 0.65).round());
```

Regla obligatoria como comentario: «Ninguna animación de UI supera `durDeliberate` (420 ms). Las animaciones son interrumpibles y nunca bloquean el input.»

### 5.2 Curvas (§7.2)

Bloque `// --- CURVAS ---`:

```dart
static const Cubic easeEntrance = Cubic(0.16, 1.0, 0.3, 1.0);  // expo-out premium, entradas
static const Cubic easeExit     = Cubic(0.4, 0.0, 1.0, 1.0);   // salidas
static const Curve easeStandard = Curves.easeInOutCubic;       // transiciones de estado generales
static const Curve easeTicker   = Curves.easeOutExpo;          // conteo de cifras
```

### 5.3 Física de resorte (§7.2)

Bloque `// --- RESORTE ---`. Usar `SpringDescription` de `dart:physics` (re-exportado por `package:flutter/physics.dart`):

```dart
static const SpringDescription springSoft = SpringDescription(
  mass: 1.0,
  stiffness: 90.0,
  damping: 20.0,
);
```
Comentario: «Se usa con `SpringSimulation` o `AnimationController.animateWith` para modales, paneles y press de cards. Para press simple basta `AnimatedScale` con `easeEntrance`; el resorte se reserva para reveals que se sienten físicos.»

### 5.4 Reduced-motion (§7.3)

Helper estático que lee la preferencia de accesibilidad del SO:

```dart
/// Devuelve true si el usuario pidió reducir animaciones (accesibilidad del SO).
/// Cuando es true: sin shimmer, sin latidos, sin parallax/blobs;
/// las transiciones se degradan a crossfade de `durCrossfadeReduced`.
static bool reduced(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Duración a usar para el crossfade de reemplazo cuando reduced == true.
static const Duration durCrossfadeReduced = Duration(milliseconds: 120);
```

Patrón de consumo (documentar como comentario): todo widget que anime debe, al inicio del `build`, evaluar `final reduce = AppMotion.reduced(context);` y:
- si `reduce` → usar `durCrossfadeReduced` + `Curves.linear`, sin shimmer, sin latido, sin blobs animados;
- si no → usar el token de duración/curva normal.

### 5.5 Patrones de motion documentados (§7.3)

Incluir un bloque de comentario extenso `/// --- PATRONES (referencia para prompts 05–65) ---` con cada patrón y su receta concreta. Estos son **especificación**, no código; los prompts posteriores los citan por nombre.

**P1 · Escalonado de listas/grillas.** Cada ítem entra `36 ms` después del anterior. Animación por ítem: fade `0→1` + `translateY 12→0 px`, con `easeEntrance` y `durBase`. Máximo ~10 ítems escalonados (el ítem 11+ entra sin retraso adicional para no demorar la grilla). Implementación sugerida: `flutter_animate` con `.animate(delay: (index.clamp(0,10) * 36).ms)` o un `AnimationController` con `Interval` por ítem.

**P2 · Press de elementos clickeables.** Al `onTapDown`/`onPointerDown`: escala a `0.97` con `durInstant` y `easeEntrance`. Al soltar/cancelar: vuelve a `1.0` con `durFast`. Usar `AnimatedScale`.

**P3 · Hover (desktop).** Al entrar el puntero (`MouseRegion`): sube elevación +1 nivel, borde a `borderStrong`/`borderGold`, aparece glow suave; todo con `durFast` y `easeStandard`. Al salir: inverso con `durFast`. Cursor `SystemMouseCursors.click`.

**P4 · Shimmer.** Barrido de `AppColors.gradGoldSheen` que cruza el elemento cada `2800–3400 ms` (elegir un valor fijo por componente dentro del rango; no aleatorio por frame). Solo en elementos activos clave (botón primario activo, panel de crédito), nunca en todos. **Se desactiva con `AppMotion.reduced`.**

**P5 · Reactor / latido.** Pulso de opacidad `0.6 ↔ 1.0` con período `~1600 ms`, curva `easeStandard`, `AnimationController` en `repeat(reverse: true)`. Solo en estado activo (un reactor offline no late). **Se desactiva con `AppMotion.reduced`.**

**P6 · Transición de pantalla (go_router).** Fade `0→1` + slide direccional de `16 px`, duración `durSlow`, curva `easeEntrance` al entrar / `easeExit` al salir. Avanzar = la pantalla entrante viene desde la derecha/abajo (+16 px); volver = inverso. Con `AppMotion.reduced`: crossfade puro de `durCrossfadeReduced`, sin slide.

**P7 · Conteo de cifras.** El `HudTicker` (prompt 06) interpola el valor con `durTicker` y `easeTicker`. Con `AppMotion.reduced`: el valor aparece directo sin conteo.

### 5.6 Cómo se consume (cabecera)

Bloque `/// USO:` en la cabecera:
```
/// AnimatedScale(duration: AppMotion.durInstant, curve: AppMotion.easeEntrance, ...)
/// AnimatedContainer(duration: AppMotion.durFast, curve: AppMotion.easeStandard, ...)
/// final reduce = AppMotion.reduced(context); // gating de shimmer/latido/blobs
/// duración de salida: AppMotion.exitOf(AppMotion.durSlow)
```

---

## 6. Estados e interacciones

No aplica (archivo de constantes). Pero `AppMotion` provee la duración/curva para **cada transición de estado** de §9 del archivo 00: `hover` → `durFast`, `pressed` → `durInstant`, `focused` → aparición del anillo con `durFast`, `loading`/`disabled` → crossfade `durBase`. Verificar que todo estado tenga token; si falta, agregarlo aquí, no en el widget.

---

## 7. Animaciones

Este archivo **es** el sistema de animación: no anima por sí mismo, define los parámetros. Los prompts 05–65 no eligen duraciones ni curvas libremente; siempre referencian `AppMotion`. Cualquier valor nuevo que un prompt posterior necesite se agrega primero como token aquí.

---

## 8. Accesibilidad

- `AppMotion.reduced(context)` es el mecanismo central de cumplimiento de §10/§7.3 del archivo 00. **Todo** prompt que anime debe llamarlo y degradar como indica P4–P7.
- `MediaQuery.maybeOf` se usa (no `MediaQuery.of`) para no romper si no hay `MediaQuery` en el árbol; fallback `false`.
- Ninguna animación bloquea el input ni supera `durDeliberate`.
- Las transiciones de pantalla con reduced-motion se reducen a crossfade de 120 ms.

---

## 9. Checklist de aceptación

- [ ] Existe `lib/core/config/theme/app_motion.dart` con la clase `AppMotion` y constructor privado.
- [ ] Las **6** duraciones de §5.1 existen como `static const Duration` con los ms exactos.
- [ ] `exitOf(Duration)` existe y devuelve ~65 % de la duración de entrada.
- [ ] `easeEntrance = Cubic(0.16,1.0,0.3,1.0)` y `easeExit = Cubic(0.4,0.0,1.0,1.0)` existen.
- [ ] `easeStandard` y `easeTicker` existen mapeados a las curvas de Material indicadas.
- [ ] `springSoft` existe como `SpringDescription(mass:1, stiffness:90, damping:20)`.
- [ ] `reduced(BuildContext)` existe, lee `MediaQuery.maybeOf(...).disableAnimations` y tiene fallback `false`.
- [ ] `durCrossfadeReduced = 120 ms` existe.
- [ ] El bloque de patrones §5.5 (P1–P7) está presente como comentario de referencia.
- [ ] La cabecera incluye el bloque `/// USO:`.
- [ ] La app compila; `flutter analyze` no agrega warnings nuevos.

---

## 10. Dependencias

- **Previo:** ninguno estricto (no referencia color ni dimensión). Recomendable después de 01–03 para mantener orden de Fase A.
- **Habilita:** 06 (`HudTicker` usa `durTicker`/`easeTicker`; latido del reactor usa P5), 07 (transiciones de glow usan `durFast`), 08 (oscilación de blobs respeta `reduced`), y todos los prompts de pantalla 09–65 que animen.
