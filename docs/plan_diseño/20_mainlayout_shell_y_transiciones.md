# 20 — MainLayout shell + transiciones de ruta

> Fase C · Shell y navegación. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Antes de ejecutar este prompt, leer el archivo 00 completo. Si algo se contradice, gana el archivo 00.

---

## 1. Objetivo

Rediseñar el scaffold de shell (`MainLayout`) que envuelve toda la zona autenticada y definir las transiciones entre rutas. El shell debe componer sidebar + title bar + contenido sobre el fondo ambiental, gestionar el z-index de las capas, y orquestar transiciones de pantalla coherentes (crossfade entre tabs hermanos, slide al entrar/salir de un detalle), preservando estado y scroll.

---

## 2. Archivos

- **Modificar:** `lib/features/dashboard/presentation/views/main_layout.dart` — reescritura: usa el `CustomTitleBar` público (prompt 18), `AppBackground` (prompt 08), y un envoltorio de transición para `navigationShell`.
- **Modificar:** `lib/core/router/app_router.dart` — reemplazar los `NoTransitionPage` de los destinos hermanos y el `builder` del detalle por `CustomTransitionPage` con las transiciones definidas acá.
- **Consumir:** `AppColors` (prompt 01), `AppDimens` (prompt 03), `AppMotion` (prompt 04), `AppBackground` (prompt 08), `Sidebar` (prompt 19), `CustomTitleBar` (prompt 18). El Connectivity HUD se delega al prompt 61.

---

## 3. Estado actual

`MainLayout` es un `ConsumerStatefulWidget`. `build` devuelve `Scaffold` → `Row[ Sidebar(), Expanded( Column[ _CustomTitleBar(), Expanded(navigationShell) ] ) ]`. No hay fondo ambiental: el `Scaffold` muestra su color por defecto. El title bar es el privado `_CustomTitleBar` (32 px). Hay una escucha de `connectivityProvider` que dispara snackbars «tácticos» con borde de color, `Courier` y `boxShadow` — todo con hex/opacidades sueltas.

El router usa `StatefulShellRoute.indexedStack` con 5 ramas. Los destinos hermanos (`/dashboard`, `/bots`, `/billing`, `/settings`, `/store`) usan `NoTransitionPage` — el cambio de tab es un corte seco. El detalle `/dashboard/detail/:botId` usa `builder` directo — transición Material por defecto, inconsistente con el resto.

Problemas: sin fondo ambiental (fondo plano, viola §3.1.1), title bar duplicado, cortes secos sin causa visual, transición del detalle ajena al sistema, snackbars de conectividad fuera del sistema de tokens, sin manejo explícito de z-index ni safe padding.

---

## 4. Visión del rediseño

El shell es el «chasis» del instrumento: una estructura fija e inmutable entre pantallas (§3.2 prohíbe romper el shell sidebar + title bar). Dentro:

- El **fondo ambiental** (`AppBackground`) cubre toda el área de contenido — void + glow radial + grid sutil. Ningún negro plano.
- El **sidebar** ancla la izquierda (capa `zSidebar`).
- El **title bar** corona el área de contenido (capa `zTitleBar`).
- El **contenido** (`navigationShell`) ocupa el resto, sobre el fondo, en la capa `zContent`.

Las transiciones tienen causa (§3.1.4):
- **Entre tabs hermanos** (BOTS ↔ PLANTILLAS ↔ PAGOS ↔ TIENDA ↔ AJUSTES): no hay relación jerárquica de «adelante/atrás», así que es un **crossfade puro** — sin desplazamiento direccional.
- **Entrar a un detalle** (`/dashboard` → `/dashboard/detail/:botId`): es ir «hacia adentro» → el detalle **entra deslizándose desde la derecha** con fade.
- **Volver del detalle** al dashboard: el inverso — el dashboard reaparece desde la izquierda con fade.

El `IndexedStack` interno del `StatefulShellRoute` preserva el estado y el scroll de cada rama: volver a un tab lo muestra tal como se dejó.

---

## 5. Especificación visual / estructural

### 5.1 Composición del shell

