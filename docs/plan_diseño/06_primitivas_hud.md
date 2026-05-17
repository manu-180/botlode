# 06 — Primitivas HUD

> Prompt de la **Fase A · Fundaciones**. Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md` y de los prompts **01–05**.
> Lee el archivo 00 completo. Implementa el vocabulario de ornamento de **§8**.

---

## 1. Objetivo

Crear la carpeta `lib/core/ui/hud/` con las **9 primitivas HUD** de §8 del archivo 00. Son el «idioma visual» de toda la app: brackets de esquina, scanlines, chaflán, barra de reactor, divisor técnico, ticker de datos, status dot, textura de grilla y etiqueta de ID. Cada prompt de pantalla (09–65) las consume; ninguno reinventa un ornamento.

---

## 2. Archivos

- **Crear:** `lib/core/ui/hud/hud_corner_brackets.dart`, `hud_scanlines.dart`, `chamfer_border.dart`, `hud_reactor_bar.dart`, `hud_divider.dart`, `hud_ticker.dart`, `hud_status_dot.dart`, `hud_grid_texture.dart`, `hud_id_tag.dart`.
- **Crear (opcional):** `lib/core/ui/hud/hud.dart` — barrel file que re-exporta las 9 primitivas.
- **Referencia:** `lib/core/ui/widgets/animated_ticker.dart` (se generaliza en `HudTicker`; el archivo viejo puede quedar como alias deprecado).

Todas importan `app_colors.dart`, `app_dimens.dart`, `app_motion.dart` según necesiten. Cabecera `// Archivo: ...` en cada uno.

---

## 3. Estado actual

No existe `lib/core/ui/hud/`. Hoy solo hay un `AnimatedTicker` básico (`Duration(seconds:2)` + `easeOutExpo` hardcodeados, sin figuras tabulares, sin prefijo de signo) y un `SkeletonBase`. No hay brackets, ni scanlines, ni chamfer, ni status dot, ni grid. Los ornamentos sci-fi que pide la visión «Hangar OS» no tienen primitivas reutilizables: si no se crean acá, cada pantalla los improvisaría con inconsistencia.

---

## 4. Visión del rediseño

Nueve widgets/utilidades pequeños, puros y reutilizables. Cada uno hace **una** cosa, recibe parámetros tokenizados, y se compone encima de los paneles. El ejecutor de un prompt de pantalla escribe `HudCornerBrackets(child: panel)` o `HudStatusDot(status: BotStatus.online)` y obtiene el ornamento correcto sin pensar en píxeles. Las primitivas son sobrias: el lujo está en la precisión (líneas de 1.5 px exactas, opacidades de §8), no en el ruido.

---

## 5. Especificación visual

Para cada primitiva: API, medidas exactas, colores por token, animación, cuándo usar / cuándo NO.

### 5.1 `HudCornerBrackets`

- **Qué es:** cuatro «escuadras» en las esquinas de un panel.
- **API:** `HudCornerBrackets({required Widget child, double armLength = 20, double thickness = 1.5, Color color = AppColors.borderGold, double inset = 0, bool topLeft/topRight/bottomLeft/bottomRight = true})`.
- **Implementación:** `Stack` con el `child` debajo y un `CustomPaint` (`IgnorePointer`) encima que dibuja las 4 escuadras. Cada escuadra = 2 segmentos perpendiculares de `armLength` px (16–22; default 20), grosor `thickness` 1.5 px, color `borderGold` por defecto.
- **Medidas:** brazos de 16–22 px; `inset` separa la escuadra del borde del panel.
- **Cuándo:** paneles principales, modales, panel de crédito, encabezados jerárquicos.
- **Cuándo NO:** cards secundarias, chips, inputs, cada caja. Diluye la jerarquía (§3.1.7).

### 5.2 `HudScanlines`

