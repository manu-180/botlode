# 00 — README · Visión, Sistema de Diseño Maestro e Índice

> **Documento canónico.** Todos los prompts numerados (01–65) de esta carpeta dependen de este archivo.
> Antes de ejecutar CUALQUIER prompt, el modelo ejecutor **debe leer este archivo completo**.
> Aquí viven los tokens, las reglas y el vocabulario visual. Los prompts individuales **no repiten** los valores: los referencian por nombre de token. Si un prompt y este archivo se contradicen, **gana este archivo**.

---

## 1. Para quién es este plan

Este plan lo va a ejecutar un modelo (Claude Sonnet) que **no tiene skills de diseño**. Por eso cada prompt es extremadamente descriptivo: dice exactamente qué medidas, qué colores (por token), qué curvas de animación, qué estados y qué checklist de aceptación. El ejecutor debe seguir el prompt al pie de la letra y, ante una duda visual, volver a este archivo 00.

**Regla de oro para el ejecutor:** no inventes valores estéticos. Todo color, espaciado, radio, sombra, glow, duración y curva tiene un token definido acá. Si necesitás un valor que no existe, **primero agregalo como token** en el archivo de tokens correspondiente y después usalo.

---

## 2. El proyecto

**botslode** es una app **Flutter de escritorio** (Windows, con `window_manager`, barra de título oculta, mínimo 1024×600, arranque 1280×720). Nombre de producto: **«BotLode Factory Terminal»**. Es un panel para crear y gestionar chatbots, ver deuda y ciclos de facturación, probar un chat contra un backend, una tienda/plantillas y flujos de cobro con tarjeta.

Stack: Flutter + Material 3, `flutter_riverpod` + `riverpod_generator`, `go_router`, `supabase_flutter`, `rive`, `lottie`, `flutter_animate`, `fl_chart`, `google_fonts`, fuente variable **Oxanium**.

**Tema:** oscuro único. No hay light mode y no se va a agregar. Todo el sistema asume fondo oscuro.

---

## 3. La visión: «Hangar OS»

El objetivo es llevar la app a un nivel **premium, ultra profesional, factor WOW**. La identidad actual ya es buena (cyberpunk industrial dorado); este plan **la eleva**, no la reemplaza. La metáfora rectora es un **sistema operativo de hangar de naves**: el usuario es un operario que ensambla, monitorea y despacha «unidades autónomas» (los bots) desde una terminal industrial de alta gama.

Tres referencias visuales que el ejecutor debe tener en mente:

1. **HUD / FUI de ciencia ficción** (interfaces de cine sci-fi): brackets de esquina, líneas finas, lecturas de datos, tickers numéricos, marcadores técnicos, escaneos.
2. **Cyberpunk industrial premium**: oro industrial sobre vacío profundo, vidrio esmerilado, cantos biselados (chamfer 45°), scanlines sutilísimas, reactores que laten.
3. **Dark cinematográfico premium** (apps pro modernas tipo Linear/Arc): profundidad por capas, glows ambientales suaves, glassmorphism con bordes hairline, física de resorte en el movimiento, jamás negro plano.

El resultado debe sentirse **caro, preciso, vivo y silencioso**. Nada chillón, nada de glitch agresivo, nada de neón saturado. El lujo está en la **precisión, la profundidad y la coherencia milimétrica**, no en el ruido.

### 3.1 Principios de diseño (no negociables)

