# 46 — Change Password Dialog · Diálogo de cambio de contraseña

> Prompt ejecutable de la **Fase F**. Antes de tocar nada, leé `00_README_VISION_Y_SISTEMA_DE_DISENO.md` completo. Todos los valores se referencian por **nombre de token**.

---

## 1. Objetivo

Rediseñar `ChangePasswordDialog`, el modal de cambio de contraseña del operador. Debe sentirse como un **terminal de actualización de credenciales** premium: modal `HoloPanel` con chaflán, scrim, brackets de esquina; tres campos `AppTextField` password con toggle de visibilidad; un medidor de fuerza de contraseña HUD segmentado; validación inline; y estados completos (idle, validando, error, success con cierre automático).

---

## 2. Archivos

- **Modificar:** `lib/features/settings/presentation/widgets/change_password_dialog.dart`
- **Consumir (no crear):** `HoloPanel` (12), `AppTextField` password (10), `AppButton` (09), `HudCornerBrackets`/`HudDivider` (06), `ChamferBorder` (06), `ErrorFeedbackCard` (16), glow (07).
- **Crear (opcional):** si no existe, un widget `_PasswordStrengthMeter` local en el mismo archivo (no archivo nuevo).
- **Tokens:** `app_colors.dart`, `app_dimens.dart`, `app_motion.dart`.

---

## 3. Estado actual

- `ConsumerStatefulWidget`. `Shortcuts`/`Actions` para Enter. `BackdropFilter` blur 10 + `Dialog(transparent)`.
- Contenedor: `Container` 450 ancho, `padding 32`, `color #09090B@0.95` (hex suelto), `radius 24`, borde `primary@0.5`, sombra `primary@0.1` blur 40 spread 2.
- `Form` con `_formKey`. **Solo 2 campos** (no 3 — falta «contraseña actual»): «NUEVA CONTRASEÑA» y «CONFIRMAR CONTRASEÑA». Este prompt agrega el campo de **contraseña actual**.
- Header: `Icon(Icons.security_rounded, 28, primary)` con `.shimmer()` infinito (no respeta reduced-motion) + título `"ACTUALIZAR CREDENCIALES"` (hardcodeado) + `IconButton` close.
- Campos vía `_buildPasswordField`: label + `TextFormField` `obscureText: true` **siempre** (sin toggle de visibilidad), `fontFamily: 'Courier'`, fill `white@0.05`, borde redondeado, `prefixIcon` candado, `autovalidateMode: onUnfocus`.
- Validación: nueva ≥ 6 caracteres; confirmar == nueva. **No hay medidor de fuerza.**
- `_errorMessage` → `ErrorFeedbackCard`. Botón submit `ElevatedButton` dorado con spinner en loading.
- `_buildSuccessState`: diálogo distinto con check verde, `.shimmer()` infinito, cierre automático a los 2 s.
- No hay `HudCornerBrackets`, no hay chaflán, no hay medidor de fuerza, no hay toggle de visibilidad.

---

## 4. Visión del rediseño

El modal es un **panel de actualización de credenciales** del hangar. De afuera hacia adentro:

- Scrim `scrim` (66 %) + `BackdropFilter` blur detrás.
- Contenedor `HoloPanel` variante modal con **chaflán** (`ChamferBorder`, esquinas biseladas a 45° — momento «hardware/instrumento»), `glassSurfaceStrong`, `elev3`, `HudCornerBrackets` dorados.
- Header con ícono en marco HUD + título + botón de cerrar accesible.
- **Tres** campos `AppTextField` password con toggle de visibilidad (ojo): contraseña actual, nueva, confirmar.
- Debajo del campo «nueva», un **medidor de fuerza HUD**: barra segmentada (4–5 segmentos) que pasa de `danger` → `warning` → `success` según la fuerza, con un label («DÉBIL» / «MEDIA» / «FUERTE»).
- Validación inline cerca de cada campo (coincidencia, longitud, fuerza mínima).
- Footer con dos `AppButton`: «CANCELAR» (ghost) y «GUARDAR» (primary).
- Estados: idle / validando / error / success — el success se integra como un overlay dentro del mismo modal (no un diálogo separado), con check, mensaje y cierre automático.

