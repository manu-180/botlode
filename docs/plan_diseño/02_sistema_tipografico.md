# 02 — Sistema tipográfico + fuente mono

> Prompt de la **Fase A · Fundaciones**. Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md` y del prompt **01** (tokens de color).
> Lee el archivo 00 completo. La escala de texto es la de **§5** del archivo 00.

---

## 1. Objetivo

Construir el sistema tipográfico completo: crear la clase `AppTextStyles` con toda la escala de §5 del archivo 00, incorporar **JetBrains Mono** vía `google_fonts` como familia de datos/HUD, y mapear la escala al `TextTheme` de `ThemeData` en `app_theme.dart`. Oxanium queda como voz de marca (display/UI); JetBrains Mono aporta el carácter «terminal de instrumentación» en números, IDs, timestamps y consola.

---

## 2. Archivos

- **Crear:** `lib/core/config/theme/app_text_styles.dart`
- **Modificar:** `lib/core/config/theme/app_theme.dart` (mapear `textTheme`, `fontFamily`, estilos de botón/input/appbar).
- **Modificar:** `lib/main.dart` (precarga de la fuente mono al arranque).
- **No tocar:** `pubspec.yaml` — `google_fonts: ^6.2.1` ya está en dependencias; Oxanium ya está como fuente de asset variable.

---

## 3. Estado actual

`app_theme.dart` define `fontFamily: 'Oxanium'` y un `TextTheme` parcial con 5 estilos sueltos (`displayLarge`, `displayMedium`, `titleLarge`, `bodyLarge`, `bodyMedium`) con tamaños y `letterSpacing` hardcodeados. No existe escala de `label`, ni estilos mono, ni una clase central de estilos: cada widget de la app arma su `TextStyle` a mano. No hay figuras tabulares en ninguna parte, así que los tickers numéricos saltan de ancho al animar. JetBrains Mono no está cargada.

---

## 4. Visión del rediseño

Una única clase `AppTextStyles` con **13 getters** de `TextStyle`, uno por token de §5. Cada widget de la app deja de inventar `TextStyle` y consume `AppTextStyles.titleM`, `AppTextStyles.numericTicker`, etc. El `TextTheme` de Material se llena con esos mismos tokens para que widgets de Material (`Text` sin estilo, `TextField`, etc.) hereden la tipografía correcta.

Dos familias, roles claros:
- **Oxanium** — display, títulos, labels, botones, navegación. La «voz».
- **JetBrains Mono** — lecturas HUD, números tabulares, IDs, timestamps, código, terminal de chat. El «instrumento».

Las cifras que se animan o se alinean en columna usan **figuras tabulares** para que el ancho de cada dígito sea idéntico y el layout no salte.

---

## 5. Especificación visual

### 5.1 Familias

- **Oxanium:** ya es asset variable (`assets/fonts/Oxanium-VariableFont_wght.ttf`). Se referencia con `fontFamily: 'Oxanium'`.
- **JetBrains Mono:** se obtiene en runtime con `google_fonts`. No se agrega como asset. Patrón de uso:
  ```dart
  import 'package:google_fonts/google_fonts.dart';
  // dentro de un getter:
  GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w400, ...)
  ```
  `GoogleFonts.jetBrainsMono(...)` devuelve un `TextStyle`; se le encadenan `.copyWith(...)` para color, tracking y `fontFeatures`.

### 5.2 Clase `AppTextStyles`

Crear `lib/core/config/theme/app_text_styles.dart` con cabecera `// Archivo: lib/core/config/theme/app_text_styles.dart`. Importa `app_colors.dart` y `google_fonts`. Todos los estilos son **getters `static`** (no `const`, porque los mono usan `GoogleFonts`).

Constante privada de feature tabular reutilizable:
```dart
const _tabular = FontFeature.tabularFigures();
```

Escala completa (§5.1 del archivo 00). Color por defecto `AppColors.textPrimary` salvo indicación:

