# 05 — Sistema de iconografía

> Prompt de la **Fase A · Fundaciones**. Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md` y de los prompts **01** (color) y **03** (dimensión).
> Lee el archivo 00 completo. Aplica §3.2 (prohibición de emojis) y §10 (contraste de glifos).

---

## 1. Objetivo

Establecer el sistema de iconografía único y coherente de la app: una sola familia de iconos, tamaños token, grosor de trazo uniforme, regla de filled-vs-outline por jerarquía, y un helper `AppIcons` que mapea **nombres semánticos** a `IconData`. Después de este prompt, ningún widget de la app referencia un `IconData` suelto ni usa un emoji: todo ícono pasa por `AppIcons`.

---

## 2. Archivos

- **Crear:** `lib/core/config/theme/app_icons.dart`
- **Modificar:** `lib/core/config/theme/app_dimens.dart` — agregar el bloque de tamaños de ícono (§5.2 de este prompt).
- **No tocar:** `pubspec.yaml` — `font_awesome_flutter: ^10.12.0` ya está; Material Icons viene con Flutter.

---

## 3. Estado actual

No hay sistema de iconografía. La app mezcla `Icons.*` de Material con `FontAwesomeIcons.*` sin criterio, los tamaños se pasan a mano (`size: 18/20/24` dispersos), y no hay regla de cuándo un ícono va relleno o de contorno. §3.2 del archivo 00 prohíbe emojis como iconos: hay que garantizar por sistema que no se cuelen. La inconsistencia de set de iconos es, según §3.1.6, uno de los factores que más rápido degrada el «premium».

---

## 4. Visión del rediseño

Un único set de iconos coherente, tamaños tokenizados, y un mapa semántico. La app es una «terminal industrial»: los iconos deben sentirse técnicos, de trazo fino y uniforme. Se elige **Font Awesome** (ya presente, estilo `light`/`regular`/`solid` con grosor consistente) como set primario; **Material Symbols** (los `Icons.*` de Flutter) solo como complemento para glifos que Font Awesome no cubre bien (chevrons de navegación, controles de ventana). El helper `AppIcons` esconde la elección concreta detrás de nombres semánticos: si mañana cambia el set, se cambia un solo archivo.

---

## 5. Especificación visual

### 5.1 Familia de iconos

- **Primaria:** Font Awesome (`font_awesome_flutter`). Preferir el peso **regular** (`FontAwesomeIcons.*` que existan en regular) para coherencia de trazo fino; usar **solid** solo para el rol «filled» de jerarquía (ver §5.3). No mezclar `light`/`duotone`.
- **Complementaria:** `Icons.*` de Material — solo para: chevrons (`Icons.chevron_left/right`, `Icons.expand_more`), controles de ventana (minimizar/maximizar/cerrar de la title bar), y casos donde Font Awesome no tenga un equivalente limpio. No usar Material para los iconos de dominio (bots, billing, etc.).
- **Prohibido:** emojis, `Icons.*` y `FontAwesomeIcons.*` referenciados directamente en widgets de pantalla, mezclar más de un estilo de trazo de Font Awesome, PNG donde puede haber vector.

### 5.2 Tamaños token (en `AppDimens`)

Agregar a `app_dimens.dart` un bloque `// --- ICONOS (tamaños) ---`:

```dart
static const double iconXS = 14;  // iconos inline en texto pequeño, badges
static const double iconS  = 18;  // iconos en labels, inputs, chips
static const double iconM  = 22;  // tamaño por defecto: botones, nav, toolbars
static const double iconL  = 28;  // iconos de encabezado, estados vacíos, acentos
```
Comentario: «`iconM` es el default. `iconL` se reserva para jerarquía. Un botón solo-ícono debe alcanzar 32×32 px de área de hit combinando tamaño + padding (`iconM 22` + `space8`×2 ≥ 32).»

### 5.3 Regla filled vs outline (jerarquía)

