# 63 — QA · Accesibilidad y Contraste

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.
> **Este es un prompt de AUDITORÍA.** Verifica que toda la app cumpla las reglas de accesibilidad de §10 y corrige las violaciones.

---

## 1. Objetivo

Auditar la accesibilidad de toda la aplicación tras los prompts 01–61: contraste WCAG, foco visible y lógico, semántica de botones solo-ícono, estado nunca solo por color, modales con salida y trap de foco, errores de formulario anunciados, y targets de hit cómodos. Una app premium también es una app usable: este control garantiza que el factor WOW no se construyó a costa de la accesibilidad.

---

## 2. Alcance de la auditoría

Todas las pantallas, modales y overlays listados en el prompt 62 §2: shell, login, dashboard, bot detail + 5 tabs, chat, biblioteca, tienda, ajustes, billing + 4 tabs + todos los modales, connectivity HUD. Cada uno en todos sus estados (default/hover/pressed/focused/loading/disabled/error/empty).

---

## 3. Procedimiento paso a paso

Recorrer cada pantalla y aplicar las siguientes verificaciones. Para cada par de color, **calcular el ratio de contraste real** (fórmula WCAG: luminancia relativa) y registrar el valor.

### Paso 1 — Contraste de texto
- Para **cada** par texto/fondo de la pantalla, calcular el ratio:
  - Texto normal (< 18.66 px regular / < 24 px bold): ratio ≥ **4.5:1**.
  - Texto grande (≥ 18.66 px bold o ≥ 24 px regular) y glifos/iconos de UI: ratio ≥ **3:1**.
- Atención especial a: `textSecondary`/`textTertiary` sobre `surface`/`surfaceHud`; colores semánticos (`success`/`warning`/`danger`/`info`/`gold`) usados como texto sobre fondos de banda; texto sobre vidrio con blur (verificar el peor caso de fondo detrás del blur); `textOnGold` sobre superficies doradas.
- Registrar todo par que no llegue y corregirlo (texto más claro, fondo más oscuro, o aumentar peso/tamaño).

### Paso 2 — Foco visible y orden de foco
- Todo elemento interactivo (botones, inputs, radios, toggles, filas clickeables, tabs, ítems de sidebar, chevrons) tiene un **anillo de foco visible** de 2 px (`cyan` o `gold` según contexto). Ningún `FocusNode` sin indicador visual; ningún `focusColor`/`overlayColor` que oculte el foco.
- Recorrer cada pantalla solo con teclado (Tab/Shift+Tab) y verificar que el **orden de foco coincide con el orden visual** (arriba→abajo, izquierda→derecha). Sin saltos ni trampas no intencionales.

### Paso 3 — Botones solo-ícono
- Todo `IconButton`/`AppIconButton`/control sin texto visible lleva `Semantics(label:)` o `tooltip` descriptivo (cerrar, descargar, minimizar, atrás, etc.). Verificar también los botones de ventana del title bar.

### Paso 4 — Estado nunca solo por color
- Todo estado (online/suspendido/offline, pagada/pendiente/fallida, éxito/error, severidad de banner) se comunica con **color + ícono + texto**, no solo color. Revisar `StatusTag`, `HudStatusDot`, banners de trial/dunning, status indicator del chat, estados de la digital card.

### Paso 5 — Modales: salida y trap de foco
- Cada modal/diálogo tiene una **salida clara** (botón cerrar/cancelar/volver). Confirmación antes de acciones destructivas y antes de descartar un modal con cambios sin guardar.
- El foco queda **atrapado dentro del modal** mientras está abierto (no se puede tabular al contenido de fondo) y, al cerrarse, vuelve al elemento que lo abrió.
- Verificar especialmente los flujos multi-paso (cancel flow): cada paso mantiene el trap; el botón destructivo no es el foco inicial.

### Paso 6 — Errores de formulario
- Todo mensaje de error de validación aparece **cerca del campo** afectado, con `Semantics(liveRegion:true)` / rol de alerta, y el **foco se mueve automáticamente al primer campo inválido** al enviar.
- Verificar: login, formularios de pasarela (Stripe/MercadoPago), add card, change password, campo de comentario del cancel flow.

### Paso 7 — Targets de hit
- Todo elemento clickeable tiene un área de hit ≥ **32×32 px** (≥ 44×44 si existe versión táctil). Verificar chevrons, íconos de descarga, botones de cerrar de banners, dots de estado clickeables, ítems pequeños de listas.

### Paso 8 — Reduced motion (verificación cruzada)
- Confirmar a alto nivel que con `MediaQuery.disableAnimations` activo no hay animación esencial perdida ni contenido inaccesible (la auditoría detallada de motion es el prompt 64; aquí solo se chequea que no rompa la usabilidad).

Para cada hallazgo: anotar pantalla/archivo/línea, la regla violada, el ratio calculado si aplica, y aplicar la corrección.

---

## 4. Criterios de aprobación

- Todos los pares texto/fondo cumplen ≥ 4.5:1 (normal) / ≥ 3:1 (grande/glifos), con valores registrados.
- Foco visible en el 100 % de los elementos interactivos; orden de foco lógico en cada pantalla.
- Todo botón solo-ícono tiene label/tooltip.
- Ningún estado depende solo del color.
- Todos los modales tienen salida clara, trap de foco y devolución de foco; las acciones destructivas piden confirmación.
- Errores de formulario anunciados con `liveRegion` y foco al primer inválido.
- Todos los targets de hit ≥ 32×32 px.

---

## 5. Checklist

- [ ] Pares texto/fondo verificados con ratio calculado en todas las pantallas.
- [ ] Foco visible en cada elemento interactivo; orden de foco lógico verificado con teclado.
- [ ] Botones solo-ícono con `Semantics`/`tooltip` (incluidos los del title bar).
- [ ] Estado = color + ícono + texto en todos los indicadores.
- [ ] Modales con salida clara, trap de foco y devolución de foco; confirmación en destructivas.
- [ ] Errores de formulario con `liveRegion` y foco al primer campo inválido.
- [ ] Targets de hit ≥ 32×32 px.
- [ ] Reduced-motion no rompe usabilidad.
- [ ] `flutter analyze` sin warnings nuevos tras las correcciones.

---

## 6. Entregable

Un informe con:

1. **Tabla de hallazgos por pantalla** — columnas: Pantalla/Componente · Archivo:línea · Categoría (contraste/foco/semántica/color-only/modal/error-form/hit-target) · Descripción · Ratio calculado (si es contraste) · Severidad.
2. **Correcciones aplicadas** — por hallazgo, el cambio realizado y el nuevo valor (ej. ratio antes/después).

La auditoría no se aprueba hasta que cada hallazgo esté corregido o documentado como deuda justificada por escrito.

---

## 7. Dependencias

- **Todos los prompts 01–61** ejecutados.
- Referencia: 01 (tokens de color y sus reglas de contraste declaradas), 02 (escala tipográfica), 09–17 (componentes núcleo y su semántica), 18–21 (shell).