| Getter | Family | size | weight | letterSpacing | height | Extras |
|---|---|---|---|---|---|---|
| `displayXL` | Oxanium | 40 | `w700` | 1.5 | 1.15 | Título hero (login). |
| `displayL` | Oxanium | 32 | `w700` | 1.2 | 1.18 | Título de pantalla grande. |
| `displayM` | Oxanium | 26 | `w700` | 1.0 | 1.2 | Títulos de sección. |
| `titleL` | Oxanium | 21 | `w600` | 0.8 | 1.25 | Títulos de panel/modal. |
| `titleM` | Oxanium | 17 | `w600` | 0.5 | 1.3 | Subtítulos, títulos de card. |
| `label` | Oxanium | 13 | `w600` | 1.4 | 1.2 | UI/tabs/botones/nav. **Texto en MAYÚSCULAS** (lo aplica el widget consumidor con `.toUpperCase()`). |
| `labelSmall` | Oxanium | 11 | `w600` | 1.6 | 1.2 | Micro-labels, badges. MAYÚSCULAS. |
| `bodyL` | Oxanium | 16 | `w400` | 0.0 | 1.5 | Texto de lectura largo. |
| `bodyM` | Oxanium | 14 | `w400` | 0.0 | 1.5 | Texto estándar. |
| `bodyS` | Oxanium | 12.5 | `w400` | 0.0 | 1.5 | Texto secundario. Color `textSecondary`. |
| `hudReadout` | JetBrains Mono | 13 | `w500` | 0.5 | 1.3 | Lecturas de datos/valores HUD. `fontFeatures: [_tabular]`. Color `textPrimary`. |
| `mono` | JetBrains Mono | 12 | `w400` | 0.0 | 1.4 | IDs, código, timestamps, terminal. `fontFeatures: [_tabular]`. Color `textSecondary`. |
| `numericTicker` | JetBrains Mono | 28 | `w700` | 0.5 | 1.0 | Cifras grandes animadas (crédito, precios). `fontFeatures: [_tabular]`. Color `textPrimary`. |

Notas de implementación:
- `letterSpacing` se expresa en logical pixels. El «+1.5» de §5 se traduce a `letterSpacing: 1.5`.
- `height` es el multiplicador de interlineado: **1.5 para body**, **~1.2 para títulos** (1.15–1.3 según tamaño, ver tabla).
- Los tres estilos mono (`hudReadout`, `mono`, `numericTicker`) **deben** incluir `fontFeatures: const [FontFeature.tabularFigures()]`. Sin esto, los tickers numéricos saltan de ancho al contar y la regla de §5 del archivo 00 se incumple.
- Cada getter devuelve un `TextStyle` con `color` explícito tomado de `AppColors` (nunca color crudo).

Patrón ejemplo para un estilo Oxanium y uno mono:
```dart
static TextStyle get titleM => const TextStyle(
      fontFamily: 'Oxanium',
      fontSize: 17, fontWeight: FontWeight.w600,
      letterSpacing: 0.5, height: 1.3,
      color: AppColors.textPrimary,
    );

static TextStyle get numericTicker => GoogleFonts.jetBrainsMono(
      fontSize: 28, fontWeight: FontWeight.w700,
      letterSpacing: 0.5, height: 1.0,
      color: AppColors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
```

### 5.3 Mapeo al `TextTheme` de `ThemeData`

En `app_theme.dart`, reemplazar el `TextTheme` literal por uno construido desde `AppTextStyles`:

| Slot Material | Token `AppTextStyles` |
|---|---|
| `displayLarge` | `displayXL` |
| `displayMedium` | `displayL` |
| `displaySmall` | `displayM` |
| `headlineMedium` | `titleL` |
| `titleLarge` | `titleL` |
| `titleMedium` | `titleM` |
| `labelLarge` | `label` |
| `labelMedium` | `label` |
| `labelSmall` | `labelSmall` |
| `bodyLarge` | `bodyL` |
| `bodyMedium` | `bodyM` |
| `bodySmall` | `bodyS` |

`fontFamily` global de `ThemeData` permanece `'Oxanium'` (los estilos mono lo sobreescriben puntualmente vía `GoogleFonts`).

### 5.4 Ajustes a estilos de componente en `app_theme.dart`

