# 19 — Sidebar de navegación · Barra lateral premium

> Fase C · Shell y navegación. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Antes de ejecutar este prompt, leer el archivo 00 completo. Si algo se contradice, gana el archivo 00.

---

## 1. Objetivo

Rediseñar la barra lateral de navegación (`Sidebar`) para convertirla en una columna HUD de alta gama: logo enmarcado, cuatro destinos principales más AJUSTES, estado activo señalado por un indicador de barra vertical dorado que se desliza entre ítems, y micro-labels técnicos bajo cada ícono. Es el ancla de navegación de toda la app y debe sentirse precisa, viva y silenciosa.

---

## 2. Archivos

- **Modificar:** `lib/features/dashboard/presentation/widgets/sidebar.dart` — reescritura completa de `Sidebar` y `_SidebarItem`, eliminando el helper suelto `_buildLabel`.
- **Consumir:** `AppColors` (prompt 01), `AppTextStyles` (prompt 02), `AppDimens` (prompt 03), `AppMotion` (prompt 04), `AppIcons` (prompt 05), `HudDivider`, `HudCornerBrackets` (prompt 06), `GlowBox` (prompt 07), tooltip HUD (prompt 13).

---

## 3. Estado actual

`Sidebar` es un `Container` de **80 px** de ancho, color hex suelto `0xFF050505`. Logo 40×40 arriba con 32 px de aire arriba y abajo. Zona central en `SingleChildScrollView` con 4 `_SidebarItem` (BOTS, PLANTILLAS, PAGOS, TIENDA) separados por `SizedBox(height: 20)`. AJUSTES fijo abajo.

Cada `_SidebarItem` es un `InkWell` → `Column` con un `Container` de padding 12, ícono 24 px (`FaIcon`) y label debajo. Estado activo: fondo `AppColors.primary` sólido, radius 12, `BoxShadow` dorado, ícono negro. El label activo usa `ShaderMask` + `shimmer` repetido infinito; el inactivo es `Text` plano `textSecondary@0.6`.

Problemas: hex suelto, opacidades sueltas, mezcla de sets de iconos (`FontAwesomeIcons` + `Icons` Material), sin tokens de espaciado, fondo dorado sólido demasiado agresivo (rompe «el oro se gana»), shimmer infinito en el label (ruido), sin indicador deslizante, sin tooltips, sin foco de teclado, sin estado hover real, sin divisor antes de AJUSTES.

---

## 4. Visión del rediseño

Una columna vertical fina (**84 px** propuestos; ver §5.1) que ancla la izquierda de la app:

- **Arriba:** el logo dentro de un marco HUD sutil — un cuadro con borde hairline y leves `HudCornerBrackets`, que lo presenta como «núcleo del sistema».
- **Centro:** cuatro destinos principales (BOTS, PLANTILLAS, PAGOS, TIENDA), cada uno un ícono `iconM` con micro-label `labelSmall` debajo.
- **Abajo:** un `HudDivider` y luego AJUSTES, anclado al pie.

El estado activo NO se pinta con un bloque dorado sólido. Se señala con tres capas mesuradas: (1) una **barra vertical dorada de 3 px** pegada al borde interno de la columna, (2) un relleno `surfaceRaised` con un `glowGold` tenue, (3) ícono `gold` y label `textPrimary`. La barra vertical es un único widget que **se desliza** verticalmente de un ítem a otro al cambiar de ruta — una transición compartida que comunica «me moví de aquí a allá». El oro se gana: sólo el ítem activo emite.

---

## 5. Especificación visual

### 5.1 Contenedor raíz

- Ancho: **84 px** (se sube de 80 a 84 para alojar cómodos el ícono `iconM` 22 px + micro-label sin apretar; si el resto del shell asume 80, mantener 80 — decisión menor, pero documentar el valor elegido como `AppDimens.sidebarWidth`).
- Fondo: `AppColors.voidBlack` (la capa más profunda — el sidebar es el «borde» del instrumento). Reemplaza el hex `0xFF050505`.
- Borde derecho: hairline 1 px `AppColors.borderSubtle` separando el sidebar del área de contenido.
- Estructura: `Column` con tres zonas — header (logo), `Expanded` central (destinos), footer (divisor + AJUSTES).
- Padding superior del header: `AppDimens.space24` (24 px). Padding inferior del footer: `AppDimens.space24`.

### 5.2 Header — logo enmarcado

