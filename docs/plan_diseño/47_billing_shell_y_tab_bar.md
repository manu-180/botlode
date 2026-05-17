# 47 — Billing · Shell y tab bar de facturación

> Depende de **00_README_VISION_Y_SISTEMA_DE_DISENO.md**. Si algo contradice al 00, gana el 00.

---

## 1. Objetivo

Rediseñar el contenedor de la pantalla de facturación (`BillingView`) y su barra de 4 tabs (Plan · Métodos de Pago · Facturas · Historial) para que deje de ser una `AppBar` Material 3 plana y se convierta en el «Centro de Crédito» del Hangar OS: fondo ambiental, encabezado HUD, tab bar con indicador deslizante y transiciones de contenido coherentes. Es el shell que hospeda a los prompts 48–60.

---

## 2. Archivos

- **Modificar:** `lib/features/billing/presentation/views/billing_view.dart`
- **Crear:** `lib/features/billing/presentation/widgets/billing_tab_bar.dart` (tab bar HUD reutilizable interno del feature)
- **Consumir (no modificar):** `lib/core/ui/background/app_background.dart` (prompt 08), `lib/core/ui/shell/page_title.dart` (prompt 21), `lib/core/ui/hud/` (prompt 06), `lib/core/config/theme/` (prompts 01–04).

---

## 3. Estado actual

`BillingView` es un `Scaffold` con `AppBar` Material 3 cuyo `title` es texto plano y cuyo `bottom` es un `TabBar` estándar con ícono + texto. El `body` resuelve `billingV2Provider` con `.when()`: `loading` muestra un `CircularProgressIndicator.adaptive` centrado; `error` muestra un ícono rojo + texto + `FilledButton` de reintento; `data` arma `_BillingTabsBody`, que coloca `DunningWarningBanner` y `TrialCountdownBanner` encima de un `TabBarView`. En desktop el contenido se centra y se limita a `maxWidth: 960`. Las 4 tabs son en gran parte stubs con `_PlaceholderCard`. No hay fondo ambiental, ni ornamento HUD, ni transición premium entre tabs: es funcional pero plano.

---

## 4. Visión del rediseño

La pantalla se siente como una **consola de facturación de la terminal industrial**. El fondo es el `AppBackground` ambiental (vacío + glow radial dorado tenue + grid). Arriba, un `PageTitle` estilo techBar con el rótulo **«CENTRO DE CRÉDITO»** (label mono superior `// FACTURACIÓN`) y un `HudDivider` que lo separa del resto. Debajo cuelgan los banners condicionales (trial/dunning, prompt 60). El elemento estrella es la **tab bar HUD**: cuatro segmentos en una pista biselada con un indicador dorado deslizante — exactamente el mismo lenguaje visual que el tab bar del bot detail (prompt 30), para coherencia milimétrica. El contenido de cada tab entra con un crossfade + slide direccional sutil. Todo respira: nada chillón, profundidad por capas, oro reservado al indicador activo y a los acentos.

---

## 5. Especificación visual

### 5.1 Estructura general (capa por capa)

`BillingView` deja de usar `AppBar`. La jerarquía es:

```
Scaffold (backgroundColor: transparent)
└─ AppBackground            // capa ambiental, prompt 08
   └─ SafeArea
      └─ Column
         ├─ PageTitle (techBar)           // encabezado
         ├─ Gap space24
         ├─ BillingTabBar                 // tab bar HUD
         ├─ Gap space16
         ├─ DunningWarningBanner / TrialCountdownBanner   // banners condicionales (prompt 60)
         └─ Expanded → _BillingTabContent // contenido de la tab activa
```

- `Scaffold.backgroundColor` = `Colors.transparent`; el color real lo pone `AppBackground`.
- Padding horizontal de pantalla: `space32` a cada lado en desktop; `space20` cuando el ancho < 720.
- El contenido de cada tab se centra y se limita a `maxWidth: 1040` (sube de 960 para acomodar la fila de 3-4 planes del prompt 49). Por debajo de 1040 ocupa el ancho disponible.

### 5.2 Encabezado — `PageTitle` techBar

- Usar el estilo techBar de `PageTitle` (prompt 21): label mono superior `hudReadout`/`mono` en `textTertiary`, texto `// FACTURACIÓN`.
- Título principal **«CENTRO DE CRÉDITO»** con `displayM` (26/700) en `textPrimary`, tracking +1.0.
- A la derecha del título, opcional: un `HudIdTag` con el estado global de la suscripción (ej. `SUB · ACTIVA`) en `mono`, color tintado según estado (ver §5.6). Solo si hay suscripción.
- Debajo, `HudDivider` horizontal a todo el ancho del contenido, con nodo brillante y, opcionalmente, etiqueta mono `// MÓDULOS`.

