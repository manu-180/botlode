# 10 — Inputs y campos de formulario (`AppTextField`)

> Prompt de la **Fase B — Componentes núcleo**. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Leé el archivo 00 completo antes de ejecutar. Todo valor se referencia por **nombre de token**.

---

## 1. Objetivo

Crear el campo de texto premium reutilizable `AppTextField` y sus variantes (password, search) con estética HUD: relleno de superficie técnica, foco en `cyan` con glow sutil, label flotante animado, helper persistente y error inline. Reemplaza el `inputDecorationTheme` plano de Material que la app usa hoy.

---

## 2. Archivos

- **Crear** `lib/core/ui/widgets/app_text_field.dart` — `AppTextField` + enum `AppTextFieldVariant` (`text`, `password`, `search`) + enum `AppTextFieldLabelMode` (`floating`, `top`).
- **Modificar** `lib/core/config/theme/app_theme.dart` — reemplazar el `inputDecorationTheme` actual (líneas 30–51) por uno alineado a los tokens, como fallback; los formularios de la app usarán `AppTextField` directamente.
- No crear subcarpetas.

---

## 3. Estado actual

`app_theme.dart` define un `InputDecorationTheme`: `filled`, `fillColor: surface.withOpacity(0.5)`, padding `20×16`, borde `radius 12` con `borderGlass`, foco en `primary` (oro) 2 px, error en `error`, label `textSecondary`. No hay label flotante animado, ni helper persistente, ni ícono prefijo, ni toggle de password, ni botón de limpiar en búsqueda, ni glow de foco. El foco en oro contradice §4.3 del archivo 00 (el oro se reserva para acción/valor; el foco técnico es **cyan**).

---

## 4. Visión del rediseño

Un campo que se siente un instrumento de terminal: caja `surfaceHud` con borde hairline, label que **flota** hacia arriba al enfocar/llenar, ícono prefijo opcional, y al foco un borde `cyan` de 2 px con glow `glowCyan` muy tenue — la sensación de «canal de datos activo». Helper text siempre visible (no salta el layout). Error debajo del campo, con ícono, en `danger`. Validación **on-blur**, nunca on-keystroke (no castiga al usuario mientras escribe).

---

## 5. Especificación visual

### 5.1 API del widget

```dart
AppTextField({
  required TextEditingController controller,
  String? label,
  AppTextFieldLabelMode labelMode = AppTextFieldLabelMode.floating,
  AppTextFieldVariant variant = AppTextFieldVariant.text,
  IconData? prefixIcon,
  String? helperText,                       // persistente
  String? Function(String?)? validator,     // se ejecuta on-blur
  ValueChanged<String>? onChanged,
  bool enabled = true,
  TextInputType? keyboardType,
  int maxLines = 1,
})
```

### 5.2 Caja del campo

- Altura mínima: 48 px (campo de una línea). Multilínea crece en alto.
- Relleno: `surfaceHud`. Radio: `radiusM` (14).
- Borde por estado (1.5 px salvo foco): ver §6.
- Padding interno: `space16` horizontal, `space12` vertical. Si hay `prefixIcon`, ícono 18 px + `space12` de gap antes del texto.
- Tipografía del texto ingresado: `bodyM`, color `textPrimary`.
- Color del cursor de texto (`cursorColor`): `cyan`.

### 5.3 Label

- **`floating`**: el label arranca dentro del campo (como placeholder) en `bodyM`/`textTertiary`. Al enfocar o si hay contenido, se anima hacia el borde superior del campo: encoge a `labelSmall` (UPPERCASE), color `cyan` si enfocado o `textSecondary` si lleno-sin-foco, montado sobre un pequeño «notch» de fondo `surfaceHud` que corta el borde.
- **`top`**: el label se renderiza como `label` (UPPERCASE) en `textSecondary`, fijo arriba del campo con `space8` de separación. No anima.

### 5.4 Helper y error

- **Helper**: debajo del campo, `space8` de separación, tipografía `bodyS`/`textTertiary`. Siempre ocupa su espacio (reserva de altura fija ≈16 px) aunque esté vacío, para que el layout no salte al aparecer el error.
- **Error**: cuando `validator` devuelve mensaje, ese espacio inferior muestra: ícono `error` 14 px en `danger` + `space4` + texto del error en `bodyS`/`danger`. El error reemplaza al helper.

### 5.5 Variantes

- **`text`**: campo estándar.
- **`password`**: `obscureText` activo; sufijo = `AppIconButton` (variante `ghost`, `sm`) con ícono ojo abierto/tachado que alterna la visibilidad; tooltip «Mostrar contraseña» / «Ocultar contraseña».
- **`search`**: `prefixIcon` forzado a ícono lupa; sufijo = botón limpiar (`AppIconButton` `ghost` `sm`, ícono X) visible solo si hay texto; al pulsarlo limpia el `controller` y mantiene el foco. Radio puede subir a `radiusPill` si el diseño de la toolbar (prompt 27) lo pide; por defecto `radiusM`.

---

## 6. Estados e interacciones (matriz §9 del archivo 00)

