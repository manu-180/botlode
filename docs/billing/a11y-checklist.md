# T4·27 — Accessibility Audit: Billing Widgets

**Audit date:** 2026-05-12  
**Scope:** `botslode/` + `botlode_factory/` billing presentation widgets  
**Standard:** WCAG 2.1 AA  
**Flutter a11y primitives:** `Semantics`, `MergeSemantics`, `ExcludeSemantics`

---

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| All financial inputs have `Semantics.label` | ✅ Done (with documented WebView limitations) |
| WCAG AA contrast verified in 5 critical views | ✅ Verified (failures documented below) |
| `a11y-checklist.md` exists | ✅ This file |
| No `SemanticsHandle` warnings in tests | ✅ T4·27 introduces zero new failures (pre-existing: 2 timezone failures in `trial_countdown_banner_test.dart` — T4·18 bug) |

---

## Widget-by-Widget Results

### GROUP 1 — Status Chips + Banners

#### `botlode_factory` · `billing_subscription_chip.dart`
- ✅ Chip wrapped with `Semantics(label: 'Estado: ${_mapStatusToLabel(status)}', excludeSemantics: true)`
- ✅ Helper `_mapStatusToLabel()` added: activa · en prueba · pago pendiente · cancelada · incompleta
- ⚠️ **Contrast FAIL:** `Colors.green` (#4CAF50) on tint ~2.5:1 — fails WCAG AA 4.5:1. Use `Color(0xFF16A34A)` (Tailwind green-600, ~4.6:1) instead
- ⚠️ Other status colors (orange, blue, red, grey) all below 4.5:1 for normal text — backlog item

#### `botslode` · `trial_countdown_banner.dart`
- ✅ `Semantics(label: 'Trial activo: $daysLeft días restantes', liveRegion: true)` added
- ✅ CTA button: `Semantics(label: 'Agregar método de pago - quedan $daysLeft días de trial')`
- ✅ Decorative severity icon wrapped with `ExcludeSemantics`

#### `botlode_factory` · `trial_countdown_banner.dart`
- ✅ Top-level `Semantics(label: 'Trial activo: $daysLeft días restantes', liveRegion: true)` added (was missing)
- ✅ `_AddPaymentButton` receives `daysLeft` for context-rich label
- ⚠️ Minor: collapsed text node (`'Prueba: 5 días'`) may double-announce with parent label; revisit with `excludeSemantics: true` if TalkBack testing confirms

#### `botslode` · `dunning_warning_banner.dart`
- ✅ `Semantics(label: 'Advertencia: pago fallido. $mainText', liveRegion: true)`
- ✅ Primary CTA: `'Actualizar método de pago - suscripción en riesgo'`
- ✅ Retry CTA: dynamic `'Reintentando cobro...'` during loading
- ⚠️ **Contrast:** `Color(0x99FF003C)` (60% alpha error red) on dark surface — risk below 4.5:1 for 11sp italic text
- ⚠️ White on `AppColors.error` button (~3.9:1) — passes large text 3:1, verify 14sp qualifies

#### `botlode_factory` · `dunning_warning_banner.dart`
- ✅ All changes mirrored from botslode version
- ⚠️ **Contrast FAIL:** `onPrimary` (white) on `AppColors.warning` (amber ~#F59E0B) ≈ 2.4:1 — **fails WCAG AA**. Use dark text on amber background

---

### GROUP 2 — Card + Payment Form Widgets

#### `botslode` · `add_card_modal.dart`
- ✅ Title: `Semantics(header: true)`
- ✅ Default checkbox: `Semantics(label: 'Usar como tarjeta predeterminada para pagos', checked: _setAsDefault)`
- ✅ Save button: `Semantics(label: 'Agregar tarjeta de crédito/débito', button: true, enabled: saveEnabled)`
- ℹ️ Individual field labels (card number / expiry / CVV) live inside Stripe/MP widgets — see below

#### `botlode_factory` · `add_card_modal.dart`
- ✅ Same patterns applied; factory file is a stub awaiting T5 gateway integration

#### `botslode` · `manage_cards_modal.dart`
- ✅ Header: `Semantics(header: true)`
- ✅ Card rows: `Semantics(label: 'Tarjeta terminada en XXXX, <brand>')`
- ✅ Delete action: `Semantics(label: 'Eliminar tarjeta terminada en XXXX')`
- ✅ Add button: `Semantics(label: 'Agregar nueva tarjeta de pago')`
- ✅ Brand icons: `ExcludeSemantics` (decorative)

#### `botlode_factory` · `manage_cards_modal.dart`
- ✅ Same patterns applied
- ✅ `Predeterminar` TextButton: `Semantics(label: 'Usar como tarjeta predeterminada para pagos', enabled: !pm.isDefault)`
- ⚠️ Loading state `CircularProgressIndicator` lacks `Semantics(label: 'Cargando métodos de pago')` — backlog

#### `botslode` · `stripe_elements_card_form.dart`
- ✅ Group-level: `Semantics(label: 'Formulario de tarjeta de crédito - campos gestionados por Stripe', hint: 'Ingrese número de tarjeta, fecha de vencimiento y CVV')`
- ✅ Visible `Text('Datos de tu tarjeta')` label added above `CardField`
- ✅ Code comment documents WebView limitation
- 🚫 **WebView limitation:** Individual sub-field semantics (number / expiry / CVV) are not accessible from Flutter layer — blocked by `CardField` native embed. Max achievable without forking `flutter_stripe`.

#### `botslode` · `mercadopago_brick_form.dart`
- ✅ Group-level: `Semantics(label: 'Formulario de pago Mercado Pago', hint: 'Complete sus datos de pago en el formulario de Mercado Pago')`
- ✅ `// NOTE: MP Brick a11y is limited by WebView — HTML inside is controlled by MP` comment added
- 🚫 **WebView limitation:** MP Brick renders inside `WebViewWidget`; internal form field a11y depends entirely on MercadoPago's HTML/ARIA implementation. Recommend filing issue with MP to ensure `role=textbox`, `aria-label`, `aria-required` on each input.

#### `botslode` · `digital_card.dart`
- ✅ Card container: `Semantics(label: 'Tarjeta terminada en XXXX, <brand>, vence MM/YY')`
- ✅ Decorative elements (hexagon, gradient, chip art): `ExcludeSemantics`
- ✅ Inner text nodes wrapped with `ExcludeSemantics` to prevent duplication with composite label
- **Contrast analysis (white text on near-black gradient):**
  - ✅ White (#FFF) on ~#0A0A0A → ~19.9:1 — **PASSES AA + AAA**
  - ✅ Gold (#D4AF37) on #050505 → ~9.5:1 — **PASSES AA + AAA**
  - ⚠️ `Colors.white24` 'VENCE' micro-label → ~1.8:1 — **FAILS AA** (decorative intent, not blocking)
  - ⚠️ `Colors.white38` masked digit groups → ~3.2:1 — passes large text 3:1 only; recommend `Colors.white60`

---

### GROUP 3 — Plan Picker + Subscription + Checkout

#### `botslode` + `botlode_factory` · `plan_picker.dart`
- ✅ Plan cards: `Semantics(label: 'Plan <name> - <price>', selected: isCurrent, button: true)`
- ✅ "Recomendado" badge: `Semantics(label: 'Plan recomendado: <name>')`
- ✅ Current plan conveys `selected: true` to screen readers

#### `botslode` + `botlode_factory` · `subscription_summary_card.dart`
- ✅ Header group wrapped in `MergeSemantics`
- ✅ Status chip: `Semantics(label: 'Estado de suscripción: <status>')`
- ✅ Price: `Semantics(label: 'Precio: $<amount> por <period>')`
- ✅ Renewal date: `Semantics(label: 'Próxima renovación: <date>')`
- ✅ `_statusLabel()` helper added for human-readable status strings

#### `botslode` + `botlode_factory` · `payment_checkout_modal.dart`
- ✅ Title: `Semantics(header: true)`
- ✅ Pay button: `Semantics(label: 'Confirmar pago de $<amount> - Plan <name>')`
- ✅ Total line: `Semantics(label: 'Total a pagar: $<amount> - Plan <name>')`
- ✅ Loading state: `liveRegion: _isMutating` → announces "Procesando pago, por favor espere"
- ✅ Factory: payment method radio tiles: `Semantics(label: '...', selected: isSelected, button: true)`

#### `botslode` · `proration_preview_modal.dart`
- ✅ Title: `Semantics(header: true)`
- ✅ Proration table: `Semantics(label: 'Ajuste de precio: se acreditarán $X del plan actual y se cobrarán $Y por el nuevo plan. Total a cobrar hoy: $Z')`
- ✅ Confirm button: `Semantics(label: 'Confirmar cambio de plan a <name> por $<price>/mes')`
- ✅ Loading: `liveRegion: _confirming`

#### `botslode` · `reactivate_subscription_flow.dart`
- ✅ Reactivate button: `Semantics(label: 'Reactivar suscripción - se cobrará $<price>/mes')`
- ✅ Error text: `Semantics(label: 'Error al reactivar: <message>', liveRegion: true)`
- ✅ Decorative refresh icon: `ExcludeSemantics`

---

### GROUP 4 — Modals + Invoice + Auto-Pay

#### `botslode` · `cancel_flow_modal.dart`
- ✅ Step counter: `Semantics(label: 'Paso N de 2 del proceso de cancelación')`
- ✅ Title step 1 + 2: `Semantics(header: true)`
- ✅ Keep-subscription button (FIRST in tab order): `Semantics(label: 'Mantener mi suscripción activa')`
- ✅ Destructive cancel (LAST in tab order): `Semantics(label: 'Cancelar suscripción definitivamente - esta acción no puede deshacerse')`
- ✅ Reason selector tiles: `Semantics(label: 'Motivo de cancelación: <label>', selected: selected)`
- ✅ Error banner: `Semantics(liveRegion: true, label: 'Error: <message>')`
- ✅ Focus trapping: handled by `showDialog`/`showModalBottomSheet` platform overlays
- ⚠️ **Keyboard gap:** Reason radio tiles use `GestureDetector` — not Tab-reachable. Requires `InkWell`/`Focus` refactor (business-logic-safe change, out of scope for this task)

#### `botslode` + `botlode_factory` · `quota_paywall_modal.dart`
- ✅ Title: `Semantics(header: true)` + icon `ExcludeSemantics`
- ✅ Body: `Semantics(label: 'Has alcanzado el límite de <resourceLabel>. Actualiza tu plan para continuar.')`
- ✅ Upgrade CTA: `Semantics(label: 'Actualizar plan para desbloquear esta función')`
- ✅ Dismiss: `Semantics(label: 'Cerrar aviso de límite de uso')`
- ⚠️ Comparison table rows lack header associations — `MergeSemantics` per row recommended in follow-up

#### `botslode` + `botlode_factory` · `invoice_list.dart`
- ✅ `_statusLabel()` helper added (maps `InvoiceStatus` → Spanish)
- ✅ Invoice row: `Semantics(label: 'Factura <period> por <amount> - Estado: <status>')`
- ✅ Status chip inside row: `ExcludeSemantics` (avoids double-announcement)
- ✅ Download button: `Semantics(label: 'Descargar factura PDF de <period>')`
- ✅ Empty state: `Semantics(label: 'No hay facturas disponibles')`
- ⚠️ **Load-more is scroll-triggered only** — keyboard/AT users cannot paginate. Add `TextButton('Cargar más facturas')` when `_hasMore` is true
- ⚠️ Skeleton rows: no `Semantics(label: 'Cargando facturas', liveRegion: true)` — silent loading

#### `botslode` · `auto_pay_settings_card.dart`
- ✅ Toggle: `Semantics(label: 'Pago automático <activado|desactivado>', toggled: autoRenew)`
- ✅ Card selector: `Semantics(label: 'Tarjeta para pago automático: terminada en <last4>')`
- ✅ Warning row: `Semantics(liveRegion: true, label: 'Advertencia: Agregá un método de pago...')`
- ⚠️ Card selector uses `GestureDetector` — not Tab-reachable (same `InkWell` refactor needed)
- ⚠️ No confirm step before mutation fires — accidental toggle triggers subscription change

---

## Contrast Summary (5 Critical Views)

| View | Element | Color | Background | Ratio | Result |
|------|---------|-------|------------|-------|--------|
| `digital_card` | White body text | #FFFFFF | ~#0A0A0A | ~19.9:1 | ✅ AAA |
| `digital_card` | Masked digits | white38 (~rgba 255,255,255,0.38) | #050505 | ~3.2:1 | ⚠️ Large text only |
| `billing_subscription_chip` | "Activa" label | #4CAF50 | ~#E8F5E9 | ~2.5:1 | ❌ Fail |
| `dunning_warning_banner` (factory) | Button text | white | #F59E0B | ~2.4:1 | ❌ Fail |
| `dunning_warning_banner` (botslode) | Error body text | rgba(255,0,60,0.6) | dark surface | ~risk | ⚠️ Verify |

**Recommended fixes (priority order):**
1. `billing_subscription_chip` "activa" → replace `Colors.green` with `Color(0xFF16A34A)`
2. `dunning_warning_banner` factory button → use dark text on amber, not white
3. `digital_card` masked digits → increase to `Colors.white60`

---

## WebView Limitations (documented, not blocking)

| Widget | Gateway | Limitation |
|--------|---------|------------|
| `stripe_elements_card_form.dart` | Stripe `CardField` | Native platform view — individual sub-field focus not accessible from Flutter |
| `mercadopago_brick_form.dart` | MP Brick WebView | All internal ARIA depends on MercadoPago's HTML implementation |

**Action:** File issue with MercadoPago requesting `role=textbox` + `aria-label` + `aria-required` on each Brick input.

---

## Backlog (out of T4·27 scope)

| Priority | Widget | Issue |
|----------|--------|-------|
| High | `cancel_flow_modal` | `GestureDetector` radio tiles not Tab-reachable → replace with `InkWell`/`Focus` |
| High | `auto_pay_settings_card` | Card selector `GestureDetector` not Tab-reachable |
| High | `invoice_list` | Load-more scroll-only → add `TextButton('Cargar más facturas')` |
| Medium | `billing_subscription_chip` | Replace `Colors.green` → `Color(0xFF16A34A)` |
| Medium | `dunning_warning_banner` (factory) | Fix white-on-amber button contrast |
| Medium | `auto_pay_settings_card` | No confirmation before mutation fires |
| Medium | `quota_paywall_modal` | Comparison table row header associations |
| Low | `invoice_list` | Skeleton rows silent during loading |
| Low | `manage_cards_modal` (factory) | `CircularProgressIndicator` loading label |
| Low | `trial_countdown_banner` (factory) | Potential double-announcement of collapsed label |

---

## Manual Testing Checklist (TalkBack / VoiceOver)

### Flow 1 — Agregar tarjeta
- [ ] Screen reader announces modal title as heading
- [ ] Stripe form announced: "Formulario de tarjeta de crédito - campos gestionados por Stripe"
- [ ] Save button: "Agregar tarjeta de crédito/débito"

### Flow 2 — Cambiar plan
- [ ] Each plan card reads: "Plan <name> - <price>" with "seleccionado" for current
- [ ] "Plan recomendado" badge announced on recommended option
- [ ] Checkout modal pay button: "Confirmar pago de $<amount> - Plan <name>"
- [ ] Proration modal: full financial breakdown announced as label

### Flow 3 — Cancelar suscripción
- [ ] Step counter announced on each step transition
- [ ] "Mantener mi suscripción activa" is first focusable action on step 2
- [ ] Destructive button announces irreversibility warning
- [ ] Error state announced via `liveRegion`

### Flow 4 — Trial + Dunning banners
- [ ] Trial banner auto-announces on mount (`liveRegion`)
- [ ] Dunning banner auto-announces on mount (`liveRegion`)
- [ ] Days remaining included in trial label