- Marco: `Container` de 48×48, centrado horizontalmente, `borderRadius: AppDimens.radiusM` (14), borde 1 px `AppColors.borderSubtle`, fondo `AppColors.surfaceHud`.
- Sobre el marco, `HudCornerBrackets` mini: brazos de 8 px, grosor 1.5 px, color `AppColors.borderGold`. Sutiles, no dominan.
- Dentro del marco: `Image.asset('assets/icon/botlode_logo.png', fit: BoxFit.contain)` a 28×28, centrado.
- Debajo del marco: `SizedBox(height: AppDimens.space24)` antes del primer destino.

### 5.3 Ítems de navegación (`_SidebarItem`)

Cada ítem es una celda vertical uniforme:

- Alto de la celda interactiva: **64 px**. Ancho: todo el ancho útil del sidebar menos la barra indicadora.
- Separación entre ítems: `AppDimens.space12` (12 px) — más ajustado que los 20 actuales, porque ahora cada celda tiene su propio alto generoso.
- Contenido: `Column(mainAxisAlignment: center)` con:
  1. **Ícono:** `iconM` (22 px) del set unificado `AppIcons` (prompt 05) — todos del mismo set, sin mezclar Material + FontAwesome. Sugerencia de mapeo: BOTS → `AppIcons.bots`, PLANTILLAS → `AppIcons.templates`, PAGOS → `AppIcons.billing`, TIENDA → `AppIcons.store`, AJUSTES → `AppIcons.settings`.
  2. `SizedBox(height: AppDimens.space4)` (4 px).
  3. **Micro-label:** `Text` con `AppTextStyles.labelSmall` (11/600, tracking +1.6, UPPERCASE), centrado. Sin `ShaderMask`, sin shimmer infinito.
- Relleno de fondo de la celda: `Container` con `borderRadius: AppDimens.radiusM` (14), aplicado con un margen interno de `AppDimens.space8` a cada lado para que el relleno no toque los bordes de la columna.

### 5.4 Indicador activo deslizante

- Es un **único** widget posicionado en un `Stack` que cubre toda la zona central de destinos (no uno por ítem).
- Forma: barra vertical de **3 px de ancho**, alto = alto de la celda activa (64 px) o un poco menos (44 px centrado verticalmente, recomendado para que se lea como «marcador» y no como borde completo).
- Color: gradiente `gradGold` vertical; `borderRadius: AppDimens.radiusPill` en los extremos.
- Posición: pegada al **borde interno** de la columna (lado derecho del sidebar, mirando al contenido). Coordenada `right: 0`.
- El indicador se mueve cambiando su `top` dentro del `Stack` mediante `AnimatedPositioned`. La posición destino se calcula a partir del índice del ítem activo (derivado de la ruta `go_router`).

### 5.5 Estado activo — capas

Cuando un ítem está activo, además del indicador deslizante:

- **Relleno de celda:** `AppColors.surfaceRaised` con `borderRadius: radiusM`.
- **Glow:** `glowGold` tenue (`elev` + glow del archivo 00 §6.4) — un solo glow, suave, no saturado.
- **Borde:** 1 px `AppColors.borderGold`.
- **Ícono:** color `AppColors.gold`.
- **Label:** color `AppColors.textPrimary`, peso 600.
- **Opcional:** `HudCornerBrackets` mini en la celda activa (brazos 6 px, `borderGold`) — sólo si no recarga; preferir omitirlos si el indicador + glow ya dan suficiente jerarquía.

NO se usa fondo dorado sólido como hoy. El oro aparece sólo en: la barra indicadora, el ícono y el borde. El relleno de la celda es gris elevado.

### 5.6 Footer — divisor + AJUSTES

- Antes de AJUSTES: un `HudDivider` horizontal (línea hairline `borderSubtle` con nodo central más brillante), con `AppDimens.space12` de margen vertical.
- AJUSTES: un `_SidebarItem` idéntico en estructura a los demás, anclado al pie por estar fuera del `Expanded`.
- El indicador deslizante también puede posicionarse sobre AJUSTES (si la ruta activa es `/settings`); el `Stack` del indicador debe cubrir centro + footer, o usarse un segundo cálculo de posición que incluya el footer. Decisión recomendada: un único `Stack` que envuelve centro **y** footer para que el deslizamiento sea continuo.

### 5.7 Tokens — resumen