```
Scaffold (backgroundColor: AppColors.background)
└─ Row
   ├─ Sidebar()                         // ancho fijo AppDimens.sidebarWidth
   └─ Expanded
      └─ Column
         ├─ CustomTitleBar(breadcrumb, systemStatus)   // alto 36 px
         └─ Expanded
            └─ Stack
               ├─ AppBackground()                       // capa de fondo, llena el Stack
               └─ _ShellTransitionSwitcher(navigationShell)  // contenido
```

- El `Scaffold.backgroundColor` se fija a `AppColors.background` para que ningún borde muestre blanco/gris.
- El `Sidebar` mantiene su ancho propio (prompt 19); el shell no lo redimensiona.
- El `CustomTitleBar` recibe dos datos del shell: el `breadcrumb` (derivado de la ruta activa) y el `SystemStatus` (derivado de `connectivityProvider`).
- El `AppBackground` se posiciona como `Positioned.fill` dentro del `Stack` del área de contenido — queda **debajo** del contenido, sólo cubre la zona a la derecha del sidebar y debajo del title bar.

### 5.2 Z-index de las capas

Según §6.5 del archivo 00, de atrás hacia adelante:

| Capa | Token z | Notas |
|---|---|---|
| `AppBackground` (void + glow + grid) | `zBase` (0) | Fondo del área de contenido. |
| `navigationShell` (contenido de pantalla) | `zContent` (10) | Sobre el fondo. |
| Toolbars sticky internas de cada vista | `zSticky` (20) | Las gestiona cada vista, no el shell. |
| `Sidebar` | `zSidebar` (30) | A la izquierda, por encima del contenido si hubiera solape. |
| `CustomTitleBar` | `zTitleBar` (40) | Corona el contenido. |
| Scrims de modal | `zOverlay` (100) | Sobre todo el shell. |
| Modales | `zModal` (110) | — |
| Toasts / Connectivity HUD | `zToast` (200) | Sobre modales. |

En la práctica, como `Row`/`Column` no se solapan, el orden de árbol ya respeta esto; los tokens `z*` se usan en los `Stack`/overlays. El shell no introduce solapes inesperados.

### 5.3 Safe padding y tamaños

- App de escritorio: no hay notch/safe area de mobile. El único «safe padding» relevante es no dejar que el contenido quede tapado por el title bar — ya resuelto porque el title bar es un hermano en `Column`, no un overlay.
- El contenido (`navigationShell`) recibe el tamaño exacto del `Expanded` inferior. El **padding de pantalla** (`AppDimens.space32` horizontal, §6.1) lo aplica **cada vista**, no el shell; el shell entrega el lienzo limpio.
- Tamaño mínimo de ventana: 1024×600 (fijado por `window_manager` en `main.dart`). El shell debe verse correcto ahí: sidebar 84 px + title bar 36 px + resto para contenido. Verificar que el contenido nunca colapse a ancho negativo.

### 5.4 Breadcrumb y SystemStatus para el title bar

- **Breadcrumb:** el shell mapea la ruta activa (`GoRouterState`) a una cadena en mayúsculas: `/dashboard` → `HANGAR`; `/dashboard/detail/:botId` → `HANGAR / UNIT-{id corto}`; `/bots` → `PLANOS`; `/billing` → `FACTURACIÓN`; `/store` → `TIENDA`; `/settings` → `PROTOCOLO`. Se pasa a `CustomTitleBar` ya formateada.
- **SystemStatus:** el shell observa `connectivityProvider` y traduce `isOnline` → `SystemStatus.operational` / `SystemStatus.offline`. El `CustomTitleBar` pinta el punto en consecuencia.

### 5.5 Connectivity HUD

- La escucha de `connectivityProvider` se mantiene en `MainLayout`, pero los snackbars «tácticos» con hex/`Courier` se reemplazan por el componente del **prompt 61** (Connectivity HUD). Este prompt 20 sólo deja el `ref.listen` y delega la presentación al prompt 61; no se inventa UI de toast acá.

---

## 6. Transiciones de ruta

### 6.1 Crossfade entre tabs hermanos

