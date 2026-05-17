# 50 — Billing · Subscription Summary Card

> Depende de **00_README_VISION_Y_SISTEMA_DE_DISENO.md**. Si algo contradice al 00, gana el 00.

---

## 1. Objetivo

Rediseñar `SubscriptionSummaryCard` como el **panel de telemetría de la suscripción**: un `HoloPanel` con brackets de esquina que muestra el plan activo, su estado, una cuenta regresiva al próximo cobro, el monto de renovación en ticker y una barra de progreso del ciclo de facturación. Cuatro tratamientos de color según estado (activa / trial / past due / cancelada).

---

## 2. Archivos

- **Modificar:** `lib/features/billing/presentation/widgets/subscription_summary_card.dart`
- **Consumir (no modificar):** `lib/core/config/theme/` (01–04), `lib/core/ui/hud/` (06), `lib/core/ui/panels/holo_panel.dart` (12), `lib/core/ui/buttons/app_button.dart` (09), `lib/features/billing/presentation/widgets/empty_state.dart`.

---

## 3. Estado actual

`SubscriptionSummaryCard` (ConsumerWidget) lee `billingV2Provider`. `loading` → `_buildSkeleton` (caja 180 px `#0F0F13` con spinner); `error` → `SizedBox.shrink`; `data` sin suscripción → `BillingEmptyState`; con suscripción → `_CardBody`.

`_CardBody` es un `Container` `#0F0F13`, radio 16, borde de color según estado (`_borderColor`). Contiene: header («Tu suscripción» + `_StatusChip`), nombre del plan `titleLarge`, precio `primary`, `_InfoRow`s condicionales (trial restante, próximo cobro/finaliza, past due, incomplete) y una fila `Wrap` de `_ActionButton`s (cambiar plan, reactivar, actualizar pago, completar pago, cancelar).

Funciona, cubre todos los estados de suscripción, pero usa hex sueltos, es un `Container` plano sin ornamento HUD, no hay cuenta regresiva real ni barra de ciclo, y el monto no tiene protagonismo.

---

## 4. Visión del rediseño

El panel se siente como una **lectura de instrumentación del ciclo de facturación**. `HoloPanel` con `HudCornerBrackets` cuyo color refleja el estado. Arriba, el plan y un `StatusTag` HUD. En el cuerpo, dos lecturas grandes: el **monto de renovación** en `numericTicker` dorado y la **cuenta regresiva** al próximo cobro como lectura mono («14 D · 06 H»). El elemento distintivo es una **barra de ciclo HUD**: una pista horizontal segmentada que muestra cuánto del ciclo de facturación transcurrió, con un nodo brillante en la posición actual. Acciones abajo como `AppButton`s. Cada estado tiñe los acentos: activa = oro/verde, trial = cyan, past due = warning, cancelada = danger desaturado.

---

## 5. Especificación visual

### 5.1 Contenedor — `HoloPanel`

- `HoloPanel` (prompt 12): relleno `gradPanel`, radio `radiusL` (20), sombra `elev1`.
- Borde y `HudCornerBrackets` según estado (§5.6).
- Padding interno `space24`.
- Opcional: `HudGridTexture` de fondo a `opacity 0.04` para profundidad.

### 5.2 Header

- Fila `spaceBetween`.
- Izquierda: micro-label `labelSmall` UPPERCASE `textTertiary` «// SUSCRIPCIÓN», y debajo el **nombre del plan** en `titleL` (21/600) `textPrimary`.
- Derecha: `StatusTag` (prompt 11) con el estado — ícono + texto + color. Mapeo: `active` → variante `success` «ACTIVA»; `trialing` → variante `info`/`cyan` «TRIAL»; `pastDue` → variante `warning` «VENCIDA»; `canceled` → variante `danger` «CANCELADA»; `incomplete` → variante `warning` «INCOMPLETA». Si `cancelAtPeriodEnd` es true, el tag muestra «FINALIZA» en `warning`.

### 5.3 Bloque de lecturas (cuerpo)

Una fila (o columna en angosto) con dos lecturas HUD:

