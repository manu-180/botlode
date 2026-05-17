# 26 — Dashboard · Botón de acción inteligente

> Depende del archivo **00 — README · Visión y Sistema de Diseño**. Leerlo completo antes de ejecutar. Todos los valores se referencian **por token**.

---

## 1. Objetivo

Rediseñar el botón de acción inteligente del Dashboard: el **CTA que muta** según el estado de crédito. Hoy es `_SmartActionButton`, un `if/else` que devuelve tres `ElevatedButton.icon` distintos con colores hardcodeados y **sin transición** entre estados (el botón salta de uno a otro). Se eleva a un único `AppButton` que **transmuta con animación**: label, ícono y color hacen crossfade sin salto de tamaño. Es el llamado a la acción más importante de la pantalla.

---

## 2. Archivos

- **Modificar:** `lib/features/dashboard/presentation/views/dashboard_view.dart` — la clase `_SmartActionButton`. Renombrar/extraer a `SmartActionButton` en `lib/features/dashboard/presentation/widgets/smart_action_button.dart`.
- **Consumir (no crear):** `AppButton` (prompt 09), `app_colors.dart` (01), `AppTextStyles` (02), `app_dimens.dart` (03), `app_motion.dart` (04), iconografía (05).
- **Contexto:** este botón se monta dentro del panel HUD de crédito (prompt 25, slot inferior).

---

## 3. Estado actual

`_SmartActionButton` recibe `isCritical`, `hasCard`, `debtAmount` y tres callbacks. Lógica:

1. **`!isCritical`** → `ElevatedButton.icon`, fondo `primary` (dorado), ícono `Icons.add_rounded`, label `"ENSAMBLAR UNIDAD"`, `onPressed: onAssemble`.
2. **`isCritical && hasCard`** → `ElevatedButton.icon`, fondo `error` (rojo), `elevation: 10`, `shadowColor: error@0.5`, ícono `Icons.flash_on_rounded`, label `"PAGAR $X AHORA"`, `onPressed: onPayCard`.
3. **`isCritical && !hasCard`** → `ElevatedButton.icon`, fondo `#009EE3` (azul Mercado Pago hardcodeado), `FaIcon(handshake)`, label `"PAGAR ONLINE"`, `onPressed: onPayLink`.

Problemas: tres widgets independientes (el switch desmonta uno y monta otro → salto visual sin transición); colores crudos (`#009EE3`); `ElevatedButton` en vez del `AppButton` del sistema; sin pulso de urgencia en el estado crítico; padding mágico.

---

## 4. Visión del rediseño

Un **único** `AppButton` que vive permanentemente en el slot del panel de crédito y **transmuta** entre tres «modos» según el crédito. La transmutación es animada: el color de fondo, el ícono y el label hacen crossfade simultáneo, **sin que el botón cambie de tamaño** (el slot reserva un ancho/alto fijos). En modo crítico-con-tarjeta el botón **respira con urgencia** (un pulso de glow rojo sutil) para tirar del ojo hacia el pago. Cada modo tiene su personalidad cromática: dorado «construcción», rojo «urgencia», cyan/azul «pago externo». El usuario percibe un solo control vivo que reacciona al estado del sistema, no tres botones distintos.

---

## 5. Especificación visual

### 5.1 Contenedor del botón

- Un solo `AppButton` (prompt 09), tamaño large, **ancho completo** del panel de crédito (`width: double.infinity`), alto fijo 52 px. El alto y el ancho son **constantes** en los tres modos: el slot no cambia de tamaño nunca.
- Padding interno: el del `AppButton` large (definido en prompt 09); el contenido (ícono + label) se centra.
- Radio: `radiusM` (el de los botones del sistema). El `AppButton` primary destacado puede usar el chaflán `chamferM` si el prompt 09 lo ofrece como variante; coherente con el panel biselado del prompt 25. Mantener una sola decisión: si el panel es biselado, el botón primario también puede serlo.

### 5.2 Los tres modos

Definir un `enum SmartActionMode { assemble, payCard, payLink }`, derivado de `isCritical` + `hasCard`:

