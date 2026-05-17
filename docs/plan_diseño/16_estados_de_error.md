# 16 — Estados de error (`ErrorFeedbackCard` reescrito · patrón global)

> Prompt de la **Fase B — Componentes núcleo**. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Leé el archivo 00 completo antes de ejecutar. Todo valor se referencia por **nombre de token**.

---

## 1. Objetivo

Reescribir `ErrorFeedbackCard` y definir el patrón global de error de la app: un panel con borde `danger`, ícono en anillo de glow, mensaje claro (causa + solución) y una acción de recuperación **obligatoria**. Cubre dos variantes: error inline (banda compacta dentro de un formulario/sección) y error de pantalla completa (una sección entera falló al cargar).

---

## 2. Archivos

- **Modificar/reescribir** `lib/core/ui/widgets/error_feedback_card.dart` — `ErrorFeedbackCard` con tokens y enum `ErrorVariant` (`inline`, `fullScreen`).
- No crear subcarpetas. Lo consumen formularios, modales de billing, dashboard, chat, etc.

---

## 3. Estado actual

`error_feedback_card.dart` actual: `Container` con `color: error.withOpacity(0.1)`, borde `error.withOpacity(0.5)`, radio fijo 12, sombra inventada `error.withOpacity(0.05)` blur 15. Ícono `gpp_bad_rounded` en círculo con shimmer. Título fijo «ERROR DE ENLACE». Mensaje único. Botón de cerrar (X), pero **no** hay acción de recuperación (reintentar/volver). Limpia el mensaje del backend con `replaceAll` ad-hoc. Problemas: hex/opacidades sueltas, radios mágicos, sin `Semantics(liveRegion)`, sin variante full-screen, sin acción de recuperación, sin reduced-motion.

---

## 4. Visión del rediseño

El error es una alerta de instrumento, no un susto. Panel con borde `danger`, un ícono de error dentro de un **anillo con `dangerGlow`** (el único momento donde el rojo emite), un título corto, un mensaje multi-línea que dice **qué pasó y cómo resolverlo**, y al menos un botón de recuperación («Reintentar» o «Volver»). Nunca un error sin salida. El error siempre se anuncia a accesibilidad (`liveRegion` / `role alert`).

---

## 5. Especificación visual

### 5.1 API del widget

```dart
ErrorFeedbackCard({
  required String title,            // corto: "ERROR DE ENLACE", "PAGO RECHAZADO"
  required String message,          // multi-línea: causa + cómo resolver
  required VoidCallback onRetry,     // acción de recuperación OBLIGATORIA
  String retryLabel = 'REINTENTAR',
  VoidCallback? onDismiss,           // opcional: cerrar (solo variante inline)
  ErrorVariant variant = ErrorVariant.inline,
})
```

- El `message` es responsabilidad de quien instancia: **debe** describir causa + solución (p. ej. «No se pudo contactar el servidor. Verificá tu conexión y reintentá.»). La sanitización de mensajes técnicos del backend (quitar `Exception:`, llaves, etc.) se hace **antes** de pasarlo al widget, en una util compartida, no con `replaceAll` dentro de la card.

### 5.2 Variante `inline` (banda compacta)

- Caja: relleno `danger` al 10 %, borde `danger` al 50 % (1.5 px), radio `radiusM` (14), sombra `elev1`. Ancho 100 % del contenedor, padding `space16`.
- Layout `Row`, `crossAxisAlignment.start`:
  1. **Ícono en anillo** — círculo 36 px: relleno `surfaceHud`, borde `danger` al 30 %, glow `dangerGlow` tenue; dentro, ícono de error 18 px en `danger`.
  2. `space16`
  3. **Bloque de texto** (`Expanded`, `Column`): `Text(title)` en `labelSmall` UPPERCASE color `danger`; `space4`; `Text(message)` en `bodyS` color `textPrimary`, interlineado 1.5.
  4. `space16`
  5. **Acciones**: `AppButton` variante `danger` tamaño `sm` con `retryLabel` (llama `onRetry`). Si `onDismiss != null`, un `AppIconButton` ghost `sm` con ícono X a la derecha del todo.

### 5.3 Variante `fullScreen` (sección entera falló)

- Centrado en el espacio disponible, igual encuadre que el `EmptyState` (prompt 15) pero en clave de error:
  1. **Anillo grande** — círculo 96 px: relleno `surfaceHud`, borde `danger` al 40 %, glow `dangerGlow`; ícono de error 40 px en `danger`.
  2. `space24`
  3. `Text(title)` en `titleM` color `textPrimary` (el rojo se reserva al ícono/borde; el título grande va legible).
  4. `space8`
  5. `Text(message)` en `bodyS` color `textTertiary`, centrado, máx 360 px de ancho.
  6. `space24`
  7. **Acción**: `AppButton` primario `md` con `retryLabel`. Opcionalmente un segundo `AppButton` `ghost` «Volver» si aplica.