### 5.3 Tab bar HUD — `BillingTabBar`

Componente nuevo en `billing_tab_bar.dart`. Recibe `TabController` y la lista de 4 ítems (`{icon, label}`). Mismo lenguaje que el tab bar del bot detail (prompt 30):

- **Pista (track):** `Container` con fondo `surfaceHud`, borde hairline `borderDefault` 1 px, radio `radiusM` (14). Altura fija **48 px**. Padding interno `space4` en todos los lados (el indicador respira dentro de la pista).
- **Segmentos:** 4 segmentos de ancho igual (`Expanded`), cada uno con ícono 16 px + label `label` (13/600 UPPERCASE, tracking +1.4). En desktop ícono y texto en fila; si el ancho del segmento < 132 px, solo ícono + tooltip.
  - Iconos: `Plan` → `Icons.workspace_premium_outlined`; `Métodos de Pago` → `Icons.credit_card_outlined`; `Facturas` → `Icons.receipt_long_outlined`; `Historial` → `Icons.history_outlined`.
- **Indicador deslizante:** un `AnimatedPositioned`/`AnimatedAlign` de pastilla que se desliza bajo el segmento activo. Relleno `gradPanel` con tinte dorado: fondo `surfaceRaised`, borde `borderGold` 1 px, radio `radiusS` (10), sombra `glowGold` muy suave (blur reducido a ~14). El indicador es la única superficie con oro estable en la pista.
- **Texto del segmento:** activo → `textPrimary` peso 700; inactivo → `textSecondary` peso 600; hover inactivo → `textPrimary` con `durFast`.
- El tab bar es sticky conceptualmente (siempre visible), pero no necesita `SliverPersistentHeader` porque el contenido scrollea internamente por tab. z-index `zSticky`.

### 5.4 Contenido de tab — `_BillingTabContent`

Reemplaza `_ResponsiveTabView`. Sigue usando `TabBarView` con `controller`, pero:

- Cada tab es un `SingleChildScrollView` con padding `space24` y `crossAxisAlignment.start`.
- El título interno de cada tab (`Text` con `titleLarge`) se reemplaza por un encabezado de sección con `titleM` (17/600) en `textPrimary` + `HudDivider` corto debajo.
- Tab 0 (Plan): apila `SubscriptionSummaryCard` (prompt 50), `PlanPicker` (prompt 49), `AutoPaySettingsCard` (prompt 58), con `space24` entre bloques.
- Tab 1 (Métodos de Pago): apila `DigitalCard` (prompt 48) y un `AppButton` secundario «GESTIONAR MÉTODOS» que abre `ManageCardsModal` (prompt 53).
- Tab 2 (Facturas): `InvoiceList` (prompt 59).
- Tab 3 (Historial): lista de `billing_events` (fuera de alcance de este prompt; mostrar `EmptyState` mientras sea stub).
- Los `_PlaceholderCard` y `_EmptyStatePill` actuales se eliminan en favor de los componentes reales o de `EmptyState` (prompt 15).

### 5.5 Estado loading de la pantalla

El `loading` de `billingV2Provider.when` ya no es un spinner pelado. Mostrar el shell completo (background + PageTitle + tab bar deshabilitado) y, en el área de contenido, un **skeleton** (prompt 14): para la tab Plan, un skeleton de `SubscriptionSummaryCard` (panel de ~180 px) + 3 rectángulos de tarjeta de plan. Para las demás tabs, 3-4 filas skeleton. La tab bar se muestra con opacidad 0.5 y no responde a toques durante el loading.

### 5.6 Tinte del estado global

