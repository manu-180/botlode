# 11 — Badges, chips y status tags (`AppBadge` · `StatusTag` · `AppFilterChip`)

> Prompt de la **Fase B — Componentes núcleo**. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Leé el archivo 00 completo antes de ejecutar. Todo valor se referencia por **nombre de token**.

---

## 1. Objetivo

Crear los tres componentes de etiquetado reutilizables: `AppBadge` (pill de conteo/etiqueta corta), `StatusTag` (estado semántico con punto de estado HUD) y `AppFilterChip` (chip seleccionable de filtro). Hoy la app dispersa pequeñas etiquetas y contadores improvisados por pantalla. Estos componentes los unifican.

---

## 2. Archivos

- **Crear** `lib/core/ui/widgets/app_badge.dart` — `AppBadge` + enum `AppBadgeTone` (`neutral`, `gold`, `cyan`, `danger`).
- **Crear** `lib/core/ui/widgets/status_tag.dart` — `StatusTag` + enum `UnitStatus` (`online`, `suspended`, `offline`, `processing`).
- **Crear** `lib/core/ui/widgets/app_filter_chip.dart` — `AppFilterChip`.
- No crear subcarpetas.

---

## 3. Estado actual

No existen componentes unificados. Los contadores (p. ej. cantidad de bots, ítems) y los estados de unidad se dibujan ad-hoc con `Container` + `Text` en cada vista, con colores y radios inconsistentes. La toolbar del dashboard (prompt 27) necesita chips de filtro que tampoco existen como widget reutilizable.

---

## 4. Visión del rediseño

- **`AppBadge`**: pill compacta `radiusPill` para contadores numéricos («3», «12») y etiquetas micro («NUEVO», «BETA»). Tono configurable; el oro reservado para destacados reales.
- **`StatusTag`**: la firma visual del estado de una unidad. Combina un `HudStatusDot` (punto con halo pulsante, prompt 06) + label en `labelSmall`. Color **siempre** acompañado de ícono/forma + texto — nunca color solo (regla §4.6 / §10 del archivo 00).
- **`AppFilterChip`**: chip seleccionable para filtros (tabs de estado del dashboard). Estado seleccionado claramente diferenciado por relleno + borde + glow.

---

## 5. Especificación visual

### 5.1 `AppBadge`

```dart
AppBadge({
  required String text,            // "3", "NUEVO", etc.
  AppBadgeTone tone = AppBadgeTone.neutral,
  bool dot = false,                // si true, muestra solo un punto sin texto
})
```

- Forma: `radiusPill`. Altura 18 px. Padding horizontal `space8` (texto) / cuadrado 8×8 si `dot`.
- Tipografía: `labelSmall` (UPPERCASE, tabular para números).
- Tonos:

| `AppBadgeTone` | Relleno | Texto | Borde |
|---|---|---|---|
| `neutral` | `surfaceRaised` | `textSecondary` | `borderDefault` 1 px |
| `gold` | `gold` al 16 % | `goldBright` | `borderGold` 1 px |
| `cyan` | `cyan` al 14 % | `cyan` | `cyan` al 32 %, 1 px |
| `danger` | `danger` al 14 % | `danger` | `danger` al 40 %, 1 px |

- `AppBadge` es no interactivo (sin estados de hover/press).

### 5.2 `StatusTag`

```dart
StatusTag({
  required UnitStatus status,
  bool compact = false,            // compact => solo el HudStatusDot + label corto
})
```

- Layout: `Row` → `HudStatusDot` (8 px, color del estado, halo pulsante) + `space8` + `Text` label en `labelSmall`.
- Caja contenedora: relleno = color del estado al 10 %, borde = color del estado al 32 % (1 px), `radiusPill`, altura 22 px, padding horizontal `space8`.
- Mapa estado → color + label + ícono:

| `UnitStatus` | Color (token) | Label | Punto |
|---|---|---|---|
| `online` | `success` | `EN LÍNEA` | `HudStatusDot` pulsante (latido 1600 ms) |
| `suspended` | `warning` | `SUSPENDIDO` | `HudStatusDot` estático |
| `offline` | `danger` | `OFFLINE` | `HudStatusDot` estático, sin glow (no emite) |
| `processing` | `cyan` | `PROCESANDO` | `HudStatusDot` con pulso rápido |

- El color **nunca** es el único portador: el label de texto distingue cada estado aunque el usuario no perciba el color.

### 5.3 `AppFilterChip`

```dart
AppFilterChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
  IconData? icon,
  int? count,                      // si !=null, muestra un AppBadge a la derecha
})
```