- Fondo con `HudGridTexture` sutil (no fondo plano).
- En `fullScreen` normalmente `onDismiss` no se usa (no hay nada que cerrar; la salida es reintentar/volver).

---

## 6. Estados e interacciones (matriz §9 del archivo 00)

`ErrorFeedbackCard` **es** el estado `error` de un contenedor; como widget no tiene `hover`/`pressed` propios. Sus elementos interactivos:

- Botón de reintento — matriz completa cubierta por `AppButton` (prompt 09): default/hover/pressed/focused/disabled.
- Botón de cerrar (`AppIconButton`) — ídem.
- Mientras `onRetry` está en curso, el botón de reintento entra en estado `loading` (`AppButton.loading = true`): bloquea doble disparo.

Relación con estados hermanos: `error` es mutuamente excluyente con `loading` (prompt 14) y `empty` (prompt 15). El contenedor elige cuál mostrar; nunca dos a la vez.

---

## 7. Animaciones

| Animación | Token duración | Token curva | Propiedad |
|---|---|---|---|
| Entrada de la card | `durBase` | `easeEntrance` | fade (0→1) + translateY 8 px (inline) / 12 px (fullScreen) |
| Salida (al hacer dismiss / reintento exitoso) | ~`durFast` | `easeExit` | fade + translateY |
| Glow del anillo | estático, tenue | — | sin pulso agresivo |

- El ícono **no** lleva shimmer infinito (el actual sí lo tiene; quitarlo): el shimmer es para elementos «activos/buenos», no para un error. El anillo emite un glow `dangerGlow` estático, suficiente.
- **Reduced motion**: la card aparece con crossfade 120 ms sin translateY. Sin glow pulsante (ya es estático).

---

## 8. Accesibilidad

- **Obligatorio**: el contenido del error va envuelto en `Semantics(liveRegion: true)` (equivalente a `role="alert"`) para que un lector de pantalla lo anuncie en cuanto aparece.
- El error se comunica con color `danger` **+ ícono + texto**: el título y el mensaje son explícitos aunque no se perciba el rojo.
- **Salida obligatoria**: siempre existe `onRetry` (assert si falta). El usuario nunca queda atrapado sin acción.
- El `message` debe decir causa + cómo resolver — no un volcado técnico. La sanitización del mensaje del backend ocurre fuera del widget.
- Contraste: `danger` sobre `surfaceHud`/relleno translúcido ≥ 4.5:1; `textPrimary`/`textTertiary` verificados; el título `fullScreen` va en `textPrimary` para máxima legibilidad.
- Foco: al aparecer un error `fullScreen`, mover el foco al botón de reintento. En formularios, además, foco al primer campo inválido (regla §10 del archivo 00, coordinado con el prompt 10).

---

## 9. Checklist de aceptación

- [ ] `error_feedback_card.dart` reescrito con tokens; enum `ErrorVariant` (`inline`, `fullScreen`).
- [ ] `onRetry` es obligatorio (`assert`); nunca hay un error sin acción de recuperación.
- [ ] Variante `inline`: banda con ícono en anillo, título `labelSmall`/`danger`, mensaje `bodyS`, botón `danger` y X opcional.
- [ ] Variante `fullScreen`: encuadre centrado con anillo 96 px, título `titleM`, mensaje, `AppButton` primario, fondo `HudGridTexture`.
- [ ] El contenido está envuelto en `Semantics(liveRegion: true)`.
- [ ] El ícono ya NO tiene shimmer infinito; el anillo emite `dangerGlow` estático.
- [ ] El mensaje describe causa + solución; la sanitización del texto del backend está fuera del widget.
- [ ] El botón de reintento entra en `loading` mientras `onRetry` corre.
- [ ] Cero hex sueltos / magic numbers; todo por token.
- [ ] Respeta reduced-motion según §7.
- [ ] `flutter analyze` sin warnings nuevos; compila en 1280×720 y 1024×600.

---

## 10. Dependencias

- **01** (color: `danger`, `dangerGlow`, `surfaceHud`, `textPrimary`, `textTertiary`).
- **02** (tipografía: `titleM`, `labelSmall`, `bodyS`).
- **03** (dimensión: `space4`, `space8`, `space16`, `space24`, `radiusM`, `elev1`).
- **04** (motion: `durFast`, `durBase`, `easeEntrance`, `easeExit`, `AppMotion.reduced`).
- **05** (iconografía: ícono de error, X).
- **06** (`HudGridTexture`).
- **09** (`AppButton`, `AppIconButton`).