| Elemento | Token |
|---|---|
| Ancho sidebar | 84 px (`AppDimens.sidebarWidth`) |
| Fondo | `AppColors.voidBlack` |
| Borde derecho | `AppColors.borderSubtle`, 1 px |
| Marco logo | `AppColors.surfaceHud`, `radiusM`, borde `borderSubtle` |
| Brackets logo / celda activa | `HudCornerBrackets` · `AppColors.borderGold` |
| Celda interactiva | alto 64 px, `radiusM` |
| Ícono | `iconM` (22 px) · `AppIcons` |
| Micro-label | `AppTextStyles.labelSmall` |
| Indicador activo | barra 3 px · `gradGold` · `radiusPill` |
| Relleno celda activa | `AppColors.surfaceRaised` + `glowGold` + borde `borderGold` |
| Ícono activo | `AppColors.gold` · Label activo `AppColors.textPrimary` |
| Ícono inactivo | `AppColors.textTertiary` · Label inactivo `AppColors.textTertiary` |
| Hover inactivo | ícono/label `AppColors.textSecondary` + relleno `AppColors.borderSubtle` |
| Divisor footer | `HudDivider` horizontal |
| Separación entre ítems | `AppDimens.space12` |

---

## 6. Estados e interacciones

Matriz §9 del archivo 00 aplicada a `_SidebarItem`.

| Estado | Qué cambia |
|---|---|
| `default` (inactivo) | Relleno `transparent`. Ícono `AppColors.textTertiary`. Label `AppColors.textTertiary`. Sin glow, sin borde. |
| `hover` (inactivo) | Relleno `AppColors.borderSubtle`. Ícono y label suben a `AppColors.textSecondary`. Sin glow dorado (el oro se reserva para activo). Cursor `SystemMouseCursors.click`. Transición `durFast` (160 ms). |
| `pressed` | Escala 0.97 (`AnimatedScale`, `durInstant`). Relleno un paso más profundo (`borderDefault`). |
| `focused` | Anillo de foco 2 px `AppColors.cyan` por dentro de la celda, sin solaparse con el indicador dorado. Visible siempre, nunca eliminado. |
| `selected/active` | Indicador deslizante posicionado sobre la celda. Relleno `surfaceRaised`, glow `glowGold`, borde `borderGold`, ícono `gold`, label `textPrimary`. Estado estable (sin shimmer infinito). |
| `disabled` | No aplica: todos los destinos están siempre disponibles. |
| `loading` / `error` / `empty` | No aplican a ítems de navegación. |

Reglas de combinación: si un ítem está `active` y además recibe `hover`, prima el estilo activo; el hover sólo añade el cursor pointer. Si está `active` y recibe `focus`, se muestran indicador dorado + anillo `cyan` simultáneamente (no se anulan).

Ruta activa: el `Sidebar` lee `GoRouterState.of(context).uri.path`. Mapeo:
- BOTS activo si `path.startsWith('/dashboard')` o `path == '/'` (incluye el detalle `/dashboard/detail/:botId`).
- PLANTILLAS activo si `path.startsWith('/bots')`.
- PAGOS activo si `path == '/billing'`.
- TIENDA activo si `path == '/store'`.
- AJUSTES activo si `path == '/settings'`.

---

## 7. Animaciones

- **Indicador deslizante:** `AnimatedPositioned` con `duration = AppMotion.durBase` (240 ms) y `curve = AppMotion.easeEntrance` (`Cubic(0.16, 1.0, 0.3, 1.0)`). Al cambiar de ruta, el indicador se desliza de la posición vieja a la nueva. Es la animación firma de la barra: comunica «me moví de aquí a allá».
- **Aparición inicial del sidebar:** los ítems entran escalonados al primer render — fade + translateY 12 px, 36 ms de retardo entre ítems (máximo 5 ítems → ~180 ms total), curva `easeEntrance`. El logo enmarcado entra primero. Esta entrada ocurre una sola vez al montar el shell.
- **Hover:** relleno + color de ícono/label con `durFast` (160 ms), curva `easeStandard`. Sólo `color`/`opacity`.
- **Press:** `AnimatedScale` a 0.97 con `durInstant` (90 ms).
- **Glow del ítem activo:** estable, no pulsante (a diferencia de un `HudStatusDot`). El glow aparece/desaparece con `durBase` al cambiar el ítem activo.
- **Sin shimmer infinito** en los labels — se elimina el `ShaderMask` + `.shimmer().animate(repeat)` actual; era ruido permanente que contradice §3.1.4 («el movimiento tiene causa»).
- **Reduced-motion (`AppMotion.reduced`):** el indicador no se desliza, salta a la posición destino con un crossfade de 120 ms. Sin entrada escalonada (los ítems aparecen ya colocados). Sin glow animado (aparece instantáneo). Los hovers se mantienen como cambio de color simple.