- `elevatedButtonTheme.textStyle` → usar `AppTextStyles.label` (13/`w600`/+1.4). El consumidor pasa el texto en MAYÚSCULAS.
- `inputDecorationTheme.labelStyle` → `AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)`.
- `inputDecorationTheme` debe declarar también `hintStyle` con `AppTextStyles.bodyM.copyWith(color: AppColors.textTertiary)`.
- `appBarTheme.titleTextStyle` → `AppTextStyles.titleM`.
- Eliminar todos los `TextStyle(...)` literales que queden en `app_theme.dart`: deben venir de `AppTextStyles`.

### 5.5 Precarga de JetBrains Mono en `main.dart`

`google_fonts` descarga la fuente la primera vez que se usa, lo que puede provocar un parpadeo. Para evitarlo, precargar en el arranque (dentro de la zona de `runZonedGuarded`, antes de `runApp`, después de `dotenv.load`):
```dart
import 'package:google_fonts/google_fonts.dart';
// ...
await GoogleFonts.pendingFonts([
  GoogleFonts.jetBrainsMono(),
]);
```
Si la llamada falla (sin red), envolver en `try/catch` que solo loguee: la app debe arrancar igual usando el fallback del sistema. No bloquear el arranque por la fuente.

---

## 6. Estados e interacciones

No aplica directamente: `AppTextStyles` provee estilos base. Los estados de §9 del archivo 00 se logran con `.copyWith()` sobre el token:
- `disabled` → `.copyWith(color: AppColors.textTertiary)` o el padre aplica `Opacity 0.4`.
- `selected/active` → `.copyWith(color: AppColors.gold)` para labels de nav/tabs activos.
- `error` → `.copyWith(color: AppColors.danger)` en mensajes de validación.
Dejar esto documentado como comentario en la clase. No crear getters separados por estado.

---

## 7. Animaciones

`AppTextStyles` no anima. Aporta la base para que el `HudTicker` (prompt 06) anime cifras sin saltos: `numericTicker`, `hudReadout` y `mono` llevan `tabularFigures` precisamente por esto. La duración del conteo es `durTicker` (prompt 04). Aquí no se define motion.

---

## 8. Accesibilidad

- `bodyS` y todo texto sobre `textSecondary` mantiene ≥4.5:1 (verificado en prompt 01).
- Ningún estilo baja de **11 px** (`labelSmall`); 11 px solo para micro-labels en MAYÚSCULAS, nunca para texto de lectura.
- Interlineado 1.5 en body cumple las recomendaciones de legibilidad.
- No usar `letterSpacing` negativo: reduce legibilidad en pantalla.
- Las MAYÚSCULAS de `label`/`labelSmall` se aplican al **texto**, no como deformación tipográfica; el ejecutor usa `.toUpperCase()` en el `String`.

---

## 9. Checklist de aceptación

- [ ] Existe `lib/core/config/theme/app_text_styles.dart` con la clase `AppTextStyles`.
- [ ] Están los **13** getters de §5.2 con size/weight/tracking/height exactos.
- [ ] `hudReadout`, `mono` y `numericTicker` usan `GoogleFonts.jetBrainsMono` e incluyen `FontFeature.tabularFigures()`.
- [ ] Los estilos Oxanium usan `fontFamily: 'Oxanium'` y los pesos correctos.
- [ ] Cada getter tiene `color` explícito desde `AppColors` (cero color crudo).
- [ ] `app_theme.dart` mapea el `TextTheme` completo desde `AppTextStyles` según la tabla §5.3.
- [ ] `app_theme.dart` no contiene ningún `TextStyle(...)` literal: botón, input y appbar usan tokens.
- [ ] `inputDecorationTheme` define `labelStyle` y `hintStyle`.
- [ ] `main.dart` precarga JetBrains Mono con `GoogleFonts.pendingFonts`, envuelto en `try/catch` que no bloquea el arranque.
- [ ] La app compila, arranca y la consola/IDs se ven en mono; los títulos en Oxanium.
- [ ] Un ticker numérico de prueba (0→1234.56) no cambia de ancho al animar.
- [ ] `flutter analyze` no agrega warnings nuevos.

---

## 10. Dependencias

- **Previo:** 01 (los estilos referencian `AppColors`).
- **Habilita:** 06 (`HudTicker` usa `numericTicker`/`hudReadout`), y todos los prompts de pantalla 09–65 que renderizan texto. El prompt 14 (skeletons) y 09 (botones) dependen del `TextTheme` ya mapeado.