| Modo | Condición | Variante `AppButton` | Color base | Glow | Ícono | Label |
|---|---|---|---|---|---|---|
| **assemble** | `!isCritical` | `primary` | `gold` (`gradGold`) | `glowGold` | ícono de ensamblaje (llave/tuerca o `add` del set prompt 05) | `"ENSAMBLAR UNIDAD"` |
| **payCard** | `isCritical && hasCard` | `danger` | `danger` | `glowStatus(danger)` | ícono de rayo/flash (`flash`) | `"PAGAR $X AHORA"` (X = `debtAmount.toInt()`) |
| **payLink** | `isCritical && !hasCard` | variante destacada `info`/`cyan` | `info` (azul) | `glowCyan` o `glowStatus(info)` | ícono de handshake/enlace externo | `"PAGAR ONLINE"` |

- El azul de Mercado Pago `#009EE3` se reemplaza por el token `info` (`#3B9DFF`) del sistema. Si se quiere conservar la asociación de marca de MP, se hace dentro del modal de pago (prompt 54/55), no en este botón del dashboard.
- Texto del label: estilo `AppTextStyles.label` (uppercase, tracking +1.4), color `textOnGold` sobre dorado, `textPrimary`/blanco sobre rojo y azul (verificar contraste, §8).
- El monto en `payCard` (`$X`) se renderiza con figuras tabulares (parte mono del label) para no saltar al cambiar de valor.

### 5.3 Posición

- El botón ocupa el **slot inferior** de la columna de datos del panel de crédito (prompt 25 §5.2, punto 9): última fila, ancho completo, separado del bloque de micro-lecturas por `SizedBox(height: space16)`.

---

## 6. Estados e interacciones (matriz — 00 §9)

| Estado | Comportamiento |
|---|---|
| `default` | El botón muestra el modo correspondiente (`assemble`/`payCard`/`payLink`). |
| `hover` | `AppButton` sube borde/elevación/glow con `durFast` (lo provee el prompt 09); cursor pointer. El glow se intensifica un paso. |
| `pressed` | Escala 0.97 con `durInstant` (provisto por `AppButton`). |
| `focused` | Anillo de foco visible 2 px (`cyan` o `gold` según contexto del prompt 09); el botón es alcanzable por teclado. |
| `loading` | Si la acción dispara un proceso inline (p. ej. `payCard` mientras `billingProvider` procesa el pago), `AppButton` entra en estado loading (spinner, deshabilitado, sin doble submit). Para `assemble` y `payLink` la acción abre un modal: el botón vuelve a `default` al abrirse el modal. |
| `disabled` | Si `billingState` aún no cargó o la acción no está disponible, `AppButton` disabled (opacidad 0.4, sin glow, sin pulso). |
| `selected/active` | No aplica (no es un toggle). |
| `error` | El error del pago se comunica vía toast (prompt 17) / modal, no en el botón. El botón vuelve a habilitado para reintentar. |

**Callbacks (conservar la lógica actual):** `assemble` → `onAssemble` (abre `CreateBotModal`); `payCard` → `onPayCard` (`_confirmPayment` → `billingProvider.processPayment`); `payLink` → `onPayLink` (abre `PaymentCheckoutModal`).

---

## 7. Animaciones

Tokens de motion (00 §7).

- **Transmutación entre modos** (el corazón de este prompt): cuando `SmartActionMode` cambia, el botón **no se desmonta**. Se anima:
  - **Color de fondo:** `AnimatedContainer`/`TweenAnimationBuilder` de `Color`, `durBase`, curva `easeStandard`. El degradé `gradGold` ↔ relleno sólido `danger`/`info` se interpola.
  - **Ícono:** `AnimatedSwitcher` con `transitionBuilder` de fade+scale (0.85→1.0), `durBase`.
  - **Label:** `AnimatedSwitcher` con fade; el cambio de texto cruza suavemente. Para evitar reflow, el `AnimatedSwitcher` mantiene alineación centrada y el botón tiene ancho fijo.
  - **Glow:** crossfade entre `glowGold` / `glowStatus(danger)` / `glowCyan`, `durBase`.
  - El **tamaño del botón no cambia** en ningún momento de la transición.