El factor WOW: el chaflán + los brackets + el medidor de fuerza segmentado animado hacen que el cambio de contraseña se sienta como una operación de sistema seria e instrumentada.

---

## 5. Especificación visual

### 5.1 Contenedor del modal

- `Dialog(backgroundColor: transparent)`, `insetPadding` cómodo.
- Detrás: `BackdropFilter` blur + un velo `scrim` (token, 66 %).
- Contenedor: `HoloPanel` en variante modal, **con `ChamferBorder`** (chaflán `chamferM` = 12 px en las 4 esquinas — recorte 45°):
  - Relleno `glassSurfaceStrong` (vidrio más opaco para legibilidad de formulario).
  - Borde `borderGold`, width 1.
  - Elevación `elev3`.
  - `HudCornerBrackets` dorados en las 4 esquinas, brazos 18 px.
  - Ancho `460`, `padding EdgeInsets.all(space32)`.
- Eliminar el `Color(0xFF09090B)` hex suelto y el `radius 24` hardcodeado.

### 5.2 Header

`Row`:

- **Ícono en marco HUD:** contenedor 44×44, radio `radiusM` (o leve chaflán), relleno `gold@0.10`, borde `gold@0.28`, ícono de candado/llave (set prompt 05), size 22, color `gold`. Shimmer del ícono **solo si `!AppMotion.reduced`** (reemplazar el `.shimmer()` infinito incondicional).
- Gap `space16`.
- **Título** (`Expanded`): `"ACTUALIZAR CREDENCIALES"`, tipografía `titleL` (Oxanium 21/600), `textPrimary`.
- **Botón de cerrar:** icon button del prompt 09, ícono `x`, con `Semantics`/tooltip `"Cerrar"`.

Debajo del header: gap `space8` + subtítulo `"Establezca una nueva clave de acceso segura para el operador."` (`bodyS`, `textSecondary`) + `HudDivider` con `space16` de margen.

### 5.3 Campos

Tres `AppTextField` variante password (prompt 10), en este orden, separados por `space20`:

1. **CONTRASEÑA ACTUAL** — label `labelSmall` `textSecondary`, placeholder, `prefixIcon` candado, **toggle de visibilidad** (ícono ojo / ojo-tachado). `textInputAction: next`. Validación: requerido (no vacío). *Campo nuevo respecto del estado actual.*
2. **NUEVA CONTRASEÑA** — igual estructura. `textInputAction: next`. Debajo, el **medidor de fuerza** (§5.4). Validación: longitud mínima (≥ 8 recomendado; mínimo 6 si se quiere mantener compatibilidad con el backend actual — usar 8 como objetivo de fuerza y 6 como hard-minimum) + fuerza no «DÉBIL».
3. **CONFIRMAR CONTRASEÑA** — igual estructura. `textInputAction: done`, `onSubmitted` dispara el guardado. Validación: debe coincidir con «nueva»; si no, mensaje inline `"Las contraseñas no coinciden"`.

- Los tres usan tipografía de input del prompt 10 (texto en `mono` para el valor, no `'Courier'`).
- `autovalidateMode: onUserInteraction` para feedback temprano sin ser agresivo.

### 5.4 Medidor de fuerza HUD (`_PasswordStrengthMeter`)

Debajo del campo «nueva contraseña»:

- **Barra segmentada:** una fila de **4 segmentos** iguales, cada uno radio `radiusXS`, alto 5 px, gap `space4`. Reposo: todos `borderSubtle`. A medida que sube la fuerza se «encienden» de izquierda a derecha.
- **Escala de color por nivel:**
  - 0 segmentos / vacío → ninguno encendido, label `"—"`.
  - 1 segmento → `danger`, label `"DÉBIL"`.
  - 2 segmentos → `warning`, label `"MEDIA"`.
  - 3 segmentos → `warning`/`success` transición, label `"BUENA"`.
  - 4 segmentos → `success`, label `"FUERTE"`, glow `successGlow` sutil en la barra.
- **Label:** a la derecha de la barra, tipografía `labelSmall`, color = color del nivel actual.
- **Cálculo de fuerza:** función local que puntúa por longitud (≥8, ≥12), presencia de mayúscula, minúscula, dígito y símbolo. No agregar dependencias externas para esto.
- El llenado de cada segmento anima con `durFast`, `easeStandard`.

### 5.5 Validación inline

- Cada campo muestra su error debajo, cerca del campo, en `bodyS` color `danger` con ícono de error pequeño, `liveRegion`/`role: alert`.
- El error global de servidor (`_errorMessage`) se muestra como `ErrorFeedbackCard` (prompt 16) encima del footer, con `onDismiss`.
- El primer campo inválido recibe foco automático al intentar guardar (§10 archivo 00).

### 5.6 Footer

- `HudDivider` con `space24` de margen superior.
- `Row` con dos `AppButton`:
  - «CANCELAR» — variante ghost. `onPressed` cierra el modal. Si hay cambios sin guardar en los campos, pedir confirmación de descarte (§10 archivo 00).
  - «GUARDAR» — variante primary (dorada), a la derecha, con más peso visual. En `loading` muestra spinner inline y se deshabilita (sin doble submit).
- Gap `space12` entre botones.

### 5.7 Estado success (integrado)

En lugar del `_buildSuccessState` como diálogo separado, el éxito se renderiza **dentro del mismo `HoloPanel`** como un crossfade del contenido:

- El formulario hace fade-out y aparece un bloque centrado: ícono `check` en anillo `success` con `successGlow`, título `"CLAVE ACTUALIZADA"` (`titleL`, `success`), mensaje `bodyM` `textSecondary`, y una micro-cuenta regresiva o barra de progreso fina indicando el cierre automático.
- Cierre automático tras `durSlow * N` (mantener ~2 s como hoy) o al click; el operador puede cerrar antes.
- Shimmer del check **solo si `!AppMotion.reduced`**.

---

## 6. Estados e interacciones

Matriz §9 del archivo 00:

| Estado | Qué cambia |
|---|---|
| `idle` | Formulario con 3 campos vacíos; botón «GUARDAR» habilitado pero el submit valida primero. |
| `hover` (campos/botones) | Borde `borderStrong`/accent, glow suave. `durFast`. |
| `focused` (campo) | Borde `gold`/`cyan` width 2, anillo de foco visible. Nunca se elimina sin reemplazo. |
| `validando` | Al pulsar «GUARDAR»: si hay errores de validación, se muestran inline y el foco va al primer campo inválido; no se envía. |
| `loading` | Tras validación OK: «GUARDAR» con spinner inline, campos y «CANCELAR» deshabilitados, sin doble submit. |
| `error` | `ErrorFeedbackCard` con el mensaje del servidor, `role: alert`; campos editables de nuevo; foco al campo relevante si aplica. |
| `success` | Crossfade al bloque de éxito (check + mensaje), cierre automático ~2 s. |
| `disabled` (botón) | Opacidad 0.4, sin glow, no interactivo. |

Interacciones de teclado: Enter en el último campo dispara guardar (conservar el `Shortcuts`/`Actions` actual); Esc cierra (con confirmación si hay cambios).

---

## 7. Animaciones