- **Outline / regular:** estado por defecto de la mayoría de los iconos — navegación inactiva, iconos de metadato, acciones secundarias, iconos dentro de inputs.
- **Filled / solid:** se reserva para **jerarquía y estado activo** — ítem de navegación seleccionado, acción primaria de un botón destacado, indicadores de estado (status dot ya es sólido por naturaleza), el ícono dentro de un badge de estado semántico.
- Regla: dentro de un mismo componente, un ícono pasa de outline a filled al activarse (mismo glifo, distinto peso). No cambiar de glifo entre estados.

### 5.4 Grosor de trazo

Font Awesome regular ya tiene grosor consistente; no se altera. Para los `Icons.*` de Material que se usen como complemento, no aplicar `weight`/`grade` que rompan la coherencia: usar el default. Todos los iconos de un mismo tamaño deben verse con el mismo «peso óptico».

### 5.5 Helper `AppIcons`

Crear `lib/core/config/theme/app_icons.dart` con cabecera `// Archivo: lib/core/config/theme/app_icons.dart`. Importa `package:flutter/material.dart` y `package:font_awesome_flutter/font_awesome_flutter.dart`. Clase `AppIcons` con constructor privado `AppIcons._();`.

Cada entrada es `static const IconData nombreSemantico = ...;`. El nombre describe el **concepto**, no el glifo. Donde un concepto necesite versión activa, declarar `nombreSolid` aparte.

Mapa mínimo a declarar (el ejecutor elige el `FontAwesomeIcons.*`/`Icons.*` más apropiado para cada concepto; entre paréntesis, sugerencia):

| Nombre semántico | Concepto | Sugerencia |
|---|---|---|
| `botUnit` | Unidad / bot | `FontAwesomeIcons.robot` |
| `botUnitSolid` | Bot activo (filled) | `FontAwesomeIcons.solidRobot` o equivalente solid |
| `blueprint` | Plano / plantilla | `FontAwesomeIcons.objectGroup` o `FontAwesomeIcons.fileCode` |
| `billing` | Facturación / crédito | `FontAwesomeIcons.creditCard` |
| `store` | Tienda | `FontAwesomeIcons.store` |
| `settings` | Ajustes | `FontAwesomeIcons.gear` |
| `dashboard` | Panel / hangar | `FontAwesomeIcons.gaugeHigh` |
| `send` | Enviar (chat) | `FontAwesomeIcons.paperPlane` |
| `search` | Buscar | `FontAwesomeIcons.magnifyingGlass` |
| `add` | Crear / añadir | `FontAwesomeIcons.plus` |
| `close` | Cerrar | `FontAwesomeIcons.xmark` |
| `check` | Confirmar / éxito | `FontAwesomeIcons.check` |
| `warning` | Advertencia | `FontAwesomeIcons.triangleExclamation` |
| `error` | Error / crítico | `FontAwesomeIcons.circleExclamation` |
| `info` | Información | `FontAwesomeIcons.circleInfo` |
| `power` | Encendido / reactor | `FontAwesomeIcons.powerOff` |
| `lock` | Seguridad / bloqueado | `FontAwesomeIcons.lock` |
| `user` | Usuario / cuenta | `FontAwesomeIcons.user` |
| `logout` | Cerrar sesión | `FontAwesomeIcons.rightFromBracket` |
| `edit` | Editar | `FontAwesomeIcons.penToSquare` |
| `delete` | Eliminar (destructivo) | `FontAwesomeIcons.trash` |
| `copy` | Copiar (embed/IDs) | `FontAwesomeIcons.copy` |
| `chevronRight` | Avanzar / expandir | `Icons.chevron_right` (Material) |
| `chevronLeft` | Volver | `Icons.chevron_left` (Material) |
| `chevronDown` | Desplegar | `Icons.expand_more` (Material) |
| `winMinimize` | Minimizar ventana | `Icons.remove` (Material) |
| `winMaximize` | Maximizar ventana | `Icons.crop_square` (Material) |
| `winClose` | Cerrar ventana | `Icons.close` (Material) |
| `connected` | Conectividad OK | `FontAwesomeIcons.wifi` |
| `disconnected` | Sin conexión | `FontAwesomeIcons.plugCircleXmark` |

