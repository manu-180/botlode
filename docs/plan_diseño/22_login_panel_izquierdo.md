# 22 — Login · Panel izquierdo (branding + Rive Catbot)

> Depende del archivo **00 — README · Visión y Sistema de Diseño**. Leerlo completo antes de ejecutar. Todos los valores de color, espaciado, tipografía, motion y ornamento se referencian **por token**, nunca por hex crudo.

---

## 1. Objetivo

Rediseñar el panel izquierdo de la pantalla de login (`LoginView`): la mitad de branding cinematográfico que contiene la animación Rive del Catbot. Hoy es funcional pero plano (un gradiente negro lineal sobre el Rive y textos con estilos inline). Se eleva a un **frame de hangar premium**: animación enmarcada, viñeta cinematográfica, ornamentos HUD de esquina y jerarquía tipográfica del sistema. Es la primera impresión de la app: debe transmitir «terminal industrial cara» en el primer segundo.

---

## 2. Archivos

- **Modificar:** `lib/features/auth/presentation/views/login_view.dart` — toda la rama `Expanded(flex: 5, …)` del `Row`, es decir el panel izquierdo. No tocar la lógica del eye-tracking (`_onTick`, `_onRiveInit`, `_onHover`, `_onExit`, los `SMINumber`).
- **Consumir (no crear):** `AppBackground` (prompt 08), `HudCornerBrackets` / `HudScanlines` / `HudIdTag` (prompt 06), `app_colors.dart` (01), `app_theme.dart` / `AppTextStyles` (02), `app_dimens.dart` (03), `app_motion.dart` (04).

---

## 3. Estado actual

El panel izquierdo es `Expanded(flex: 5)` envuelto en `LayoutBuilder` + `MouseRegion` (hover y exit para el eye-tracking). Dentro, un `Stack` con:

1. `Positioned.fill` con `RiveAnimation.direct` (artboard `Catbot`, `BoxFit.cover`), estados `loading`/`error`.
2. `Positioned.fill` con un `Container` de gradiente lineal vertical negro `0.3 → 0.8`.
3. `Positioned(bottom: 60, left: 60)` con una `Column`: un `Container` con borde dorado y texto `"FACTORY TERMINAL v1.0"` en fuente `Courier`; el título `"BotLode"` a 80 px peso 900; un subtítulo de 400 px de ancho en blanco al 70 %.

Problemas: gradiente plano (no funde el Rive con el fondo, lo oscurece a secas), tipografía con `fontFamily: 'Courier'` y tamaños mágicos, sin ornamento HUD, sin animación de entrada escalonada, el borde divisorio es un `BorderSide` suelto.

---

## 4. Visión del rediseño

El panel izquierdo se siente como **mirar a través del visor de una terminal de hangar**. La Rive del Catbot está «contenida» dentro de un marco técnico: brackets de esquina la enmarcan, una viñeta radial cinematográfica funde sus bordes con el vacío (no la tapa: la integra), y scanlines microscópicas le dan textura de pantalla CRT de instrumentación. La marca aparece abajo a la izquierda con jerarquía clara: tag HUD → título hero con un acento dorado que «emite» → subtítulo de soporte. Todo entra escalonado al cargar, como un sistema que arranca por capas.

El Catbot sigue siguiendo el mouse (eye-tracking intacto). El factor WOW: el personaje se siente **vivo dentro de una máquina cara**, no pegado sobre un fondo negro.

---

## 5. Especificación visual

### 5.1 Proporción del panel

- El `Row` raíz mantiene dos `Expanded`. Cambiar el panel izquierdo a `flex: 58` y el derecho (prompt 23) a `flex: 42`, de modo que el izquierdo ocupe **58 %** del ancho. A 1280 px → ~742 px; a 1024 px (mínimo) → ~594 px. Verificar que la Rive no se recorte de forma incómoda en 1024 px.

### 5.2 Estructura en capas (`Stack`, de atrás hacia adelante)

El panel izquierdo es un `Stack` con `clipBehavior: Clip.hardEdge` y los siguientes `Positioned.fill` (orden = orden de pintado):

1. **Capa fondo — `AppBackground`** (prompt 08): vacío + glow radial ambiental + grid sutil. Variante sin blobs intensos para no competir con la Rive. Esta capa garantiza que aun mientras la Rive carga, el panel tiene profundidad (no negro plano).

2. **Capa Rive — Catbot.** `RiveAnimation.direct(file, artboard: 'Catbot', fit: BoxFit.cover, onInit: _onRiveInit)`. Envolverla en un `Transform.scale(scale: 1.06, alignment: Alignment.center)` para que el zoom evite que el borde de la animación quede expuesto al aplicar la viñeta. Mantener `loading` (spinner `gold`, tamaño 28 px, centrado) y `error` (ícono `broken_image` color `danger`, sin shimmer agresivo: un fade in simple).

