# 57 — Billing · Cancel Flow + Reactivate Flow

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.

---

## 1. Objetivo

Rediseñar dos flujos opuestos del ciclo de vida de la suscripción: el **`CancelFlowModal`** (multi-paso, deliberado, destructivo, con indicador de pasos HUD y ofertas de retención) y el **`ReactivateSubscriptionFlow`** (corto, claro, celebratorio sin exageración). Ambos deben sentirse parte del mismo sistema «Hangar OS»: el de cancelar pesa y frena; el de reactivar fluye y reasegura.

---

## 2. Archivos

- `lib/features/billing/presentation/widgets/cancel_flow_modal.dart` — reescritura visual; lógica conservada (`cancelSubscription`, `BillingException`, `not_implemented`).
- `lib/features/billing/presentation/widgets/reactivate_subscription_flow.dart` — reescritura visual; lógica conservada (`reactivateSubscription`, estado bloqueado sin método de pago, redirección a `AddCardModal`).

---

## 3. Estado actual

**Cancel:** modal de 2 pasos en `_ModalContainer` (`0xFF09090B`, radio 20). Paso 1: header con ícono `cancel_outlined` en círculo `error@0.1`, 4 `_ReasonRadioTile` (radio custom simple), `TextField` de comentario, `FilledButton` continuar + `TextButton` mantener. Paso 2: header con botón atrás cuadrado, `_ConsequencesBullets` en caja `white@0.03`, `FilledButton` mantener (primario) + `OutlinedButton` confirmar (destructivo). Sin indicador de pasos, sin ofertas de retención, hex sueltos, transición entre pasos seca (`setState`).

**Reactivate:** `AlertDialog` Material plano (`0xFF0F0F13`, radio 16). Dos estados: bloqueado (sin método de pago, redirige a alta) y confirmación (con tarjeta default). Sin feedback positivo de éxito más allá de un `SnackBar`. Sin lenguaje HUD.

---

## 4. Visión del rediseño

### 4.1 Cancel — flujo de 3 pasos «desacople de unidad»

Modal `HoloPanel` modal con un **indicador de pasos HUD** en el tope: tres segmentos `STEP 01 / 02 / 03` con barras finas; el activo emisivo en `warning`, los completados en `success` apagado, los futuros en `borderSubtle`. El tono es serio pero respetuoso, no agresivo.

- **Paso 1 — Confirmación + lo que se pierde.** Resumen de qué implica cancelar (los `_ConsequencesBullets`), presentado como lectura HUD. CTA primaria «CONTINUAR» en `ghost` neutro (no oro: cancelar no es una acción a premiar); botón secundario destacado «MANTENER SUSCRIPCIÓN» en `primary` oro.
- **Paso 2 — Motivo.** 4 radios HUD (`_ReasonRadioTile` rediseñados con el patrón del prompt 11) + campo de comentario opcional (`AppTextField`).
- **Paso 3 — Ofertas de retención.** Una o dos «tarjetas de oferta» (mini-`HoloPanel`) — ej. pausar la suscripción, descuento — presentadas como rescate. Debajo, la **confirmación destructiva final** con doble confirmación: un checkbox/switch HUD «Entiendo que perderé el acceso» que habilita el botón `danger` «CANCELAR DEFINITIVAMENTE».

### 4.2 Reactivate — flujo corto celebratorio «re-energizar unidad»

Modal `HoloPanel` modal compacto. Dos estados:

- **Bloqueado** (sin método de pago): panel con ícono de candado, mensaje claro, CTA «AGREGAR MÉTODO» que abre `AddCardModal`.
- **Confirmación:** ícono `refresh` energizado, resumen «se cobrará el dd/MM/yyyy a •••• 4242», CTA `primary` «REACTIVAR».
- **Éxito:** tras reactivar, micro-celebración: el panel hace un destello `successGlow` único y suave (no épico, no confeti), check animado, y cierra. Sin exageración: es un «sistema online», no una victoria.

---

## 5. Especificación visual

### 5.1 Contenedor común

