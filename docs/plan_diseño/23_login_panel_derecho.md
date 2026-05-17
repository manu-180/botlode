# 23 — Login · Panel derecho (formulario «IDENTIFICACIÓN REQUERIDA»)

> Depende del archivo **00 — README · Visión y Sistema de Diseño**. Leerlo completo antes de ejecutar. Todos los valores se referencian **por token**.

---

## 1. Objetivo

Rediseñar el panel derecho del login: el formulario de autenticación. Hoy es un `Container` negro plano con inputs custom (`_LoginInput`) y un `ElevatedButton` dorado, con un toast de error ad-hoc. Se eleva a un **panel de identificación HUD**: superficie de vidrio enmarcada, candado en anillo HUD, campos del sistema de inputs (prompt 10), botón del sistema (prompt 09) y toast del sistema (prompt 17). Debe sentirse como autenticarse en una terminal segura.

---

## 2. Archivos

- **Modificar:** `lib/features/auth/presentation/views/login_view.dart` — la rama `Expanded(flex: 4, …)` del `Row` (panel derecho), el bloque `AnimatedPositioned` del toast de error, y la clase `_LoginInput` (se **elimina**, reemplazada por `AppTextField`). Conservar la lógica de auth: `_formKey`, `_emailController`, `_passController`, `_submit`, `ref.listen(authProvider)`.
- **Consumir (no crear):** `AppTextField` (prompt 10), `AppButton` (prompt 09), `HoloPanel` (prompt 12), sistema de toasts (prompt 17), `HudCornerBrackets` (06), `app_colors.dart` (01), `AppTextStyles` (02), `app_dimens.dart` (03), `app_motion.dart` (04).

---

## 3. Estado actual

`Expanded(flex: 4)` → `Container` con `color: Color(0xFF0A0A0A)` y `Border(left: BorderSide(borderGlass))` → `Center` → `SingleChildScrollView(padding: 60)` → `ConstrainedBox(maxWidth: 450)` → `Column`:

- Ícono `Icons.lock_outline_rounded` `primary` 48 px con `.scale(elasticOut)`.
- Título `"IDENTIFICACIÓN REQUERIDA"` 28 px peso bold Oxanium.
- Subtítulo `"Ingrese sus credenciales para acceder al núcleo."` color `textSecondary` al 80 %.
- `Form` con dos `_LoginInput` (email y password), separados por `SizedBox(height: 24)`.
- `ElevatedButton` ancho, alto 56, fondo `primary`, con estado loading (spinner + `"VERIFICANDO..."`).

El toast vive aparte en el `Stack` raíz: un `AnimatedPositioned` que baja desde `top: -150` a `top: 40`, `Container` rojo oscuro `#140000` con borde `error`.

Problemas: fondo negro plano, `_LoginInput` reinventa lo que el prompt 10 ya estandariza, botón con `ElevatedButton` crudo (debe ser `AppButton`), toast ad-hoc (debe ser el del prompt 17), sin ornamento HUD, sin animación de entrada del panel.

---

## 4. Visión del rediseño

El panel derecho es un **módulo de identificación montado sobre el vacío**. No un rectángulo negro: una superficie `surface` con costura HUD a la izquierda, brackets de esquina y profundidad. El candado vive dentro de un **anillo HUD** que emite `glowGold`, como un lector biométrico. El formulario usa los campos premium del sistema (foco con anillo, validación inline). El botón es el `AppButton` primary con su estado loading propio. Los errores ya no son un toast casero: usan el sistema global de toasts (prompt 17), apareciendo con vocabulario consistente. Al cargar, el panel **entra deslizándose desde la derecha** con un fade — como un módulo que se acopla a la terminal.

---

## 5. Especificación visual

### 5.1 Contenedor del panel

- `Expanded(flex: 42)` (coordinado con prompt 22: izquierdo 58 / derecho 42).
- Fondo: superficie `surface` (no negro plano `#0A0A0A`). Aplicar `gradPanel` (linear 160° `surfaceRaised → surface`) como relleno sutil.
- Borde izquierdo: el divisor de costura HUD lo aporta el panel izquierdo (prompt 22 §5.4). El panel derecho **no** dibuja su propio `BorderSide` izquierdo.
- `HudCornerBrackets` (prompt 06) en las esquinas del panel, brazo 18 px, color `borderGold`, margen `space24`.
- Contenido: `Center` → `SingleChildScrollView(padding: EdgeInsets.all(space48))` → `ConstrainedBox(maxWidth: 420)` → `Column(crossAxisAlignment: start)`.

### 5.2 Encabezado del formulario (`Column`, top → bottom)

1. **Candado en anillo HUD.** Un `SizedBox(56×56)` con un `Stack` centrado:
   - Anillo: `Container` circular 56×56, borde 1.5 px `borderGold`, fondo `surfaceHud`, `boxShadow: glowGold` (blur 24, `goldGlow`).
   - Ícono: `Icons.lock_outline_rounded` (o el ícono de candado del set del prompt 05), 26 px, color `gold`, centrado.
   - Detalle opcional: dos micro-marcas de bracket en los lados del anillo (líneas de 6 px `borderGold`), estilo lector biométrico.