- Forma: `radiusPill`. Altura 32 px. Padding horizontal `space12`.
- Contenido: `Row` → (ícono 14 px opcional + `space8`) + `Text` label `label` (UPPERCASE) + (`space8` + `AppBadge` con `count` opcional).

---

## 6. Estados e interacciones (matriz §9 del archivo 00)

`AppBadge` y `StatusTag` son **no interactivos**: solo tienen `default`. (`StatusTag.online`/`processing` tienen animación de latido del punto, pero no estados de input.)

`AppFilterChip` es interactivo — matriz completa:

| Estado | Relleno | Borde | Texto/ícono | Glow |
|---|---|---|---|---|
| `default` (no seleccionado) | `surface` | `borderDefault` 1 px | `textSecondary` | ninguno |
| `hover` | `surfaceRaised` | `borderStrong` 1 px | `textPrimary` | ninguno; cursor `click` |
| `pressed` | `surfaceHud` | `borderStrong` 1 px | `textPrimary` | ninguno; escala 0.97 |
| `selected` | `gold` al 16 % | `borderGold` 1.5 px | `goldBright` | `glowGold` tenue, estable |
| `selected + hover` | `gold` al 22 % | `borderGold` 1.5 px | `goldBright` | `glowGold` un paso más intenso |
| `focused` | igual al estado base | + anillo `cyan` 2 px externo | — | — |
| `disabled` | `surface` | `borderSubtle` 1 px | `textTertiary` | ninguno; opacidad 0.4 |

- `loading`/`error`/`empty` no aplican a chips de filtro.

---

## 7. Animaciones

| Interacción | Token duración | Token curva | Propiedad |
|---|---|---|---|
| Latido del `HudStatusDot` (online/processing) | ~1600 ms (online) / más rápido (processing) | pulso opacidad 0.6↔1.0 | provisto por la primitiva del prompt 06 |
| Chip hover (color/borde) | `durFast` | `easeStandard` | `AnimatedContainer` |
| Chip selección (transición a/desde `selected`) | `durBase` | `easeStandard` | relleno, borde, glow |
| Chip press | `durInstant` | `easeStandard` | `AnimatedScale` 0.97 |

- **Reduced motion**: el `HudStatusDot` deja de latir (queda en opacidad fija) — el estado se sigue distinguiendo por color + label. Las transiciones de chip se reducen a crossfade 120 ms.

---

## 8. Accesibilidad

- **Regla central**: color siempre + ícono/forma + texto. `StatusTag` cumple porque el label de texto es explícito; `AppBadge` numérico ya es texto.
- Contraste: cada par texto/relleno verificado ≥ 4.5:1 (texto normal) / ≥ 3:1 (UPPERCASE micro). Los tonos con relleno translúcido se verifican sobre `surface`.
- `AppFilterChip`: `Semantics(button: true, selected: selected, label: '$label${count != null ? ", $count" : ""}')`. Foco visible con anillo `cyan`. Activable con `Enter`/`Space`.
- `StatusTag`: `Semantics(label: 'Estado: <label>')`, no interactivo.
- Área de hit del chip ≥ 32×32 px.

---

## 9. Checklist de aceptación

- [ ] Existen `app_badge.dart`, `status_tag.dart` y `app_filter_chip.dart` en `lib/core/ui/widgets/`.
- [ ] `AppBadge` soporta los 4 tonos y modo `dot`; tipografía `labelSmall`, forma `radiusPill`.
- [ ] `StatusTag` combina `HudStatusDot` + label; mapea los 4 estados a color/label correctos.
- [ ] Ningún estado se comunica solo por color: siempre hay texto/ícono.
- [ ] `AppFilterChip` implementa la matriz completa de §6, incluyendo `selected` con `glowGold`.
- [ ] El punto de estado late en `online`/`processing` y queda estático con reduced-motion.
- [ ] Chip seleccionado expone `Semantics(selected: true)`.
- [ ] Cero hex sueltos / magic numbers; todo por token.
- [ ] `flutter analyze` sin warnings nuevos; compila en 1280×720 y 1024×600.

---

## 10. Dependencias

- **01** (color: `gold`, `goldBright`, `cyan`, `success`, `warning`, `danger`, `surface`, `surfaceRaised`, `surfaceHud`, `borderDefault`, `borderStrong`, `borderSubtle`, `borderGold`, `textPrimary/Secondary/Tertiary`).
- **02** (tipografía: `labelSmall`).
- **03** (dimensión: `space*`, `radiusPill`, `glowGold`).
- **04** (motion: `durInstant`, `durFast`, `durBase`, `easeStandard`, `AppMotion.reduced`).
- **05** (iconografía).
- **06** (`HudStatusDot`).
