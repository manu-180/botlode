# 43 — Store View · «Tienda»

> Prompt ejecutable de la **Fase F**. Antes de tocar nada, leé `00_README_VISION_Y_SISTEMA_DE_DISENO.md` completo. Todos los valores se referencian por **nombre de token**.

---

## 1. Objetivo

Rediseñar la vista de la tienda de addons («Tienda»): encabezado HUD, toolbar con buscador y tabs de categoría, y una grilla de `ProductCard`. **Punto crítico:** el catálogo hoy devuelve vacío (`StoreProduct.catalog => []`). Por eso el **estado vacío es el protagonista** de esta pantalla: debe ser un `EmptyState` rico y premium («CATÁLOGO EN PREPARACIÓN» / «PRÓXIMAMENTE») con ornamento HUD, no una caja triste. El rediseño también deja resuelto el layout con productos y el estado de carga.

---

## 2. Archivos

- **Modificar:** `lib/features/store/presentation/views/store_view.dart`
- **Consumir (no crear):** `AppBackground` (08), `PageTitle` (21), `AppTextField` search (10), chips segmentados (11), `SkeletonBase` (14), `EmptyState` (15), `HudCornerBrackets`/`HudDivider`/`HudScanlines` (06), `ProductCard` (44).
- **Tokens:** `app_colors.dart`, `app_dimens.dart`, `app_motion.dart`.

Los helpers locales `_buildHeader`, `_buildCategories`, `_categoryChip` se eliminan o se reescriben sobre los componentes núcleo. No se toca el modelo `StoreProduct`.

---

## 3. Estado actual

- `ConsumerWidget`. `Scaffold(backgroundColor: AppColors.background)` — fondo plano.
- `Column`: `_buildHeader()` arriba + `Expanded` con `Padding 24` que contiene `_buildCategories()` + grilla.
- `_buildHeader`: barra con `color: surface`, borde inferior `primary@0.2`. Ícono `FontAwesomeIcons.store` en container redondeado dorado + título `'TIENDA'` (Oxanium 20, hardcodeado) + subtítulo + un buscador placeholder de 250×40 con `TextField` crudo.
- `_buildCategories`: `Row` de chips. `_categoryChip` con `radius 20` hardcodeado, relleno/borde según `isActive`.
- Grilla: `GridView.builder`, `SliverGridDelegateWithFixedCrossAxisCount` `crossAxisCount 3`, spacing `20`, `childAspectRatio 0.85`. `itemCount: products.length`.
- **`StoreProduct.catalog` devuelve `[]`** → `itemCount` es 0 → la grilla se renderiza **vacía sin ningún mensaje**. La pantalla actual queda en blanco. Esto es el problema principal a resolver.

---

## 4. Visión del rediseño

La tienda se lee como un **catálogo de armamento/módulos del hangar**. Tres capas:

1. **Fondo ambiental** (`AppBackground`) con acento **`gold`** (la tienda es la zona de «adquisición», dorada por naturaleza — es valor/dinero).
2. **Encabezado + toolbar**: `PageTitle` techBar dorado, fila con buscador `AppTextField` y tabs de categoría (chips segmentados del prompt 11).
3. **Cuerpo** que resuelve **tres escenarios**:
   - **Vacío (escenario real hoy):** un `EmptyState` ceremonioso y caro — un panel HUD central con brackets de esquina, ícono grande, título «CATÁLOGO EN PREPARACIÓN», línea mono «// SYNC_PENDING», mensaje «Los módulos premium estarán disponibles próximamente» y, opcionalmente, un campo de email/CTA «Avisarme» o simplemente un botón ghost «Volver al hangar». No es una caja gris triste: es un anuncio deliberado.
   - **Con productos:** grilla de `ProductCard` escalonada.
   - **Cargando:** grilla de skeletons.

El factor WOW del vacío: hacer que «no hay nada» se sienta como una **pantalla de sistema intencional** («módulo en preparación»), con la misma calidad HUD que el resto de la app.

---

## 5. Especificación visual

### 5.1 Estructura

```
Scaffold(backgroundColor: transparent)
└─ AppBackground(accent: AppColors.gold)
   └─ Column
      ├─ Padding(horizontal: space32, top: space32)
      │   └─ PageTitle(style: techBar, accentColor: gold)
      ├─ SizedBox(height: space24)
      ├─ Padding(horizontal: space32) → _StoreToolbar()
      ├─ SizedBox(height: space24)
      └─ Expanded(child: _StoreBody())   // vacío | grilla | skeleton
```

### 5.2 Fondo

