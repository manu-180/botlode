# 09 — Sistema de botones reutilizable (`AppButton` / `AppIconButton`)

> Prompt de la **Fase B — Componentes núcleo**. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Antes de ejecutar este prompt, leé el archivo 00 completo. Todos los valores se referencian por **nombre de token**; no escribas hex ni magic numbers.

---

## 1. Objetivo

Crear el sistema de botones único de la app: un widget `AppButton` con cuatro variantes (`primary`, `secondary`, `danger`, `ghost`), tres tamaños (`sm`/`md`/`lg`), ícono opcional y estado `loading`; más un `AppIconButton` solo-ícono con tooltip obligatorio. Hoy la app usa `ElevatedButton` de Material con estilo plano del tema. El rediseño los reemplaza por botones HUD coherentes con la metáfora «Hangar OS»: el botón primario **emite luz**, el resto vive en grises técnicos.

---

## 2. Archivos

- **Crear** `lib/core/ui/widgets/app_button.dart` — `AppButton`, enum `AppButtonVariant`, enum `AppButtonSize`.
- **Crear** `lib/core/ui/widgets/app_icon_button.dart` — `AppIconButton`.
- **Modificar** `lib/core/config/theme/app_theme.dart` — quitar el `elevatedButtonTheme` plano actual (líneas 54–68) o dejarlo solo como fallback de terceros; los widgets nuevos no dependen del tema.
- No crear subcarpetas. Ambos archivos viven directo en `lib/core/ui/widgets/`.

---

## 3. Estado actual

`app_theme.dart` define un `ElevatedButtonThemeData` con `backgroundColor: AppColors.primary`, texto negro, `elevation: 0`, `radius 8`, padding `24×16`. Es funcional pero plano: sin gradiente, sin glow, sin estados de hover/press diferenciados, sin variantes. No existe botón secundario, peligro ni ghost coherentes. Cada pantalla improvisa sus botones.

---

## 4. Visión del rediseño

Cuatro variantes con jerarquía visual nítida:

- **`primary`** — relleno con gradiente `gradGold`, texto `textOnGold`, la acción que el ojo persigue. En hover/activo **emite** `glowGold`. Chaflán `chamferM` opcional (`chamfer: true`) para los CTA más jerárquicos (login, «recargar crédito»).
- **`secondary`** — relleno `surface`, borde `borderStrong` (1.5 px), texto `textPrimary`. Acción neutra/alternativa. En hover el borde sube a `borderGold` y aparece glow apenas perceptible.
- **`danger`** — relleno `surface`, borde `danger` (1.5 px), texto `danger`, ícono `danger`. Acciones destructivas (cancelar suscripción, eliminar). En hover aparece `glowStatus(danger)`.
- **`ghost`** — sin relleno, sin borde, solo texto/ícono `textSecondary`. En hover el texto sube a `textPrimary` y aparece un relleno `borderSubtle`. Para acciones terciarias («Cancelar» en modales, «Ver más»).

Todos comparten: tipografía `label` (UPPERCASE), radio `radiusM` (salvo variante chaflán), micro-interacción de press idéntica, spinner de carga que reemplaza el contenido.

---

## 5. Especificación visual

### 5.1 API del widget `AppButton`

```dart
AppButton({
  required String label,
  required VoidCallback? onPressed,   // null => disabled
  AppButtonVariant variant = AppButtonVariant.primary,
  AppButtonSize size = AppButtonSize.md,
  IconData? leadingIcon,              // ícono opcional a la izquierda del label
  bool loading = false,
  bool chamfer = false,               // solo aplica visualmente a variant.primary
  bool expand = false,                // ocupa el ancho disponible (width: double.infinity)
})
```

### 5.2 Tamaños (alturas y métricas exactas)

| `AppButtonSize` | Altura | Padding horizontal | Tipografía label | Ícono | Gap ícono↔label |
|---|---|---|---|---|---|
| `sm` | 32 px | `space12` (12) | `labelSmall` | 14 px | `space8` (8) |
| `md` | 44 px | `space20` (20) | `label` | 16 px | `space8` (8) |
| `lg` | 52 px | `space24` (24) | `label` | 18 px | `space12` (12) |

- Forma: `RoundedRectangleBorder` con `radiusM` (14). Si `variant == primary && chamfer == true`, usar el `ChamferBorder` del prompt 06 (`chamferM` = 12) en lugar del radio.
- El label SIEMPRE va en mayúsculas (`label.toUpperCase()`), color y tracking según el token tipográfico.
- Si `expand == true`, el botón ocupa `double.infinity` de ancho y centra su contenido.