2. `SizedBox(height: space24)`.
3. **Título.** `Text("IDENTIFICACIÓN REQUERIDA")` con estilo `AppTextStyles.displayM` (26 px / 700 / tracking +1.0 / Oxanium), color `textPrimary`.
4. `SizedBox(height: space8)`.
5. **Subtítulo.** `Text("Ingrese sus credenciales para acceder al núcleo.")` con estilo `AppTextStyles.bodyS` (12.5 px / 400 / Oxanium), color `textSecondary`.
6. `SizedBox(height: space40)`.

### 5.3 Formulario (`Form` con `_formKey`)

`Column` con:

1. **Campo email.** `AppTextField` (prompt 10), variante estándar:
   - `label: "CORREO ELECTRÓNICO"` (estilo `label` del sistema, uppercase).
   - `prefixIcon`: ícono de arroba del set (prompt 05).
   - `controller: _emailController`, `keyboardType: emailAddress`, `textInputAction: TextInputAction.next`.
   - `validator`: requerido + debe contener `@` (conservar la lógica actual).
   - `autovalidateMode`: igual que hoy — se activa tras el primer blur (`onUserInteraction` después de `_touched`).
2. `SizedBox(height: space20)`.
3. **Campo password.** `AppTextField` variante password (prompt 10): incluye toggle de visibilidad (ojo) ya provisto por el componente.
   - `label: "CLAVE DE ACCESO"`, `prefixIcon`: ícono de llave del set.
   - `controller: _passController`, `obscureText: true`, `textInputAction: TextInputAction.done`, `onSubmitted: (_) => _submit()`.
   - `validator`: requerido + mínimo 6 caracteres (conservar).
4. `SizedBox(height: space16)`.
5. **Recordar sesión (opcional).** `Row(mainAxisAlignment: start)` con un checkbox del sistema (estilo HUD: cuadrado `radiusXS`, check `gold`) + `Text("Mantener sesión iniciada")` estilo `bodyS` `textSecondary`. Estado controlado por un `bool _rememberSession` local. Si la persistencia de sesión no está implementada en `authProvider`, dejar el control presente pero documentar que el flag se pasa a `signIn` cuando exista soporte. No bloquear la entrega por esto.
6. `SizedBox(height: space32)`.

### 5.4 Botón de submit

- `AppButton` (prompt 09), variante `primary`, ancho completo (`width: double.infinity`), alto 56 px (`AppButton` con tamaño large), `glowGold` activo.
- Label reposo: `"ACCEDER AL SISTEMA"` (estilo `label`, uppercase).
- Estado `loading`: lo maneja `AppButton` internamente — spinner `textOnGold` 18 px + label `"VERIFICANDO..."`. El botón se deshabilita; nada de doble submit.
- `onPressed: authState.isLoading ? null : _submit`.

### 5.5 Toast de error

Eliminar el `AnimatedPositioned` ad-hoc. Usar el **sistema de toasts del prompt 17**: cuando `ref.listen(authProvider)` detecta `next.error != prev?.error`, llamar al servicio de toasts con variante `error`, título `"ACCESO DENEGADO"` y mensaje `next.error`. El toast aparece en la capa `zToast`, vocabulario HUD consistente con el resto de la app. El `Timer` de 8 s actual se reemplaza por el auto-dismiss del sistema de toasts.

Mantener el efecto sobre la Rive: al disparar error, `_moodInput?.value = 1.0`; al auto-cerrarse el toast, volver a `3.0`. Conectar ese «volver a 3.0» al callback de dismiss del toast (o a un `Timer` paralelo equivalente).

---

## 6. Estados e interacciones (matriz del formulario — 00 §9)

| Estado | Qué ocurre |
|---|---|
| `idle` | Panel montado, campos vacíos, botón `primary` habilitado, sin toast. Foco automático en el campo email. |
| `focused` (campo) | El `AppTextField` muestra su anillo de foco (2 px, `cyan` o `gold` según prompt 10). Orden de tab: email → password → recordar → botón. |
| `validando` (un campo, tras blur) | `autovalidateMode.onUserInteraction`: el campo muestra error inline (borde `danger` + mensaje cerca del campo, `liveRegion`). |
| `pressed` (botón) | `AppButton` escala 0.97 `durInstant`. |
| `loading` (submit en curso) | `authState.isLoading == true`: botón en estado loading (spinner + "VERIFICANDO..."), `onPressed: null`. Campos no se deshabilitan visualmente pero un nuevo submit está bloqueado. |
| `error` (auth falla) | Toast `error` del prompt 17 con "ACCESO DENEGADO" + mensaje. Catbot mood 1.0. El botón vuelve a habilitado para reintentar. Foco se mantiene; si el error es de campo, foco al primer campo inválido. |
| `success` (auth ok) | `go_router` redirige al shell autenticado (`/dashboard`) con la transición de pantalla del prompt 20. No mostrar toast de éxito (la navegación es la confirmación). |
| `disabled` | El botón se considera disabled solo durante `loading`. |

