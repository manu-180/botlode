# 53 — Billing · Manage Cards Modal

> Depende de **00_README_VISION_Y_SISTEMA_DE_DISENO.md**. Si algo contradice al 00, gana el 00.

---

## 1. Objetivo

Rediseñar `ManageCardsModal` como el **panel de gestión de métodos de pago** del Hangar OS: un modal `HoloPanel` alto con header «GESTIÓN DE MÉTODOS», una lista scrolleable de tarjetas como mini-paneles HUD con menú contextual (predeterminada / eliminar con confirmación), botón de alta y estados vacío/carga.

---

## 2. Archivos

- **Modificar:** `lib/features/billing/presentation/widgets/manage_cards_modal.dart`
- **Consumir (no modificar):** `lib/core/config/theme/` (01–04), `lib/core/ui/hud/` (06), `lib/core/ui/panels/holo_panel.dart` (12), `lib/core/ui/buttons/app_button.dart` (09), `lib/core/ui/menus/` (13: menú contextual), `lib/features/billing/presentation/widgets/empty_state.dart` (15), `add_card_modal.dart` (prompt 51).

---

## 3. Estado actual

`ManageCardsModal` (ConsumerWidget) lee `billingV2Provider` con `.when()`: loading → caja 200 px con spinner; error → `SizedBox`; data → un `Container` `#09090B` radio 30, borde `white24`, sombra negra, `maxHeight` 70 % de pantalla, presentado como bottom sheet.

Contenido: header (columna «GESTIÓN DE MÉTODOS» micro-label + «Tus Tarjetas» título + `IconButton` close), una `ListView.separated` de `_buildCardItem`, y un `OutlinedButton` «agregar tarjeta». Cada `_buildCardItem` es un `Container` con relleno/borde según `isDefault`, mini-ícono de marca (`FaIcon`), número `•••• last4` en Courier, vencimiento, badge «PREDETERMINADA» y un `PopupMenuButton` con «Establecer como predeterminada» / «Eliminar». `_handleDelete` valida que no sea el único método con suscripción activa y confirma con un `AlertDialog`.

Lógica completa (guardas, confirmación), pero contenedor plano, ítems sin profundidad HUD, `PopupMenuButton` Material genérico, sin animación de entrada.

---

## 4. Visión del rediseño

El modal es una **consola de inventario de métodos de pago**. `HoloPanel` alto (max-height 70 %), con `HudCornerBrackets` y un header HUD. La lista es una pila de **mini-`HoloPanel`** — cada uno una «celda» de tarjeta con mini-logo de marca, número enmascarado en `mono`, vencimiento, un `StatusTag` «PREDETERMINADA» dorado si aplica, y un botón de menú que abre el menú contextual HUD (prompt 13) con «Marcar predeterminada» y «Eliminar» (destructiva, `danger`, con confirmación). Abajo, un `AppButton` «AÑADIR TARJETA». El scroll interno tiene fades en los bordes. Estado vacío con `EmptyState`; loading con skeletons de fila.

---

## 5. Especificación visual

### 5.1 Presentación y contenedor

- Presentación: centrado en desktop sobre scrim + `BackdropFilter` blur (igual que prompt 51); bottom sheet en < 600.
- `HoloPanel` (prompt 12) con `ChamferBorder` (`chamferM`), relleno `glassSurfaceStrong`, radio `radiusXL` (28), sombra `elev3`, `HudCornerBrackets` `borderGold`.
- `maxHeight` 70 % de la altura de pantalla; ancho máximo 480 px en desktop.
- Padding interno `space24` horizontal, `space24` vertical.

### 5.2 Header

- Fila `spaceBetween`.
- Izquierda, columna: micro-label `labelSmall` UPPERCASE `textTertiary` «// GESTIÓN DE MÉTODOS»; debajo, título «TUS TARJETAS» en `titleM` (17/600) `textPrimary`.
- Derecha: icon button `Icons.close` (prompt 09) con tooltip «Cerrar».
- `HudDivider` debajo del header.

### 5.3 Lista de métodos de pago

- `ListView.separated` con `shrinkWrap`, separador `space12`, dentro de un `Flexible` para que respete el `maxHeight`.
- El área de lista tiene **fades de scroll**: un degradé `surface→transparent` de ~16 px arriba y abajo (`ShaderMask` o overlay) para indicar contenido scrolleable.

