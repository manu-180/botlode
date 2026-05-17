# 45 — Settings View · «Protocolo de Seguridad»

> Prompt ejecutable de la **Fase F**. Antes de tocar nada, leé `00_README_VISION_Y_SISTEMA_DE_DISENO.md` completo. Todos los valores se referencian por **nombre de token**.

---

## 1. Objetivo

Rediseñar la vista de ajustes («Protocolo de Seguridad»): la pantalla de gestión de credenciales y sesión del operador. Debe pasar de tres botones sueltos centrados a un **panel de configuración HUD coherente**: encabezado con escudo en anillo HUD, las opciones como filas/`HoloPanel`s de ajuste (ícono + label + descripción + control), la acción destructiva «CERRAR SESIÓN» separada y con confirmación, y un modal «SOBRE BOTSLODE» que también se diseña en este prompt.

---

## 2. Archivos

- **Modificar:** `lib/features/settings/presentation/views/settings_view.dart`
- **Crear:** un widget de modal «Acerca de» — `lib/features/settings/presentation/widgets/about_botslode_dialog.dart`.
- **Consumir (no crear):** `AppBackground` (08), `HoloPanel` (12), `AppButton` (09), `HudCornerBrackets`/`HudDivider` (06), `EmptyState`/diálogo de confirmación si existe primitiva (15/16), glow (07).
- **Tokens:** `app_colors.dart`, `app_dimens.dart`, `app_motion.dart`.

El widget local `_SecurityActionButton` se reemplaza por filas de ajuste `_SettingRow` sobre `HoloPanel`.

---

## 3. Estado actual

- `ConsumerWidget`. `Scaffold` + `Stack`. Fondo: `RadialGradient` manual (`surface@0.6` → `background`, radius 1.2). Plano.
- `Center` + `ConstrainedBox(maxWidth: 500)` + `Column` centrada verticalmente.
- Ícono de seguridad: `Container` circular 120×120, fondo negro, borde `primary@0.3`, sombra `primary@0.1` blur 50 spread 10. Dentro, `Icon(Icons.shield_outlined, 50, primary)` con `.shimmer()` de `flutter_animate` (2000 ms) **en loop infinito** — no respeta reduced-motion.
- Título `"PROTOCOLO DE SEGURIDAD"` (`displayMedium`, 24, hardcodeado). Subtítulo `bodyLarge`.
- 2 botones `_SecurityActionButton` (no 3 — la vista actual NO tiene «SOBRE BOTSLODE»; este prompt lo agrega):
  - «ACTUALIZAR CONTRASEÑA» (`primary`) → abre `ChangePasswordDialog`.
  - «CERRAR SESIÓN» (`error`, `isDestructive`) → `signOut()` + `go('/login')` **sin confirmación**.
- `_SecurityActionButton`: `Focus` + `MouseRegion` + `AnimatedContainer` 200 ms, radio 16, ícono en container, label + subLabel, chevron. Hover cambia fondo/borde/sombra.
- Footer mono `"SECURE CONNECTION // ENCRYPTED"` (`fontFamily: 'Courier'`).

---

## 4. Visión del rediseño

La pantalla se lee como el **panel de seguridad de la terminal**: una columna centrada, contenida, con jerarquía clara.

1. **Fondo ambiental** (`AppBackground`) con acento `gold`.
2. **Encabezado ceremonial:** un escudo dentro de un **anillo HUD** con `glowGold` y un shimmer sutil que **respeta reduced-motion**; título `displayM`; subtítulo.
3. **Bloque de opciones:** las acciones dejan de ser «botones sueltos» y pasan a ser **filas de ajuste** dentro de uno o dos `HoloPanel`s — cada fila con ícono en marco, label, descripción y un control/chevron a la derecha. Esto da la sensación de un panel de configuración real, no de un menú de botones.
4. **Acción destructiva separada:** «CERRAR SESIÓN» vive abajo, visualmente separada (con un `HudDivider`), en `danger`, y **pide confirmación** antes de ejecutarse.
5. **«SOBRE BOTSLODE»** abre un modal «acerca de» con estilo HUD: versión, marca, créditos.