1. **Profundidad siempre.** Ningún fondo plano. El fondo de cada pantalla es un sistema de capas: vacío base + glow radial ambiental + textura/grid sutil. Las superficies flotan sobre el fondo con elevación clara.
2. **El oro se gana.** `#FFC000` es la marca y se reserva para: acción primaria, valor/dinero, estado destacado y branding. Si todo es dorado, nada lo es. La mayoría de la UI vive en grises técnicos; el oro es el acento que el ojo persigue.
3. **La luz tiene fuente.** Los glows no son decoración: indican energía, foco o estado. Un botón primario «emite»; una unidad offline «no emite».
4. **El movimiento tiene causa.** Cada animación comunica una relación causa-efecto. Nada se mueve «porque queda lindo». Curvas de resorte/ease-out, 150–320 ms, escalonado en listas.
5. **Densidad con aire.** Es una herramienta densa en datos, pero cada bloque respira. Ritmo de espaciado estricto de 4 px.
6. **Coherencia milimétrica.** Mismo radio, mismo grosor de borde, mismo set de iconos, mismas curvas en toda la app. La inconsistencia mata el factor premium más rápido que cualquier otra cosa.
7. **Ornamento HUD con criterio.** Brackets de esquina, scanlines y tickers se usan en momentos jerárquicos (paneles principales, modales, encabezados), no en cada caja. El ornamento subraya la jerarquía; no la diluye.

### 3.2 Anti-patrones (prohibido)

- Fondos planos de un solo color.
- Emojis como iconos. Solo iconos vectoriales (Lucide / Font Awesome ya presente), grosor de trazo coherente.
- Glow/neón saturado o glitch agresivo (skew, salto de píxeles llamativo). El glitch, si se usa, es microscópico y raro.
- Oro en todos lados. Oro como color de texto de párrafo. Oro en bordes de cajas secundarias.
- Sombras inventadas: solo la escala de elevación definida.
- Animaciones que bloquean input, que duran >500 ms, o que mueven `width`/`height`/`top`/`left` (usar `transform`/`opacity`/`Transform`/`AnimatedScale`).
- PNG donde puede haber vector. Bordes que desaparecen. Texto gris sobre gris.
- Romper la estructura de navegación shell (sidebar + title bar) entre pantallas.

---

## 4. Tokens de color (paleta maestra)

La app ya tiene `lib/core/config/theme/app_colors.dart`. El prompt 01 lo reescribe y **extiende**. Esta es la paleta canónica final. Todos los valores son ARGB sobre tema oscuro.

### 4.1 Capas de fondo (profundidad)

| Token | Hex | Uso |
|---|---|---|
| `voidBlack` | `#03070C` | Capa más profunda del fondo, viñeta de bordes. |
| `background` | `#050A10` | Fondo base de la app (ya existe). |
| `bgElevated01` | `#0A111A` | Primer nivel de elevación (zonas de contenido). |
| `surface` | `#0F1621` | Superficie de paneles/cards (ya existe). |
| `surfaceRaised` | `#141D2B` | Cards en hover, modales, popovers. |
| `surfaceHud` | `#0C1118` | Fondo de lecturas HUD/terminal. |

### 4.2 Vidrio (glassmorphism)

| Token | Valor | Uso |
|---|---|---|
| `glassSurface` | `rgba(20,30,45,0.55)` | Relleno de panel de vidrio (con blur). |
| `glassSurfaceStrong` | `rgba(24,34,50,0.72)` | Vidrio de modales (más opaco para legibilidad). |
| `glassHighlightTop` | `rgba(255,255,255,0.06)` | Highlight de 1 px en el borde superior del vidrio. |
| `glassBorder` | `rgba(255,255,255,0.10)` | Borde hairline estándar de vidrio (ya existe). |
| `scrim` | `rgba(3,6,11,0.66)` | Velo de fondo detrás de modales (66 %). |

### 4.3 Marca / acentos

| Token | Hex | Uso |
|---|---|---|
| `gold` (`primary`) | `#FFC000` | Acción primaria, valor/dinero, branding. Oro industrial. |
| `goldBright` | `#FFD740` | Punta de gradiente, highlight, hover del oro. |
| `goldDeep` | `#C8930A` | Sombra/base de gradiente del oro, estados pressed. |
| `goldGlow` | `rgba(255,192,0,0.35)` | Glow del oro. |
| `cyan` (`secondary`) | `#00F0FF` | Acento técnico/datos, estado «procesando», líneas HUD. |
| `cyanGlow` | `rgba(0,240,255,0.30)` | Glow del cyan. |
| `accentMagenta` | `#FF2FD4` | Acento de mood «happy» del bot (ajuste de `#FF00D6` para contraste). |
| `accentViolet` | `#9B5CFF` | Acento de mood «confused» del bot (ajuste de `#7B00FF` para contraste). |