El ejecutor puede agregar entradas si un prompt posterior las pide, **siempre** como nombre semántico nuevo en este archivo — nunca un `IconData` suelto en una pantalla.

Comentario de cabecera obligatorio: «PROHIBIDO usar emojis o referenciar `Icons.*`/`FontAwesomeIcons.*` directamente en widgets de pantalla. Todo ícono pasa por `AppIcons`.»

### 5.6 Reglas de alineación

- Los iconos inline en texto se alinean al **baseline** del texto: usar `Icon` dentro de un `Row` con `crossAxisAlignment: CrossAxisAlignment.center`, o un `WidgetSpan` con `alignment: PlaceholderAlignment.middle` cuando el ícono va en medio de un `RichText`.
- El tamaño del ícono inline = `iconXS`/`iconS` según el tamaño del texto acompañante (regla: ícono ≈ altura de la x del texto + ~2 px).
- Iconos en botones: centrados, con `space8` de gap respecto al label.
- Color del ícono: hereda del `IconTheme` o se pasa explícito desde `AppColors`. Nunca color crudo.

---

## 6. Estados e interacciones

Aplicar §9 del archivo 00 a los iconos:
- `default` → outline/regular, color `textSecondary`.
- `hover` → color sube a `textPrimary` o `gold` según contexto, `durFast`.
- `pressed` → el botón contenedor escala 0.97 (P2 de prompt 04); el ícono no cambia de glifo.
- `selected/active` → glifo **solid**, color `gold`.
- `disabled` → opacidad 0.4, color `textTertiary`.
- `error` → ícono `AppIcons.error`, color `danger`.
`AppIcons` no maneja estado; los maneja el widget consumidor. Documentar esto como comentario.

---

## 7. Animaciones

Los iconos en sí no animan. El cambio de color en hover usa `durInstant`/`durFast` (prompt 04). Un cambio outline→solid en selección puede hacer un crossfade de `durFast`. Sin rotaciones ni rebotes salvo que un prompt posterior lo pida explícitamente (p. ej. spinner de loading, que es otro componente).

---

## 8. Accesibilidad

- Contraste de glifo ≥ **3:1** sobre su fondo (§10). Verificar `textSecondary` y `gold` sobre `surface`/`surfaceHud` (ya cubierto por prompt 01).
- **Todo botón solo-ícono** lleva `Semantics(label: ...)` o `Tooltip` con un label descriptivo en español. Esto es obligatorio y se repetirá en cada prompt de componente con iconos.
- El estado nunca se comunica solo con el ícono ni solo con color: ícono + color + texto (§10).
- Área de hit mínima 32×32 px (ver §5.2).

---

## 9. Checklist de aceptación

- [ ] Existe `lib/core/config/theme/app_icons.dart` con la clase `AppIcons` y constructor privado.
- [ ] `app_dimens.dart` tiene el bloque de tamaños `iconXS=14, iconS=18, iconM=22, iconL=28`.
- [ ] `AppIcons` declara todas las entradas de la tabla §5.5 como `static const IconData`.
- [ ] Los iconos de dominio usan Font Awesome con un único estilo de trazo; Material solo para chevrons y controles de ventana.
- [ ] Conceptos con estado activo tienen variante `*Solid` declarada.
- [ ] La cabecera incluye la prohibición de emojis y de iconos sueltos.
- [ ] No queda ningún `IconData` suelto ni emoji en el código tras la migración de los prompts que consuman iconos.
- [ ] La app compila; `flutter analyze` no agrega warnings nuevos.

---

## 10. Dependencias

- **Previo:** 01 (color de iconos), 03 (tamaños viven en `AppDimens`).
- **Habilita:** 06 (las primitivas HUD usan `AppIcons` para sus glifos), 09 (botones), 19 (sidebar), 18 (title bar) y todos los prompts de pantalla que muestren iconos.
