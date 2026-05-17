# 13 — Tooltips y popovers (`HudTooltip` · `HudPopoverMenu`)

> Prompt de la **Fase B — Componentes núcleo**. Depende del archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md`.
> Leé el archivo 00 completo antes de ejecutar. Todo valor se referencia por **nombre de token**.

---

## 1. Objetivo

Crear dos overlays reutilizables: `HudTooltip`, el tooltip de la app con estética HUD, y `HudPopoverMenu`, el menú contextual / popover de lista de acciones. Ambos son consumidos por botones (prompt 09), barras de acciones y cualquier control que necesite ayuda contextual o un menú.

---

## 2. Archivos

- **Crear** `lib/core/ui/widgets/hud_tooltip.dart` — `HudTooltip` (wrapper de un child) + el painter de la micro-flecha.
- **Crear** `lib/core/ui/widgets/hud_popover_menu.dart` — `HudPopoverMenu`, `HudPopoverItem` (modelo de ítem), helper `showHudPopover(...)`.
- No crear subcarpetas.

---

## 3. Estado actual

La app usa el `Tooltip` de Material por defecto (fondo gris plano, sin estética HUD) o directamente no tiene tooltips. No existe un menú contextual / popover propio: cuando se necesita una lista de acciones se improvisa con `PopupMenuButton` de Material, que rompe la coherencia visual «Hangar OS».

---

## 4. Visión del rediseño

- **`HudTooltip`**: una etiqueta de instrumento. Fondo `surfaceRaised`, borde `borderGold` hairline, texto en fuente `mono`/`bodyS`, una micro-flecha apuntando al origen, aparece con fade+scale **desde el punto de origen** tras un delay de 400 ms. Compacto, sin sombra agresiva (`elev2`).
- **`HudPopoverMenu`**: panel flotante de vidrio (`HoloPanel`-like) con una lista vertical de ítems; cada ítem con hover; divisores `HudDivider` entre grupos; los ítems destructivos van separados al final y en color `danger`. Se cierra al hacer click afuera o con `Esc`.

---

## 5. Especificación visual

### 5.1 `HudTooltip`

```dart
HudTooltip({
  required Widget child,
  required String message,
  TooltipPosition preferred = TooltipPosition.top,  // top/bottom/left/right
})
```

- Caja: fondo `surfaceRaised`, borde `borderGold` 1 px, radio `radiusS` (10), padding `space8` horizontal / `space4` vertical, sombra `elev2`.
- Texto: tipografía `mono` (JetBrains Mono) o `bodyS` para mensajes más largos; color `textPrimary`. Una sola línea preferida; ancho máximo 240 px (wrap si excede).
- **Micro-flecha**: triángulo de 6 px de alto pintado con `CustomPainter`, mismo relleno `surfaceRaised` y borde `borderGold`, apuntando hacia el `child` según `preferred`.
- **Posicionamiento**: separado 6 px del `child`. Si no entra en `preferred`, hace flip al lado opuesto (igual que Material `Tooltip`). Capa de render: `zModal` (overlay).
- **Delay de aparición**: 400 ms de hover sostenido antes de mostrarse. Desaparece de inmediato al salir el mouse.

### 5.2 `HudPopoverMenu` / `HudPopoverItem`

```dart
HudPopoverItem({
  required String label,
  required IconData icon,
  required VoidCallback onSelected,
  bool destructive = false,         // ítem en color danger, va al final
  bool enabled = true,
})