El factor WOW: el anillo HUD del escudo + las filas de ajuste agrupadas en panel + la confirmación de logout hacen que la pantalla se sienta como una consola de sistema seria, no como una pantalla de ajustes improvisada.

---

## 5. Especificación visual

### 5.1 Estructura

```
Scaffold(backgroundColor: transparent)
└─ AppBackground(accent: AppColors.gold)
   └─ Center
      └─ ConstrainedBox(maxWidth: 540)   // 520–560 permitido; usar 540
         └─ SingleChildScrollView
            └─ Column
               ├─ _SecurityHeader()            // escudo + título + subtítulo
               ├─ SizedBox(height: space40)
               ├─ HoloPanel( _SettingRow("Actualizar contraseña") )
               ├─ SizedBox(height: space12)
               ├─ HoloPanel( _SettingRow("Sobre BotLode") )
               ├─ SizedBox(height: space24)
               ├─ HudDivider()
               ├─ SizedBox(height: space24)
               ├─ HoloPanel( _SettingRow("Cerrar sesión", danger) )
               └─ SizedBox(height: space32) + footer mono
```

`SingleChildScrollView` para que en 1024×600 nada quede cortado.

### 5.2 Fondo

- Reemplazar el `Stack` + `RadialGradient` manual por `AppBackground` con `accent: AppColors.gold` (glow radial dorado ambiental, grid HUD sutil).

### 5.3 Encabezado (`_SecurityHeader`)

- **Escudo en anillo HUD:** un `Stack` centrado:
  - Anillo exterior: círculo de 116×116, borde `borderGold` width 1.5, con `glowGold` (`elev0` + `glowGold`).
  - Un segundo anillo interno fino `gold@0.20` (da la doble línea «instrumento»).
  - Centro: círculo `surfaceHud`, dentro `Icon` de escudo (set unificado prompt 05), size 48, color `gold`.
  - **Shimmer:** un barrido `gradGoldSheen` sobre el ícono cada ~3000 ms. **Debe respetar `AppMotion.reduced`**: con reduced-motion activo, el shimmer no corre (ícono estático). Reemplazar el `.shimmer()` infinito actual por una versión que consulte `AppMotion.reduced`.
- Gap `space24`.
- **Título:** `"PROTOCOLO DE SEGURIDAD"`, tipografía `displayM` (Oxanium 26/700). Color `textPrimary`. Sin tamaño hardcodeado.
- Gap `space8`.
- **Subtítulo:** `"Gestión de credenciales y acceso al sistema central."`, `bodyM`, `textSecondary`, centrado.

### 5.4 Filas de ajuste (`_SettingRow` sobre `HoloPanel`)

Cada opción es una fila dentro de un `HoloPanel` (radio `radiusL`, padding `EdgeInsets.symmetric(horizontal: space20, vertical: space16)`):

- `Row`, `crossAxisAlignment: center`:
  - **Ícono en marco:** contenedor 44×44, radio `radiusM`, relleno `<accent>@0.10`, borde `<accent>@0.28`, ícono size 22 color `<accent>`.
  - Gap `space16`.
  - **Texto** (`Expanded`, `Column` start): label en `titleM` (Oxanium 17/600) `textPrimary`; gap `space4`; descripción en `bodyS` `textSecondary`.
  - **Control derecho:** chevron (`>`/`chevron_right` del set prompt 05), size 18, color `<accent>@0.4` reposo / `@1.0` hover. (Si en el futuro alguna fila lleva un `Switch`, va acá; hoy todas son navegacionales.)
- Filas concretas:
  1. **«ACTUALIZAR CONTRASEÑA»** — accent `gold`, ícono de llave/candado, descripción `"Modificar la clave de acceso del operador"`. `onTap` → `showDialog(ChangePasswordDialog())` (prompt 46).
  2. **«SOBRE BOTLODE»** — accent `cyan`, ícono de info, descripción `"Versión, créditos y estado del sistema"`. `onTap` → `showDialog(AboutBotslodeDialog())` (§5.6).