3. **Capa viñeta cinematográfica.** Un `Positioned.fill` con un `Container` cuyo `decoration` combina **dos** gradientes mediante un `Stack` de dos contenedores (Flutter no soporta multi-gradiente en un solo `BoxDecoration`):
   - 3a. **Viñeta radial:** `RadialGradient(center: Alignment.center, radius: 1.15, colors: [transparent, transparent, voidBlack@0.85], stops: [0.0, 0.55, 1.0])`. Funde los cuatro bordes de la Rive con el vacío.
   - 3b. **Gradiente inferior de legibilidad:** `LinearGradient(begin: topCenter, end: bottomCenter, colors: [transparent, transparent, voidBlack@0.92], stops: [0.0, 0.45, 1.0])`. Asegura que la marca abajo se lea sobre cualquier frame de la animación.
   Ambos contenedores son `IgnorePointer` para no bloquear el `MouseRegion` del eye-tracking.

4. **Capa scanlines — `HudScanlines`** (prompt 06): overlay no interactivo, `opacity 0.035`, separación 3 px. `IgnorePointer`. Si reduced-motion está activo y las scanlines tienen animación de barrido, se renderizan estáticas.

5. **Capa ornamento — `HudCornerBrackets`** (prompt 06): brackets en las cuatro esquinas del panel, brazo 20 px, grosor 1.5 px, color `borderGold`, con un `Padding` de `space24` respecto del borde físico del panel. Enmarca toda la composición.

6. **Capa marca:** `Positioned(left: space48, bottom: space48)` con la `Column` de branding (§5.3). `right` libre; ancho del subtítulo limitado por `ConstrainedBox`.

### 5.3 Bloque de marca (`Column`, `crossAxisAlignment: start`)

De arriba hacia abajo:

1. **Micro-logo + tag HUD.** Un `Row` (`mainAxisSize: min`, `gap` = `space8`):
   - Micro-logo: glifo de marca vectorial 20×20 px en color `gold` (si no existe asset, usar el ícono de marca definido en prompt 05; nunca emoji ni PNG).
   - `HudIdTag` (prompt 06) con texto `"FACTORY TERMINAL v1.0"`, tipografía `labelSmall` (JetBrains Mono según prompt 06), color de texto `gold`, borde `borderGold` 1 px, fondo `surfaceHud`, padding horizontal `space12` / vertical `space4`, radio `radiusXS`.
2. `SizedBox(height: space20)`.
3. **Título hero.** Texto `"BotLode"` con estilo `AppTextStyles.displayXL` (40 px / 700 / tracking +1.5 / Oxanium), color `textPrimary`. Aplicar un **acento dorado emisor** en la letra/segmento final: renderizar como `RichText` con dos `TextSpan` — `"BotLod"` en `textPrimary` y `"e"` en `gold` con un `Shadow` suave equivalente a `glowGold` (blur 16, color `goldGlow`). El glow es sutil: la letra «emite», no «brilla chillón».
4. `SizedBox(height: space12)`.
5. **Subtítulo.** `ConstrainedBox(maxWidth: 420)` con `Text("Gestión avanzada de flotas autónomas y sistemas de inteligencia artificial conversacional.")`, estilo `AppTextStyles.bodyL` (16 px / 400 / interlineado 1.5 / Oxanium), color `textSecondary`.

### 5.4 Divisor entre paneles

El borde izquierdo del panel derecho (prompt 23) ya no es un `BorderSide` plano: el panel izquierdo aporta una **línea de costura HUD vertical** en su borde derecho — `Positioned(right: 0, top: 0, bottom: 0)` con un `Container` de 1 px de ancho, color `borderGold` al 50 %, con un nodo más brillante (segmento de 40 px en `gold`) centrado verticalmente. Coordinar con prompt 23 para no duplicar la línea.

---

## 6. Estados e interacciones

Aplicar la matriz del archivo 00 §9 en lo que corresponde a este panel (panel mayormente no interactivo, salvo el eye-tracking):

| Estado | Comportamiento |
|---|---|
| `default` | Rive en mood 3.0 (dorado/vendedor, ya seteado en `_onRiveInit`). Catbot mira al centro. |
| `hover` (mouse dentro del panel) | El eye-tracking ya implementado mueve `LookX`/`LookY` (no modificar). Sin cambio de borde ni glow del panel. |
| `loading` (Rive cargando) | `AppBackground` + spinner `gold` centrado 28 px. El bloque de marca puede ya estar visible (no depende de la Rive). |
| `error` (Rive falla) | `AppBackground` + ícono `broken_image` `danger` centrado, fade-in `durBase`. El bloque de marca permanece visible. La app sigue siendo usable porque el formulario está en el panel derecho. |
| `disabled` / `pressed` / `focused` / `selected` | No aplican: el panel no es un control. |