- **Entrada del modal:** fade + scale `0.96 → 1.0` con `springSoft`, `durSlow`. El scrim hace fade-in en paralelo. Salida ~65 % de la entrada (`durBase`), `easeExit`.
- **Medidor de fuerza:** cada segmento se enciende con `durFast`, `easeStandard`; el cambio de color es `durFast`.
- **Toggle de visibilidad:** crossfade del ícono ojo, `durInstant`.
- **Crossfade a success:** el contenido del formulario hace fade-out y el bloque de éxito fade-in, `durBase`, `easeStandard`.
- **Shimmer del ícono / del check:** solo si `!AppMotion.reduced`.
- **Reduced motion:** entrada del modal = crossfade 120 ms sin scale; sin shimmer; el medidor cambia sin animación de barrido (salto directo de color). Respetar `AppMotion.reduced`.

---

## 8. Accesibilidad

- Contraste: título `titleL` `textPrimary` ≥ 12:1; subtítulo/mensajes `textSecondary` ≥ 4.5:1; labels `labelSmall` `textSecondary` ≥ 4.5:1; texto de error `danger` ≥ 4.5:1.
- El botón de cerrar es solo-ícono → `Semantics`/tooltip `"Cerrar"`. Los toggles de visibilidad también: `"Mostrar/Ocultar contraseña"`.
- El medidor de fuerza **no comunica el nivel solo por color**: lleva el label textual («DÉBIL»/«MEDIA»/«BUENA»/«FUERTE») además del color y la cantidad de segmentos.
- Errores de formulario: mensaje cerca del campo + `liveRegion`/`role: alert` + foco automático al primer campo inválido.
- Salida clara siempre: botón cerrar + «CANCELAR» + Esc. Confirmar descarte si hay cambios sin guardar.
- Foco se mueve al primer campo al abrir el modal y vuelve a la fila de origen al cerrarlo. Orden de foco = orden visual.
- Targets de toggles y botones ≥ 32×32 px de área de hit.

---

## 9. Checklist de aceptación

- [ ] El contenedor es un `HoloPanel` modal con `ChamferBorder` (chaflán), scrim `scrim` y `HudCornerBrackets`.
- [ ] El `Color(0xFF09090B)` y el `radius 24` hardcodeados fueron eliminados.
- [ ] Hay **tres** campos `AppTextField` password: actual, nueva, confirmar — cada uno con toggle de visibilidad.
- [ ] Ningún `fontFamily: 'Courier'` queda; el valor de los campos usa `mono`.
- [ ] Existe el medidor de fuerza HUD: barra de 4 segmentos que pasa `danger`→`warning`→`success` con label textual.
- [ ] Validación inline: requerido (actual), longitud/fuerza (nueva), coincidencia (confirmar); foco al primer campo inválido al guardar.
- [ ] Footer con `AppButton` «CANCELAR» (ghost) y «GUARDAR» (primary); `loading` con spinner y sin doble submit.
- [ ] El estado `success` se integra en el mismo modal (crossfade), no en un diálogo separado, con cierre automático.
- [ ] Los shimmer (ícono header, check de éxito) respetan `AppMotion.reduced`.
- [ ] Entrada del modal con fade + scale `springSoft`/`durSlow`; reduced-motion → crossfade 120 ms.
- [ ] Esc / cerrar / cancelar disponibles; confirmación de descarte si hay cambios sin guardar.
- [ ] El soporte de Enter (`Shortcuts`/`Actions`) se conserva.
- [ ] Cero hex sueltos, cero magic numbers de espaciado.
- [ ] `flutter analyze` sin warnings nuevos; se ve correcto en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01, 02 (`titleL`, `bodyS`, `labelSmall`, `mono`), 03 (dimensiones, chaflán `chamferM`), 04 (motion), 05 (iconografía), 06 (`HudCornerBrackets`, `HudDivider`, `ChamferBorder`), 07 (glow).
- **Componentes núcleo:** 09 (`AppButton`, icon button), 10 (`AppTextField` password con toggle), 12 (`HoloPanel`), 16 (`ErrorFeedbackCard`).
- **Mismo grupo:** 45 (`SettingsView`) — la fila «ACTUALIZAR CONTRASEÑA» abre este diálogo.
