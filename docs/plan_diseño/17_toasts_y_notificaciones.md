# 17 — Toasts y notificaciones (`AppToast` · `ToastService`)

> Prompt de la **Fase B — Componentes núcleo**. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Leé el archivo 00 completo antes de ejecutar. Todo valor se referencia por **nombre de token**.

---

## 1. Objetivo

Crear el sistema de toasts / notificaciones efímeras HUD: un widget `AppToast` y un servicio `ToastService` para dispararlos. Reemplaza los snackbars actuales (que en `main_layout.dart` ya tienen un estilo HUD provisional con shimmer e íconos de wifi). El sistema soporta cuatro tipos semánticos, posición fija top-center, auto-dismiss con barra de progreso y entrada slide+fade.

---

## 2. Archivos

- **Crear** `lib/core/ui/widgets/app_toast.dart` — `AppToast` (widget visual) + enum `ToastType` (`success`, `warning`, `error`, `info`).
- **Crear** `lib/core/ui/widgets/toast_service.dart` — `ToastService` con `show(...)` (gestiona el overlay y la cola).
- **Modificar** `lib/features/dashboard/presentation/views/main_layout.dart` — el método `_showTacticalSnackbar` (líneas 56–99) pasa a usar `ToastService.show(...)`; eliminar el `SnackBar` ad-hoc y la fuente `'Courier'`.
- No crear subcarpetas.

---

## 3. Estado actual

`main_layout.dart` muestra notificaciones de conectividad con `ScaffoldMessenger.showSnackBar`: contenedor negro `0.9`, borde de 2 px en `error`/`success`, sombra de glow, ícono wifi con `.shimmer` infinito, texto en fuente `'Courier'` con `letterSpacing 2.0`. El error usa `Duration(days: 1)` (persistente). Problemas: depende de `ScaffoldMessenger`, usa hex/opacidades y fuente sueltas (`'Courier'` en lugar del token `mono`), no hay tipos `warning`/`info`, no hay barra de progreso, no hay cola controlada, ni `aria-live`, ni reduced-motion.

> Nota: el HUD específico de conectividad (offline persistente / reconexión) se refina en el **prompt 61**. Este prompt 17 crea el sistema base que el 61 reutiliza.

---

## 4. Visión del rediseño

Un toast es un parte de telemetría: aparece arriba al centro, deslizándose desde el borde superior, con borde teñido del color del tipo, `HudCornerBrackets` sutiles, ícono semántico, mensaje en `bodyM`, y una **fina barra de progreso** abajo que se vacía marcando el tiempo restante. No roba el foco. Se auto-descarta en 3–5 s. Se apilan ordenados si hay varios.

---

## 5. Especificación visual

### 5.1 API

```dart
// Widget visual:
AppToast({
  required ToastType type,
  required String message,
  String? title,                    // opcional, en labelSmall UPPERCASE
  VoidCallback? onAction,            // acción opcional (ej. "DESHACER")
  String? actionLabel,
})

// Servicio:
ToastService.show({
  required BuildContext context,
  required ToastType type,
  required String message,
  String? title,
  Duration duration = const Duration(seconds: 4),
  VoidCallback? onAction,
  String? actionLabel,
})
```

### 5.2 Caja del toast

- Ancho: fijo 380 px (o `min(380, ancho disponible - space32)`).
- Relleno: `surfaceRaised` con leve tinte del color de tipo (color de tipo al ~6 %). Radio `radiusM` (14). Sombra `elev3`.
- Borde: 1.5 px del color del tipo (ver §5.4).
- `HudCornerBrackets` (prompt 06) sutiles en las 4 esquinas, color = color del tipo, brazos cortos (~14 px).
- Padding interno: `space16`.

### 5.3 Layout interno

`Column`:
- Fila principal (`Row`, `crossAxisAlignment.start`):
  1. **Ícono** — 20 px, color del tipo.
  2. `space12`
  3. **Bloque texto** (`Expanded`, `Column`): si hay `title`, `Text(title)` en `labelSmall` UPPERCASE color del tipo + `space2`; luego `Text(message)` en `bodyM` color `textPrimary`, hasta 2 líneas (wrap).
  4. Si hay `actionLabel`: `space12` + `AppButton` `ghost` `sm` con `actionLabel` (llama `onAction` y descarta el toast).
  5. `space8` + `AppIconButton` `ghost` `sm` con ícono X (descarta el toast).
- **Barra de progreso** — debajo de la fila, separada `space12`: línea de 2 px de alto, fondo `borderSubtle`, relleno color del tipo, que se **vacía** linealmente de 100 % a 0 % a lo largo de `duration`. Indica el tiempo restante.

### 5.4 Tipos semánticos

| `ToastType` | Color (token) | Ícono sugerido | Uso |
|---|---|---|---|
| `success` | `success` | check en círculo | Operación completada. |
| `warning` | `warning` | triángulo de atención | Aviso, atención requerida. |
| `error` | `danger` | círculo de error | Algo falló. |
| `info` | `info` | «i» en círculo | Mensaje informativo neutro. |

- El color **siempre** acompañado de ícono + texto (regla §10 del archivo 00).

### 5.5 Posición y apilado

- Posición: **top-center** del área de contenido (desktop), separado `space24` del borde superior. Capa: `zToast` (200).
- Si hay varios toasts activos, se apilan verticalmente con gap `space12`; el más reciente entra arriba o abajo de la pila de forma consistente. Máximo ~3 visibles simultáneos; el `ToastService` encola el resto.
- El toast NO ocupa el ancho completo ni bloquea la UI: es un overlay no modal.

