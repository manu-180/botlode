# 08 — Fondo de aplicación / capa ambiental

> Prompt de la **Fase A · Fundaciones**, último de la fase. Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md` y de los prompts **01, 03, 04, 06**.
> Lee el archivo 00 completo. Materializa §3.1.1 («profundidad siempre. Ningún fondo plano»).

---

## 1. Objetivo

Crear el widget `AppBackground`, la capa ambiental que envuelve el contenido de **cada pantalla** de la app. Es un sistema de capas —vacío radial + blobs de glow ambiental + textura de grilla + viñeta— que elimina por completo los fondos planos. Es el cierre de la Fase A: después de este prompt, ninguna pantalla puede mostrar un color de fondo liso.

---

## 2. Archivos

- **Crear:** `lib/core/ui/app_background.dart`
- **Crear (privado, en el mismo archivo o aparte):** un `CustomPainter` para la viñeta si no se resuelve con `RadialGradient`.
- **No tocar todavía:** `MainLayout`/`Scaffold` — el prompt 20 (shell) integra `AppBackground` en el layout; este prompt solo entrega el widget listo y verificable en aislamiento.

Cabecera `// Archivo: lib/core/ui/app_background.dart`. Importa `app_colors.dart`, `app_dimens.dart`, `app_motion.dart`, y `HudGridTexture` del prompt 06.

---

## 3. Estado actual

El `scaffoldBackgroundColor` del tema es `AppColors.background` (`#050A10`) liso. No hay capa ambiental: cada pantalla se dibuja sobre negro plano. Esto viola directamente el principio §3.1.1 («ningún fondo plano; el fondo de cada pantalla es un sistema de capas: vacío base + glow radial ambiental + textura/grid sutil»). Sin `AppBackground`, todos los prompts de pantalla heredarían un fondo muerto.

---

## 4. Visión del rediseño

`AppBackground` es un `Stack` de capas que produce profundidad cinematográfica «silenciosa»: un vacío que no es negro plano sino un radial sutil, dos o tres halos de luz ambiental que respiran lentamente, una retícula técnica casi invisible, y una viñeta que oscurece los bordes para enfocar el centro. El contenido de la pantalla flota encima. El efecto debe ser **caro y discreto**: nada se mueve rápido, nada brilla fuerte. Es el «aire» del hangar.

---

## 5. Especificación visual

### 5.1 API del widget

```dart
class AppBackground extends StatefulWidget {
  final Widget child;
  final bool showGrid;     // default true
  final bool showBlobs;    // default true
  final bool showVignette; // default true
  const AppBackground({ super.key, required this.child,
    this.showGrid = true, this.showBlobs = true, this.showVignette = true });
}
```
Es `StatefulWidget` porque la oscilación de los blobs necesita un `AnimationController`. El `child` es el contenido de la pantalla (lo que hoy iría dentro del `Scaffold`).

### 5.2 Orden de capas (de fondo a frente, en un `Stack`)

El `Stack` con `fit: StackFit.expand`. Capas, índice 0 = más al fondo:

1. **Capa 0 — Vacío base.** `Container` con `decoration: BoxDecoration(gradient: AppColors.gradVoid)`. `gradVoid` es el `RadialGradient` centro `bgElevated01` (80 %) → bordes `voidBlack`. Esto reemplaza visualmente el `scaffoldBackgroundColor` liso.
2. **Capa 1 — Blobs de glow ambiental.** 2–3 círculos difuminados, absolutamente posicionados (`Positioned`), envueltos en `IgnorePointer`. Detalle en §5.3.
3. **Capa 2 — Textura de grilla.** `HudGridTexture` (prompt 06) a opacidad muy baja, celda 32 px. Se renderiza solo si `showGrid`. `IgnorePointer`.
4. **Capa 3 — Viñeta de bordes.** Oscurecimiento radial de los bordes con `voidBlack`. Detalle en §5.4. Solo si `showVignette`. `IgnorePointer`.
5. **Capa 4 — Contenido.** `widget.child`. Es la única capa interactiva; recibe todo el hit-testing.

