# 59 — Billing · Invoice List

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.

---

## 1. Objetivo

Rediseñar `InvoiceList` para que el historial de facturas se sienta una **tabla de registro HUD**: header de columnas en `label`, filas con fecha en mono, monto en cifras tabulares alineadas, `StatusTag` de estado, botón de descarga `AppIconButton`, hover de fila, orden por columna con indicador, y estados vacío/carga pulidos. La densidad de datos no debe sacrificar el factor premium.

---

## 2. Archivos

- `lib/features/billing/presentation/widgets/invoice_list.dart` — reescritura visual; lógica conservada (paginación por cursor, scroll infinito, expansión de ítems, `onDownloadPdf`, `invoicesRepositoryProvider`).

---

## 3. Estado actual

`ListView.builder` de `_InvoiceRow`: `InkWell` con chevron `AnimatedRotation`, número + período, monto, `_StatusChip` y `IconButton` de descarga, separados por `Divider`. Detalle expandible con `_ItemsDetail`. `_StatusChip` usa **colores Material claros hardcodeados** (`0xFFE8F5E9`, `0xFF2E7D32`, etc.) pensados para fondo blanco — incoherentes con el tema oscuro. Skeleton `_SkeletonList` de 6 `_SkeletonRow` con `_Bone` gris plano sin shimmer. Estado vacío `BillingEmptyState` con ícono `receipt_long`. Estado de error básico. Sin header de columnas, sin orden, sin alineación tabular, tipografía vía `Theme.textTheme` genérico.

---

## 4. Visión del rediseño

La lista es un **registro de facturación de la terminal**. Arriba, un **header de columnas fijo** con etiquetas técnicas (`FECHA`, `MONTO`, `ESTADO`, `·`) en `label` `textSecondary`, sobre `surfaceHud`, con `HudDivider` debajo. Cada factura es una **fila HUD** con `HudDivider` hairline entre filas (no `Divider` Material): la fecha en `mono`, el monto a la derecha en `hudReadout` con figuras tabulares perfectamente alineado en columna, un `StatusTag` (pagada/pendiente/fallida/anulada) en colores del tema oscuro, y un `AppIconButton` de descarga. En hover, la fila eleva su fondo a `surfaceRaised` y un `HudReactorBar` lateral fino se enciende. El header permite ordenar por columna; la columna activa muestra una flecha de orden. Vacío y carga reciben tratamiento premium: skeleton con shimmer, `EmptyState` «SIN FACTURAS».

---

## 5. Especificación visual

### 5.1 Header de columnas (alto 36 px, sticky al tope de la lista)

- Fondo `surfaceHud`, padding horizontal `space16`.
- `Row` con anchos fijos (ver §5.3):
  - **FECHA** — flex, alineado a la izquierda.
  - **MONTO** — ancho 120 px, alineado a la derecha.
  - **ESTADO** — ancho 110 px, centrado.
  - **·** (descarga) — ancho 48 px.
- Etiquetas en `label` `textSecondary` UPPERCASE.
- Cada etiqueta de columna ordenable es un botón: al activarse muestra una flecha `arrow_upward`/`arrow_downward` 12 px en `gold` a su lado; las inactivas sin flecha.
- `HudDivider` con nodo brillante debajo del header.

### 5.2 Fila de factura (`_InvoiceRow`, alto ~56 px colapsada)

- `Stack`: barra lateral `HudReactorBar` vertical de 2 px en el borde izquierdo (apagada en reposo, encendida en hover) + contenido.
- Padding horizontal `space16`, vertical `space12`.
- `Row`:
  - **Chevron** de expansión `chevron_right` 18 px `textTertiary`, `AnimatedRotation` 0→0.25.
  - **Columna FECHA** (flex): `invoice.number` en `bodyM` `textPrimary` `w600`; debajo el período en `mono` `textTertiary`.
  - **Columna MONTO** (120 px, derecha): monto en `hudReadout` mono con `FontFeature.tabularFigures()`, `textPrimary`.
  - **Columna ESTADO** (110 px, centro): `StatusTag` (prompt 11).
  - **Columna descarga** (48 px): `AppIconButton` `download` 18 px; habilitado solo si `pdfUrl != null && onDownloadPdf != null`, si no `disabled` (opacidad 0.4).
- Entre filas: `HudDivider` hairline (`borderSubtle`), sin nodo.
- Detalle expandido `_ItemsDetail`: fondo `bgElevated01`, padding horizontal `space24`; cada `_ItemLine` con descripción `bodyS` `textSecondary`, cantidad×precio en `mono` `textTertiary`, importe en `hudReadout` `textPrimary` alineado a la columna MONTO.

### 5.3 `StatusTag` por estado (colores del tema oscuro — reemplazan los hex Material)

| `InvoiceStatus` | Token color | Ícono | Label |
|---|---|---|---|
| `paid` | `success` | `check_circle` | PAGADA |
| `open` | `warning` | `schedule` | PENDIENTE |
| `voided` | `textTertiary` | `block` | ANULADA |
| `uncollectible` | `danger` | `warning` | INCOBRABLE |
| `draft` | `info` | `edit` | BORRADOR |

`StatusTag`: pill `radiusPill`, fondo color@0.12, borde color@0.3, ícono 12 px + texto `labelSmall` del color, padding `space8`/`space2`.

### 5.4 Estado vacío

