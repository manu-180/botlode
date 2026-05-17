# 03 — Tokens de dimensión

> Prompt de la **Fase A · Fundaciones**. Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md` y del prompt **01** (tokens de color).
> Lee el archivo 00 completo. Los valores son los de **§6** del archivo 00.

---

## 1. Objetivo

Crear `lib/core/config/theme/app_dimens.dart`, la fuente única de verdad para **espaciado, radios, chaflán, elevación (sombras + glows) y z-index**. Después de este prompt, ningún widget de la app puede usar un número mágico de padding, un `BorderRadius.circular(N)` arbitrario ni una `BoxShadow` inventada: todo viene de `AppDimens`.

---

## 2. Archivos

- **Crear:** `lib/core/config/theme/app_dimens.dart`
- **No tocar:** ningún otro archivo. La migración de magic numbers de la app la hacen los prompts de pantalla; este prompt deja la API lista.

---

## 3. Estado actual

No existe ningún archivo de dimensiones. Hoy los valores están dispersos: `app_theme.dart` usa `BorderRadius.circular(12)`, `circular(8)`, paddings `EdgeInsets.symmetric(horizontal: 20/24, vertical: 16)`; `skeleton_base.dart` usa `borderRadius = 12`; cada vista de billing/dashboard repite sus propios `SizedBox(height: 16/20/24)` y sombras hechas a mano. No hay escala de elevación, no hay glows reutilizables, no hay z-index documentado. Resultado: inconsistencia de radios y sombras, justo lo que §3.1 del archivo 00 marca como «lo que más rápido mata el factor premium».

---

## 4. Visión del rediseño

Una clase `AppDimens` con cinco bloques de `static const` (espaciado, radios, chaflán, elevación, z-index) más un helper estático para glow de estado. El ejecutor de cualquier prompt posterior escribe `padding: EdgeInsets.all(AppDimens.space20)`, `BorderRadius.circular(AppDimens.radiusL)`, `boxShadow: AppDimens.elev1`, `boxShadow: [...AppDimens.elev2, ...AppDimens.glowGold]`. La escala de 4 px garantiza ritmo vertical coherente; la escala de elevación garantiza que toda la app comparta el mismo lenguaje de profundidad.

---

## 5. Especificación visual

Crear `lib/core/config/theme/app_dimens.dart` con cabecera `// Archivo: lib/core/config/theme/app_dimens.dart`. Importa `package:flutter/material.dart` y `app_colors.dart`. Clase `AppDimens` con constructor privado `AppDimens._();`.

### 5.1 Espaciado — escala base 4 px (§6.1)

Tipo `double`. Bloque comentado `// --- ESPACIADO (escala 4px) ---`:

```dart
static const double space2  = 2;
static const double space4  = 4;
static const double space8  = 8;
static const double space12 = 12;
static const double space16 = 16;
static const double space20 = 20;
static const double space24 = 24;
static const double space32 = 32;
static const double space40 = 40;
static const double space48 = 48;
static const double space64 = 64;
```

Guía de consumo (comentario en el bloque):
- Padding interno de cards: `space20` o `space24`.
- Gap entre cards de grilla: `space20`.
- Padding horizontal de pantalla (desktop): `space32`.
- Gaps de jerarquía de sección: `space16` / `space24` / `space32` / `space48`.

### 5.2 Radios (§6.2)

Tipo `double`. Bloque `// --- RADIOS ---`:

```dart
static const double radiusXS   = 6;    // chips compactos, micro-elementos
static const double radiusS    = 10;   // badges, tags pequeños
static const double radiusM    = 14;   // inputs y botones
static const double radiusL    = 20;   // cards y paneles
static const double radiusXL   = 28;   // modales
static const double radiusPill = 999;  // pills/chips redondeados
```

Helpers de conveniencia (devuelven `BorderRadius`):
```dart
static BorderRadius get brM => BorderRadius.circular(radiusM);
static BorderRadius get brL => BorderRadius.circular(radiusL);
static BorderRadius get brXL => BorderRadius.circular(radiusXL);
static BorderRadius get brPill => BorderRadius.circular(radiusPill);
```

### 5.3 Chaflán HUD (§6.3)

```dart
static const double chamferM = 12; // recorte de esquina a 45° para paneles/botones HUD
```
Comentario obligatorio: «El `ShapeBorder`/`ClipPath` que consume `chamferM` lo define el prompt 06 (`ChamferBorder`/`ChamferClipper`). El chaflán es para acentos jerárquicos (paneles HUD, botón primario destacado, marcos de tabs), NO para todas las cajas.»

### 5.4 Escala de elevación — sombras y glows (§6.4)

Las sombras se declaran como `List<BoxShadow>` para poder hacer spread (`...AppDimens.elev1`) y combinar elevación + glow en un mismo `boxShadow`. Bloque `// --- ELEVACIÓN (sombras) ---`:

```dart
static const List<BoxShadow> elev0 = <BoxShadow>[];

static const List<BoxShadow> elev1 = [
  BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 8),
];

static const List<BoxShadow> elev2 = [
  BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 24),
];

static const List<BoxShadow> elev3 = [
  BoxShadow(color: Color(0x99000000), offset: Offset(0, 16), blurRadius: 48),
];
```
(`0x66` ≈ 0.4 alpha, `0x80` ≈ 0.5, `0x99` ≈ 0.6 — coinciden con §6.4.)

Glows — bloque `// --- GLOWS (emisión) ---`. Un glow es una `BoxShadow` con `offset: Offset.zero` y `spreadRadius` pequeño:

```dart
static const List<BoxShadow> glowGold = [
  BoxShadow(color: AppColors.goldGlow, blurRadius: 24, spreadRadius: 1),
];

static const List<BoxShadow> glowCyan = [
  BoxShadow(color: AppColors.cyanGlow, blurRadius: 20, spreadRadius: 1),
];
```

Helper de glow de estado genérico (recibe un color sólido y deriva la opacidad 0.28):
```dart
static List<BoxShadow> glowStatus(Color color) => [
  BoxShadow(
    color: color.withOpacity(0.28),
    blurRadius: 18,
    spreadRadius: 1,
  ),
];
```

**Regla de combinación** (comentario obligatorio en el bloque, copiada de §6.4): «Un elemento usa UNA sombra de elevación + OPCIONALMENTE UN glow. Nunca dos glows. Nunca sombras fuera de esta escala. Para combinar: `boxShadow: [...AppDimens.elev1, ...AppDimens.glowGold]`.»

`elev0` se incluye como lista vacía para que el código que necesita «sin sombra» igual pase por un token y no por `[]` literal.

### 5.5 Z-index / capas (§6.5)

Tipo `int`. Bloque `// --- Z-INDEX / CAPAS ---`. Flutter no tiene z-index nativo; estas constantes documentan y se usan para ordenar hijos en un `Stack` o como `elevation` lógica. Comentario que lo aclare.

```dart
static const int zBase             = 0;
static const int zContent          = 10;
static const int zSticky           = 20;   // toolbars sticky
static const int zSidebar          = 30;
static const int zTitleBar         = 40;
static const int zOverlay          = 100;  // scrims
static const int zModal            = 110;
static const int zToast            = 200;
static const int zEpicNotification = 300;
```

### 5.6 Cómo se consumen (bloque doc en cabecera del archivo)

Dejar en la cabecera un comentario `/// USO:` con ejemplos:
```
/// padding:      EdgeInsets.all(AppDimens.space20)
/// gap:          SizedBox(height: AppDimens.space16)
/// radio:        borderRadius: AppDimens.brL
/// card reposo:  boxShadow: AppDimens.elev1
/// card hover:   boxShadow: [...AppDimens.elev2, ...AppDimens.glowGold]
/// glow estado:  boxShadow: AppDimens.glowStatus(AppColors.success)
/// chaflán:      el ShapeBorder lo provee el prompt 06 con AppDimens.chamferM
```

---

## 6. Estados e interacciones

No aplica (archivo de constantes). Pero la escala de elevación **cubre los estados** de §9 del archivo 00:
- `default` → `elev1`.
- `hover` → `elev2` (+1 nivel) y opcionalmente un glow.
- `pressed` → vuelve a `elev1` (el elemento se «hunde»).
- `selected/active` → `elev1` + glow estable.
- `modal/popover` → `elev3`.
Verificar que para cada estado de elevación exista el token; si la app necesitara un nivel intermedio, agregarlo a la escala antes de cerrar el prompt (no inventarlo en el widget).

---

## 7. Animaciones

`AppDimens` no anima. Provee los **valores destino** que los widgets interpolan: un `AnimatedContainer` que pasa de `elev1` a `elev2` en hover usa estos tokens como extremos. Las duraciones/curvas de esa interpolación vienen del prompt 04. Aquí no se define motion.

---

## 8. Accesibilidad

- Las constantes de espaciado garantizan áreas de hit cómodas: cualquier botón solo-ícono debe alcanzar mínimo 32×32 px (§10 del archivo 00) combinando ícono + padding (`iconM 22` + `space8`×2 = 38 px). Dejar esto como comentario junto a `space8`.
- Los radios no afectan accesibilidad directamente, pero el chaflán nunca debe recortar contenido ni foco visible.
- El z-index asegura que scrims (`zOverlay`) queden bajo modales (`zModal`) y estos bajo toasts (`zToast`): el foco y los mensajes `liveRegion` siempre quedan por encima del contenido.

---

## 9. Checklist de aceptación

- [ ] Existe `lib/core/config/theme/app_dimens.dart` con la clase `AppDimens` y constructor privado.
- [ ] Los **11** tokens de espaciado de §5.1 existen como `static const double`.
- [ ] Los **6** radios de §5.2 existen, más los helpers `brM`/`brL`/`brXL`/`brPill`.
- [ ] `chamferM = 12` existe con su comentario de uso.
- [ ] `elev0`, `elev1`, `elev2`, `elev3` existen como `List<BoxShadow>` con offsets/blur de §6.4.
- [ ] `glowGold` y `glowCyan` existen como `List<BoxShadow>` usando `AppColors.goldGlow`/`cyanGlow`.
- [ ] `glowStatus(Color)` existe como helper estático con opacidad 0.28 y blur 18.
- [ ] Los **9** tokens de z-index de §5.5 existen como `static const int`.
- [ ] La cabecera incluye el bloque `/// USO:` de §5.6.
- [ ] La regla «una sombra + un glow máximo» está escrita como comentario en el bloque de elevación.
- [ ] El archivo no declara ningún color crudo: los glows referencian `AppColors`.
- [ ] La app compila; `flutter analyze` no agrega warnings nuevos.

---

## 10. Dependencias

- **Previo:** 01 (`glowGold`/`glowCyan` referencian `AppColors.goldGlow`/`cyanGlow`).
- **Habilita:** 06 (`ChamferBorder` consume `chamferM`; las primitivas usan radios), 07 (glass/glow combinan `elev*` + `glow*`), 08 (fondo usa z-index) y todos los prompts de pantalla 09–65.