| Estado | Borde | Relleno | Label | Glow |
|---|---|---|---|---|
| `default` | `borderDefault`, 1.5 px | `surfaceHud` | en placeholder (floating) o arriba (top) | ninguno |
| `hover` | `borderStrong`, 1.5 px | `surfaceHud` | sin cambio | ninguno; cursor `text` |
| `focused` | `cyan`, **2 px** | `surfaceHud` | flotado y en `cyan` | `glowCyan` muy tenue (boxShadow) |
| `filled` (lleno, sin foco) | `borderDefault`, 1.5 px | `surfaceHud` | flotado y en `textSecondary` | ninguno |
| `error` | `danger`, 1.5 px (2 px si además enfocado) | `surfaceHud` | flotado y en `danger` | `glowStatus(danger)` muy tenue |
| `disabled` | `borderSubtle`, 1 px | `surfaceHud` al 50 % opacidad | en `textTertiary` | ninguno; cursor por defecto; no editable |

- **Validación**: se dispara en `onBlur` (pérdida de foco) y al `submit` del formulario. NO on-keystroke. Si el usuario corrige un campo en error y vuelve a salir, se revalida y el error se limpia si pasó.
- En `error`, el `Semantics` del campo expone el mensaje (ver §8).
- `loading`: el campo en sí no tiene loading; si un formulario está enviando, los campos pasan a `disabled` mientras dura el envío.
- `empty`: no aplica a un input individual.

---

## 7. Animaciones

| Interacción | Token duración | Token curva | Propiedad |
|---|---|---|---|
| Label flotante (sube/baja) | `durFast` | `easeStandard` | posición Y + tamaño de fuente (`AnimatedDefaultTextStyle` + `AnimatedAlign`/`AnimatedPositioned`) |
| Borde cambia de color/grosor | `durFast` | `easeStandard` | `AnimatedContainer` border |
| Glow de foco aparece/desaparece | `durFast` | `easeStandard` | `boxShadow` |
| Aparición del texto de error | `durFast` | `easeEntrance` | fade + translateY 4 px |
| Sufijo «limpiar» aparece/desaparece (search) | `durInstant` | `easeStandard` | `AnimatedOpacity` |

- **Reduced motion**: el label no se desliza, hace crossfade entre estado bajo y estado flotado (120 ms); el error aparece sin translateY. El glow aparece instantáneo.
- Ninguna animación bloquea la escritura.

---

## 8. Accesibilidad

- Contraste: `textPrimary` sobre `surfaceHud` ≥ 12:1; `textSecondary`/`textTertiary` verificados ≥ 4.5:1 / ≥ 3:1.
- Foco visible: borde `cyan` 2 px es el indicador; nunca se elimina. Orden de `Tab` = orden visual.
- El error se anuncia: envolver el bloque de error en `Semantics(liveRegion: true)` y asociar el mensaje al campo (`InputDecoration.errorText` o `Semantics(label: ...)`).
- Al enviar un formulario con errores: foco automático al **primer** campo inválido (el formulario contenedor llama `requestFocus` sobre él).
- El estado de error lleva color `danger` **+ ícono + texto**.
- `password`: el toggle es un control accesible con tooltip; el campo enmascarado no expone el contenido a accesibilidad cuando está oculto.

---

## 9. Checklist de aceptación

- [ ] Existe `app_text_field.dart` en `lib/core/ui/widgets/` con `AppTextField` y los dos enums.
- [ ] Las 3 variantes funcionan: `text`, `password` (toggle), `search` (lupa + limpiar).
- [ ] Label en modo `floating` anima al enfocar/llenar; modo `top` fijo.
- [ ] Foco usa borde `cyan` 2 px + `glowCyan` tenue — NO oro.
- [ ] Helper text es persistente y reserva altura fija (el layout no salta al mostrar error).
- [ ] Error inline = ícono `danger` + texto `bodyS` debajo del campo.
- [ ] Validación se ejecuta on-blur y on-submit, nunca on-keystroke.
- [ ] Matriz de estados de §6 implementada (default/hover/focused/filled/error/disabled).
- [ ] El error está envuelto en `Semantics(liveRegion: true)`.
- [ ] Cero hex sueltos / magic numbers; todo por token.
- [ ] Respeta reduced-motion según §7.
- [ ] `flutter analyze` sin warnings nuevos; compila en 1280×720 y 1024×600.

---

## 10. Dependencias

- **01** (color: `surfaceHud`, `borderDefault`, `borderStrong`, `borderSubtle`, `cyan`, `cyanGlow`, `danger`, `textPrimary/Secondary/Tertiary`).
- **02** (tipografía: `bodyM`, `bodyS`, `label`, `labelSmall`).
- **03** (dimensión: `space*`, `radiusM`, `radiusPill`, `glowCyan`, `glowStatus`).
- **04** (motion: `durInstant`, `durFast`, `easeStandard`, `easeEntrance`, `AppMotion.reduced`).
- **05** (iconografía: lupa, ojo/ojo-tachado, X, ícono de error).
- **09** (`AppIconButton` — para el toggle de password y el botón limpiar de search).