- Hover de la fila: borde del `HoloPanel` pasa a `<accent>@0.4`, `elev1→elev2`, glow suave del accent, chevron a `@1.0`. `durFast`.

### 5.5 Acción destructiva — «CERRAR SESIÓN»

- Separada del bloque anterior por un `HudDivider` (con label opcional `// SESIÓN`).
- Misma estructura `_SettingRow` pero accent `danger`: ícono de power/logout en marco `danger@0.10`/`danger@0.28`, label `"CERRAR SESIÓN"`, descripción `"Desconectar al operador y volver al login"`.
- Hover: borde `danger`, glow `dangerGlow`.
- `onTap` → **abre un diálogo de confirmación** antes de ejecutar. El diálogo (puede ser una primitiva existente o un `HoloPanel` modal simple): título `"¿CERRAR SESIÓN?"`, mensaje, dos `AppButton`: «Cancelar» (ghost) y «Cerrar sesión» (danger). Solo al confirmar se ejecuta `ref.read(authProvider.notifier).signOut()` + `GoRouter.of(context).go('/login')`. Cumple §10 archivo 00: confirmar antes de acción destructiva.

### 5.6 Modal «SOBRE BOTLODE» (`AboutBotslodeDialog`)

Crear `lib/features/settings/presentation/widgets/about_botslode_dialog.dart`. Modal de estilo HUD:

- `Dialog` con scrim `scrim` (66 %), `BackdropFilter` blur.
- Contenedor: `HoloPanel` variante modal — `glassSurfaceStrong`, radio `radiusXL`, borde `borderGold`, `elev3`, `HudCornerBrackets` dorados en las 4 esquinas. Ancho `420`, padding `space32`.
- Contenido (`Column`, `mainAxisSize: min`):
  - **Header:** logo/ícono de la marca (anillo HUD pequeño dorado) + título `"BOTLODE FACTORY TERMINAL"` (`titleL` Oxanium) + botón de cerrar (icon button del prompt 09, con `Semantics`/tooltip).
  - `HudDivider`.
  - **Bloque de datos** en lectura HUD (`surfaceHud`, radio `radiusS`, padding `space16`): filas label/valor en `hudReadout` mono:
    - `VERSIÓN` → leer de `DEPLOY_VERSION`/`AppConfig` si está disponible; si no, placeholder coherente.
    - `BUILD` → identificador de build.
    - `MOTOR` → `Flutter Desktop`.
  - `space16`.
  - **Marca / créditos:** texto `bodyS` `textSecondary` centrado: descripción corta del producto + línea de copyright. Línea mono `textTertiary` con `// HANGAR OS`.
  - `space24`.
  - **Footer:** un `AppButton` ghost ancho completo `"CERRAR"`.
- Entrada del modal: fade + scale `0.96→1.0`, `springSoft`, `durSlow`. Reduced-motion → crossfade 120 ms.

### 5.7 Footer de la vista