### 5.3 Relleno y bordes por variante (estado `default`)

| Variante | Relleno | Borde | Color texto/ícono |
|---|---|---|---|
| `primary` | `gradGold` (LinearGradient 135°) | ninguno | `textOnGold` |
| `secondary` | `surface` | `borderStrong`, 1.5 px | `textPrimary` |
| `danger` | `surface` | `danger`, 1.5 px | `danger` |
| `ghost` | transparente | ninguno | `textSecondary` |

- Elevación en reposo: `elev1` para `primary` y `secondary`; `elev0` para `danger` y `ghost`.
- El contenido (ícono + label) va en un `Row` con `mainAxisSize.min`, `mainAxisAlignment.center`.

### 5.4 Capas internas de `AppButton`

1. **Contenedor base** — `AnimatedContainer` con `durFast`/`easeStandard`, decoración según variante y estado.
2. **Capa de contenido** — `Row` ícono + `SizedBox(width: gap)` + `Text(label)`. Si `loading == true`, esta capa se reemplaza por el spinner (§6.6).
3. **Detección de input** — `MouseRegion` (cursor + hover) + `GestureDetector`/`Listener` (press). Envolver todo en `Semantics(button: true, ...)`.

---

## 6. Estados e interacciones (matriz §9 del archivo 00 — obligatoria)

### 6.1 `default`
Reposo. Decoración de §5.3. Cursor por defecto hasta entrar el mouse.

### 6.2 `hover` (desktop)
`MouseRegion.onEnter`. Transición `durFast` con `easeStandard`:
- `primary`: aparece `glowGold` (boxShadow), el gradiente se aclara ~6 % (mezclar hacia `goldBright`).
- `secondary`: borde pasa de `borderStrong` a `borderGold`; aparece `glowStatus(gold)` muy tenue; elevación sube a `elev2`.
- `danger`: aparece `glowStatus(danger)`; el relleno se tiñe con `danger` al 8 %.
- `ghost`: aparece relleno `borderSubtle`; texto/ícono suben a `textPrimary`.
- Cursor: `SystemMouseCursors.click` en todas las variantes habilitadas.

### 6.3 `pressed`
`onTapDown`. `AnimatedScale` a **0.97** con `durInstant`. El relleno baja un paso de profundidad: `primary` → mezclar gradiente hacia `goldDeep`; `secondary`/`danger`/`ghost` → relleno `surfaceHud`. Al soltar (`onTapUp`/`onTapCancel`), vuelve a escala 1.0 con `durFast`.

### 6.4 `focused`
Navegación por teclado (`Focus`/`FocusableActionDetector`). Anillo de foco de 2 px, color `cyan`, dibujado **por fuera** del borde del botón (usar `BoxShadow` con spread o un `Container` envolvente con padding `space2`). El anillo nunca se elimina sin reemplazo. `Enter`/`Space` activan `onPressed`.

### 6.5 `disabled`
`onPressed == null`. Opacidad global 0.4, sin glow, sin hover, sin press, cursor por defecto (`SystemMouseCursors.basic`). `Semantics(enabled: false)`. No dispara callbacks.

### 6.6 `loading`
`loading == true`. El botón queda no interactivo (se trata como disabled para input) pero **sin** bajar opacidad a 0.4: mantiene su color para indicar «trabajando». El contenido (ícono+label) se reemplaza por `AppSpinner` (definido en el prompt 14) de diámetro = altura del texto del tamaño activo (≈16 px en `md`). Color del spinner: `textOnGold` en `primary`, color de texto de la variante en el resto. Previene doble submit. `Semantics(label: '$label, cargando')`.

### 6.7 `error`
`AppButton` no tiene estado `error` propio; el error se comunica en el componente contenedor (formulario/modal) vía los prompts 16/17. No aplica matriz de error aquí.

### 6.8 `empty`
No aplica a un botón.

---

## 7. `AppIconButton` (botón solo-ícono)

### 7.1 API

```dart
AppIconButton({
  required IconData icon,
  required VoidCallback? onPressed,
  required String tooltip,            // OBLIGATORIO — accesibilidad
  AppButtonVariant variant = AppButtonVariant.ghost,
  AppButtonSize size = AppButtonSize.md,
  bool loading = false,
})
```

### 7.2 Especificación