- **Pulso de urgencia (solo modo `payCard`):** un latido de glow `danger` muy sutil — opacidad del `glowStatus(danger)` oscilando 0.30↔0.50, período ~1400 ms, curva `easeInOutCubic` ida y vuelta. No escala el botón, no parpadea el relleno: solo «respira» el glow. Es el único modo con pulso.
- **Entrada:** el botón entra con el panel de crédito (prompt 25/24), sin animación propia adicional.
- **Reduced motion:** la transmutación entre modos se reduce a un crossfade simple de 120 ms (color, ícono y label cambian juntos sin scale); **el pulso de urgencia se desactiva por completo** (el botón muestra el glow `danger` estable en su valor medio).

---

## 8. Accesibilidad

- Contraste del label: `textOnGold` sobre `gold` ≥ 4.5:1 (ya garantizado por el token); texto blanco/`textPrimary` sobre `danger` e `info` debe verificarse ≥ 4.5:1 — si `info` no alcanza, oscurecer el relleno un paso o usar el texto del sistema definido para botones sobre color.
- El estado crítico no se comunica solo por el color rojo: el **label cambia** ("PAGAR $X AHORA" / "PAGAR ONLINE") y el **ícono cambia** (rayo / handshake). Color + texto + ícono.
- El ícono nunca va solo: siempre acompañado del label. Aun así, `Semantics`/`tooltip` describe la acción completa ("Pagar deuda con tarjeta", "Pagar online", "Ensamblar nueva unidad").
- Foco visible siempre; el botón es parte del orden de tab del header (prompt 24 §8).
- En `loading` el botón está semánticamente disabled; no admite doble submit del pago.
- El pulso de urgencia respeta reduced-motion (se apaga).
- Área de hit ≥ 32×32 px (el botón es grande, ancho completo: cumple sobrado).

---

## 9. Checklist de aceptación

- [ ] Existe un único `SmartActionButton` basado en `AppButton`; las tres ramas `ElevatedButton` separadas fueron eliminadas.
- [ ] El botón tiene ancho completo y alto fijo (52 px) **constante** en los tres modos: el slot no cambia de tamaño.
- [ ] Modo `assemble`: `AppButton` primary dorado, `glowGold`, ícono de ensamblaje, "ENSAMBLAR UNIDAD".
- [ ] Modo `payCard`: variante `danger`, `glowStatus(danger)`, ícono de rayo, "PAGAR $X AHORA" con monto tabular.
- [ ] Modo `payLink`: variante destacada `info`/`cyan`, ícono de handshake, "PAGAR ONLINE". El `#009EE3` hardcodeado fue reemplazado por el token `info`.
- [ ] La transición entre modos anima color + ícono + label + glow (crossfade), sin desmontar el widget, sin salto de tamaño.
- [ ] El modo `payCard` tiene un pulso de urgencia de glow sutil (~1400 ms), sin escalar ni parpadear el relleno.
- [ ] Los tres callbacks (`onAssemble`/`onPayCard`/`onPayLink`) conservan su comportamiento.
- [ ] Estados hover/pressed/focused/loading/disabled del `AppButton` aplicados.
- [ ] Con reduced-motion: transmutación = crossfade 120 ms; pulso de urgencia desactivado.
- [ ] Contraste del label verificado en los tres colores de fondo.
- [ ] `Semantics`/`tooltip` describe la acción completa de cada modo.
- [ ] Cero hex crudo, cero `ElevatedButton`, cero magic numbers.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 10. Dependencias

- **Fundaciones:** 01 (colores — `gold`, `danger`, `info`, glows), 02 (tipografía `label`, mono para el monto), 03 (dimensiones), 04 (motion), 05 (iconografía — ensamblaje, rayo, handshake).
- **Componentes núcleo:** 09 (`AppButton` y sus variantes/estados), 17 (toasts de error de pago).
- **Pieza contenedora:** 25 (panel HUD de crédito — provee el slot inferior y la lógica `isCritical`/`hasCard`).
- **Shell:** 24 (layout del dashboard).