- Texto mono `"SECURE CONNECTION // ENCRYPTED"`, tipografía `mono` (JetBrains Mono, **no `'Courier'`**), color `textTertiary`. Centrado, `space32` de margen superior.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` | Encabezado + 2 filas de ajuste + fila de logout. |
| `hover` (fila) | Borde del `HoloPanel` con tinte del accent, `elev2`, glow suave, chevron a opacidad plena. `durFast`. |
| `pressed` (fila) | Escala 0.98, relleno un paso más profundo. `durInstant`. |
| `focused` (fila) | Anillo de foco 2 px (`gold`/`cyan`/`danger` según fila). El soporte de teclado (Enter activa) del `Focus` actual se conserva. |
| `loading` | Durante `signOut()` la fila de logout muestra spinner inline y se deshabilita; sin doble submit. |
| `error` | Si `signOut()` falla, un toast/`ErrorFeedbackCard` (prompt 16/17) con `role: alert`. |

Modal «Sobre BotLode»: estados idle (solo lectura) + cierre. Diálogo de confirmación de logout: idle / confirmando (spinner) / error.

---

## 7. Animaciones

- **Entrada de la vista:** encabezado entra con fade + translateY 12 px, `easeEntrance`, `durBase`; las filas de ajuste entran escalonadas 36 ms cada una (fade + translateY), `easeEntrance`, `durBase`.
- **Shimmer del escudo:** barrido `gradGoldSheen` cada ~3000 ms, **solo si `!AppMotion.reduced`**.
- **Hover de filas:** `durFast`, `easeStandard`. Press: `durInstant`.
- **Modales (about + confirmación):** fade + scale `springSoft`, `durSlow` entrada; salida ~65 % de la entrada.
- **Reduced motion:** sin shimmer, sin escalonado, sin scale de modal (crossfade 120 ms), sin translateY. Respetar `AppMotion.reduced`.

---

## 8. Accesibilidad

- Contraste: título `displayM` `textPrimary` ≥ 12:1; subtítulo y descripciones `textSecondary` ≥ 4.5:1; footer mono `textTertiary` ≥ 3:1; valores HUD del modal verificar ≥ 4.5:1.
- Cada fila de ajuste es un control: `Semantics(button: true, label: ...)`. El soporte de Enter del `Focus` se mantiene.
- El botón de cerrar del modal es solo-ícono → lleva `Semantics`/tooltip `"Cerrar"`.
- **Acción destructiva con confirmación obligatoria** (§10 archivo 00): «CERRAR SESIÓN» nunca ejecuta directo.
- Foco visible en todas las filas, botones y campos; orden de foco = orden visual; foco se mueve al modal al abrirlo y vuelve a la fila al cerrarlo.
- El estado no se comunica solo por color: la fila destructiva lleva ícono + label + ubicación separada, no solo el rojo.

---

## 9. Checklist de aceptación

- [ ] El `Stack` + `RadialGradient` manual fue reemplazado por `AppBackground` con acento `gold`.
- [ ] El escudo está en un anillo HUD con `glowGold`; el shimmer **respeta `AppMotion.reduced`** (ya no es loop infinito incondicional).
- [ ] El título usa `displayM` (token), sin tamaño hardcodeado.
- [ ] Las opciones son filas de ajuste (`_SettingRow`) sobre `HoloPanel`, con ícono en marco + label + descripción + chevron; `_SecurityActionButton` fue eliminado.
- [ ] «ACTUALIZAR CONTRASEÑA» abre `ChangePasswordDialog` (prompt 46).
- [ ] «SOBRE BOTLODE» existe y abre el nuevo `AboutBotslodeDialog`.
- [ ] El archivo `about_botslode_dialog.dart` fue creado con estilo HUD (HoloPanel modal, `HudCornerBrackets`, datos en `hudReadout`, botón cerrar).
- [ ] «CERRAR SESIÓN» está separada por un `HudDivider`, en `danger`, y **pide confirmación** antes de ejecutar `signOut()`.
- [ ] La fila de logout muestra estado `loading` durante el `signOut()`.
- [ ] El footer mono usa `mono` (JetBrains Mono), no `'Courier'`.
- [ ] Entrada escalonada de filas; modales con `springSoft`/`durSlow`.
- [ ] `reduced-motion` desactiva shimmer, escalonado, scale de modal y translateY.
- [ ] Cero hex sueltos, cero magic numbers de espaciado.
- [ ] `flutter analyze` sin warnings nuevos; se ve correcto y sin recorte en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01, 02 (`displayM`, `titleM`, `bodyS`, `mono`, `hudReadout`), 03, 04, 05 (iconografía), 06 (`HudCornerBrackets`, `HudDivider`), 07 (glow).
- **Componentes núcleo:** 09 (`AppButton`, icon button), 12 (`HoloPanel`), 16 (`ErrorFeedbackCard`), 17 (toasts).
- **Shell:** 08 (`AppBackground`).
- **Mismo grupo:** 46 (`ChangePasswordDialog`) — lo abre la fila de contraseña.