### 5.3 Blobs de glow ambiental

Tres blobs (usar 2 si el rendimiento lo exige; default 3). Cada blob es un `Container` circular con un `RadialGradient` de centro coloreado translúcido → transparente, sin borde. **No** usar `BoxShadow` para esto: usar el gradiente del propio círculo para que el difuminado sea suave y barato.

| Blob | Color centro | Diámetro | Posición (ancla) | Opacidad centro |
|---|---|---|---|---|
| A (oro) | `AppColors.gold` | 520 px | `top: -160, left: -120` (esquina superior izquierda, fuera de pantalla parcialmente) | 0.10 |
| B (cyan) | `AppColors.cyan` | 460 px | `bottom: -180, right: -140` (esquina inferior derecha) | 0.08 |
| C (oro tenue, opcional) | `AppColors.gold` | 360 px | `top: 40%` aprox, `right: -120` (centro-derecha) | 0.06 |

- Cada blob: `RadialGradient(colors: [color.withOpacity(op), color.withOpacity(0)])`, `stops: [0.0, 1.0]`.
- Las posiciones son aproximadas; el ejecutor las ajusta para que el centro de cada blob quede **parcialmente fuera** del viewport (el halo entra desde los bordes, no flota como una mancha centrada).
- **Oscilación lenta:** un único `AnimationController` con `duration` entre **12 y 20 s** (elegir ~16 s), `repeat(reverse: true)`. Cada blob deriva de ese controller un desplazamiento sutil (`Transform.translate` de ±10–18 px) y/o una micro-variación de opacidad (±0.02), con desfase distinto por blob (usar `Interval` o un offset de fase) para que no se muevan sincronizados.
- **Reduced-motion:** si `AppMotion.reduced(context)` es `true`, no crear/avanzar el controller — los blobs quedan estáticos en su posición media. Verificarlo en `initState`/`didChangeDependencies` y en `build`.
- **Performance:** los blobs son `RepaintBoundary` para aislar su repintado del contenido. Si `showBlobs` es `false`, no se construyen.

### 5.4 Viñeta de bordes

Oscurecimiento de los 4 bordes para enfocar el centro. Dos opciones, el ejecutor elige:
- **Opción A (preferida):** un `DecoratedBox` con `RadialGradient` centro transparente → bordes `voidBlack` a opacidad ~0.55, `radius: 1.1`, `center: Alignment.center`, `stops: [0.55, 1.0]`. Es barato y suave.
- **Opción B:** un `CustomPainter` que pinta un gradiente radial equivalente.
La viñeta nunca debe oscurecer tanto que «coma» contenido ubicado cerca de los bordes — es sutil. `IgnorePointer`.

### 5.5 Integración

`AppBackground` envuelve el cuerpo de cada pantalla. El prompt 20 lo coloca en `MainLayout` así que el shell entero (sidebar + contenido) comparte un fondo continuo. El `Scaffold` debe tener `backgroundColor: Colors.transparent` para que `AppBackground` se vea; el `gradVoid` de la capa 0 es el fondo real. Documentar esto como nota para el prompt 20.

### 5.6 Medidas resumidas

- Blob A: 520 px, top -160 / left -120, oro @0.10.
- Blob B: 460 px, bottom -180 / right -140, cyan @0.08.
- Blob C: 360 px, ~40 % alto / right -120, oro @0.06.
- Oscilación: ~16 s, `reverse:true`, traslación ±10–18 px, fase distinta por blob.
- Grid: celda 32 px, opacidad 0.04 (la trae `HudGridTexture`).
- Viñeta: radial a `voidBlack` @~0.55, stops 0.55→1.0.

---

## 6. Estados e interacciones

