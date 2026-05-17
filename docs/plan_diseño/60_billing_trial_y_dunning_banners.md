# 60 — Billing · Trial Countdown + Dunning Warning Banners

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.

---

## 1. Objetivo

Rediseñar los dos banners horizontales que coronan el área de billing: `TrialCountdownBanner` (cuenta regresiva del período de prueba, con CTA de upgrade) y `DunningWarningBanner` (aviso de cobro fallido, con CTAs de reintento/actualización). Deben sentirse **alertas de estado de sistema** del «Hangar OS»: bandas técnicas con brackets finos, ticker de cuenta regresiva, jerarquía de severidad clara, y entrada slide-down.

---

## 2. Archivos

- `lib/features/billing/presentation/widgets/trial_countdown_banner.dart` — reescritura visual; lógica conservada (`_daysLeft`, `_severity`, descarte, apertura de `AddCardModal`).
- `lib/features/billing/presentation/widgets/dunning_warning_banner.dart` — reescritura visual; lógica conservada (`retryPayment`, `errorMessage`, apertura de `AddCardModal`, no descartable).

---

## 3. Estado actual

**Trial:** `Container` con `color.withValues(alpha:0.08)`, borde `color@0.35`, `radius 12`, margen 16/8. Ícono de reloj de arena según severidad, título «Trial: X días restantes», subtítulo + `FilledButton` solo si no hay método de pago, `IconButton` de cierre. Severidad: `secondary` (>7 días) / `warning` (3–7) / `error` (≤2). Sin ticker animado, sin ornamento HUD, tipografía plana.

**Dunning:** `Container` `error@0.08`, borde `error@0.4` 1.5 px, `radius 12`. Ícono `error_outline`, título «Pago fallido», mensaje con fecha de suspensión, último error en itálica. Dos `FilledButton`/`OutlinedButton` apilados (actualizar / reintentar). **Hex sueltos** `0xCCFF003C`, `0x99FF003C`, `0x66FF003C` (basados en el `#FF003C` viejo, no en el `danger` nuevo `#FF2D55`). No descartable.

---

## 4. Visión del rediseño

Ambos banners son **bandas de alerta HUD** de ancho completo, ubicadas sobre los tabs de billing. Llevan `HudCornerBrackets` finos, una franja de color de severidad a la izquierda (barra `HudReactorBar` vertical), ícono semántico, mensaje claro causa+solución, y CTAs a la derecha. Entran con un slide-down suave.

- **Trial:** banda informativa/dorada según severidad. El número de días se presenta con `HudTicker` — al renderizarse «cuenta» hasta el valor, y baja con dignidad si se actualiza. CTA «MEJORAR AHORA» en oro. Descartable (botón X) salvo cuando es crítico (≤2 días + sin método de pago).
- **Dunning:** banda `danger` (o `warning` si todavía hay margen de gracia). Mensaje en dos partes — causa («PAGO RECHAZADO») y solución («Actualizá tu método de pago»). Botones «Reintentar» y «Actualizar». No descartable mientras la suscripción siga en `past_due` — es un estado crítico.

---

## 5. Especificación visual

### 5.1 Estructura común de banda

- `Container` ancho completo, margen horizontal `space16`, vertical `space8`.
- Fondo: color de severidad @ 0.08 sobre `surface`; borde color@0.35; `radiusM`.
- `HudCornerBrackets` finos (brazo 12 px, 1 px) en el color de severidad.
- Barra lateral izquierda: `HudReactorBar` vertical 3 px en el color de severidad, late suave en estados de advertencia.
- Padding interno `space16`.
- `HudScanlines` opcional muy tenue (`opacity 0.035`).

### 5.2 Trial — variantes de severidad

| Días restantes | Color | Ícono | Tono |
|---|---|---|---|
| > 7 | `info` | `hourglass_top` | Informativo neutro. |
| 3–7 | `warning` | `hourglass_bottom` | Advertencia. |
| ≤ 2 | `danger` | `hourglass_disabled` | Crítico. |

- **Layout:** `Row`. Ícono de severidad 20 px en el color. Gap `space12`.
- **Bloque central:** título `QUEDAN [HudTicker] DÍAS DE PRUEBA` — la cifra en `numericTicker` mono (compacta, ~18 px aquí) con figuras tabulares, en el color de severidad; el resto del texto en `label`. Si no hay método de pago, subtítulo `bodyS` «Agregá un método de pago para no perder el acceso».
- **CTA:** `AppButton` `primary` «MEJORAR AHORA» (oro, `gradGold`) cuando falta método de pago; si ya hay método, CTA secundaria opcional o nada.
- **Descartar:** `AppIconButton` (X) a la derecha; oculto cuando la severidad es crítica (`danger`) y falta método de pago.

### 5.3 Dunning — variantes

| Caso | Color | Ícono |
|---|---|---|
| `past_due` con margen de gracia (fecha futura) | `warning` | `error_outline` |
| `past_due` sin margen / suspensión inminente | `danger` | `report` / `gpp_bad` |

