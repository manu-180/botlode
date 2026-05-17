# 64 — QA · Motion y Reduced-Motion

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.
> **Este es un prompt de AUDITORÍA.** Verifica que toda la animación de la app cumpla el sistema de motion de §7 y que `AppMotion.reduced` se respete en cada pantalla.

---

## 1. Objetivo

Auditar el sistema de movimiento de toda la aplicación tras los prompts 01–61: que toda animación use tokens de `app_motion.dart`, que las duraciones y curvas estén dentro de los rangos correctos, que el escalonado de listas sea consistente, que ninguna animación bloquee el input ni anime propiedades de layout, y — punto crítico — que el modo `reduced motion` esté respetado en cada pantalla. El movimiento debe tener causa y nunca obstruir; con reduced-motion activo, la app debe quedar silenciosa pero funcional.

---

## 2. Alcance de la auditoría

Toda animación, transición y micro-interacción de las pantallas/modales/overlays del prompt 62 §2. Incluye: transiciones de ruta, entradas de panel/modal, hover/press de todo elemento clickeable, escalonado de grillas y listas, tickers numéricos, shimmer, latidos de reactor, parallax/blobs ambientales del fondo, tilt de la digital card, overlays épicos del bot detail, banners y toasts.

---

## 3. Procedimiento paso a paso

Recorrer cada pantalla y verificar:

### Paso 1 — Tokens de motion
- **Cero `Duration(...)` y cero `Curve`/`Cubic(...)` hardcodeados** en el código de UI. Toda duración sale de los tokens `durInstant`…`durTicker`; toda curva de `easeEntrance`/`easeExit`/`easeStandard`/`springSoft`/`easeTicker`. Buscar restos como `Duration(milliseconds: 200)`, `Curves.easeInOut` suelto, `2000.ms`.

### Paso 2 — Rango de duraciones
- Micro-interacciones (hover, press, cambios de color): ≤ 320 ms (`durInstant`/`durFast`/`durBase`).
- Ninguna animación de UI supera **420 ms** (`durDeliberate`), salvo el conteo de cifras (`durTicker` 900 ms, que es la única excepción permitida).
- Verificar que no haya animaciones lentas tipo 500 ms+ heredadas.

### Paso 3 — Curvas correctas por rol
- Entradas usan ease-out (`easeEntrance`); salidas usan ease-in (`easeExit`).
- La animación de **salida dura ~65 %** de la de entrada (se siente responsiva). Verificar que cada par entrada/salida cumpla esa proporción.
- Transiciones de estado generales: `easeStandard`. Modales/paneles/press de cards: `springSoft`.

### Paso 4 — Escalonado de listas
- Grillas y listas (bot cards, blueprint cards, product cards, invoice list, plan picker) escalonan la entrada **36 ms por ítem**, máximo ~10 ítems escalonados; los demás aparecen sin escalonado. Verificar consistencia del valor en todas las listas.

### Paso 5 — Interrumpibilidad y no bloqueo
- Toda animación es **interrumpible** (un nuevo estado cancela la animación en curso sin glitch) y **nunca bloquea el input** del usuario. Verificar que no haya `await` de animaciones que congelen botones, ni overlays que capturen toques durante una transición.

### Paso 6 — Propiedades animadas
- **Ninguna animación anima `width`, `height`, `top` o `left`.** Solo `transform`/`opacity`/`Transform`/`AnimatedScale`/`AnimatedSlide`/`FractionalTranslation`. Buscar `AnimatedContainer` que interpole tamaño/posición y reemplazar por transform. `AnimatedSize` es aceptable solo para revelar/colapsar contenido (ej. detalle de factura), no para movimiento.

### Paso 7 — Reduced motion (CRÍTICO)
- Confirmar que `app_motion.dart` expone `AppMotion.reduced` leyendo `MediaQuery.disableAnimations` / accesibilidad del SO.
- Recorrer **cada pantalla con reduced-motion activo** y verificar que se desactivan o reducen a un crossfade de 120 ms:
  - **Shimmer** (skeletons, elementos activos, ícono del connectivity HUD).
  - **Latidos / reactor** (`HudReactorBar`, status dots, banners de severidad).
  - **Parallax** y **blobs ambientales** del fondo (`AppBackground`).
  - **Tilt** de la digital card.
  - **Conteo de tickers** (`HudTicker`/`numericTicker`): muestran el valor final directo.
  - **Transiciones de ruta y de modal**: se reducen a crossfade 120 ms (sin slide).
  - **Escalonado de listas**: desaparece (todos los ítems aparecen juntos).
  - **Overlays épicos** del bot detail: reducidos a una aparición simple.
- Verificar que con reduced-motion ninguna información se pierde y nada queda visualmente roto.

Para cada hallazgo: anotar pantalla/archivo/línea, la regla violada, y aplicar la corrección.

---

## 4. Criterios de aprobación

- Cero `Duration`/`Curve` hardcodeados; todo motion por token.
- Todas las duraciones dentro de rango (micro ≤ 320 ms, máximo 420 ms salvo `durTicker`).
- Curvas correctas por rol; salida ≈ 65 % de la entrada.
- Escalonado de listas consistente (36 ms/ítem, máx ~10).
- Toda animación interrumpible y sin bloquear input.
- Ninguna animación de `width`/`height`/`top`/`left`.
- `AppMotion.reduced` respetado en cada pantalla: shimmer, latidos, parallax, blobs, tilt y tickers desactivados o reducidos a crossfade 120 ms.

---

## 5. Checklist

- [ ] Paso 1 — cero `Duration`/`Curve` hardcodeados.
- [ ] Paso 2 — duraciones dentro de rango.
- [ ] Paso 3 — curvas correctas; salida ≈ 65 % de la entrada.
- [ ] Paso 4 — escalonado de listas consistente.
- [ ] Paso 5 — animaciones interrumpibles y sin bloqueo de input.
- [ ] Paso 6 — sin animar `width`/`height`/`top`/`left`.
- [ ] Paso 7 — reduced-motion verificado pantalla por pantalla: shimmer, latidos, parallax, blobs, tilt, tickers, transiciones y escalonado desactivados/reducidos.
- [ ] Con reduced-motion no se pierde información ni se rompe el layout.
- [ ] `flutter analyze` sin warnings nuevos tras las correcciones.

---

## 6. Entregable

Un informe con:

1. **Lista de violaciones** — tabla: Pantalla/Componente · Archivo:línea · Categoría (token/duración/curva/escalonado/bloqueo/propiedad-animada/reduced-motion) · Descripción.
2. **Fixes aplicados** — por violación, el cambio realizado (valor suelto → token, propiedad de layout → transform, branch de reduced-motion agregado).
3. **Confirmación de reduced-motion** — listado por pantalla confirmando que cada efecto (shimmer/latido/parallax/blob/tilt/ticker) se desactiva o degrada correctamente.

La auditoría no se aprueba hasta que la lista de violaciones esté vacía o documentada como deuda justificada.

---

## 7. Dependencias

- **Todos los prompts 01–61** ejecutados.
- Referencia: 04 (`app_motion.dart` — curvas, duraciones, `AppMotion.reduced`), 08 (fondo con parallax/blobs), 14 (skeletons/shimmer), 48 (digital card con tilt), 06 (HUD: reactor bar, ticker), 09–17 (micro-interacciones de componentes núcleo), 20 (transiciones de ruta).