---

## 8. Accesibilidad

- Cada ítem lleva `Semantics` con `label` («Bots», «Plantillas», «Pagos», «Tienda», «Ajustes»), `button: true` y `selected: isActive`.
- Tooltip HUD (prompt 13) en cada ítem, mostrado en hover, con el nombre completo del destino — útil porque el micro-label es de 11 px.
- Foco de teclado visible: anillo 2 px `cyan`. Orden de foco: BOTS → PLANTILLAS → PAGOS → TIENDA → AJUSTES (coincide con orden visual de arriba hacia abajo). Navegable con Tab y activable con Enter/Espacio.
- El estado activo se comunica por **indicador de posición + color + ícono + label más brillante**, no sólo por color (cumple §10).
- Contraste: ícono/label inactivo `textTertiary` sobre `voidBlack` ≥ 3:1 (glifo de UI); en hover sube a `textSecondary` (≥ 4.5:1); activo `textPrimary` (≥ 12:1).
- Hit area de cada celda ≥ 32×32 px (acá 64 px de alto × ancho útil ≈ 68 px).
- Respetar `MediaQuery.disableAnimations` para el deslizamiento del indicador y la entrada escalonada.

---

## 9. Checklist de aceptación

- [ ] El sidebar usa un único ancho tokenizado (`AppDimens.sidebarWidth`, 84 px o 80 px documentado); cero hex sueltos (`0xFF050505` eliminado).
- [ ] Fondo `AppColors.voidBlack`; borde derecho hairline `borderSubtle`.
- [ ] Logo dentro de un marco HUD (`surfaceHud`, `radiusM`) con `HudCornerBrackets` mini.
- [ ] Cuatro destinos principales + AJUSTES; AJUSTES anclado al pie.
- [ ] Todos los íconos provienen del set unificado `AppIcons` a tamaño `iconM` (22 px); sin mezcla Material + FontAwesome.
- [ ] Cada ítem: ícono + micro-label `labelSmall` debajo, centrados.
- [ ] El estado activo NO usa fondo dorado sólido: usa indicador de barra 3 px + relleno `surfaceRaised` + `glowGold` tenue + borde `borderGold` + ícono `gold` + label `textPrimary`.
- [ ] Existe un único indicador deslizante (`AnimatedPositioned`) que se mueve entre ítems con `durBase` + `easeEntrance`.
- [ ] El indicador cubre también AJUSTES cuando la ruta es `/settings`.
- [ ] Hover inactivo: relleno `borderSubtle`, ícono/label `textSecondary`; sin oro.
- [ ] Press: escala 0.97 con `durInstant`.
- [ ] `HudDivider` horizontal antes de AJUSTES.
- [ ] Foco de teclado visible (anillo 2 px `cyan`), orden de foco de arriba hacia abajo.
- [ ] Cada ítem tiene `Semantics` (`selected`) + tooltip HUD.
- [ ] Eliminado el `ShaderMask` + shimmer infinito del label; sin ruido de movimiento permanente.
- [ ] Reduced-motion respetado (indicador salta con crossfade 120 ms, sin entrada escalonada).
- [ ] `flutter analyze` sin warnings nuevos; se ve correcto en 1280×720 y en 1024×600.

---

## 10. Dependencias

Deben estar completados antes de ejecutar este prompt:

- **01** — Tokens de color (`voidBlack`, `surfaceHud`, `surfaceRaised`, `borderSubtle`, `borderDefault`, `borderGold`, `gold`, `textPrimary`, `textSecondary`, `textTertiary`, `cyan`, `glowGold`).
- **02** — Sistema tipográfico (`AppTextStyles.labelSmall`).
- **03** — Tokens de dimensión (`AppDimens.space4/8/12/24`, `radiusM`, `radiusPill`, `sidebarWidth`).
- **04** — Sistema de motion (`AppMotion`: `durInstant`, `durFast`, `durBase`, `easeEntrance`, `easeStandard`, `reduced`).
- **05** — Iconografía (`AppIcons.bots`, `templates`, `billing`, `store`, `settings`, tamaño `iconM`).
- **06** — Primitivas HUD (`HudDivider`, `HudCornerBrackets`).
- **07** — Primitivas de glow/glass (`GlowBox` para el `glowGold` del ítem activo).
- **13** — Tooltips HUD.

Se integra con: **20** (MainLayout shell, que posiciona el sidebar y comparte la ruta activa) y **21** (PageTitle, coherencia de jerarquía de navegación).