- **Layout:** `Column`. Fila superior: ícono 20 px + bloque de texto:
  - Título causa «PAGO RECHAZADO» en `label` del color.
  - Mensaje solución `bodyS` `textSecondary`: «Actualizá tu método de pago. Tu acceso podría suspenderse el dd/MM/yyyy.»
  - Si hay `errorMessage`: línea adicional en `mono` `textTertiary` (motivo técnico del rechazo).
- **CTAs** (gap `space14`): `AppButton` `primary`/`danger` «ACTUALIZAR MÉTODO» (ancho completo) + `AppButton` `ghost` «REINTENTAR COBRO» (ancho completo). En reintento, spinner mono dentro del botón.
- **No descartable:** sin botón X.

### 5.4 Tipografía y color

- Cero hex sueltos: `0xCCFF003C`/`0x99FF003C`/`0x66FF003C` se reemplazan por `danger`/`textSecondary`/`textTertiary` o por `danger.withValues(alpha:)` con el `danger` nuevo del token.
- Texto sobre fondo de banda: títulos en el color de severidad, cuerpo en `textSecondary`/`textTertiary` para garantizar contraste.

---

## 6. Estados e interacciones (matriz §9)

| Estado | Trial | Dunning |
|---|---|---|
| `default` | Banda visible según severidad. | Banda visible según margen de gracia. |
| `hover` (CTA/X) | Borde + glow, `durFast`. | Borde + glow. |
| `pressed` | Escala 0.97, `durInstant`. | Igual. |
| `focused` | Anillo 2 px `gold` (CTA), `cyan` (X). | Anillo 2 px según botón. |
| `loading` | — | Botón reintentar con spinner mono; ambos botones bloqueados. |
| `dismissed` | Banda desaparece con slide-up (`SizedBox.shrink`). | No aplica (no descartable). |
| `error` | — | Error de reintento vía `SnackBar` HUD; banda permanece. |
| oculto | Sin trial activo / descartado. | Suscripción no `past_due`. |

---

## 7. Animaciones

- **Entrada:** slide-down + fade — translateY −16 px → 0, `durSlow`, `easeEntrance`.
- **Salida (Trial descartado):** slide-up + fade, ~65 % de la entrada, `easeExit`.
- **HudTicker (Trial):** la cifra de días cuenta hasta el valor en `durTicker` con `easeTicker` al montarse; si el valor baja (día nuevo), reanima.
- **Barra lateral / brackets en `warning`/`danger`:** latido de opacidad 0.6↔1.0 a ~1600 ms (`HudReactorBar` reactor).
- **Cambio de severidad:** crossfade `durBase` del color de fondo/borde/ícono.
- **Reduced motion:** sin slide (fade simple 120 ms); sin latido; el `HudTicker` muestra el número final directo.

---

## 8. Accesibilidad

- Ambos banners: `Semantics(liveRegion:true)` — un cambio de estado de billing debe anunciarse.
- Severidad comunicada por color + ícono + texto (nunca solo color).
- Botón descartar (Trial): `Semantics`/`tooltip` «Cerrar aviso de prueba».
- CTAs con label descriptivo (incluir días restantes / riesgo de suspensión, como hoy).
- Contraste: títulos de color de severidad y cuerpo sobre el fondo de banda ≥ 4.5:1 (verificar; usar variante de cuerpo más clara si `info`/`warning`/`danger` no llegan).
- El banner de Dunning es no descartable a propósito: tiene salida vía resolver el pago, no vía cerrar — documentarlo.
- Foco visible; orden: contenido → CTA primaria → CTA secundaria → descartar.

---

## 9. Checklist de aceptación

- [ ] Ambos banners con `HudCornerBrackets` finos y barra lateral `HudReactorBar` de severidad.
- [ ] Trial: cuenta regresiva con `HudTicker` que anima el conteo; CTA «MEJORAR AHORA» en oro.
- [ ] Trial descartable salvo severidad crítica; Dunning no descartable.
- [ ] Dunning: mensaje en dos partes (causa + solución); variantes `warning`/`danger`.
- [ ] **Todos los hex sueltos eliminados** (`0xCC/0x99/0x66 FF003C` → tokens `danger`/texto).
- [ ] Entrada slide-down `easeEntrance`; salida ~65 %.
- [ ] Severidad por color + ícono + texto; `Semantics(liveRegion:true)` en ambos.
- [ ] Espaciados/radios por token; cero magic numbers.
- [ ] Reduced-motion respetado (sin slide/latido/conteo animado).
- [ ] Contrastes verificados ≥ 4.5:1.
- [ ] `flutter analyze` sin warnings nuevos; se ve bien en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01–08 (color — incluye `danger` nuevo, tipografía + mono, dimensiones, motion, iconos, HUD: brackets/reactor bar/ticker/scanlines, glow/glass, fondo).
- **Componentes núcleo:** 09 (`AppButton`, `AppIconButton`), 11 (chips/tags), 17 (`SnackBar` HUD para error de reintento).
- **Billing:** 47 (shell de billing — los banners se ubican sobre la tab bar), 51 (`AddCardModal`, destino de las CTAs).