- **Monto de renovación:** label `labelSmall` `textTertiary` «PRÓXIMO COBRO»; valor en `numericTicker` (JetBrains Mono tabular, ~28, 700) `gold`, con prefijo `$` `titleM` y sufijo `/mes` o `/año` en `bodyS` `textSecondary`. Si no hay precio, mostrar «—».
- **Cuenta regresiva:** label `labelSmall` `textTertiary` «RENUEVA EN»; valor como `HudTicker`/lectura `hudReadout` mono — formato «14 D · 06 H» (días y horas hasta `currentPeriodEnd`). Si está cancelada/incompleta, este bloque se reemplaza por la fecha de finalización.
- Separar las dos lecturas con un `HudDivider` vertical fino.

### 5.4 Barra de ciclo HUD

- Una pista horizontal de 8 px de alto, ancho completo, radio `radiusPill`.
- Fondo de pista `surfaceHud` con borde `borderSubtle`.
- Relleno de progreso = porcentaje del ciclo transcurrido (`now - currentPeriodStart` sobre `currentPeriodEnd - currentPeriodStart`). Relleno con `gradGold` (activa) o el gradiente de estado correspondiente.
- Un **nodo brillante** (`HudStatusDot` pequeño con glow) en la posición actual del progreso — late suave en estado activo.
- Debajo, dos micro-labels `mono` en los extremos: a la izquierda la fecha de inicio del ciclo, a la derecha la fecha de fin (`d MMM`).
- En estado cancelada, la barra se desatura; en trial, la barra usa `cyan` y la etiqueta dice «TRIAL» en el centro.

### 5.5 Filas de información contextual (`_InfoRow`)

Mantener `_InfoRow` pero reestilizar: ícono 14 px + texto `bodyM`. Aparecen según estado:

- Trial: ícono `Icons.hourglass_top`, color `cyan`, «Trial: N días restantes».
- `cancelAtPeriodEnd`: ícono `Icons.event`, `warning`, «Tu suscripción finaliza el {fecha}».
- Past due: ícono `Icons.warning`, `danger`, «Cobro pendiente» en peso bold.
- Incomplete: ícono `Icons.lock_outline`, `warning`, «Pago incompleto — se requiere autenticación».

### 5.6 Tratamiento por estado

| Estado | Borde / brackets | Acento de barra y lecturas |
|---|---|---|
| `active` | `borderGold` 1 px, brackets `borderGold` | barra `gradGold`, monto `gold` |
| `trialing` | `cyan @ 0.4`, brackets `cyan` | barra `cyan`, label «TRIAL» en `cyan` |
| `pastDue` | `warning` 2 px, brackets `warning` | barra `warning`, `InfoRow` de alerta visible |
| `incomplete` | `warning` 2 px, brackets `warning` | igual que past due |
| `canceled` | `danger @ 0.4`, brackets `danger` | panel desaturado, barra apagada |
| `cancelAtPeriodEnd` | `warning @ 0.4` | barra `warning`, `StatusTag` «FINALIZA» |

### 5.7 Acciones

Fila `Wrap` de `AppButton`s (prompt 09), gap `space8`, separados del cuerpo por un `HudDivider` horizontal:

- «CAMBIAR PLAN» → `AppButton` primario (activa/trial).
- «REACTIVAR» → `AppButton` variante `success` (si `cancelAtPeriodEnd`).
- «ACTUALIZAR PAGO» → `AppButton` variante `warning` (past due).
- «COMPLETAR PAGO» → `AppButton` variante `warning` (incomplete).
- «CANCELAR» → `AppButton` variante peligro/ghost `danger` (activa/trial, si no está ya cancelando).

### 5.8 Estados vacío y loading