- **Qué es:** overlay no interactivo de líneas horizontales finas.
- **API:** `HudScanlines({double opacity = 0.035, double gap = 3, bool animate = false})`. Pensado para ir dentro de un `Stack` como capa superior, o como `child` envuelto.
- **Implementación:** `IgnorePointer` + `CustomPaint`. El painter dibuja líneas horizontales de 1 px cada `gap` (3 px) con `Colors.white.withOpacity(opacity)` (0.035, sutilísimo).
- **animate:** si `true` y `!AppMotion.reduced(context)`, las líneas hacen un desplazamiento vertical muy lento (recorrido `gap` px en ~6 s, loop). Con reduced-motion → estáticas.
- **Cuándo:** opcional por panel HUD principal, terminal de chat.
- **Cuándo NO:** cubrir toda la app; sobre texto de lectura largo (resta legibilidad).

### 5.3 `ChamferBorder` + `ChamferClipper`

- **Qué es:** la forma de canto biselado a 45°.
- **API 1 — `ChamferBorder`:** un `OutlinedBorder`/`ShapeBorder` que recorta las 4 esquinas (o las indicadas) a 45° con corte `AppDimens.chamferM` (12 px). Parámetros: `cut = AppDimens.chamferM`, `side = BorderSide.none`, flags por esquina. Se usa en `shape:` de `Material`/`Container`/`Card`.
- **API 2 — `ChamferClipper`:** un `CustomClipper<Path>` con el mismo recorte, para usar en `ClipPath` cuando se necesita recortar contenido (p. ej. una imagen).
- **Implementación:** el `Path` se arma con `lineTo` saltando `cut` px en cada esquina elegida. `ChamferBorder` implementa `getInnerPath`, `getOuterPath`, `paint` (dibuja `side` si no es `none`) y `scale`/`copyWith`.
- **Cuándo:** paneles HUD principales, botón primario destacado, marcos de tabs (momentos «hardware/instrumento»).
- **Cuándo NO:** todas las cajas; cards/inputs normales usan radios redondeados (`radiusM`/`radiusL`).

### 5.4 `HudReactorBar`

- **Qué es:** barra fina que «late» con glow; indica energía/estado.
- **API:** `HudReactorBar({Axis axis = Axis.vertical, double thickness = 3, double length = 48, required Color color, bool pulsing = true})`.
- **Implementación:** `Container` de `thickness` × `length` (o invertido si horizontal), relleno `color`, esquinas `radiusPill`, con `boxShadow: AppDimens.glowStatus(color)`. Si `pulsing` y `!reduced`: `AnimationController` `repeat(reverse:true)` que anima opacidad/intensidad del glow `0.6↔1.0` período ~1600 ms (patrón P5 del prompt 04).
- **Medidas:** grosor 2–4 px (default 3); largo configurable.
- **Cuándo:** indicador de energía en bot card, panel de crédito, status del chat.
- **Cuándo NO:** como divisor decorativo sin significado de estado.

### 5.5 `HudDivider`

- **Qué es:** divisor horizontal técnico.
- **API:** `HudDivider({String? label, Color lineColor = AppColors.borderDefault, Color nodeColor = AppColors.cyan})`.
- **Implementación:** `Row`: línea hairline 1 px (`lineColor`) a izquierda, un nodo/segmento más brillante (`nodeColor`, ~6–10 px) y, si hay `label`, texto centrado con `AppTextStyles.mono` en `textTertiary` (formato sugerido `// LABEL` en mayúsculas), luego línea a derecha. Si no hay label: línea continua con el nodo a un tercio.
- **Cuándo:** separar secciones dentro de un panel, encabezar bloques de formulario.
- **Cuándo NO:** entre cada par de filas; usar `borderSubtle` para divisores triviales.

### 5.6 `HudTicker`