- Forma cuadrada con `radiusM`. Lado = altura del tamaño (`sm`=32, `md`=44, `lg`=52). Área de hit mínima 32×32 (§10 del archivo 00).
- Tamaño del ícono: igual al de `AppButton` por tamaño (14/16/18 px).
- Variantes: reutiliza el mismo relleno/borde/glow de §5.3 (`ghost` es el default y el más usado para barras de acciones).
- **`tooltip` es obligatorio**: si está vacío, el widget debe lanzar un `assert` en debug. El tooltip usa el componente del prompt 13 (Tooltip HUD). Además se expone vía `Semantics(button: true, label: tooltip)`.
- Estados: misma matriz de §6 (hover/pressed/focused/disabled/loading). El spinner de `loading` ocupa el centro del cuadrado.

---

## 8. Animaciones

| Interacción | Token duración | Token curva | Propiedad animada |
|---|---|---|---|
| Cambio de color/borde en hover | `durFast` | `easeStandard` | color, boxShadow (vía `AnimatedContainer`) |
| Aparición de glow | `durFast` | `easeStandard` | `boxShadow` |
| Press (scale down) | `durInstant` | `easeStandard` | `AnimatedScale` 1.0→0.97 |
| Release (scale up) | `durFast` | `easeStandard` | `AnimatedScale` 0.97→1.0 |
| Entrada del spinner de loading | `durFast` | `easeEntrance` | crossfade contenido↔spinner |

- **Reduced motion** (`AppMotion.reduced`, prompt 04): el press no escala (cambia solo el color), el glow aparece sin transición (instantáneo), el spinner gira igual (es feedback funcional, no decoración). Sin shimmer en botones.
- Ninguna animación supera `durFast`. Ninguna anima `width`/`height`.

---

## 9. Accesibilidad

- Todo botón solo-ícono tiene `tooltip` + `Semantics.label`. `assert` si falta.
- Contraste: `textOnGold` sobre `gradGold` ≥ 4.5:1; `textPrimary` sobre `surface` ≥ 12:1; `danger` sobre `surface` ≥ 4.5:1 (verificar con la paleta §4). El estado destructivo lleva color **+ ícono + texto**, nunca solo color.
- Foco visible siempre (anillo `cyan` 2 px), navegable con `Tab`, activable con `Enter`/`Space`.
- `disabled` reportado a accesibilidad (`Semantics(enabled: false)`); `loading` reportado como ocupado.
- Área de hit ≥ 32×32 px incluso en `sm`.

---

## 10. Checklist de aceptación

- [ ] Existen `app_button.dart` y `app_icon_button.dart` en `lib/core/ui/widgets/`.
- [ ] `AppButton` soporta las 4 variantes, los 3 tamaños, `leadingIcon`, `loading`, `chamfer`, `expand`.
- [ ] `primary` usa `gradGold` + `textOnGold`; emite `glowGold` en hover/activo.
- [ ] `secondary`/`danger`/`ghost` cumplen relleno/borde/color de §5.3.
- [ ] Las alturas son exactamente 32/44/52 px por tamaño.
- [ ] La matriz completa de §6 está implementada (default/hover/pressed/focused/disabled/loading).
- [ ] Press anima escala a 0.97 con `durInstant`; hover usa `durFast`.
- [ ] El anillo de foco `cyan` 2 px es visible y nunca se elimina sin reemplazo.
- [ ] `loading` reemplaza el contenido por `AppSpinner`, mantiene color y bloquea doble submit.
- [ ] `AppIconButton` exige `tooltip` (assert) y lo expone como `Semantics.label`.
- [ ] Cero hex sueltos y cero magic numbers: todo por token.
- [ ] Respeta reduced-motion según §8.
- [ ] `flutter analyze` sin warnings nuevos; compila en 1280×720 y 1024×600.

---

## 11. Dependencias

- **01** (tokens de color: `gradGold`, `goldGlow`, `borderStrong`, `borderGold`, `danger`, `textOnGold`, `surface`, `surfaceHud`, `borderSubtle`).
- **02** (tipografía: `label`, `labelSmall`).
- **03** (dimensión: `space*`, `radiusM`, `chamferM`, `elev0/1/2`, `glowGold`, `glowStatus`).
- **04** (motion: `durInstant`, `durFast`, `easeStandard`, `easeEntrance`, `AppMotion.reduced`).
- **06** (primitivas HUD: `ChamferBorder`).
- **14** (`AppSpinner` — para el estado `loading`; si el prompt 14 aún no se ejecutó, dejar un spinner provisional con `CircularProgressIndicator` y reemplazarlo al cerrar el prompt 14).