- Reemplazar `Scaffold(backgroundColor: background)` por `AppBackground` con `accent: AppColors.gold` (glow radial dorado tenue ambiental).
- El borde inferior `primary@0.2` del header actual desaparece: la separación la da el `HudDivider` debajo de la toolbar, no un borde de barra opaca.

### 5.3 PageTitle

- `title: "TIENDA"`, `subtitle: "Potencia tus unidades con módulos premium"`.
- `style: PageTitleStyle.techBar`, `accentColor: AppColors.gold`.
- Eliminar el `Container` header manual con ícono dorado y `Text` 'TIENDA' hardcodeado: el `PageTitle` del prompt 21 ya provee ícono + título + subtítulo coherentes.

### 5.4 Toolbar (`_StoreToolbar`)

`Row`, `crossAxisAlignment: center`:

- **Izquierda — tabs de categoría.** Chips segmentados del prompt 11. Primer chip `TODOS` activo; el resto derivado de `ProductCategory.values` (`cat.displayName`, tinte `cat.color`). `radiusPill`, gap `space8`, tipografía `labelSmall`. Activo → relleno tinte `@0.12` + borde tinte + texto tinte; inactivo → transparente, borde `borderDefault`, texto `textSecondary`.
- **Spacer.**
- **Derecha — buscador.** `AppTextField` variante search (prompt 10), `width: 280`, `radiusM`, ícono lupa, placeholder `"Buscar módulo..."`. Reemplaza el `TextField` crudo de 250×40 actual.
- Debajo de la toolbar: `HudDivider` (prompt 06) fino, ancho completo, con margen `space16`.

### 5.5 Cuerpo — estado vacío (PROTAGONISTA)

Cuando `products.isEmpty`: renderizar un `EmptyState` (prompt 15) en su variante **rica/ceremonial**, centrado en el `Expanded`, dentro de un panel HUD:

- Panel central: ancho máximo `420`, `HoloPanel`/contenedor de vidrio con `radiusXL`, padding `space40`.
- `HudCornerBrackets` dorados (`gold`) en las 4 esquinas del panel — siempre visibles (es un panel jerárquico, §8 archivo 00 lo permite).
- Capa `HudScanlines` sutilísima dentro del panel (`opacity 0.035`), estática (no animada).
- **Ícono central:** ícono grande (caja/módulo o engranaje, 56–64 px) dentro de un anillo dorado tenue con `glowGold` suave. Pulso de opacidad lento opcional (latido 1600 ms) — desactivable por reduced-motion.
- **Título:** `"CATÁLOGO EN PREPARACIÓN"`, tipografía `titleL` (Oxanium 21/600), color `textPrimary`.
- **Línea mono:** `"// SYNC_PENDING — MÓDULOS EN ENSAMBLAJE"`, tipografía `mono` (JetBrains Mono), color `textTertiary`.
- **Mensaje:** `"Los módulos premium para tus unidades estarán disponibles próximamente."`, `bodyM`, `textSecondary`, centrado, `height 1.5`.
- **Acción (opcional):** un `AppButton` ghost `"VOLVER AL HANGAR"` que navega al dashboard, o un micro-campo de email + botón «Avisarme». Si se duda, usar el botón ghost — es lo más simple y suficiente.
- El conjunto entra con fade + scale `0.96 → 1.0`, `springSoft`, `durSlow`.

Este estado **no** es una `Icon` gris con texto: es una pantalla de sistema deliberada, a la altura del resto de la app.

### 5.6 Cuerpo — estado con productos

Cuando `products.isNotEmpty`:

- `GridView.builder`, `SliverGridDelegateWithMaxCrossAxisExtent`:
  - `maxCrossAxisExtent: 320`
  - `childAspectRatio: 0.82`
  - `crossAxisSpacing: space20`, `mainAxisSpacing: space20`.
- `padding: EdgeInsets.symmetric(horizontal: space32) + bottom: space32`.
- Cada ítem es un `ProductCard` (prompt 44) con su `staggerIndex`.
- Se prefiere `MaxCrossAxisExtent` sobre `FixedCrossAxisCount 3`: en 1024 px de ancho, 3 columnas fijas dan cards demasiado angostas; el `maxCrossAxisExtent` se adapta.

### 5.7 Cuerpo — estado de carga

Cuando la carga sea async (hoy es síncrona; dejar el branch listo): grilla de **6 skeletons** `SkeletonBase` con la geometría del `ProductCard` (radio `radiusL`, aspect 0.82), shimmer activo. `crossfade` `durBase` hacia la grilla real o el estado vacío al resolverse.