**Submit con Enter:** estando el foco en el campo password, Enter dispara `_submit` vía `onSubmitted`. Estando en email, Enter pasa el foco a password (`TextInputAction.next`). El `Form.validate()` corre antes de llamar a `signIn`.

---

## 7. Animaciones

Tokens de motion (00 §7), `flutter_animate`.

- **Entrada del panel:** al montar, todo el panel derecho entra con `.fadeIn(duration: durSlow)` + `.moveX(begin: 24, end: 0)` (slide desde la derecha), curva `easeEntrance`.
- **Entrada escalonada interna** (delays relativos al inicio de la entrada del panel):
  1. Anillo del candado: `.scale(begin: 0.85, end: 1.0, duration: durBase, curve: easeEntrance)`, delay 120 ms. (Reemplaza el `elasticOut` actual por una curva del sistema.)
  2. Título: fade + `moveY(8→0)`, `durBase`, delay 200 ms.
  3. Subtítulo: fade + `moveY(8→0)`, `durBase`, delay 280 ms.
  4. Campos del formulario: fade + `moveY(10→0)`, `durBase`, delay 360 ms (los dos campos juntos o escalonados 36 ms entre sí).
  5. Botón: fade + `moveY(8→0)`, `durBase`, delay 460 ms.
  Total ≤ ~480 ms; aceptable como reveal escénico de pantalla de entrada (excede ligeramente `durDeliberate` solo por el escalonado, no por una animación individual).
- **Glow del anillo del candado:** latido sutil de `goldGlow` 0.25↔0.40 cada 3200 ms (patrón reactor). Opcional. Se desactiva con reduced-motion.
- **Foco automático en email:** al completar la animación de entrada, `FocusScope` enfoca el campo email.
- **Reduced motion:** sin slide del panel ni escalonado — crossfade único de 120 ms; sin latido del anillo; foco al email inmediato.

---

## 8. Accesibilidad

- Contraste: `textPrimary` (título) y `textSecondary` (subtítulo, recordar) sobre `surface`/`gradPanel` ≥ 4.5:1; verificar.
- El candado es decorativo: `ExcludeSemantics` o `Semantics` sin rol; el título `"IDENTIFICACIÓN REQUERIDA"` transmite el propósito.
- Foco visible siempre en los campos y el botón (anillo del prompt 10/09); nunca se elimina sin reemplazo.
- Errores de formulario: mensaje inline cerca del campo + foco automático al primer campo inválido tras un submit fallido por validación.
- El toast de error usa `liveRegion` (lo provee el prompt 17) para que un lector de pantalla lo anuncie.
- El botón en `loading` está semánticamente disabled; no permite doble submit.
- El estado de error nunca se comunica solo por color: toast con ícono + título + texto, y campos con borde + ícono + mensaje.
- Target del checkbox de "recordar sesión" ≥ 32×32 px de área de hit.
- Salida clara: si en el futuro hay un enlace «¿olvidó su clave?», debe ser navegable por teclado.

---

## 9. Checklist de aceptación

- [ ] El panel derecho usa `flex: 42`; fondo `surface` con `gradPanel`, nunca `#0A0A0A` plano.
- [ ] `HudCornerBrackets` presentes; el divisor izquierdo lo aporta el panel 22 (no se duplica).
- [ ] Candado dentro de un anillo HUD circular con borde `borderGold` y `glowGold`.
- [ ] Título en `displayM`, subtítulo en `bodyS` `textSecondary`.
- [ ] La clase `_LoginInput` fue eliminada; email y password usan `AppTextField` (prompt 10) con sus variantes.
- [ ] El botón es `AppButton` primary, ancho completo, alto 56, con estado loading propio (spinner + "VERIFICANDO...").
- [ ] Checkbox "Mantener sesión iniciada" presente, estilo HUD.
- [ ] El toast de error usa el sistema del prompt 17 (no `AnimatedPositioned` ad-hoc); título "ACCESO DENEGADO".
- [ ] La Rive del Catbot pasa a mood 1.0 en error y vuelve a 3.0 al cerrarse el toast.
- [ ] El panel entra con slide+fade desde la derecha; entrada interna escalonada con `easeEntrance`.
- [ ] Foco automático en el campo email tras la entrada; Enter en password dispara submit; Tab respeta orden visual.
- [ ] Validación inline tras blur; foco al primer campo inválido tras submit fallido.
- [ ] `authState.isLoading` deshabilita el botón; sin doble submit.
- [ ] Con reduced-motion: crossfade 120 ms, sin latidos, foco al email inmediato.
- [ ] Cero hex crudo, cero `fontFamily: 'Courier'`, cero tamaños mágicos.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores), 02 (tipografía), 03 (dimensiones), 04 (motion), 05 (iconografía).
- **Componentes núcleo:** 06 (`HudCornerBrackets`), 07 (glow/glass para el anillo), 09 (`AppButton`), 10 (`AppTextField` email/password/checkbox), 12 (`HoloPanel`/superficie de panel), 17 (sistema de toasts).
- **Shell:** 20 (transición de ruta `go_router` hacia el dashboard en `success`).
- **Pareja directa:** 22 (panel izquierdo) — proporción `flex` y divisor de costura.