- `EmptyState` unificado (prompt 15): ícono `receipt_long` 48 px en cápsula tenue, título «SIN FACTURAS» en `titleM`, subtítulo «Aparecerán acá cuando se emita la primera» en `bodyS` `textSecondary`. Centrado, sin acción (no hay acción posible).

### 5.5 Estado de carga

- Header de columnas visible (real).
- 6 filas `SkeletonBase` (prompt 14): bloque de fecha, bloque de monto a la derecha, bloque de status pill, todos con shimmer `gradGoldSheen`. `HudDivider` entre skeletons.

### 5.6 Estado de error

- `ErrorFeedbackCard` (prompt 16) centrado: ícono, mensaje «No pudimos cargar las facturas», `AppButton` `ghost` «Reintentar» → `_loadFirst`.

### 5.7 Carga incremental (footer de scroll infinito)

- Al cargar la página siguiente: fila-footer con un `HudReactorBar` horizontal animado o spinner mono pequeño + texto `mono` `textTertiary` «cargando…», padding `space20`.

---

## 6. Estados e interacciones (matriz §9)

| Estado | Qué cambia |
|---|---|
| `default` | Fila en reposo, fondo transparente, barra lateral apagada. |
| `hover` (fila) | Fondo a `surfaceRaised`, barra lateral `HudReactorBar` encendida (`gold` tenue), cursor pointer, `durFast`. |
| `pressed` (fila) | Fondo un paso más profundo, `durInstant`. |
| `focused` (fila/botón) | Anillo 2 px `cyan` (fila), `gold` (descarga). |
| `expanded` | Chevron rotado, detalle de ítems visible con `AnimatedSize`. |
| `selected` (columna de orden) | Etiqueta de columna en `gold` + flecha de dirección. |
| `loading` (primera carga) | `_SkeletonList` con shimmer. |
| `loading` (paginación) | Footer con barra/spinner mono. |
| `disabled` (descarga) | `AppIconButton` opacidad 0.4 si no hay `pdfUrl`. |
| `empty` | `EmptyState` «SIN FACTURAS». |
| `error` | `ErrorFeedbackCard` con reintento. |

---

## 7. Animaciones

- **Entrada de filas:** escalonado de 36 ms por fila (fade + translateY 12 px), máximo ~10 filas; las siguientes aparecen sin escalonado.
- **Hover de fila:** fondo y barra lateral suben en `durFast` `easeStandard`.
- **Expansión:** `AnimatedSize` con `durBase`, `easeStandard`; chevron rota `durFast`.
- **Skeleton:** shimmer `gradGoldSheen` cada ~3000 ms.
- **Orden:** al reordenar, las filas hacen un crossfade `durBase` (no reflow brusco).
- **Reduced motion:** sin shimmer (skeleton estático), sin escalonado de entrada, hover sin glow animado (cambio instantáneo de fondo); expansión = crossfade 120 ms.

---

## 8. Accesibilidad

- Cada fila: `Semantics(button:true, expanded:, label:)` con la descripción «Factura {período} por {monto} — Estado: {estado}» (conservar la lógica actual).
- `StatusTag` con `Semantics(label:)`; estado = color + ícono + texto.
- `AppIconButton` de descarga: `Semantics`/`tooltip` «Descargar factura PDF de {período}»; `enabled` refleja disponibilidad.
- Header de columnas ordenables: cada uno es un botón con `Semantics` que anuncia el criterio y la dirección de orden.
- Contraste: monto `textPrimary` sobre fondo de fila y `StatusTag` ≥ 4.5:1; verificar cada color de estado.
- Targets de hit ≥ 32×32 px (descarga ya envuelta en área cómoda).
- Foco visible; orden de foco: chevron/fila → descarga, fila por fila.

---

## 9. Checklist de aceptación

- [ ] Header de columnas HUD (`FECHA`, `MONTO`, `ESTADO`, `·`) con orden por columna e indicador de dirección.
- [ ] Filas con `HudDivider` hairline (no `Divider` Material); fecha en `mono`, monto en `hudReadout` con figuras tabulares alineadas en columna.
- [ ] `_StatusChip` reemplazado por `StatusTag` con colores del tema oscuro; **todos los hex Material claros eliminados**.
- [ ] Hover de fila con barra lateral `HudReactorBar` y elevación de fondo.
- [ ] Skeleton con shimmer; footer de paginación HUD.
- [ ] Estado vacío `EmptyState` «SIN FACTURAS»; estado de error `ErrorFeedbackCard` con reintento.
- [ ] Anchos de columna fijos definidos (MONTO 120, ESTADO 110, descarga 48); alineaciones correctas.
- [ ] Espaciados/radios por token; cero magic numbers; cero `Theme.textTheme` genérico (usar tokens de tipografía).
- [ ] Reduced-motion respetado.
- [ ] `flutter analyze` sin warnings nuevos; se ve bien en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01–08 (color, tipografía + mono, dimensiones, motion, iconos, HUD: divider/reactor bar/brackets, glow/glass, fondo).
- **Componentes núcleo:** 09 (`AppIconButton`, `AppButton`), 11 (`StatusTag`), 12 (`HoloPanel` — base de las filas si se usa mini-panel), 14 (`SkeletonBase`), 15 (`EmptyState`), 16 (`ErrorFeedbackCard`).
- **Billing:** 47 (shell de billing).
