# 30 — Bot Detail · Layout general y sistema de tabs

> Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leerlo completo antes de ejecutar.
> Fase E · Bot detail y chat. Este prompt define la **estructura contenedora**; los prompts 31–37 rediseñan su contenido interno.

---

## 1. Objetivo

Rediseñar el layout maestro de la pantalla de detalle de unidad (`BotDetailView`) y su sistema de navegación por tabs. Hoy es un `Row` de dos columnas con tabs deslizantes de 2 segmentos; el rediseño lo convierte en una **estación de monitoreo de unidad** de dos columnas firmes con una barra de 5 tabs HUD, encabezado de comando con identidad de la unidad, y transiciones de contenido con causa.

---

## 2. Archivos

- **Modificar:** `lib/features/dashboard/presentation/views/bot_detail_view.dart`
  - Reescribir el `build` raíz: `Scaffold` → `AppBackground` → `MainLayout` shell → `Row` de dos columnas.
  - Reescribir `_SciFiSlidingTabs` / `_SciFiSlidingTabsState` → renombrar a `_UnitTabBar`.
  - Reescribir `_EditableHeader` → renombrar a `_UnitCommandHeader` (la edición inline del nombre se delega al tab Config, prompt 33).
- **Crear:** `lib/features/dashboard/presentation/widgets/unit_tab_bar.dart` (extraer `_UnitTabBar` a archivo propio reutilizable).
- **Crear:** `lib/features/dashboard/presentation/widgets/unit_command_header.dart`.
- **No tocar:** la lógica de `bots_provider`, el embed string, ni los providers de mood/chat.

---

## 3. Estado actual

- `Scaffold` con `body: Row` de dos columnas: izquierda fija con la Rive a pantalla parcial, derecha con `_SciFiSlidingTabs` (solo **2** tabs: "MONITOR" y "TERMINAL") y debajo un `Expanded` que conmuta por `_selectedTab == 0`.
- Los tabs son un `Row` de dos `Expanded`, cada uno un `_buildTabItem` con ícono + label; el activo se pinta con color de relleno, sin indicador deslizante real.
- El encabezado (`_EditableHeader`) mezcla botón volver, edición inline del nombre y acciones.
- Bordes con `AppColors.borderGlass`, radios sueltos (`circular(16)`, `circular(24)`), sin tokens de dimensión, sin ornamento HUD coherente, sin profundidad de fondo.
- No hay `HudIdTag`, ni `StatusTag`, ni indicador de tab animado.

**Objetivo del rediseño:** pasar a **5 tabs** (Dashboard, Config, Knowledge, Mood, Embed), columna izquierda firme con el avatar y su HUD, encabezado de comando claro, e indicador de tab deslizante premium.

---

## 4. Visión del rediseño

La pantalla se siente como abrir el panel de control de una unidad autónoma en el hangar. A la **izquierda**, una columna fija ocupa la unidad física: el avatar Rive enmarcado y su telemetría (prompt 31). A la **derecha**, una zona de trabajo con una **regleta de 5 tabs HUD** —segmentos separados por `HudDivider` verticales— y debajo el contenido del tab activo. El tab seleccionado tiene un **indicador `gold` deslizante** que se desliza físicamente entre segmentos con resorte, dejando una estela de `glowGold`. Cambiar de tab hace un **crossfade direccional** del contenido: el panel saliente se va, el entrante llega desde el lado correcto. El encabezado superior es una barra de comando: botón volver, nombre de la unidad grande, `HudIdTag` con el ID corto, y `StatusTag` con el estado operativo.

---

## 5. Especificación visual

### 5.1 Estructura raíz y grilla

```
AppBackground (gradVoid + glow ambiental + HudGridTexture, prompt 08)
└── MainLayout shell (sidebar + title bar, prompt 20)
    └── Padding horizontal space32, vertical space24
        └── Column
            ├── _UnitCommandHeader            ← altura fija 64 px
            ├── space24 (gap)
            └── Expanded → Row (gap space24)
                ├── ColumnIzquierda  flex 42   (min 380 px, max 460 px)
                │   └── prompt 31 (Rive + HUD estado)
                └── ColumnDerecha    flex 58
                    └── Column
                        ├── _UnitTabBar       ← altura fija 52 px
                        ├── space20 (gap)
                        └── Expanded → contenido del tab activo
```

- **Reparto de columnas:** izquierda `flex: 42`, derecha `flex: 58`. La izquierda se acota con `ConstrainedBox(minWidth: 380, maxWidth: 460)`.
- **Gap entre columnas:** `space24` (`SizedBox(width: 24)`).
- **Padding de pantalla:** `space32` horizontal, `space24` vertical (tokens §6.1).

### 5.2 Breakpoints (desktop, ventana 1024–1920+)