`AppBackground` no es interactivo: todas sus capas decorativas son `IgnorePointer`; solo el `child` recibe puntero. No tiene estados de §9 propios (no hay hover/press/disabled de un fondo). Los flags `showGrid`/`showBlobs`/`showVignette` permiten que pantallas concretas (p. ej. una pantalla muy densa en datos) atenúen capas — pero por defecto las tres están activas. Documentar que apagar capas es excepción, no norma.

---

## 7. Animaciones

- **Única animación:** la oscilación lenta de los blobs — `AnimationController` ~16 s, `repeat(reverse:true)`, traslación/opacidad sutil con fase desfasada por blob. Curva `easeStandard` o `Curves.easeInOut` (movimiento orgánico, sin aceleración brusca).
- **Reduced-motion:** con `AppMotion.reduced` activo, los blobs no se animan (controller no se inicia); el resto del fondo es estático de todos modos.
- No hay shimmer, ni scanlines animadas, ni parallax con el mouse en esta capa (el parallax, si alguna pantalla lo quiere, es decisión de ese prompt y siempre gateado por reduced-motion).
- El contenido (`child`) puede tener sus propias animaciones de entrada; eso lo gestionan los prompts de pantalla, no `AppBackground`.

---

## 8. Accesibilidad

- Todas las capas decorativas son `IgnorePointer` + `ExcludeSemantics`: el árbol de accesibilidad solo ve el `child`.
- El fondo **no debe reducir el contraste del contenido**: las opacidades de blobs (0.06–0.10) y grid (0.04) son lo bastante bajas para no afectar la legibilidad del texto encima; la viñeta solo toca los bordes, donde no hay texto crítico. Verificar que un texto `textSecondary` sobre el fondo siga en ≥4.5:1.
- Respeta `MediaQuery.disableAnimations` vía `AppMotion.reduced` (§7.3, §10).
- El fondo se ve correcto en 1280×720 y en el mínimo 1024×600: los blobs anclados a esquinas con offset negativo siguen entrando bien en la resolución mínima.

---

## 9. Checklist de aceptación

- [ ] Existe `lib/core/ui/app_background.dart` con el widget `AppBackground` (`StatefulWidget`).
- [ ] La API expone `child` y los flags `showGrid`/`showBlobs`/`showVignette` (default `true`).
- [ ] La capa 0 usa `AppColors.gradVoid` (radial) — no hay color de fondo plano.
- [ ] Hay 2–3 blobs de glow con los colores/diámetros/posiciones/opacidades de §5.3, cada uno con `RadialGradient` y `IgnorePointer`.
- [ ] Los blobs oscilan con un `AnimationController` de 12–20 s, `reverse:true`, fase desfasada, dentro de `RepaintBoundary`.
- [ ] Con `AppMotion.reduced(context)` los blobs quedan estáticos (controller no se inicia).
- [ ] La capa de grilla usa `HudGridTexture` (celda 32, opacidad 0.04) y solo aparece si `showGrid`.
- [ ] La viñeta oscurece los bordes con `voidBlack` de forma sutil, solo si `showVignette`.
- [ ] El orden del `Stack` es: vacío → blobs → grid → viñeta → `child`.
- [ ] Todas las capas decorativas son `IgnorePointer`/`ExcludeSemantics`; solo el `child` recibe puntero.
- [ ] El widget se ve correcto en 1280×720 y 1024×600.
- [ ] Cero color/dimensión/duración crudos: todo desde tokens.
- [ ] La app compila; `flutter analyze` no agrega warnings nuevos.

---

## 10. Dependencias

- **Previo:** 01 (`gradVoid`, `voidBlack`, `gold`, `cyan`), 03 (z-index y radios), 04 (`AppMotion.reduced` y curvas), 06 (`HudGridTexture`).
- **Habilita:** 20 (`MainLayout` envuelve el shell en `AppBackground`), 22/24 (login y dashboard se montan sobre este fondo) y todos los prompts de pantalla 21–65. Cierra la Fase A: con 01–08 hechos, las fundaciones están completas.