### 5.4 Fila de tarjeta — mini-`HoloPanel`

Cada ítem es un mini-`HoloPanel`:

- Relleno `surfaceHud` (normal) o `gradPanel` con tinte dorado (`isDefault`), borde `borderDefault` 1 px (normal) o `borderGold` 1.5 px (`isDefault`), radio `radiusM` (14), padding `space16`.
- Fila horizontal:
  1. **Mini-logo de marca:** un recuadro 50×34, fondo `surface`, radio `radiusS`, con el `FaIcon` de la marca (`ccVisa`, `ccMastercard`, `ccAmex`, `ccDiscover`) o `Icons.credit_card` genérico, color `textSecondary` 20 px. `ExcludeSemantics`.
  2. Gap `space12`. Columna:
     - Número enmascarado «•••• {last4}» en `mono` (JetBrains Mono 14) `textPrimary` (o `gold` si `isDefault`).
     - Vencimiento + marca en `bodyS` `textTertiary` («VISA · 08/27»).
  3. `Spacer`.
  4. **`StatusTag`** «PREDETERMINADA» (variante `gold`) si `isDefault` — ícono `Icons.star` + texto.
  5. Botón de menú: icon button `Icons.more_vert` (prompt 09) que abre el menú contextual.

### 5.5 Menú contextual

- Usar el menú contextual HUD del prompt 13 (no `PopupMenuButton` Material plano).
- Ítems:
  - «Marcar como predeterminada» — solo si `!isDefault`. Ícono `Icons.star_outline`.
  - «Eliminar» — destructiva: texto `danger`, ícono `Icons.delete_outline` `danger`.
- Al elegir «Eliminar»: aplicar la guarda existente (no eliminar el único método con suscripción activa → mostrar toast/`SnackBar` HUD del prompt 17) y, si procede, abrir un **diálogo de confirmación HUD** (prompt 13/16): título «¿Eliminar este método?», cuerpo con la advertencia, botones «CANCELAR» (foco por defecto) / «ELIMINAR» (`AppButton` peligro `danger`).

### 5.6 Botón de alta

- `AppButton` variante secundaria/ghost dorada, ancho completo, alto 50, ícono `Icons.add_card`, texto «AÑADIR TARJETA».
- Cierra este modal y abre `AddCardModal` (prompt 51).
- Separado de la lista por un `HudDivider`.

### 5.7 Estados vacío y loading

