# 15 — Estados vacíos (`EmptyState`)

> Prompt de la **Fase B — Componentes núcleo**. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Leé el archivo 00 completo antes de ejecutar. Todo valor se referencia por **nombre de token**.

---

## 1. Objetivo

Crear el widget `EmptyState` unificado: el patrón que se muestra cuando una grilla, lista o sección no tiene contenido. Reemplaza los «vacíos» improvisados (texto suelto centrado, o peor, nada) por una composición consistente con ícono, mensaje útil y acción sugerida.

---

## 2. Archivos

- **Crear** `lib/core/ui/widgets/empty_state.dart` — `EmptyState` + enum `EmptyStateVariant` (`neutral`, `noResults`).
- No crear subcarpetas. Lo consumen el dashboard (prompt 29), biblioteca, tienda, lista de facturas, popover sin ítems (prompt 13), etc.

---

## 3. Estado actual

No existe un componente de estado vacío. Cuando una grilla queda sin datos, las pantallas muestran un `Text` centrado sin jerarquía, o un espacio en blanco. No hay ícono, no hay acción sugerida, no hay coherencia visual con la metáfora «Hangar OS».

---

## 4. Visión del rediseño

Un estado vacío que se siente «bahía despejada, lista para recibir una unidad»: no un error, sino una invitación. Composición centrada: un ícono grande dentro de un **anillo HUD tenue** (círculo de borde fino con glow muy suave), un título en `titleM`, una descripción breve en `bodyS`/`textTertiary`, y opcionalmente un `AppButton` primario que ofrece la acción obvia (p. ej. «Ensamblar primera unidad»). Detrás, una `HudGridTexture` muy sutil para que el vacío tampoco sea un fondo plano.

---

## 5. Especificación visual

### 5.1 API del widget

```dart
EmptyState({
  required IconData icon,
  required String title,
  required String description,
  EmptyStateVariant variant = EmptyStateVariant.neutral,
  Widget? action,                  // típicamente un AppButton primario
})
```

### 5.2 Layout (centrado en su contenedor)

`Column` con `mainAxisAlignment.center`, `crossAxisAlignment.center`, ancho de contenido máximo 360 px (el texto no se estira a todo el ancho):

1. **Anillo + ícono** — un círculo de 96 px de diámetro: borde 1.5 px `borderDefault`, relleno `surfaceHud`, glow `glowStatus` muy tenue alrededor. Dentro, el `icon` a 40 px en color `textSecondary` (en variante `noResults` el ícono va en `cyan` apagado).
2. `space24`
3. **Título** — `Text(title)` en `titleM`, color `textPrimary`, centrado.
4. `space8`
5. **Descripción** — `Text(description)` en `bodyS`, color `textTertiary`, centrado, interlineado 1.5, máximo 2–3 líneas.
6. `space24` (solo si hay `action`)
7. **Acción** — el widget `action` (un `AppButton` primario tamaño `md`), centrado.

### 5.3 Fondo

- Detrás de la `Column`, una `HudGridTexture` (prompt 06) a su opacidad estándar (0.04) — muy sutil, para evitar el fondo plano (§3.1.1 del archivo 00).
- El `EmptyState` ocupa todo el alto/ancho disponible de su contenedor y centra el bloque.

### 5.4 Variantes

| `EmptyStateVariant` | Uso | Ícono sugerido | Color del ícono |
|---|---|---|---|
| `neutral` | No hay nada todavía (grilla recién creada, lista sin elementos) | ícono de la entidad (caja/hangar/unidad) | `textSecondary` |
| `noResults` | Una búsqueda o filtro no arrojó resultados | lupa | `cyan` apagado |

- En `noResults`, la descripción debe sugerir corregir la búsqueda («Probá con otros términos o limpiá los filtros») y la `action`, si existe, suele ser «Limpiar filtros».

---

## 6. Estados e interacciones (matriz §9 del archivo 00)

`EmptyState` es en sí mismo el estado `empty` de un contenedor; no es un control interactivo. Sus únicos elementos interactivos son:

- El `action` opcional — su matriz de estados (hover/pressed/focused/disabled/loading) la cubre el `AppButton` del prompt 09. `EmptyState` no agrega estados propios.

No tiene `hover`/`pressed`/`focused` a nivel de widget. No tiene `loading` (eso es el skeleton del prompt 14) ni `error` (eso es el prompt 16): son estados hermanos, mutuamente excluyentes, que el contenedor elige mostrar.

---

## 7. Animaciones

| Animación | Token duración | Token curva | Propiedad |
|---|---|---|---|
| Entrada del bloque completo | `durBase` | `easeEntrance` | fade (0→1) + translateY 12 px |
| Glow del anillo | estático y muy tenue (sin pulso) | — | — |

- Entrada secuencial suave opcional: anillo → título → descripción → acción, con escalonado de 36 ms entre elementos (máx 4 elementos). Si se aplica, usar `easeEntrance`.
- **Reduced motion**: el bloque aparece con un crossfade simple de 120 ms, sin translateY ni escalonado. El glow del anillo ya es estático, no cambia.

---

## 8. Accesibilidad

- Contraste: `textPrimary` (título) ≥ 12:1 sobre el fondo; `textTertiary` (descripción) ≥ 3:1 — verificar; si el contraste de `textTertiary` queda justo, considerar `textSecondary` para la descripción.
- El `EmptyState` se anuncia como una región: `Semantics(label: '$title. $description')` para que un lector de pantalla entienda el estado sin depender del ícono.
- El ícono es decorativo: `ExcludeSemantics` sobre el ícono y el anillo (la información ya está en el texto).
- Si hay `action`, es un objetivo de foco normal (cubierto por `AppButton`): foco visible, navegable, área de hit ≥ 32×32.
- El estado vacío comunica con ícono + título + descripción: no depende del color.

---

## 9. Checklist de aceptación

- [ ] Existe `empty_state.dart` en `lib/core/ui/widgets/` con `EmptyState` y `EmptyStateVariant`.
- [ ] Layout centrado: anillo+ícono (96 px) → título `titleM` → descripción `bodyS`/`textTertiary` → acción opcional.
- [ ] El anillo tiene borde `borderDefault`, relleno `surfaceHud` y glow `glowStatus` tenue.
- [ ] Fondo con `HudGridTexture` sutil (no fondo plano).
- [ ] Las dos variantes (`neutral`, `noResults`) cambian ícono y color según §5.4.
- [ ] El bloque entra con fade + translateY (`durBase`/`easeEntrance`).
- [ ] El `action` opcional es un `AppButton` y conserva su matriz de estados.
- [ ] `Semantics` anuncia título + descripción; ícono/anillo en `ExcludeSemantics`.
- [ ] Cero hex sueltos / magic numbers; todo por token.
- [ ] Respeta reduced-motion según §7.
- [ ] `flutter analyze` sin warnings nuevos; compila en 1280×720 y 1024×600.

---

## 10. Dependencias

- **01** (color: `surfaceHud`, `borderDefault`, `cyan`, `textPrimary`, `textSecondary`, `textTertiary`).
- **02** (tipografía: `titleM`, `bodyS`).
- **03** (dimensión: `space8`, `space24`, `glowStatus`).
- **04** (motion: `durBase`, `easeEntrance`, `AppMotion.reduced`).
- **05** (iconografía: ícono de entidad, lupa).
- **06** (`HudGridTexture`).
- **09** (`AppButton` — para el slot `action`).