`HoloPanel` modal: `glassSurfaceStrong` blur 18, `radiusXL`, `elev3`, `HudCornerBrackets` brazo 18 px, padding `space24`. Sobre `scrim`. Cancel `maxWidth 540`; Reactivate `maxWidth 460`.

### 5.2 Indicador de pasos HUD (solo Cancel, alto 28 px)

- `Row` de 3 segmentos. Cada segmento: barra `HudReactorBar` horizontal fina (3 px) + label `labelSmall` («MOTIVO», «OFERTA», «CONFIRMAR» — o `STEP 01/02/03`).
- Activo: barra emisiva `warning` con glow `warningGlow`; completado: `success@0.5` sin glow; futuro: `borderSubtle`.

### 5.3 Cancel · Paso 1

- Header: chip biselado `ChamferBorder` con ícono `link_off`/`cancel` 22 px en `warning`, título «¿SEGURO QUE QUERÉS CANCELAR?» en `titleL`.
- `_ConsequencesBullets` → contenedor `surfaceHud`, `radiusM`, borde `borderSubtle`; cada bullet con ícono `check_circle` 15 px `textSecondary` + texto `bodyM` `textPrimary`.
- Acciones (`Column` stretch): `AppButton` `primary` «MANTENER SUSCRIPCIÓN» arriba; `AppButton` `ghost` «CONTINUAR CON LA CANCELACIÓN» abajo.

### 5.4 Cancel · Paso 2

- Header con botón atrás: `AppIconButton` (`arrow_back`) + título «¿POR QUÉ TE VAS?».
- 4 `_ReasonRadioTile` HUD: `radiusM`, fondo `surface`; seleccionado → borde `borderGold`, relleno `goldGlow@0.4`, punto interior `gold`; label `bodyM`, seleccionado en `gold` `w600`. Hover → `borderStrong`.
- `AppTextField` (prompt 10) multilinea, label «Contanos más (opcional)».
- Acciones: `AppButton` `ghost` «CONTINUAR» (deshabilitado sin motivo) + `TextButton` «Volver» / «Mantener suscripción».

### 5.5 Cancel · Paso 3

- Header con atrás + título «UNA ÚLTIMA COSA».
- Tarjetas de oferta: mini-`HoloPanel`, borde `borderGold`, ícono (`pause_circle`, `local_offer`), título `titleM`, descripción `bodyS`, CTA `AppButton` `secondary`.
- `HudDivider` con etiqueta `// CONFIRMACIÓN FINAL`.
- Doble confirmación: switch HUD (ver §5.7) «Entiendo que perderé el acceso a mis bots» en `bodyS`. Mientras esté off, el botón final está `disabled`.
- Botón final `AppButton` variante `danger` «CANCELAR DEFINITIVAMENTE» (relleno `danger`, glow `dangerGlow` solo en hover). `Semantics` aclara que es irreversible.

### 5.6 Reactivate

- Bloqueado: ícono `lock` 22 px en `warning`, título «MÉTODO DE PAGO REQUERIDO», cuerpo `bodyM` `textSecondary`, acciones `ghost` «Cancelar» + `primary` «AGREGAR MÉTODO».
- Confirmación: chip biselado con ícono `refresh` 22 px en `gold` (con `glowGold` tenue), título «REACTIVAR SUSCRIPCIÓN», lectura HUD del cargo en `surfaceHud` (fecha en `mono`, monto en `hudReadout` `gold`), tarjeta en `mono`. Acciones `ghost` «Cancelar» + `primary` «REACTIVAR».
- Éxito: panel hace destello `successGlow`, ícono `check_circle` `success` con escala-in `springSoft`, texto «SISTEMA REACTIVADO» en `label` `success`; auto-cierre `durDeliberate` después.

### 5.7 Switch HUD de doble confirmación

Riel biselado 44×24, `radiusPill`; OFF: relleno `surfaceHud`, perilla `textTertiary`; ON: relleno `danger@0.5`, perilla `danger` con glow `glowStatus(danger)`. Transición `durFast` `easeStandard`.

---

## 6. Estados e interacciones (matriz §9)