> Los moods del bot usan acentos: online→`success`, angry→`danger`, happy→`accentMagenta`, vendor→`gold`, confused→`accentViolet`, tech→`cyan`. Cada uno tiene su glow vía `glowStatus(color)`.

### 4.4 Estados semánticos

| Token | Hex | Uso |
|---|---|---|
| `success` | `#00FF94` | Activo, online, positivo. |
| `successGlow` | `rgba(0,255,148,0.28)` | Glow de éxito. |
| `warning` | `#FF9D2E` | Mantenimiento, suspendido, vence pronto. |
| `warningGlow` | `rgba(255,157,46,0.28)` | Glow de advertencia. |
| `danger` (`error`) | `#FF2D55` | Crítico, error, offline, destructivo. (Ajuste de `#FF003C` para mejor contraste.) |
| `dangerGlow` | `rgba(255,45,85,0.30)` | Glow de error. |
| `info` | `#3B9DFF` | Informativo neutro (banners de trial, ayuda). |

### 4.5 Texto y bordes

| Token | Hex / Valor | Uso |
|---|---|---|
| `textPrimary` | `#EAF0F7` | Texto principal. Contraste ≥ 12:1 sobre `surface`. |
| `textSecondary` | `#9FB0C3` | Texto secundario/labels. Contraste ≥ 4.5:1. |
| `textTertiary` | `#5E6E82` | Texto deshabilitado, metadatos, hints. ≥ 3:1. |
| `textOnGold` | `#0A0A0A` | Texto sobre superficies doradas. |
| `borderSubtle` | `rgba(255,255,255,0.06)` | Divisores internos muy sutiles. |
| `borderDefault` | `rgba(255,255,255,0.10)` | Borde estándar de cajas. |
| `borderStrong` | `rgba(255,255,255,0.16)` | Borde de hover/foco neutro. |
| `borderGold` | `rgba(255,192,0,0.32)` | Borde con tinte dorado para énfasis. |

### 4.6 Gradientes

| Token | Definición |
|---|---|
| `gradGold` | Linear 135°: `goldBright #FFD740` → `gold #FFC000` → `goldDeep #C8930A`. |
| `gradGoldSheen` | Linear usado para barridos de shimmer: transparente → `rgba(255,255,255,0.4)` → transparente. |
| `gradPanel` | Linear 160°: `surfaceRaised` → `surface`. Relleno sutil de paneles. |
| `gradVoid` | Radial: centro `bgElevated01` (al 80 %) → bordes `voidBlack`. Fondo de pantalla. |
| `gradCyanData` | Linear: `cyan` → `rgba(0,240,255,0.0)`. Para barras/charts de datos. |

**Regla de contraste:** todo par texto/fondo se verifica a ≥ 4.5:1 (texto normal) y ≥ 3:1 (texto grande / glifos de UI). El color nunca es el único portador de información: estado siempre lleva ícono + texto además de color.

---

## 5. Sistema tipográfico

**Familia display/UI:** **Oxanium** (variable, ya en `assets/fonts/`). Es la voz de la marca. Headings, labels, botones, navegación.

**Familia mono/datos:** se agrega **JetBrains Mono** (vía `google_fonts`). Es para lecturas HUD, números tabulares, IDs, código, timestamps, terminal de chat. Da el toque «terminal de instrumentación». El prompt 02 la incorpora.

### 5.1 Escala de texto (tokens en `AppTheme`/`AppTextStyles`)