- **Qué es:** generaliza `AnimatedTicker`. Texto numérico mono que cuenta hacia su valor.
- **API:** `HudTicker({required double value, String prefix = '', String suffix = '', int decimals = 2, TextStyle? style, bool animate = true, bool showSign = false})`.
- **Implementación:** `TweenAnimationBuilder<double>` con `duration: AppMotion.durTicker`, `curve: AppMotion.easeTicker`. `style` por defecto `AppTextStyles.numericTicker` (mono + figuras tabulares — clave para no saltar de ancho). Formatea con `toStringAsFixed(decimals)`; `showSign` antepone `+`/`-`. Si `!animate` o `AppMotion.reduced(context)`: muestra el valor final sin conteo.
- **Mejora sobre el actual:** usa tokens de motion (no `Duration(seconds:2)` hardcodeado), figuras tabulares por el estilo, soporte de signo.
- **Cuándo:** crédito, precios, contadores grandes.
- **Cuándo NO:** números que cambian cada frame (latencia en vivo); ahí texto plano.
- El `AnimatedTicker` viejo queda como `@Deprecated` reexportando `HudTicker`, para no romper imports.

### 5.7 `HudStatusDot`

- **Qué es:** punto de estado con halo de glow pulsante.
- **API:** `HudStatusDot({required HudStatus status, double size = 10, bool showLabel = false})` donde `HudStatus` es un enum `{ online, processing, suspended, offline }`.
- **Implementación:** círculo de `size` px con color según estado — `online → success`, `processing → cyan`, `suspended → warning`, `offline → textTertiary`. Halo: `boxShadow: AppDimens.glowStatus(color)` salvo `offline` (sin glow). `online` y `processing` laten (P5, ~1600 ms) si `!reduced`; `suspended`/`offline` estáticos. Si `showLabel`: a la derecha un `AppTextStyles.labelSmall` con el texto del estado.
- **Cuándo:** estado de bot, conectividad, estado del chat.
- **Accesibilidad:** el estado nunca es solo el color del punto; siempre acompañado de label o tooltip.

### 5.8 `HudGridTexture`

- **Qué es:** `CustomPainter` de retícula técnica muy tenue.
- **API:** widget `HudGridTexture({double cell = 32, double opacity = 0.04, Color color = AppColors.cyan})` que envuelve un `CustomPaint`/`IgnorePointer`.
- **Implementación:** el painter dibuja líneas verticales y horizontales 1 px cada `cell` px (default 32) con `color.withOpacity(opacity)` (0.04, casi imperceptible). Sin animación.
- **Cuándo:** fondo de paneles HUD, capa del `AppBackground` (prompt 08).
- **Cuándo NO:** sobre contenido denso de texto.

### 5.9 `HudIdTag`

- **Qué es:** etiqueta mono pequeña tipo `UNIT-04F` para esquinas de cards.
- **API:** `HudIdTag({required String text, Color color = AppColors.textTertiary, IconData? icon})`.
- **Implementación:** `Container` con `AppTextStyles.mono` (uppercase), padding `space4`/`space8`, fondo `surfaceHud` con opacidad ~0.6, borde `borderSubtle`, radio `radiusXS`. Opcional `icon` (de `AppIcons`, `iconXS`) a la izquierda.
- **Cuándo:** esquina de bot card, encabezado de panel, marcar IDs técnicos.
- **Cuándo NO:** como badge de estado (eso es prompt 11).

---

## 6. Estados e interacciones

Las primitivas son mayormente decorativas/no interactivas (`IgnorePointer` donde aplique). Estados relevantes:
- `HudStatusDot` y `HudReactorBar` reflejan estado de dominio (online/processing/suspended/offline) — su color y latido cambian con el estado.
- `HudTicker` tiene un estado implícito «animando» vs «en reposo».
- Ninguna primitiva responde a hover/press salvo que el padre la haga interactiva.
Documentar en cada archivo que la primitiva no captura puntero (no roba hit-testing al contenido).

---

## 7. Animaciones