El `HudIdTag` del encabezado y el color de acento del banner usan: `active` → `success`; `trialing` → `info`/`cyan`; `pastDue`/`incomplete` → `warning`; `canceled` → `danger`. El estado nunca se comunica solo por color: el tag siempre lleva texto (`ACTIVA`, `TRIAL`, etc.).

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` | Tab bar en reposo, indicador bajo la tab activa. |
| `hover` (segmento inactivo) | Texto pasa a `textPrimary`, aparece un glow muy tenue bajo el segmento, cursor pointer. `durFast`. |
| `pressed` (segmento) | Escala 0.97 del segmento, `durInstant`. |
| `focused` | Segmento con anillo de foco 2 px `cyan`; navegable con `Tab`/flechas. El orden de foco sigue el orden visual. |
| `selected/active` | Indicador deslizado bajo el segmento, texto 700 `textPrimary`. |
| `loading` | Tab bar a opacidad 0.5, no interactiva; área de contenido con skeleton. |
| `error` | `billingV2Provider` en error: el shell se mantiene; el área de contenido muestra `ErrorFeedbackCard` (prompt 16) con mensaje y botón «REINTENTAR» que invalida `billingV2Provider`. |
| `empty` | Por tab: cada tab maneja su propio `empty` con `EmptyState` (sin plan, sin métodos, sin facturas). |
| `disabled` | No aplica al shell completo. |

Interacciones de teclado: flechas izquierda/derecha mueven entre tabs cuando el foco está en la tab bar; `Home`/`End` saltan a la primera/última. El estado de tab activa NO se persiste entre navegaciones (siempre arranca en Plan).

---

## 7. Animaciones

- **Entrada de la pantalla:** la transición de ruta la maneja `go_router` (prompt 20: fade + slide 16 px). El shell no añade animación de entrada propia salvo un fade-in de 120 ms del contenido.
- **Indicador de tab:** al cambiar de tab, el indicador se desliza con `durBase` (240 ms) y curva `easeStandard`. Es un movimiento de `transform`/posición, nunca de `width`/`height` del layout.
- **Cambio de contenido de tab:** crossfade de `durBase` + slide direccional de 12 px (tab a la derecha entra desde la derecha, a la izquierda desde la izquierda). Implementar con un `AnimatedSwitcher` o la transición nativa del `TabBarView` envuelta.
- **Hover de segmento:** glow + color suben con `durFast` (160 ms).
- **Skeleton:** shimmer estándar del prompt 14.
- **Reduced motion:** con `AppMotion.reduced` activo, el indicador salta sin deslizar (crossfade 120 ms), el cambio de tab es crossfade puro sin slide, sin shimmer en skeleton (skeleton estático).

---

## 8. Accesibilidad

- Cada segmento es un `Tab` semántico con `Semantics(label: 'Pestaña <nombre>', selected: <bool>)`. El `TabBarView` mantiene los `Semantics` por tab ya presentes.
- Contraste: texto de segmento activo `textPrimary` sobre `surfaceRaised` ≥ 12:1; inactivo `textSecondary` sobre `surfaceHud` ≥ 4.5:1; verificar.
- El estado de la suscripción en el `HudIdTag` lleva texto además de color.
- Foco visible 2 px `cyan` en cada segmento; nunca se elimina sin reemplazo.
- Targets clickeables: cada segmento ≥ 48 px de alto, ancho mínimo 32 px de área de hit.
- El botón «REINTENTAR» del estado error recibe foco automático cuando aparece el error.
- Banners de trial/dunning: ver prompt 60 para su semántica `liveRegion`.

---

## 9. Checklist de aceptación

- [ ] `BillingView` ya no usa `AppBar`; usa `AppBackground` + `PageTitle` techBar.
- [ ] El encabezado dice «CENTRO DE CRÉDITO» con label mono `// FACTURACIÓN` y un `HudDivider` debajo.
- [ ] Existe `billing_tab_bar.dart` con la tab bar HUD: pista `surfaceHud`, indicador deslizante dorado, 4 segmentos.
- [ ] El indicador se desliza al cambiar de tab con `durBase`/`easeStandard`.
- [ ] El cambio de contenido de tab usa crossfade + slide direccional 12 px.
- [ ] Los banners condicionales (prompt 60) se renderizan entre la tab bar y el contenido.
- [ ] El estado `loading` muestra el shell + skeletons, no un spinner pelado.
- [ ] El estado `error` muestra `ErrorFeedbackCard` con botón de reintento que invalida el provider.
- [ ] El contenido se limita a `maxWidth: 1040` y se centra en desktop.
- [ ] Se eliminaron `_PlaceholderCard` y `_EmptyStatePill`; cada tab usa componentes reales o `EmptyState`.
- [ ] Cero hex sueltos, cero magic numbers: todo por token.
- [ ] Reduced motion respetado (indicador salta, sin slide, sin shimmer).
- [ ] La pantalla se ve correcta en 1280×720 y en el mínimo 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (color), 02 (tipografía + mono), 03 (dimensiones), 04 (motion), 05 (iconografía), 06 (primitivas HUD: `HudDivider`, `HudIdTag`), 08 (`AppBackground`).
- **Componentes núcleo:** 09 (`AppButton`), 12 (`HoloPanel`), 14 (skeletons), 15 (`EmptyState`), 16 (`ErrorFeedbackCard`).
- **Shell:** 20 (transiciones de ruta), 21 (`PageTitle`).
- **Referencia de patrón:** 30 (tab bar del bot detail — mismo lenguaje visual).
- **Hospeda:** 48 (digital card), 49 (plan picker), 50 (summary card), 53 (manage cards), 58 (auto-pay), 59 (invoice list), 60 (banners).