| Token | Tamaño | Peso | Tracking | Familia | Uso |
|---|---|---|---|---|---|
| `displayXL` | 40 | 700 | +1.5 | Oxanium | Título hero (login). |
| `displayL` | 32 | 700 | +1.2 | Oxanium | Título de pantalla grande. |
| `displayM` | 26 | 700 | +1.0 | Oxanium | Títulos de sección. |
| `titleL` | 21 | 600 | +0.8 | Oxanium | Títulos de panel/modal. |
| `titleM` | 17 | 600 | +0.5 | Oxanium | Subtítulos, títulos de card. |
| `label` | 13 | 600 | +1.4 (UPPERCASE) | Oxanium | Labels de UI, tabs, botones, navegación. |
| `labelSmall` | 11 | 600 | +1.6 (UPPERCASE) | Oxanium | Micro-labels, badges. |
| `bodyL` | 16 | 400 | 0 | Oxanium | Texto de lectura largo. |
| `bodyM` | 14 | 400 | 0 | Oxanium | Texto estándar. |
| `bodyS` | 12.5 | 400 | 0 | Oxanium | Texto secundario. |
| `hudReadout` | 13 | 500 | +0.5 | JetBrains Mono | Lecturas de datos, valores HUD. |
| `mono` | 12 | 400 | 0 | JetBrains Mono | IDs, código, timestamps, terminal. |
| `numericTicker` | 28 | 700 | +0.5 | JetBrains Mono · **tabular figures** | Cifras grandes animadas (crédito, precios). |

**Reglas:** interlineado 1.5 para body, 1.2 para titulares. Todo número que se anima o se alinea en columna usa **figuras tabulares** (`fontFeatures: [FontFeature.tabularFigures()]`) para evitar saltos de layout. `font-display` no aplica (app nativa), pero la fuente mono se precarga al arranque.

---

## 6. Espaciado, radios, chaflán, elevación, z-index

El prompt 03 crea `lib/core/config/theme/app_dimens.dart` con estos tokens.

### 6.1 Espaciado — escala base 4 px

`space2=2`, `space4=4`, `space8=8`, `space12=12`, `space16=16`, `space20=20`, `space24=24`, `space32=32`, `space40=40`, `space48=48`, `space64=64`.

- Padding interno de cards: `space20` o `space24`.
- Gap entre cards en grilla: `space20`.
- Padding de pantalla (desktop): `space32` horizontal.
- Gaps de jerarquía de sección: 16 / 24 / 32 / 48.

### 6.2 Radios

`radiusXS=6`, `radiusS=10`, `radiusM=14`, `radiusL=20`, `radiusXL=28`, `radiusPill=999`.

- Inputs y botones: `radiusM`.
- Cards/paneles: `radiusL`.
- Modales: `radiusXL`.
- Badges/chips: `radiusPill`.

### 6.3 Chaflán HUD (chamfer)

Cantos biselados a 45° para momentos «hardware/instrumento»: paneles HUD principales, botones primarios destacados, marcos de tabs. Token `chamferM=12` (recorte de esquina). Se aplica con un `ShapeBorder`/`ClipPath` definido en el prompt 06. **No** se usa en todas las cajas: el chaflán es para acentos jerárquicos; el resto usa radios redondeados.

### 6.4 Escala de elevación (sombras)

Las sombras se combinan con un glow opcional. Tokens en `app_dimens.dart`:

| Token | Sombra | Uso |
|---|---|---|
| `elev0` | ninguna | Elementos pegados al fondo. |
| `elev1` | `0 2 8 rgba(0,0,0,0.4)` | Cards en reposo. |
| `elev2` | `0 8 24 rgba(0,0,0,0.5)` | Cards en hover, dropdowns. |
| `elev3` | `0 16 48 rgba(0,0,0,0.6)` | Modales, popovers. |
| `glowGold` | `0 0 24 goldGlow` (blur 24, spread 1) | Emisión de elementos dorados activos. |
| `glowCyan` | `0 0 20 cyanGlow` | Emisión cyan (datos/proceso). |
| `glowStatus(color)` | `0 0 18 color@0.28` | Glow genérico de estado. |

**Regla:** un elemento usa **una** sombra de elevación + **opcionalmente un** glow. Nunca dos glows. Nunca sombras fuera de la escala.