- `HudReactorBar` y `HudStatusDot` (online/processing): latido de opacidad 0.6↔1.0, ~1600 ms, `repeat(reverse:true)`, curva `easeStandard` (patrón P5).
- `HudScanlines` con `animate:true`: desplazamiento vertical lento ~6 s.
- `HudTicker`: conteo con `durTicker` + `easeTicker` (patrón P7).
- **Todas** consultan `AppMotion.reduced(context)` y se quedan estáticas si está activo. Sin reduced-motion no hay shimmer/latido.
- `HudCornerBrackets`, `HudDivider`, `HudGridTexture`, `HudIdTag`, `ChamferBorder`: estáticos (un prompt de pantalla puede animar su aparición vía fade, pero la primitiva en sí no anima).

---

## 8. Accesibilidad

- Todas las primitivas decorativas van envueltas en `ExcludeSemantics` o son `IgnorePointer`: no agregan ruido al árbol de accesibilidad ni roban foco.
- `HudStatusDot`: el estado se expone con `Semantics(label: ...)` describiendo el estado en texto; nunca solo color.
- Contraste: las opacidades 0.035/0.04 de scanlines/grid son decorativas y no portan información, así que no aplican umbrales de contraste; pero **no** deben reducir el contraste del texto que cubren — por eso van debajo del contenido o con opacidad mínima.
- `HudTicker`: el valor numérico es texto real y legible por lector de pantalla.
- Con `AppMotion.reduced`: sin latidos ni scroll de scanlines.

---

## 9. Checklist de aceptación

- [ ] Existe `lib/core/ui/hud/` con los 9 archivos de primitivas (+ barrel `hud.dart` opcional).
- [ ] `HudCornerBrackets` dibuja 4 escuadras de 16–22 px, grosor 1.5 px, color `borderGold` por defecto, configurable por esquina.
- [ ] `HudScanlines` dibuja líneas a opacidad 0.035, gap 3 px, `IgnorePointer`, animación opcional gateada por reduced-motion.
- [ ] `ChamferBorder` (ShapeBorder) y `ChamferClipper` (CustomClipper) recortan a 45° con `AppDimens.chamferM`.
- [ ] `HudReactorBar` late a ~1600 ms con `glowStatus`, gateado por reduced-motion, configurable axis/grosor/largo.
- [ ] `HudDivider` dibuja línea hairline + nodo brillante + label mono opcional.
- [ ] `HudTicker` usa `durTicker`/`easeTicker`, estilo `numericTicker` con figuras tabulares, soporta prefijo/sufijo/signo y respeta reduced-motion; `AnimatedTicker` queda como alias `@Deprecated`.
- [ ] `HudStatusDot` cubre 4 estados con color + glow + latido correctos y expone `Semantics`.
- [ ] `HudGridTexture` dibuja retícula a opacidad 0.04, celda 32 px, sin animar.
- [ ] `HudIdTag` renderiza texto mono uppercase con fondo `surfaceHud`, borde `borderSubtle`, radio `radiusXS`.
- [ ] Las primitivas decorativas son `IgnorePointer`/`ExcludeSemantics`.
- [ ] Cero color/dimensión/duración crudos: todo desde `AppColors`/`AppDimens`/`AppMotion`/`AppTextStyles`.
- [ ] La app compila; `flutter analyze` no agrega warnings nuevos.

---

## 10. Dependencias

- **Previo:** 01 (color), 02 (`AppTextStyles` para ticker/divider/tag), 03 (`AppDimens` para chamfer/glow/radios), 04 (`AppMotion` para latidos/ticker/reduced), 05 (`AppIcons` para glifos de `HudIdTag`/`HudDivider`).
- **Habilita:** 07 (glass/glow se componen con estas primitivas), 08 (`AppBackground` usa `HudGridTexture`), 12 (`HoloPanel` usa brackets/scanlines/chamfer) y prácticamente todos los prompts de pantalla 09–65.