| Ancho de ventana | Comportamiento |
|---|---|
| ≥ 1440 px | Layout pleno: izquierda flex 42 (hasta 460 px), derecha flex 58. |
| 1180–1439 px | Izquierda se fija a 380 px (no flex), derecha toma el resto. |
| 1024–1179 px (mínimo soportado) | Izquierda se comprime a 340 px; el avatar Rive reduce a 240×240 (lo resuelve el prompt 31). Tabs pueden ocultar el label y dejar solo ícono si el ancho del segmento < 92 px. |

Usar `LayoutBuilder` en la raíz del `Row` para elegir el modo. Nunca scroll horizontal; la columna derecha siempre puede hacer scroll vertical interno.

### 5.3 `_UnitCommandHeader`

- Contenedor `Row`, altura 64 px, sin fondo propio (vive sobre `AppBackground`).
- **Botón volver:** `AppIconButton` (prompt 09), ícono `arrow-left` (set prompt 05), tamaño 40×40, variante `ghost`. `tooltip: "Volver al hangar"`. Dispara `context.pop()`.
- `SizedBox(width: space16)`.
- **Bloque identidad** (`Expanded`, `Column`, `crossAxisAlignment: start`):
  - Fila superior: nombre de la unidad en `titleL` color `textPrimary` + `SizedBox(width: space12)` + `HudIdTag` (prompt 06) con `UNIT-${botId corto}` en `mono`/`labelSmall`, color `textTertiary`, borde `borderSubtle`.
  - Fila inferior (gap `space4`): `labelSmall` color `textTertiary` UPPERCASE con la clase del bot o `// UNIDAD AUTÓNOMA`.
- **`StatusTag`** (prompt 11) a la derecha: refleja estado operativo del bot (`ACTIVA` `success`, `SUSPENDIDA` `warning`, `OFFLINE` `danger`). Lleva `HudStatusDot` + ícono + texto.
- Las acciones (Editar/Eliminar/Compartir) NO van aquí: las define el prompt 37 como barra de acciones, ubicada a la derecha del `StatusTag` con un `HudDivider` vertical de separación.

### 5.4 `_UnitTabBar` — regleta de 5 tabs HUD

- Contenedor: `HoloPanel` compacto (prompt 12) variante `flat`, altura 52 px, relleno `surfaceHud`, borde `borderDefault`, radio `radiusM`, `chamfer` en las 2 esquinas superiores (`chamferM`, vía `ChamferBorder` prompt 06).
- Contenido: `Row` de 5 segmentos `Expanded`, cada uno separado del siguiente por un `HudDivider` **vertical** de 1 px (línea hairline `borderSubtle` con nodo central más brillante).
- **Los 5 tabs** (orden fijo, índices 0–4):

  | Índice | Label (`label`, UPPERCASE) | Ícono (set prompt 05) |
  |---|---|---|
  | 0 | DASHBOARD | `gauge` / `activity` |
  | 1 | CONFIG | `sliders` |
  | 2 | KNOWLEDGE | `book-open` |
  | 3 | MOOD | `smile` / `sparkles` |
  | 4 | EMBED | `code` |

- **Segmento de tab:** `Row` centrado: ícono 16 px + `SizedBox(width: space8)` + label. Padding interno `space12` horizontal.
  - Tab inactivo: ícono y label `textSecondary`.
  - Tab activo: ícono y label `textPrimary`; ícono toma tinte `gold`.
- **Indicador deslizante:** una barra horizontal de 3 px de alto, color `gold`, posicionada en el **borde inferior** del segmento activo, con `glowGold` (blur 24). Se posiciona con un `AnimatedPositioned`/`Stack` cuyo `left` y `width` se calculan según el segmento activo. Ancho del indicador = ancho del segmento − `space16` (centrado, deja 8 px de margen a cada lado).
- Si el ancho de segmento < 92 px (breakpoint mínimo): ocultar label, dejar solo ícono centrado; el indicador conserva su lógica.

### 5.5 Zona de contenido del tab

- `Expanded` debajo de la tab bar, con `space20` de gap.
- El contenido es uno de los 5 paneles (prompts 32–36) seleccionado por `_selectedTab`.
- Envoltura: `AnimatedSwitcher` con `duration: durBase`, `transitionBuilder` que combina `FadeTransition` + `SlideTransition` direccional (ver §7).
- Cada panel hijo lleva su propia `Key` (`ValueKey(_selectedTab)`) para que el switcher detecte el cambio.

---

## 6. Estados e interacciones

Matriz §9 aplicada a **cada segmento de tab**:

| Estado | Apariencia |
|---|---|
| `default` (inactivo) | Ícono/label `textSecondary`, sin indicador, sin glow. |
| `hover` | Fondo del segmento aclara a `borderSubtle`; ícono/label suben a `textPrimary` al 80 %; cursor pointer. `durFast`. |
| `pressed` | Escala del contenido del segmento a 0.97, `durInstant`. |
| `focused` (teclado) | Anillo de foco 2 px `cyan` insertado dentro del segmento, radio `radiusXS`. Nunca se elimina. |
| `selected/active` | Ícono/label `textPrimary` + tinte `gold` en ícono; indicador `gold` con `glowGold` debajo. |
| `disabled` | No aplica: los 5 tabs están siempre disponibles. |