El panel no captura foco de teclado. El orden de tabulación arranca directamente en el campo email del panel derecho.

---

## 7. Animaciones

Todas con tokens de motion (00 §7). Usar `flutter_animate` (ya en el proyecto).

- **Entrada escalonada del bloque de marca** al montar la vista:
  1. `HudIdTag`: `.fadeIn(duration: durBase)` + `.moveY(begin: 10, end: 0)`, curva `easeEntrance`, delay 120 ms.
  2. Título `"BotLode"`: `.fadeIn(duration: durSlow)` + `.moveY(begin: 16, end: 0)`, curva `easeEntrance`, delay 220 ms.
  3. Subtítulo: `.fadeIn(duration: durSlow)` + `.moveY(begin: 12, end: 0)`, curva `easeEntrance`, delay 340 ms.
  Escalonado total ≤ 420 ms (límite `durDeliberate`).
- **Brackets HUD:** fade-in `durBase`, delay 80 ms; sin animación de bucle.
- **Acento dorado del título:** el `Shadow` del span `"e"` puede tener un latido de opacidad muy sutil (`goldGlow` 0.25↔0.40) cada 3200 ms — patrón de shimmer/reactor de 00 §7.3. **Opcional.** Se desactiva con reduced-motion.
- **Reduced motion** (`AppMotion.reduced` / `MediaQuery.disableAnimations`): sin latido del acento, sin barrido de scanlines; la entrada escalonada se reduce a un único crossfade de 120 ms para todo el bloque de marca.
- El eye-tracking del Catbot **no** se considera animación decorativa (es interacción causal): se mantiene siempre, incluso con reduced-motion.

---

## 8. Accesibilidad

- Contraste: `textPrimary` y `textSecondary` se verifican sobre la zona inferior del panel donde el gradiente 3b llega a `voidBlack@0.92` — debe cumplir ≥ 4.5:1 para el subtítulo y ≥ 3:1 para el título. El gradiente inferior existe precisamente para garantizar esto sobre cualquier frame de la Rive.
- El `HudIdTag` comunica versión: texto + borde, no solo color.
- La Rive es decorativa: envolverla en `ExcludeSemantics` o marcarla `Semantics(label: 'Animación de marca BotLode')` sin rol interactivo.
- El estado `error` de la Rive no debe sugerir que la app está rota: el panel derecho sigue operativo. No mostrar texto alarmante.
- El acento dorado emisor nunca es el único portador de significado (es puramente decorativo).
- Foco: el panel no recibe foco; el primer `FocusNode` enfocado al montar es el del email (prompt 23).

---

## 9. Checklist de aceptación

- [ ] El panel izquierdo ocupa `flex: 58` (~58 % del ancho); se ve correcto en 1280×720 y 1024×600.
- [ ] El fondo es `AppBackground` (capas), nunca negro plano; visible incluso mientras la Rive carga.
- [ ] La Rive Catbot se renderiza con `BoxFit.cover` + `Transform.scale(1.06)`; el eye-tracking sigue funcionando (mover el mouse mueve los ojos).
- [ ] Hay una viñeta radial + un gradiente inferior de legibilidad, ambos `IgnorePointer`.
- [ ] `HudScanlines` y `HudCornerBrackets` presentes; brackets con `space24` de margen, brazo 20 px, color `borderGold`.
- [ ] Bloque de marca: `HudIdTag` "FACTORY TERMINAL v1.0", título "BotLode" en `displayXL` con acento dorado emisor en la última letra, subtítulo en `bodyL` `textSecondary` con `maxWidth: 420`.
- [ ] Cero `fontFamily: 'Courier'`, cero hex crudo, cero tamaños mágicos: todo por token.
- [ ] Entrada escalonada (tag → título → subtítulo) con `easeEntrance`, total ≤ 420 ms.
- [ ] Con reduced-motion activo: sin latidos ni barridos; entrada = crossfade 120 ms.
- [ ] Línea de costura HUD vertical en el borde derecho del panel (coordinada con prompt 23, sin duplicar).
- [ ] El subtítulo cumple contraste ≥ 4.5:1 sobre la zona inferior del panel.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores), 02 (tipografía/Oxanium/JetBrains Mono), 03 (dimensiones), 04 (motion), 05 (iconografía — micro-logo de marca), 06 (primitivas HUD: `HudCornerBrackets`, `HudScanlines`, `HudIdTag`), 08 (`AppBackground`).
- **Componentes núcleo:** 07 (glow/glass) para el `Shadow` del acento dorado.
- **Pareja directa:** 23 (panel derecho) — coordinar la proporción `flex` y el divisor entre paneles.
- **Shell:** no aplica (el login se renderiza fuera del `MainLayout` shell).