- Vacío (`methods.isEmpty`): `EmptyState` (prompt 15) — ícono `Icons.credit_card_off` (aquí sí cabe, es ausencia de inventario, no error) o `Icons.add_card` en anillo HUD, título «Sin métodos de pago», subtítulo «Agregá una tarjeta para habilitar el cobro automático», `AppButton` «AÑADIR TARJETA».
- Loading: 2-3 skeletons de fila de tarjeta (prompt 14) con shimmer dentro del modal — no un spinner de 200 px.
- Error: `ErrorFeedbackCard` (prompt 16) dentro del modal con reintento, en lugar del `SizedBox` actual.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` | Lista de mini-paneles; el predeterminado destacado con borde `borderGold` + `StatusTag`. |
| `hover` (fila) | Borde sube a `borderStrong`, elevación +1, glow suave, cursor pointer. `durFast`. |
| `pressed` (fila / botones) | Escala 0.97, `durInstant`. |
| `focused` | Fila y botón de menú con anillo de foco 2 px `cyan`. Orden: cerrar → filas (cada una con su menú) → añadir. |
| `selected/active` | El método predeterminado: borde `borderGold`, `StatusTag` «PREDETERMINADA». |
| `loading` | Skeletons de fila con shimmer. |
| `disabled` | El ítem «Marcar predeterminada» no aparece para el método ya predeterminado. |
| `error` | `ErrorFeedbackCard` con reintento dentro del modal. |
| `empty` | `EmptyState` «Sin métodos de pago». |
| Eliminar último método con suscripción activa | Bloqueado: `SnackBar`/toast HUD `danger` explicando que primero hay que agregar otra tarjeta. |
| Confirmar eliminación | Diálogo de confirmación HUD; foco por defecto en «CANCELAR». |

---

## 7. Animaciones

- **Entrada del modal:** scrim fade-in `durBase`; panel scale 0.94 → 1.0 + fade con `springSoft`.
- **Salida:** scale + fade `durFast` (~65 %), `easeExit`.
- **Lista:** las filas entran escalonadas — 36 ms por ítem, fade + `translateY` 12 px, `easeEntrance`, máximo ~10 ítems.
- **Eliminar una tarjeta:** la fila sale con fade + `translateX` corto + colapso de altura `durBase`; las filas inferiores se reacomodan suavemente.
- **Marcar predeterminada:** la fila destino gana borde dorado + `StatusTag` con crossfade `durFast`; la fila que pierde el estado lo suelta en paralelo.
- **Hover de fila:** borde + glow `durFast`.
- **Reduced motion:** sin escalonado (filas aparecen juntas, fade 120 ms), sin colapso animado al eliminar (la fila desaparece directo), sin scale en la entrada del modal.

---

## 8. Accesibilidad

- El modal atrapa el foco; al cerrar, vuelve al elemento que lo abrió. Escape y scrim cierran.
- Header con `Semantics(header: true)`.
- Cada fila: `Semantics(label: 'Tarjeta terminada en {last4}, {marca}')`; el `StatusTag` y el menú aportan su propia semántica; mini-logo `ExcludeSemantics`.
- Botón de menú: `Semantics(label: 'Opciones para tarjeta terminada en {last4}')`.
- Ítem «Eliminar»: `Semantics(label: 'Eliminar tarjeta terminada en {last4}')`; el diálogo de confirmación con foco por defecto en la acción segura.
- Toast de bloqueo (último método): `Semantics`/`liveRegion` para que el lector lo anuncie.
- Contraste: número `mono` `textPrimary` ≥ 4.5:1; vencimiento `textTertiary` ≥ 3:1; `StatusTag` con ícono + texto.
- Foco visible 2 px `cyan`; orden de foco = orden visual.
- Targets ≥ 44 px en filas, botón de menú y CTA.

---

## 9. Checklist de aceptación

- [ ] El modal se presenta sobre scrim + `BackdropFilter` blur.
- [ ] Contenedor `HoloPanel` biselado, `radiusXL`, `maxHeight` 70 %, `HudCornerBrackets`.
- [ ] Header «GESTIÓN DE MÉTODOS» / «TUS TARJETAS» con `HudDivider`.
- [ ] Cada tarjeta es un mini-`HoloPanel`; la predeterminada con borde `borderGold` + `StatusTag`.
- [ ] Número en `mono`, vencimiento en `bodyS`, mini-logo de marca.
- [ ] Menú contextual HUD (prompt 13) con «Marcar predeterminada» / «Eliminar» (`danger`).
- [ ] Eliminar abre confirmación HUD; guarda del último método con suscripción activa preservada.
- [ ] `AppButton` «AÑADIR TARJETA» que cierra y abre `AddCardModal`.
- [ ] Lista con fades de scroll arriba/abajo.
- [ ] Estado vacío con `EmptyState`; loading con skeletons de fila; error con `ErrorFeedbackCard`.
- [ ] Entrada escalonada de filas; eliminación con colapso animado.
- [ ] Cero hex sueltos, cero magic numbers: todo por token.
- [ ] Foco atrapado; Escape/scrim cierran; semántica por fila correcta.
- [ ] Reduced motion respetado (sin escalonado, sin colapso animado, sin scale).
- [ ] Se ve correcto en 1280×720 y 1024×600.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (color: `glassSurfaceStrong`, `surfaceHud`, `borderGold`, `scrim`), 02 (tipografía: `titleM`, `mono`, `labelSmall`, `bodyS`), 03 (dimensiones: `radiusXL`, `radiusM`, `chamferM`, `elev3`), 04 (motion: `springSoft`, `easeEntrance`), 05 (iconografía), 06 (`HudCornerBrackets`, `HudDivider`).
- **Componentes núcleo:** 09 (`AppButton`, icon button), 12 (`HoloPanel`), 13 (menú contextual, confirmación), 14 (skeletons), 15 (`EmptyState`), 16 (`ErrorFeedbackCard`), 17 (toasts HUD).
- **Shell:** 47 (se abre desde la tab «Métodos de Pago»). Abre: 51 (Add Card Modal).