| Estado | Cancel | Reactivate |
|---|---|---|
| `default` | Paso visible según `_step`. | Confirmación o bloqueado según método de pago. |
| `hover` | Botones/radios/tarjetas: borde + glow, `durFast`. | Botones: borde + glow. |
| `pressed` | Escala 0.97, `durInstant`. | Igual. |
| `focused` | Anillo 2 px (`cyan` neutro, `gold` primario, `danger` destructivo). | Anillo 2 px. |
| `selected` | Radio/oferta con borde `borderGold`, glow estable. | — |
| `disabled` | «CONTINUAR» sin motivo; botón final sin doble confirmación. | «REACTIVAR» mientras `_isLoading`. |
| `loading` | Botón final con spinner mono; todo el modal bloqueado, sin doble submit. | Botón con spinner; modal bloqueado. |
| `error` | Banda `danger` con `liveRegion`; el flujo permite reintentar. | Texto de error `danger` con `liveRegion`. |
| `success` | Cierra + `SnackBar`. | Destello `successGlow` + auto-cierre. |

---

## 7. Animaciones

- **Entrada de modal:** scrim fade `durBase`; panel scale 0.96→1.0 `springSoft` `easeEntrance`.
- **Transición entre pasos (Cancel):** el paso saliente hace fade + slide −24 px (`easeExit`, `durFast`); el entrante fade + slide +24 px (`easeEntrance`, `durBase`). Avanzar = entra desde la derecha; volver = desde la izquierda.
- **Indicador de pasos:** la barra activa enciende su glow con un pulso `durBase` al cambiar de paso.
- **Switch HUD:** perilla se desplaza `durFast` `easeStandard`; glow aparece con la perilla.
- **Reactivate éxito:** destello `successGlow` `durSlow` (un solo pulso, sin repeat); check escala-in `springSoft`.
- **Reduced motion:** transición entre pasos = crossfade 120 ms sin slide; sin pulsos de glow; el destello de éxito se reduce a un cambio de borde estático.

---

## 8. Accesibilidad

- Cada paso anuncia «Paso N de 3…» con `Semantics`.
- Botón atrás y cerrar: `Semantics`/`tooltip`.
- Radios: `Semantics(selected:, button:)`.
- Switch de doble confirmación: `Semantics(toggled:, label:)`; obligatorio antes del botón destructivo.
- El botón destructivo nunca queda como acción por defecto/foco inicial: el foco inicial del paso 3 va al área de ofertas; la opción de mantener/cancelar el flujo está siempre accesible.
- Errores con `liveRegion`.
- Contraste: `warning`/`danger`/`success` sobre vidrio ≥ 4.5:1 para texto.
- Reduced-motion respetado.

---

## 9. Checklist de aceptación

- [ ] Ambos modales migrados a `HoloPanel` modal; `_ModalContainer` y `AlertDialog` planos eliminados; cero hex sueltos.
- [ ] Indicador de pasos HUD de 3 segmentos en Cancel, con estados activo/completado/futuro.
- [ ] Cancel tiene 3 pasos: confirmación, motivo, ofertas + confirmación destructiva con doble confirmación.
- [ ] Switch HUD custom de doble confirmación bloquea el botón `danger` hasta activarse.
- [ ] Transiciones entre pasos animadas con dirección coherente; reduced-motion = crossfade.
- [ ] Reactivate corto: estados bloqueado/confirmación/éxito; éxito con destello `successGlow` sutil (no épico).
- [ ] Todos los botones usan `AppButton`; espaciados por token.
- [ ] Errores con `liveRegion`; foco lógico; barrier no descartable durante loading.
- [ ] `flutter analyze` sin warnings nuevos; se ve bien en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01–08 (color, tipografía, dimensiones, motion, iconos, HUD, glow/glass, fondo).
- **Componentes núcleo:** 09 (`AppButton` variantes primary/ghost/danger/secondary, `AppIconButton`), 10 (`AppTextField`), 11 (radios/switch HUD), 12 (`HoloPanel`), 16 (estados de error).
- **Billing:** 47 (shell), 49 (identidad de planes), 51 (`AddCardModal`, destino del estado bloqueado de Reactivate).