- **Navegación por teclado:** flechas izquierda/derecha mueven el tab activo; `Home`/`End` van al primero/último; el foco visual sigue al tab activo. Orden de tabulación: header → tab bar → contenido.
- **Cambio de tab:** al seleccionar, `setState(_selectedTab)`; el indicador se desliza y el contenido hace crossfade direccional.

---

## 7. Animaciones

- **Indicador de tab deslizante:** `AnimatedPositioned` (o `TweenAnimationBuilder` sobre `left`/`width`), `duration: durBase` (240 ms), curva `easeStandard`. Si se quiere el toque premium, usar un `AnimationController` con `SpringSimulation` (`springSoft`) para que el indicador "asiente" con un micro-rebote. El `glowGold` acompaña el movimiento (mismo `AnimatedContainer`).
- **Crossfade direccional del contenido:** al pasar de tab N a tab M:
  - Dirección = `M > N` → entra desde la derecha (+24 px X), sale hacia la izquierda; `M < N` → inverso.
  - `transitionBuilder`: `SlideTransition` (offset `Tween(Offset(±0.06, 0) → Offset.zero)`) + `FadeTransition`. `duration: durBase`; salida ~65 % (≈156 ms) vía `reverseDuration`.
  - Curva entrada `easeEntrance`, salida `easeExit`.
- **Entrada inicial de la pantalla:** header y columnas hacen fade + translateY 12 px escalonado: header (0 ms), columna izquierda (+36 ms), tab bar (+72 ms), contenido (+108 ms). Curva `easeEntrance`, `durBase`.
- **Hover de segmento:** transición de color/fondo con `durFast`.
- **Reduced motion** (`AppMotion.reduced`): el indicador salta sin spring (corte directo o tween de 120 ms); el crossfade se reduce a un fade puro de 120 ms sin slide; sin escalonado de entrada.

---

## 8. Accesibilidad

- Cada segmento de tab es un `Semantics` con `selected: index == _selectedTab`, `label: "<NOMBRE TAB>, pestaña ${index+1} de 5"`, role tab; el contenedor es `tablist`.
- El contenido del tab activo es un `Semantics` con role `tabpanel`.
- Botón volver: `AppIconButton` con `tooltip` + `Semantics(label: "Volver al hangar")`.
- `HudIdTag` y `StatusTag` exponen su texto a accesibilidad; el estado nunca depende solo del color (siempre ícono + texto).
- Foco visible en todos los tabs (anillo `cyan` 2 px); orden de foco coincide con el orden visual izquierda→derecha.
- Contraste: label de tab activo `textPrimary` sobre `surfaceHud` ≥ 12:1; label inactivo `textSecondary` ≥ 4.5:1. Verificar.
- Targets: cada segmento ≥ 32 px de alto y ≥ 92 px de ancho (o ícono-solo de 44×44 en el breakpoint mínimo).

---

## 9. Checklist de aceptación

- [ ] La pantalla usa `AppBackground` + `MainLayout` shell; no hay fondo plano.
- [ ] Layout de 2 columnas con flex 42/58, gap `space24`, padding `space32`/`space24`.
- [ ] Columna izquierda acotada a 380–460 px y se comprime correctamente en los 3 breakpoints.
- [ ] `_UnitCommandHeader` muestra botón volver, nombre `titleL`, `HudIdTag` con ID corto, `StatusTag` con estado real.
- [ ] La tab bar tiene exactamente 5 tabs en el orden Dashboard·Config·Knowledge·Mood·Embed, con `HudDivider` vertical entre cada uno.
- [ ] El tab activo muestra indicador `gold` deslizante con `glowGold`; al cambiar de tab el indicador se desliza con `durBase`.
- [ ] El contenido del tab cambia con crossfade direccional (derecha/izquierda según índice) `durBase`.
- [ ] Navegación por teclado con flechas funciona; foco visible `cyan` en cada tab.
- [ ] Cero hex sueltos y cero magic numbers: todo por tokens (`space*`, `radius*`, `chamferM`, colores, `dur*`, curvas).
- [ ] Reduced motion: sin slide ni spring ni escalonado; crossfade de 120 ms.
- [ ] Compila y se ve correcto en 1280×720 y en 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores), 02 (tipografía: `titleL`, `label`, `labelSmall`, `mono`), 03 (`space*`, `radius*`, `chamferM`, `elev*`, `glowGold`, `z*`), 04 (`dur*`, curvas, `springSoft`, reduced-motion), 05 (iconografía), 06 (`HudDivider`, `HudIdTag`, `ChamferBorder`, `HudStatusDot`).
- **Núcleo:** 09 (`AppIconButton`), 11 (`StatusTag`), 12 (`HoloPanel`).
- **Shell:** 20 (`MainLayout`), 21 (`PageTitle` como referencia de encabezado).
- **Habilita:** 31–37 (contenido de columnas y tabs), que asumen este contenedor.