showHudPopover({
  required BuildContext context,
  required Offset anchor,           // posición del control que lo abre
  required List<HudPopoverItem> items,
})
```

- Panel: fondo `glassSurfaceStrong` con blur, borde `glassBorder` 1 px + highlight `glassHighlightTop`, radio `radiusM` (14), sombra `elev3`. Ancho mínimo 200 px, máximo 280 px.
- Cada ítem: `Row` → ícono 16 px + `space12` + `Text(label)` en `bodyM`; altura 40 px; padding horizontal `space12`.
  - Ítems normales: ícono/texto `textSecondary` (`textPrimary` en hover).
  - Ítems `destructive`: ícono/texto `danger`; se agrupan **al final**, separados del resto por un `HudDivider`.
- `HudDivider` (prompt 06) separa grupos lógicos de ítems y siempre antes del bloque destructivo.
- Posicionamiento: el panel se ancla al control que lo abrió (`anchor`), se abre hacia abajo por defecto, hace flip hacia arriba si no entra. Capa: `zModal`.

---

## 6. Estados e interacciones (matriz §9 del archivo 00)

### 6.1 `HudTooltip`
No es un control con foco; estados:
- `default` (oculto) → `hover` 400 ms → `visible`. Al salir el mouse, vuelve a oculto.
- No tiene `pressed`/`focused`/`disabled` propios.
- Reduced motion: aparece sin animación de escala (solo el contenido, instantáneo o crossfade 120 ms).

### 6.2 `HudPopoverItem` (cada ítem es interactivo)

| Estado | Relleno | Texto/ícono |
|---|---|---|
| `default` | transparente | `textSecondary` (o `danger` si destructivo) |
| `hover` | `borderSubtle` (relleno tenue) | `textPrimary` (o `danger` más brillante) ; cursor `click` |
| `pressed` | `surfaceHud` | igual; sin escala (los ítems de lista no escalan, solo cambian relleno) |
| `focused` | igual al base | + anillo `cyan` 2 px interno al ítem |
| `disabled` | transparente | `textTertiary`, opacidad 0.4, no seleccionable |

- `loading`/`error`/`empty`: si la lista de ítems llega vacía, el popover muestra un mini `EmptyState` (prompt 15) con texto «Sin acciones disponibles».

### 6.3 Cierre del popover
- Click fuera del panel → cierra.
- Tecla `Esc` → cierra.
- Seleccionar un ítem → ejecuta `onSelected` y cierra.
- El popover atrapa el foco mientras está abierto; al cerrarse devuelve el foco al control que lo abrió.

---

## 7. Animaciones

| Interacción | Token duración | Token curva | Propiedad |
|---|---|---|---|
| Tooltip aparece | `durFast` | `easeEntrance` | fade (0→1) + scale (0.92→1.0) con origen en la flecha |
| Tooltip desaparece | ~`durInstant` (≈65 % de la entrada) | `easeExit` | fade |
| Popover abre | `durBase` | `easeEntrance` | fade + scale (0.96→1.0) con origen en el `anchor` + translateY 6 px |
| Popover cierra | ~`durFast` | `easeExit` | fade + scale |
| Ítem hover (relleno) | `durFast` | `easeStandard` | `AnimatedContainer` |

- **Reduced motion**: tooltip y popover aparecen con crossfade 120 ms sin escala ni translate.
- Las animaciones de overlay no bloquean el input del resto de la app.

---

## 8. Accesibilidad

- `HudTooltip` provee el texto accesible del control que envuelve (especialmente para `AppIconButton`): se expone vía `Semantics(label: message)` además del overlay visual.
- Contraste: `textPrimary` sobre `surfaceRaised` ≥ 12:1; ítems sobre `glassSurfaceStrong` verificados ≥ 4.5:1; los `destructive` en `danger` ≥ 4.5:1.
- Popover: foco visible (anillo `cyan`) en cada ítem, navegable con flechas ↑/↓, `Enter` selecciona, `Esc` cierra. Orden de foco = orden visual.
- Acción destructiva: separada visualmente + color `danger` + ícono — nunca solo color. Si la acción es irreversible, el `onSelected` debe abrir una confirmación (no se confirma dentro del popover).
- El popover es modal-ligero: no roba el foco de teclado del SO, pero captura foco interno mientras está abierto.

---

## 9. Checklist de aceptación

- [ ] Existen `hud_tooltip.dart` y `hud_popover_menu.dart` en `lib/core/ui/widgets/`.
- [ ] `HudTooltip` usa fondo `surfaceRaised`, borde `borderGold`, texto `mono`/`bodyS`, micro-flecha y delay 400 ms.
- [ ] El tooltip aparece con fade+scale desde el origen y respeta `preferred` con flip.
- [ ] `HudPopoverMenu` es un panel de vidrio con lista de `HudPopoverItem`.
- [ ] Los ítems `destructive` van al final, separados por `HudDivider`, en color `danger`.
- [ ] Cada ítem implementa la matriz de §6.2 (default/hover/pressed/focused/disabled).
- [ ] El popover cierra con click afuera y con `Esc`; devuelve el foco al abridor.
- [ ] Ambos overlays se renderizan en capa `zModal`.
- [ ] Navegación por teclado con flechas + `Enter` + `Esc`.
- [ ] Cero hex sueltos / magic numbers; todo por token.
- [ ] Respeta reduced-motion según §7.
- [ ] `flutter analyze` sin warnings nuevos; compila en 1280×720 y 1024×600.

---

## 10. Dependencias

- **01** (color: `surfaceRaised`, `surfaceHud`, `glassSurfaceStrong`, `glassBorder`, `glassHighlightTop`, `borderGold`, `borderSubtle`, `cyan`, `danger`, `textPrimary/Secondary/Tertiary`).
- **02** (tipografía: `mono`, `bodyS`, `bodyM`).
- **03** (dimensión: `space*`, `radiusS`, `radiusM`, `elev2`, `elev3`, `zModal`).
- **04** (motion: `durInstant`, `durFast`, `durBase`, `easeEntrance`, `easeExit`, `easeStandard`, `AppMotion.reduced`).
- **05** (iconografía de los ítems).
- **06** (`HudDivider`).
- **07** (`GlassDecoration` para el panel del popover).
- **15** (`EmptyState` — para el popover sin ítems).