### 6.5 Escala de z-index / capas

`zBase=0`, `zContent=10`, `zSticky=20` (toolbars sticky), `zSidebar=30`, `zTitleBar=40`, `zOverlay=100` (scrims), `zModal=110`, `zToast=200`, `zEpicNotification=300`. El ejecutor no usa valores arbitrarios.

---

## 7. Sistema de motion

El prompt 04 crea `lib/core/config/theme/app_motion.dart` con curvas y duraciones. Flutter: las curvas son `Cubic`/`Curves`, las duraciones `Duration`.

### 7.1 Duraciones

| Token | Valor | Uso |
|---|---|---|
| `durInstant` | 90 ms | Cambios de color en hover/press. |
| `durFast` | 160 ms | Micro-interacciones, hover de card. |
| `durBase` | 240 ms | Transiciones estándar (paneles, tabs). |
| `durSlow` | 320 ms | Entradas de modal, transiciones de pantalla. |
| `durDeliberate` | 420 ms | Reveals escénicos (no superar nunca esto en UI). |
| `durTicker` | 900 ms | Conteo de cifras numéricas. |

**Regla:** la animación de salida dura ~65 % de la de entrada (se siente responsiva). Las animaciones son interrumpibles y nunca bloquean el input.

### 7.2 Curvas

| Token | Definición | Uso |
|---|---|---|
| `easeEntrance` | `Cubic(0.16, 1.0, 0.3, 1.0)` | Entradas (el «expo-out» premium). |
| `easeExit` | `Cubic(0.4, 0.0, 1.0, 1.0)` | Salidas. |
| `easeStandard` | `Curves.easeInOutCubic` | Transiciones de estado generales. |
| `springSoft` | `SpringDescription(mass:1, stiffness:90, damping:20)` | Modales, paneles, press de cards. |
| `easeTicker` | `Curves.easeOutExpo` | Conteo de cifras. |

### 7.3 Patrones de motion

- **Escalonado de listas/grillas:** cada ítem entra 36 ms después del anterior (fade + translateY 12 px), máximo ~10 ítems escalonados.
- **Press de elementos táctiles/clickeables:** escala a 0.97 con `durInstant`, vuelve a 1.0 al soltar.
- **Hover (desktop):** elevación + borde + glow suben con `durFast`.
- **Shimmer:** barrido de `gradGoldSheen` cada 2800–3400 ms en elementos activos clave (no en todos).
- **Reactor / latido:** barras de estado «laten» con un pulso de opacidad 0.6↔1.0 a ~1600 ms, solo en estado activo.
- **Transición de pantalla (go_router):** fade + slide direccional de 16 px. Avanzar = entra desde la derecha/abajo; volver = inverso.
- **Reduced motion:** el prompt 04 expone `AppMotion.reduced` (lee `MediaQuery.disableAnimations` / accesibilidad del SO). Cuando está activo: sin shimmer, sin latidos, sin parallax; las transiciones se reducen a un crossfade de 120 ms. Cada prompt que anima debe respetar esto.

---

## 8. Vocabulario de ornamento HUD

El prompt 06 crea estas primitivas reutilizables en `lib/core/ui/hud/`. El resto de prompts las consume.