---

## 6. Estados e interacciones (matriz §9 del archivo 00)

`AppToast` es efímero; sus estados:

- `default` (visible) — mostrando contenido, barra de progreso corriendo.
- `hover` — al pasar el mouse por encima, **se pausa** el auto-dismiss y la barra de progreso (cortesía: el usuario está leyendo). Al salir el mouse, se reanuda. Cursor por defecto (el toast no es clickeable salvo sus botones).
- `pressed`/`focused` — no aplican al toast como contenedor; aplican a sus botones internos (`AppButton`/`AppIconButton`, prompt 09, con su propia matriz).
- `dismissing` — saliendo (slide+fade hacia arriba). Disparado por: fin del temporizador, click en X, click en la acción, o swipe/drag hacia arriba (opcional).
- `disabled`/`loading`/`empty` — no aplican.

El toast **no roba foco**: no captura el foco de teclado de la app. Sus botones son alcanzables por `Tab` solo si el usuario navega hacia ellos, pero el foco no salta automáticamente al toast.

---

## 7. Animaciones

| Animación | Token duración | Token curva | Propiedad |
|---|---|---|---|
| Entrada del toast | `durSlow` | `easeEntrance` | slide desde arriba (translateY -16 px → 0) + fade (0→1) |
| Salida del toast | ~`durFast` (≈65 % de la entrada) | `easeExit` | slide hacia arriba + fade |
| Barra de progreso | = `duration` del toast (3–5 s) | lineal | escala/ancho del relleno 1.0→0.0 |
| Reacomodo de la pila al entrar/salir un toast | `durBase` | `easeStandard` | posición Y de los toasts restantes |

- **Reduced motion** (`AppMotion.reduced`): entrada y salida se reducen a crossfade 120 ms sin slide. La barra de progreso sigue (es funcional). Sin shimmer en el ícono — quitar el `.shimmer` infinito que tenía el snackbar viejo.
- Ninguna animación bloquea el input de la app.

---

## 8. Accesibilidad

- **`aria-live`**: el contenido del toast va envuelto en `Semantics(liveRegion: true)`. Para `error` y `warning` el anuncio es más asertivo (equivalente a `role="alert"`); `success`/`info` son `polite`.
- El toast **no roba el foco**: cumple la regla de no interrumpir el flujo del usuario.
- El auto-dismiss se **pausa en hover** para dar tiempo de lectura; además siempre hay una X para cierre manual — el usuario nunca depende solo del temporizador.
- Color + ícono + texto siempre juntos: el tipo se entiende sin percibir el color.
- Contraste: el color del tipo sobre `surfaceRaised` ≥ 3:1 (es glifo/borde); `textPrimary` sobre `surfaceRaised` ≥ 12:1.
- La barra de progreso es indicación de tiempo; no es el único medio de cierre (la X y el hover-pausa la complementan).
- Duración mínima recomendada 3 s, máxima 5 s para mensajes cortos; los errores que requieren acción deben usar `actionLabel` o derivar al patrón del prompt 16 en lugar de un toast efímero.

---

## 9. Checklist de aceptación

- [ ] Existen `app_toast.dart` y `toast_service.dart` en `lib/core/ui/widgets/`.
- [ ] `AppToast` soporta los 4 tipos (`success`/`warning`/`error`/`info`) con color e ícono semántico.
- [ ] El toast tiene `HudCornerBrackets` sutiles y borde teñido del tipo.
- [ ] Posición top-center, capa `zToast`, ancho 380 px, no modal, no roba foco.
- [ ] Barra de progreso de 2 px se vacía a lo largo de `duration` (3–5 s).
- [ ] Auto-dismiss se pausa en hover y se reanuda al salir; siempre hay X de cierre manual.
- [ ] Entrada slide+fade desde arriba con `durSlow`/`easeEntrance`; salida más rápida con `easeExit`.
- [ ] El `ToastService` encola y apila (máx ~3 visibles) con reacomodo animado.
- [ ] `main_layout._showTacticalSnackbar` migrado a `ToastService.show`; eliminada la fuente `'Courier'` y el `SnackBar` ad-hoc.
- [ ] Contenido envuelto en `Semantics(liveRegion: true)`.
- [ ] Sin `.shimmer` infinito en el ícono.
- [ ] Cero hex sueltos / magic numbers; todo por token.
- [ ] Respeta reduced-motion según §7.
- [ ] `flutter analyze` sin warnings nuevos; compila en 1280×720 y 1024×600.

---

## 10. Dependencias

- **01** (color: `surfaceRaised`, `borderSubtle`, `success`, `warning`, `danger`, `info`, `textPrimary`).
- **02** (tipografía: `labelSmall`, `bodyM`, `mono`).
- **03** (dimensión: `space2`, `space8`, `space12`, `space16`, `space24`, `space32`, `radiusM`, `elev3`, `zToast`).
- **04** (motion: `durFast`, `durBase`, `durSlow`, `easeEntrance`, `easeExit`, `easeStandard`, `AppMotion.reduced`).
- **05** (iconografía: check, triángulo de atención, círculo de error, «i», X).
- **06** (`HudCornerBrackets`).
- **09** (`AppButton`, `AppIconButton` — para la acción y la X).
