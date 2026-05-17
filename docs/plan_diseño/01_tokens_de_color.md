# 01 — Tokens de color

> Prompt de la **Fase A · Fundaciones**. Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Lee el archivo 00 completo antes de ejecutar este prompt. Los valores de color son los de **§4** del archivo 00; aquí se materializan en código.

---

## 1. Objetivo

Reescribir y **extender** `lib/core/config/theme/app_colors.dart` con la paleta maestra completa definida en §4 del archivo 00 (capas de fondo, vidrio, marca, semánticos, texto/bordes, gradientes). El archivo es la **única fuente de verdad de color** de toda la app: ningún otro archivo puede declarar un `Color(0x...)` suelto. Este prompt es el cimiento de los 64 prompts restantes; si un token falta acá, el resto del plan no compila.

---

## 2. Archivos

- **Modificar (reescribir):** `lib/core/config/theme/app_colors.dart`
- **No tocar todavía:** ningún otro archivo. La migración de hex sueltos de la app la harán los prompts de cada pantalla; este prompt solo deja la API de color lista y los alias para que nada se rompa al recompilar.

---

## 3. Estado actual

El archivo actual define 13 miembros:

```dart
background #050A10 · surface #0F1621 · glassSurface rgba(20,30,45,0.7)
primary #FFC000 · secondary #00F0FF · error #FF003C · success #00FF94
warning #FF9900 · textPrimary #E0E6ED · textSecondary #94A3B8
borderGlass rgba(255,255,255,0.1) · borderHighlight rgba(255,192,0,0.3)
primaryGradient (LinearGradient oro)
```

Problemas: paleta insuficiente para profundidad por capas (un solo `background` + `surface`), no hay tokens de vidrio fuerte ni de scrim, no hay escala de texto terciario, los nombres de borde (`borderGlass`, `borderHighlight`) no coinciden con el sistema nuevo, `error #FF003C` tiene contraste pobre, y solo existe un gradiente. Estos miembros **se usan en toda la app** (`app_theme.dart`, vistas de billing, dashboard, etc.), así que **no se pueden eliminar**: se mantienen como alias.

---

## 4. Visión del rediseño

`AppColors` pasa a ser una clase de tokens exhaustiva y autodocumentada, organizada en bloques con comentario de cabecera por categoría. Cada token lleva un comentario de una línea con su uso y, donde aplique, su ratio de contraste verificado. La paleta habilita la regla de oro del archivo 00 §3.1: **profundidad siempre** (6 capas de fondo), **el oro se gana** (oro aislado en su bloque de marca), **la luz tiene fuente** (tokens `*Glow` separados de los colores sólidos).

Resultado: un archivo donde el ejecutor de cualquier prompt posterior encuentra el token exacto que necesita sin inventar valores, y donde los nombres viejos siguen resolviendo para que la app compile sin tocar 40 archivos.

---

## 5. Especificación visual (tokens a declarar)

Declarar **todos** los miembros como `static const`. Usar `Color(0xAARRGGBB)` para sólidos y `Color.fromRGBO(r,g,b,opacity)` para colores con alpha fraccional. Bloques, en este orden:

### 5.1 Capas de fondo (profundidad) — §4.1

| Token | Valor | Comentario obligatorio |
|---|---|---|
| `voidBlack` | `Color(0xFF03070C)` | Capa más profunda; viñeta de bordes del fondo. |
| `background` | `Color(0xFF050A10)` | Fondo base de la app. (Token existente — mantener.) |
| `bgElevated01` | `Color(0xFF0A111A)` | Primer nivel de elevación; zonas de contenido. |
| `surface` | `Color(0xFF0F1621)` | Superficie de paneles/cards. (Token existente — mantener.) |
| `surfaceRaised` | `Color(0xFF141D2B)` | Cards en hover, modales, popovers. |
| `surfaceHud` | `Color(0xFF0C1118)` | Fondo de lecturas HUD/terminal. |