### 5.8 Color y tipografía

- Acento global: `gold` / `goldGlow`. El `cyan` no aparece salvo dentro de un `ProductCard` cuyo `accentColor` sea cyan.
- Cero hex sueltos, cero `Oxanium`/tamaños hardcodeados: todo por tokens de §5 archivo 00.

---

## 6. Estados e interacciones

| Estado | Comportamiento |
|---|---|
| `default` (con productos) | Toolbar + grilla escalonada. |
| `empty` | El estado real hoy: panel `EmptyState` rico «CATÁLOGO EN PREPARACIÓN» (§5.5). |
| `empty` (filtro sin resultados) | Si hay catálogo pero el filtro no devuelve nada: `EmptyState` más sobrio (ícono lupa, «SIN COINCIDENCIAS», acción «Limpiar filtro»). Distinto del vacío ceremonial de catálogo. |
| `loading` | Grilla de skeletons (§5.7). |
| `hover`/`pressed`/`focused` | Pertenecen a `ProductCard`, chips y buscador (prompts 44, 11, 10). |

Interacciones: buscador filtra en vivo; chip filtra por categoría; solo un chip activo.

---

## 7. Animaciones

- **Entrada de vista:** `PageTitle` + toolbar entran con fade + translateY 12 px, `easeEntrance`, `durBase`.
- **Estado vacío:** el panel `EmptyState` entra con fade + scale `0.96→1.0`, `springSoft`, `durSlow`. Latido lento opcional del ícono (1600 ms).
- **Grilla:** `ProductCard` escalonadas 36 ms, `easeEntrance`, `durBase`, tope ~10.
- **Cambio de filtro:** crossfade `durFast` entre sets.
- **Reduced motion:** sin escalonado, sin scale de entrada (crossfade 120 ms), sin latido del ícono ni scanlines animadas. Respetar `AppMotion.reduced`.

---

## 8. Accesibilidad

- Contraste: título `displayL`/`titleL` `textPrimary` ≥ 12:1; subtítulo y mensajes `textSecondary` ≥ 4.5:1; línea mono `textTertiary` ≥ 3:1.
- Buscador con `Semantics` label `"Buscar módulo"`; chips anuncian `selected`.
- El `EmptyState` no comunica el estado solo por ícono ni color: lleva título + texto explícito.
- Foco visible en chips, buscador y botón del `EmptyState`; orden de foco = orden visual.
- Botón del `EmptyState` con label descriptivo y área de hit ≥ 32×32 px.

---

## 9. Checklist de aceptación

- [ ] El `Scaffold(backgroundColor: background)` plano fue reemplazado por `AppBackground` con acento `gold`.
- [ ] El header manual (`_buildHeader`) fue reemplazado por `PageTitle` techBar dorado.
- [ ] La toolbar usa `AppTextField` search (prompt 10) y chips segmentados (prompt 11); el `TextField` crudo y `_categoryChip` con radio hardcodeado fueron eliminados.
- [ ] Hay un `HudDivider` debajo de la toolbar.
- [ ] **El estado vacío real** (`catalog == []`) muestra un `EmptyState` rico: panel HUD con `HudCornerBrackets`, ícono con `glowGold`, título «CATÁLOGO EN PREPARACIÓN», línea mono y mensaje. No es una caja gris.
- [ ] El estado vacío entra con fade + scale `springSoft`/`durSlow`.
- [ ] El layout con productos usa `maxCrossAxisExtent 320`, `childAspectRatio 0.82`, spacing `space20`, con `ProductCard` escalonadas.
- [ ] El branch de `loading` con skeletons está contemplado.
- [ ] El estado `empty` por filtro sin resultados es distinto del vacío de catálogo (más sobrio, con «Limpiar filtro»).
- [ ] `reduced-motion` desactiva escalonado, scale de entrada, latido y scanlines animadas.
- [ ] Cero hex sueltos, cero magic numbers de espaciado.
- [ ] `flutter analyze` sin warnings nuevos; se ve correcto en 1280×720 y 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01, 02, 03, 04, 06 (`HudCornerBrackets`, `HudDivider`, `HudScanlines`), 07 (glow), 08 (`AppBackground`).
- **Componentes núcleo:** 09 (`AppButton`), 10 (`AppTextField` search), 11 (chips segmentados), 12 (`HoloPanel`), 14 (`SkeletonBase`), 15 (`EmptyState`).
- **Shell:** 21 (`PageTitle`).
- **Mismo grupo:** 44 (`ProductCard`) — la grilla lo consume.