1. **Corner brackets (`HudCornerBrackets`)** — cuatro «escuadras» de líneas finas (1.5 px) en las esquinas de un panel. Largo de brazo 16–22 px. Color configurable (default `borderGold`). Marca jerarquía: solo en paneles principales, modales y el panel de crédito.
2. **Scanline overlay (`HudScanlines`)** — overlay no interactivo de líneas horizontales a `opacity 0.035`, separación 3 px. Sutilísimo. Opcional por panel. Se desactiva con reduced-motion si se anima.
3. **Chamfer shape (`ChamferBorder` / `ChamferClipper`)** — `ShapeBorder` con esquinas biseladas a 45° (`chamferM`). Para paneles HUD y botones destacados.
4. **Reactor bar (`HudReactorBar`)** — barra vertu/horizontal fina que «late» con glow; indica energía/estado. Ya existe una versión en `status_indicator.dart`; se generaliza.
5. **Tech divider (`HudDivider`)** — divisor horizontal: línea hairline con un nodo/segmento más brillante y, opcionalmente, una etiqueta mono centrada (ej. `// SISTEMA`).
6. **Data ticker (`HudTicker`)** — texto numérico mono con figuras tabulares que cuenta hacia su valor. Generaliza el `AnimatedTicker` existente.
7. **Status dot (`HudStatusDot`)** — punto de estado con halo de glow pulsante (online/suspendido/offline + procesando).
8. **Grid texture (`HudGridTexture`)** — `CustomPainter` de retícula técnica muy tenue (`opacity 0.04`) para fondos de panel.
9. **Corner ID tag (`HudIdTag`)** — etiqueta mono pequeña tipo `UNIT-04F` para esquinas de cards.

Estas primitivas son el «idioma» visual. El ejecutor las usa; no reinventa cada ornamento.

---

## 9. Matriz de estados de componentes

Todo componente interactivo define explícitamente sus estados. El ejecutor nunca entrega un componente sin todos los estados aplicables.

| Estado | Qué cambia |
|---|---|
| `default` | Reposo. |
| `hover` (desktop) | +Borde (`borderStrong`/`borderGold`), +elevación 1 nivel, glow suave aparece, cursor pointer. `durFast`. |
| `pressed` | Escala 0.97, color de relleno un paso más profundo. `durInstant`. |
| `focused` | Anillo de foco visible de 2 px (`cyan` o `gold` según contexto) — nunca se elimina sin reemplazo. |
| `selected/active` | Relleno o borde de acento, glow estable, label más brillante. |
| `loading` | Spinner/skeleton; el elemento se deshabilita; nada de doble submit. |
| `disabled` | Opacidad 0.4, sin glow, cursor por defecto, no interactivo, semánticamente disabled. |
| `error` | Borde `danger`, ícono de error, mensaje con `role: alert` (semántica de Flutter `liveRegion`). |
| `empty` | Estado vacío con ícono, mensaje útil y acción sugerida. |

---

## 10. Reglas de accesibilidad (obligatorias en cada prompt)

- Contraste texto ≥ 4.5:1; glifos/iconos de UI ≥ 3:1. Verificar cada par.
- Foco visible siempre; orden de foco coincide con el orden visual.
- Todo botón solo-ícono lleva `Semantics`/`tooltip` con label descriptivo.
- El estado nunca se comunica solo por color: siempre color + ícono + texto.
- Respetar `MediaQuery.disableAnimations` (reduced motion) — ver §7.3.
- Targets clickeables cómodos (es desktop con mouse, pero mínimo 32×32 px de área de hit; 44×44 si hay versión táctil).
- Modales y flujos multi-paso: siempre una salida clara (cerrar/cancelar/volver). Confirmar antes de acciones destructivas. Confirmar antes de descartar un modal con cambios sin guardar.
- Errores de formulario: mensaje cerca del campo + foco automático al primer campo inválido.

---

## 11. Estructura de cada prompt (template que el ejecutor verá)

Cada archivo 01–65 sigue esta estructura. El ejecutor la lee de arriba a abajo:

1. **Objetivo** — qué se rediseña y por qué, en 2–3 líneas.
2. **Archivos** — rutas exactas a crear/modificar.
3. **Estado actual** — cómo se ve hoy ese componente.
4. **Visión del rediseño** — el resultado deseado, factor WOW explicado.
5. **Especificación visual** — layout, medidas exactas, tokens de color, tipografía, ornamentos HUD, capa por capa.
6. **Estados e interacciones** — la matriz de §9 aplicada a este componente.
7. **Animaciones** — entradas, micro-interacciones, curvas y duraciones por token.
8. **Accesibilidad** — los puntos de §10 aplicables.
9. **Checklist de aceptación** — lista verificable; el componente no está «listo» hasta cumplirla.
10. **Dependencias** — qué prompts deben estar hechos antes.