### 5.2 Vidrio (glassmorphism) — §4.2

| Token | Valor | Comentario |
|---|---|---|
| `glassSurface` | `Color.fromRGBO(20, 30, 45, 0.55)` | Relleno de panel de vidrio (con blur). **Ajustar opacidad de 0.7 a 0.55** para el blur de prompt 07. |
| `glassSurfaceStrong` | `Color.fromRGBO(24, 34, 50, 0.72)` | Vidrio de modales (más opaco, legibilidad). |
| `glassHighlightTop` | `Color.fromRGBO(255, 255, 255, 0.06)` | Highlight de 1 px en el borde superior del vidrio. |
| `glassBorder` | `Color.fromRGBO(255, 255, 255, 0.10)` | Borde hairline estándar de vidrio. |
| `scrim` | `Color.fromRGBO(3, 6, 11, 0.66)` | Velo de fondo detrás de modales (66 %). |

### 5.3 Marca / acentos — §4.3

| Token | Valor | Comentario |
|---|---|---|
| `gold` | `Color(0xFFFFC000)` | Acción primaria, valor/dinero, branding. Oro industrial. |
| `goldBright` | `Color(0xFFFFD740)` | Punta de gradiente, highlight, hover del oro. |
| `goldDeep` | `Color(0xFFC8930A)` | Base/sombra de gradiente del oro, estado pressed. |
| `goldGlow` | `Color.fromRGBO(255, 192, 0, 0.35)` | Glow del oro. |
| `cyan` | `Color(0xFF00F0FF)` | Acento técnico/datos, estado «procesando», líneas HUD. |
| `cyanGlow` | `Color.fromRGBO(0, 240, 255, 0.30)` | Glow del cyan. |

### 5.4 Estados semánticos — §4.4

| Token | Valor | Comentario |
|---|---|---|
| `success` | `Color(0xFF00FF94)` | Activo, online, positivo. |
| `successGlow` | `Color.fromRGBO(0, 255, 148, 0.28)` | Glow de éxito. |
| `warning` | `Color(0xFFFF9D2E)` | Mantenimiento, suspendido, vence pronto. (Antes `#FF9900`.) |
| `warningGlow` | `Color.fromRGBO(255, 157, 46, 0.28)` | Glow de advertencia. |
| `danger` | `Color(0xFFFF2D55)` | Crítico, error, offline, destructivo. Reemplaza `#FF003C` (mejor contraste). |
| `dangerGlow` | `Color.fromRGBO(255, 45, 85, 0.30)` | Glow de error. |
| `info` | `Color(0xFF3B9DFF)` | Informativo neutro (banners de trial, ayuda). |

### 5.5 Texto y bordes — §4.5

| Token | Valor | Comentario |
|---|---|---|
| `textPrimary` | `Color(0xFFEAF0F7)` | Texto principal. Contraste ≥ 12:1 sobre `surface`. (Sube de `#E0E6ED`.) |
| `textSecondary` | `Color(0xFF9FB0C3)` | Texto secundario/labels. Contraste ≥ 4.5:1. |
| `textTertiary` | `Color(0xFF5E6E82)` | Deshabilitado, metadatos, hints. ≥ 3:1. |
| `textOnGold` | `Color(0xFF0A0A0A)` | Texto sobre superficies doradas. |
| `borderSubtle` | `Color.fromRGBO(255, 255, 255, 0.06)` | Divisores internos muy sutiles. |
| `borderDefault` | `Color.fromRGBO(255, 255, 255, 0.10)` | Borde estándar de cajas. |
| `borderStrong` | `Color.fromRGBO(255, 255, 255, 0.16)` | Borde de hover/foco neutro. |
| `borderGold` | `Color.fromRGBO(255, 192, 0, 0.32)` | Borde con tinte dorado para énfasis. |

### 5.6 Alias de compatibilidad (NO eliminar — la app los importa)

Declarar al final, en un bloque comentado `// --- ALIAS LEGADO (no romper imports existentes) ---`:

```dart
@Deprecated('Usar gold')        static const Color primary = gold;
@Deprecated('Usar danger')      static const Color error = danger;
@Deprecated('Usar borderDefault') static const Color borderGlass = borderDefault;
@Deprecated('Usar borderGold')  static const Color borderHighlight = borderGold;
```

Reglas de los alias:
- `secondary`, `background`, `surface`, `glassSurface`, `success`, `warning`, `textPrimary`, `textSecondary` **conservan su nombre original** y no necesitan alias separado: ya forman parte de la paleta nueva. `secondary` puede declararse como `static const Color secondary = cyan;`.
- Marcar con `@Deprecated` **solo** los alias cuyo nombre cambió (`primary`, `error`, `borderGlass`, `borderHighlight`). Esto genera warnings de lint que sirven de hoja de ruta para la migración, sin romper la compilación.
- **Prohibido** eliminar cualquier nombre que la app ya use hoy. Verificar con `flutter analyze` que no aparezcan errores de símbolo no encontrado.

### 5.7 Gradientes (getters) — §4.6

Exponer los gradientes como **getters estáticos** que devuelven `LinearGradient` / `RadialGradient` (no como campos `const`, para poder usar `Alignment` y stops con claridad). Mantener `primaryGradient` existente como alias de `gradGold`.

| Getter | Tipo | Definición exacta |
|---|---|---|
| `gradGold` | `LinearGradient` | `begin: Alignment.topLeft, end: Alignment.bottomRight` (≈135°), `colors: [goldBright, gold, goldDeep]`, `stops: [0.0, 0.55, 1.0]`. |
| `gradGoldSheen` | `LinearGradient` | Barrido de shimmer: `begin: Alignment.topLeft, end: Alignment.bottomRight`, `colors: [Colors.transparent, Color.fromRGBO(255,255,255,0.4), Colors.transparent]`, `stops: [0.35, 0.5, 0.65]`. |
| `gradPanel` | `LinearGradient` | ≈160°: `begin: Alignment.topCenter` ligeramente a la izquierda, `end: Alignment.bottomCenter` a la derecha (`begin: Alignment(-0.3,-1), end: Alignment(0.3,1)`), `colors: [surfaceRaised, surface]`. |
| `gradVoid` | `RadialGradient` | `center: Alignment(0,-0.2), radius: 1.2`, `colors: [bgElevated01, voidBlack]`, `stops: [0.0, 0.8]`. Fondo de pantalla (prompt 08). |
| `gradCyanData` | `LinearGradient` | `begin: Alignment.bottomCenter, end: Alignment.topCenter`, `colors: [cyan, Color.fromRGBO(0,240,255,0.0)]`. Para barras/charts. |

Mantener:
```dart
@Deprecated('Usar gradGold')
static LinearGradient get primaryGradient => gradGold;
```

### 5.8 Documentación de contraste

En la cabecera del archivo, dejar un bloque de comentario `/// CONTRASTE VERIFICADO (WCAG 2.1, sobre fondo indicado)` con cada par crítico y su ratio aproximado:

```
/// textPrimary  sobre surface (#0F1621)  → ~13.5:1  (AAA)
/// textSecondary sobre surface           → ~6.2:1   (AA normal)
/// textTertiary sobre surface            → ~3.1:1   (AA grande / glifos UI)
/// textOnGold   sobre gold (#FFC000)     → ~11:1    (AAA)
/// gold         sobre surface            → ~9:1     (uso como glifo/acento)
/// danger       sobre surface            → ~4.6:1   (AA normal)
/// success      sobre surface            → ~10.5:1  (AAA)
```
El ejecutor verifica cada ratio con una calculadora de contraste; si alguno cae por debajo del umbral de §4 (4.5:1 texto, 3:1 glifo), lo anota como hallazgo y **no** inventa un color nuevo: lo escala dentro de la paleta.

---

## 6. Estados e interacciones