- Sin suscripción: `EmptyState` (prompt 15) con ícono `Icons.workspace_premium` en anillo HUD, título «Sin suscripción activa», subtítulo «Elegí un plan para comenzar», `AppButton` «VER PLANES».
- Loading: skeleton del panel (prompt 14) — `HoloPanel` con shimmer, bloques rectangulares simulando header, lecturas y barra. No un spinner pelado.
- Error: el shell (prompt 47) maneja el error de billing; aquí basta `SizedBox.shrink` o un skeleton si se prefiere coherencia.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` | Panel en reposo, brackets y barra según estado de suscripción. |
| `hover` (botones de acción) | Borde + glow del `AppButton` suben `durFast`. |
| `pressed` | `AppButton` a escala 0.97, `durInstant`. |
| `focused` | Cada acción con anillo de foco 2 px `cyan`. |
| `selected/active` | El estado de la suscripción se refleja en `StatusTag` + brackets + barra. |
| `loading` | Skeleton de panel con shimmer. |
| `disabled` | Si un callback de acción es null, ese botón no se renderiza (no se muestra deshabilitado). |
| `error` | Manejado por el shell; opcionalmente skeleton. |
| `empty` | `EmptyState` «Sin suscripción activa». |

---

## 7. Animaciones

- **Entrada:** fade + `translateY` 12 px, `durBase`, `easeEntrance`.
- **Monto de renovación:** al cargar y al cambiar, `HudTicker` que cuenta en `durTicker` (900 ms) con `easeTicker`.
- **Barra de ciclo:** el relleno se anima de 0 a su valor en `durSlow` (320 ms) con `easeStandard` al aparecer el panel.
- **Nodo de la barra:** en estado activo, late con pulso de opacidad 0.6↔1.0 a ~1600 ms (patrón reactor del 00 §7.3). No late en cancelada/past due.
- **Cuenta regresiva:** se actualiza cada minuto; el cambio de valor hace un micro-crossfade.
- **Cambio de estado de suscripción:** brackets y borde cambian de color con crossfade `durBase`.
- **Reduced motion:** sin ticker (el monto salta), la barra aparece a su valor final sin animar, el nodo no late.

---

## 8. Accesibilidad

- `MergeSemantics` en el grupo header (plan + estado + precio) para que el lector lo lea como una unidad, como en el actual.
- `StatusTag` con ícono + texto + color; nunca solo color.
- Contraste: nombre `titleL` `textPrimary` ≥ 12:1; monto `gold` ≥ 4.5:1; cuenta regresiva `hudReadout` `textPrimary` ≥ 4.5:1; labels `textTertiary` (decorativos, ≥ 3:1) — el dato real cumple holgado.
- La barra de ciclo expone `Semantics(value: 'Ciclo de facturación al X%')`.
- Cada `AppButton` de acción con `Semantics` de botón y label descriptivo.
- Foco visible 2 px `cyan`; orden de foco = orden visual.
- Targets ≥ 48 px de alto en las acciones.

---

## 9. Checklist de aceptación

- [ ] El panel se renderiza sobre `HoloPanel` con `HudCornerBrackets`.
- [ ] El nombre del plan en `titleL`; estado en `StatusTag` HUD con ícono + texto.
- [ ] Monto de renovación en `numericTicker` `gold` con ticker al cargar.
- [ ] Cuenta regresiva al próximo cobro como lectura `hudReadout` mono.
- [ ] Barra de ciclo HUD con relleno proporcional, nodo brillante y fechas de inicio/fin.
- [ ] Borde, brackets y barra cambian de color según estado (activa/trial/past due/cancelada/incomplete).
- [ ] Panel desaturado en estado cancelada.
- [ ] Acciones como `AppButton` con variantes correctas por estado.
- [ ] Estado vacío con `EmptyState`; loading con skeleton de panel (no spinner).
- [ ] El nodo de la barra late solo en estado activo.
- [ ] Cero hex sueltos, cero magic numbers: todo por token.
- [ ] `MergeSemantics` y `Semantics` correctos; estado por texto + color.
- [ ] Reduced motion respetado (sin ticker, barra sin animar, sin latido).
- [ ] Se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (color: `gradGold`, `gradPanel`, semánticos), 02 (tipografía: `titleL`, `numericTicker`, `hudReadout`, `labelSmall`), 03 (dimensiones: `radiusL`, `radiusPill`, `elev1`), 04 (motion: `durTicker`, `easeTicker`), 05 (iconografía), 06 (`HoloPanel` via 12, `HudCornerBrackets`, `HudDivider`, `HudTicker`, `HudStatusDot`, `HudGridTexture`).
- **Componentes núcleo:** 09 (`AppButton`), 11 (`StatusTag`), 12 (`HoloPanel`), 14 (skeleton), 15 (`EmptyState`).
- **Shell:** 47 (tab «Plan»). Relacionado: 49 (plan picker), 57 (cancel/reactivate flow), 60 (banners de estado).