---

## 12. Orden de ejecución

Los prompts están numerados en **orden de dependencia**. Se ejecutan en secuencia 01 → 65. Las fases:

- **Fase A · Fundaciones (01–08):** tokens y primitivas. Nada visual «de pantalla» todavía, pero todo lo demás depende de esto. **No saltear.**
- **Fase B · Componentes núcleo (09–17):** botones, inputs, badges, paneles, tooltips, skeletons, estados vacío/error, toasts. Librería de UI reutilizable.
- **Fase C · Shell y navegación (18–21):** title bar, sidebar, layout, page titles.
- **Fase D · Dashboard (22–29):** login + bahía de carga + bot card.
- **Fase E · Bot detail y chat (30–40):** detalle de unidad, tabs, consola de chat.
- **Fase F · Biblioteca, tienda, ajustes (41–46).**
- **Fase G · Billing (47–60):** todo el área de facturación.
- **Fase H · Cierre y QA (61–65):** conectividad + auditorías de consistencia, accesibilidad, motion y pulido final.

Tras cada fase conviene correr `flutter analyze` y compilar (`flutter run -d windows`) para validar visualmente. Tras tocar providers anotados, `dart run build_runner build --delete-conflicting-outputs`.

---

## 13. Índice completo de prompts

| # | Archivo | Alcance |
|---|---|---|
| 00 | README · Visión y sistema de diseño | Este documento. |
| **Fase A — Fundaciones** | | |
| 01 | Tokens de color | Reescribe `app_colors.dart` con la paleta §4. |
| 02 | Sistema tipográfico + fuente mono | `app_theme.dart`, JetBrains Mono, escala §5. |
| 03 | Tokens de dimensión | `app_dimens.dart`: espaciado, radios, chaflán, elevación, z-index. |
| 04 | Sistema de motion | `app_motion.dart`: curvas, duraciones, reduced-motion. |
| 05 | Sistema de iconografía | Set unificado, tamaños, helper de iconos. |
| 06 | Primitivas HUD | `lib/core/ui/hud/`: brackets, scanlines, chamfer, reactor, divisor, ticker, grid. |
| 07 | Primitivas de glow y glass | Decoraciones reutilizables (`GlassDecoration`, `GlowBox`). |
| 08 | Fondo de aplicación / capa ambiental | `AppBackground`: void + glow radial + grid + blobs. |
| **Fase B — Componentes núcleo** | | |
| 09 | Botones | Primario, secundario, peligro, ghost, icon button. |
| 10 | Inputs y campos de formulario | Text field, password, search, validación. |
| 11 | Badges, chips y status tags | Pills, contadores, etiquetas de estado. |
| 12 | Panel/Card base (`HoloPanel`) | Contenedor de vidrio reutilizable. |
| 13 | Tooltips y popovers | Tooltip HUD, menús contextuales. |
| 14 | Skeletons y estados de carga | `SkeletonBase` premium, shimmer. |
| 15 | Estados vacíos | Patrón unificado de empty state. |
| 16 | Estados de error | `ErrorFeedbackCard` + patrón global. |
| 17 | Toasts y overlay de notificaciones | Snackbars HUD, sistema de toasts. |
| **Fase C — Shell y navegación** | | |
| 18 | Custom title bar | Barra de título de ventana. |
| 19 | Sidebar de navegación | Barra lateral, ítems, estado activo. |
| 20 | MainLayout shell + transiciones | Scaffold de shell, transiciones de ruta. |
| 21 | PageTitle | Los 3 estilos de encabezado de página. |
| **Fase D — Dashboard** | | |
| 22 | Login · panel izquierdo | Branding + Rive. |
| 23 | Login · panel derecho | Formulario de identificación. |
| 24 | Dashboard · layout y fondo | «Bahía de Carga». |
| 25 | Dashboard · panel HUD de crédito | Lectura de crédito sci-fi. |
| 26 | Dashboard · botón de acción inteligente | CTA mutante según estado de crédito. |
| 27 | Dashboard · toolbar | Búsqueda + tabs de filtro. |
| 28 | Bot card | Ítem de grilla de unidades. |
| 29 | Dashboard · estados vacío y carga | Grilla vacía / skeleton. |
| **Fase E — Bot detail y chat** | | |
| 30 | Bot detail · layout + tabs | Estructura general y sistema de tabs. |
| 31 | Bot detail · RiveBotDisplay + HUD de estado | Marco del avatar y lecturas. |
| 32 | Bot detail · tab Dashboard | Métricas de la unidad. |
| 33 | Bot detail · tab Config | Formulario de configuración. |
| 34 | Bot detail · tab Knowledge | Base de conocimiento. |
| 35 | Bot detail · tab Mood | Selector de personalidad/mood. |
| 36 | Bot detail · tab Embed | Código de inserción. |
| 37 | Bot detail · acciones flotantes + overlays épicos | FABs y notificaciones terminal. |
| 38 | Chat console · panel terminal | Consola de chat de prueba. |
| 39 | Chat · burbujas de mensaje | Mensajes usuario/bot. |
| 40 | Chat · status indicator | Indicador de estado del chat. |
| **Fase F — Biblioteca, tienda, ajustes** | | |
| 41 | Bots library view | «Biblioteca de Planos». |
| 42 | Blueprint card | Ítem de plantilla/plano. |
| 43 | Store view | Tienda. |
| 44 | Product card | Ítem de producto. |
| 45 | Settings view | «Protocolo de Seguridad». |
| 46 | Change password dialog | Diálogo de cambio de contraseña. |
| **Fase G — Billing** | | |
| 47 | Billing · shell + tab bar | Estructura de 4 tabs. |
| 48 | Billing · digital card | Tarjeta digital (4 estados). |
| 49 | Billing · plan picker | Selector de planes. |
| 50 | Billing · subscription summary card | Resumen de suscripción. |
| 51 | Billing · add card modal | Modal de alta de tarjeta. |
| 52 | Billing · formularios de pasarela | Stripe Elements / MercadoPago Brick. |
| 53 | Billing · manage cards modal | Gestión de métodos. |
| 54 | Billing · payment checkout modal | Modal de checkout. |
| 55 | Billing · quota paywall modal | Paywall por cuota. |
| 56 | Billing · proration preview modal | Previsualización de prorrateo. |
| 57 | Billing · cancel flow + reactivate flow | Cancelación y reactivación. |
| 58 | Billing · auto-pay settings card | Tarjeta de autopago. |
| 59 | Billing · invoice list | Lista de facturas. |
| 60 | Billing · trial countdown + dunning banners | Banners de trial y mora. |
| **Fase H — Cierre y QA** | | |
| 61 | Connectivity HUD | Snackbars de estado de conexión. |
| 62 | QA · consistencia cross-screen | Auditoría de coherencia. |
| 63 | QA · accesibilidad y contraste | Auditoría WCAG. |
| 64 | QA · motion y reduced-motion | Auditoría de animaciones. |
| 65 | QA · pase final de pulido WOW | Barrido final de glows, profundidad y micro-interacciones. |

---

## 14. Definición de «listo» (Definition of Done global)

Un prompt está terminado cuando:

- Todos los archivos listados fueron modificados/creados.
- El componente usa **solo tokens** de este documento (cero hex sueltos, cero magic numbers de espaciado).
- Todos los estados aplicables de §9 están implementados.
- Las animaciones usan tokens de §7 y respetan reduced-motion.
- Cumple las reglas de accesibilidad de §10.
- El checklist de aceptación del prompt está 100 % verde.
- `flutter analyze` no agrega warnings nuevos.
- La app compila y la pantalla se ve correctamente en 1280×720 y en el mínimo 1024×600.

El factor WOW no es opcional: si una pantalla se ve «correcta pero plana», no está lista. Profundidad, glow con propósito, movimiento con causa y coherencia milimétrica son requisitos, no extras.