No aplica directamente (es un archivo de tokens, no un widget). Sin embargo, los tokens deben **cubrir todos los estados** de la matriz de §9 del archivo 00:

- `hover` → `borderStrong`, `borderGold`.
- `pressed` → `goldDeep` (relleno un paso más profundo).
- `focused` → `cyan` / `gold` para el anillo de foco.
- `disabled` → no hay token de color propio; se logra con `Opacity 0.4` sobre el color base (regla del archivo 00 §9). No declarar un `*Disabled`.
- `error` → `danger` + `dangerGlow`.

Verificar que para cada estado exista el token necesario; si falta, agregarlo a la paleta antes de cerrar el prompt.

---

## 7. Animaciones

No aplica (archivo de datos estático). Los tokens `*Glow` existen para que los prompts de motion (04) y de glow (07) animen opacidad/blur sobre ellos; no se anima nada dentro de `app_colors.dart`.

---

## 8. Accesibilidad

- Cada par texto/fondo del bloque 5.8 cumple §10 del archivo 00 (≥4.5:1 texto, ≥3:1 glifo).
- `danger` se eligió `#FF2D55` en lugar de `#FF003C` precisamente para subir el contraste sobre fondos oscuros.
- El color **nunca** es el único portador de estado: los prompts que consuman `success`/`warning`/`danger` siempre añaden ícono + texto. Dejar esto escrito como comentario en el bloque 5.4.

---

## 9. Checklist de aceptación

- [ ] `app_colors.dart` declara los **6** tokens de fondo de §5.1 con los valores hex exactos.
- [ ] Declara los **5** tokens de vidrio de §5.2; `glassSurface` se actualizó a opacidad `0.55`.
- [ ] Declara los **6** tokens de marca de §5.3 (`gold`, `goldBright`, `goldDeep`, `goldGlow`, `cyan`, `cyanGlow`).
- [ ] Declara los **2** acentos de mood `accentMagenta` (`#FF2FD4`) y `accentViolet` (`#9B5CFF`) — ver archivo 00 §4.3. Reemplazan los hex sueltos `#FF00D6` y `#7B00FF` que hoy usan los moods «happy» y «confused» del bot. Documentar el mapeo mood→color en comentario.
- [ ] Declara los **7** tokens semánticos de §5.4; `warning` = `#FF9D2E`, `danger` = `#FF2D55`.
- [ ] Declara los **8** tokens de texto/borde de §5.5; `textTertiary` y `textOnGold` existen.
- [ ] Los nombres legados `primary`, `secondary`, `error`, `background`, `surface`, `glassSurface`, `glassBorder` (o el equivalente migrado) **resuelven** — la app compila sin error de símbolo.
- [ ] Los alias de nombre cambiado (`primary`, `error`, `borderGlass`, `borderHighlight`) llevan `@Deprecated`.
- [ ] Los **5** gradientes (`gradGold`, `gradGoldSheen`, `gradPanel`, `gradVoid`, `gradCyanData`) existen como getters con el tipo correcto; `primaryGradient` sigue funcionando como alias.
- [ ] La cabecera incluye el bloque de contraste verificado de §5.8.
- [ ] Todos los miembros son `static const` (gradientes pueden ser `static ... get`).
- [ ] No quedan `Color(0x...)` mágicos fuera de `AppColors`: `flutter analyze` no agrega warnings nuevos y la app sigue compilando.
- [ ] Cada token tiene comentario de uso de una línea.

---

## 10. Dependencias

- **Previo:** ninguno. Es el primer prompt de la Fase A.
- **Habilita:** 02 (tipografía usa colores de texto), 03 (elevación referencia `goldGlow`/`cyanGlow`), 06 (primitivas HUD usan `borderGold`, `cyan`, `surfaceHud`), 07 (glass/glow consumen tokens de vidrio y `*Glow`), 08 (fondo usa `gradVoid`, `voidBlack`) y **todos** los prompts de pantalla 09–65.