- En `app_router.dart`, reemplazar los `NoTransitionPage` de los 5 destinos por `CustomTransitionPage` con `transitionsBuilder` que aplique **sólo** `FadeTransition`.
- Duración: `AppMotion.durBase` (240 ms). Curva: `AppMotion.easeStandard`.
- Sin desplazamiento: tabs hermanos no tienen relación adelante/atrás, así que cualquier slide sería movimiento sin causa (§3.1.4).
- Alternativa equivalente y preferida si se quiere preservar el `IndexedStack`: en lugar de transición de página, envolver `navigationShell` en `MainLayout` con un `AnimatedSwitcher` que reaccione al cambio de `navigationShell.currentIndex` aplicando un crossfade `durBase`. El `IndexedStack` de `StatefulShellRoute` ya preserva el estado; el `AnimatedSwitcher` sólo cruza la opacidad de la rama saliente y entrante. Esta es la implementación recomendada (`_ShellTransitionSwitcher`).

### 6.2 Slide al entrar/salir del detalle

- El detalle `/dashboard/detail/:botId` deja de usar `builder` directo y pasa a `CustomTransitionPage`.
- **Entrar** (push del detalle): el detalle entra con `SlideTransition` desde la derecha — `Offset(0.04, 0)` → `Offset.zero` (16 px sobre un ancho típico; usar fracción para que escale) combinado con `FadeTransition` 0→1. Duración `AppMotion.durSlow` (320 ms), curva `AppMotion.easeEntrance`.
- **Volver** (pop al dashboard): la transición inversa — el detalle sale hacia la derecha (`secondaryAnimation` mueve el dashboard ligeramente a la izquierda `Offset(-0.04,0)` con fade). La salida dura ~65 % de la entrada → ≈ 210 ms (`durBase`), curva `easeExit`.
- El desplazamiento es de **16 px** efectivos (§7.3 archivo 00): expresarlo como fracción del ancho para mantener la magnitud visual.

### 6.3 Distinción tab vs detalle

- El `_ShellTransitionSwitcher` (§6.1) gobierna sólo el cambio entre ramas hermanas → crossfade puro.
- La transición de detalle ocurre **dentro** de la rama 1 (Dashboard tiene una sub-ruta), gobernada por el `CustomTransitionPage` del `GoRoute` del detalle → slide direccional.
- Resultado: cambiar de PAGOS a TIENDA = crossfade; abrir una unidad desde el hangar = slide desde la derecha; volver = slide inverso. Coherente con la jerarquía real de navegación.

### 6.4 Preservación de scroll y estado

- `StatefulShellRoute.indexedStack` ya mantiene vivas las 5 ramas en un `IndexedStack`: el scroll y el estado de cada tab se preservan automáticamente al cambiar de tab y volver.
- Para el detalle: al volver del detalle al dashboard, el dashboard sigue montado (es la rama padre) → su `ScrollController` conserva la posición. No se debe recrear la vista del dashboard al hacer pop.
- No usar `key`s que fuercen rebuild de las ramas. El `_ShellTransitionSwitcher` debe cruzar opacidad **sin** desmontar el `IndexedStack` interno (si se usa `AnimatedSwitcher`, darle como `child` el `navigationShell` con una `ValueKey(currentIndex)` sólo para detectar el cambio, cuidando que el `IndexedStack` subyacente siga vivo — o preferir un `AnimatedOpacity` doble manual para no desmontar nada).

---

## 7. Animaciones

- **Transición entre tabs:** crossfade `durBase` (240 ms), `easeStandard`. Sin slide.
- **Entrar a detalle:** slide-desde-derecha 16 px + fade, `durSlow` (320 ms), `easeEntrance`.
- **Volver de detalle:** slide-hacia-derecha + fade inverso, ≈ `durBase` (≈ 65 % de la entrada), `easeExit`.
- **Aparición inicial del shell** (tras login): el `AppBackground` aparece primero; sidebar y title bar entran con un fade `durSlow`; el contenido de la primera pantalla anima según su propio prompt. El shell no debe encadenar animaciones largas (>500 ms).
- **Reduced-motion (`AppMotion.reduced`):** todas las transiciones de ruta — tanto crossfade de tabs como slide de detalle — se reducen a un **crossfade de 120 ms** sin desplazamiento. El `AppBackground` no anima blobs/parallax. Verificar leyendo `MediaQuery.disableAnimations` o `AppMotion.reduced`.
- Las transiciones nunca bloquean el input ni animan `width`/`height`/`top`/`left` directos: usar `FadeTransition`/`SlideTransition` (`Transform` interno).

---

## 8. Accesibilidad

- El shell mantiene una estructura de navegación estable: sidebar + title bar nunca desaparecen entre pantallas (§3.2).
- Orden de foco global: title bar (controles de ventana) → sidebar (destinos) → contenido de la pantalla. Coincide con el orden visual.
- Las transiciones de ruta no atrapan el foco: al completar la transición, el foco pasa al contenido de la nueva pantalla (primer elemento foco-able o el encabezado `PageTitle`).
- Respetar `MediaQuery.disableAnimations` en TODAS las transiciones (crossfade 120 ms).
- El fondo ambiental (`AppBackground`) es decorativo: marcarlo `ExcludeSemantics` para que no contamine el árbol de accesibilidad.
- Contraste: el contenido siempre se renderiza sobre `AppBackground`, cuyo punto más claro (`bgElevated01`) garantiza que el texto `textPrimary`/`textSecondary` mantenga ≥ 4.5:1.
- La salida de cualquier pantalla siempre está disponible vía sidebar; no hay estados sin escape.

---

## 9. Checklist de aceptación

- [ ] `MainLayout` compone `Row[ Sidebar, Expanded( Column[ CustomTitleBar, Expanded( Stack[ AppBackground, contenido ] ) ] ) ]`.
- [ ] Usa el `CustomTitleBar` público (prompt 18); el `_CustomTitleBar` privado fue eliminado.
- [ ] El área de contenido tiene fondo ambiental `AppBackground`; ningún negro/gris plano visible.
- [ ] `Scaffold.backgroundColor` = `AppColors.background`.
- [ ] El shell pasa al title bar el breadcrumb derivado de la ruta y el `SystemStatus` derivado de `connectivityProvider`.
- [ ] Los z-index siguen los tokens `z*` de §6.5; sin solapes inesperados.
- [ ] El padding de pantalla lo aplican las vistas, no el shell; el shell entrega lienzo limpio.
- [ ] Tabs hermanos: transición crossfade puro `durBase` + `easeStandard`, sin slide.
- [ ] Entrar a detalle: slide-desde-derecha 16 px + fade `durSlow` + `easeEntrance`.
- [ ] Volver de detalle: slide inverso + fade, ≈ 65 % de la duración de entrada, `easeExit`.
- [ ] El estado y el scroll de cada tab se preservan al cambiar de tab y volver (`IndexedStack` intacto, sin rebuild forzado).
- [ ] El dashboard conserva su scroll al volver del detalle.
- [ ] Los snackbars de conectividad se delegan al prompt 61; sin UI de toast con `Courier`/hex en `MainLayout`.
- [ ] Reduced-motion: todas las transiciones a crossfade 120 ms, sin desplazamiento, sin parallax.
- [ ] `AppBackground` envuelto en `ExcludeSemantics`.
- [ ] Cero hex sueltos, cero magic numbers; sólo tokens del archivo 00.
- [ ] `flutter analyze` sin warnings nuevos; el shell se ve correcto en 1280×720 y en 1024×600.

---

## 10. Dependencias

Deben estar completados antes de ejecutar este prompt:

- **01** — Tokens de color (`background`, `bgElevated01`).
- **03** — Tokens de dimensión (`AppDimens.space32`, `sidebarWidth`, alto de title bar, escala `z*`).
- **04** — Sistema de motion (`AppMotion`: `durBase`, `durSlow`, `easeStandard`, `easeEntrance`, `easeExit`, `reduced`).
- **08** — Fondo de aplicación (`AppBackground`).
- **18** — Custom title bar (`CustomTitleBar` público, `SystemStatus`).
- **19** — Sidebar de navegación (`Sidebar`, `AppDimens.sidebarWidth`).

Se integra con: **21** (PageTitle, encabezado dentro del lienzo que entrega el shell), **61** (Connectivity HUD, presentación de los avisos de red), y toda la Fase D-G (las vistas que el shell aloja).
