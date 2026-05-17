# 41 — Bots Library View · «Biblioteca de Planos»

> Prompt ejecutable de la **Fase F**. Antes de tocar nada, leé el archivo `00_README_VISION_Y_SISTEMA_DE_DISENO.md` completo. Todos los valores se referencian por **nombre de token**: ningún hex suelto, ningún número mágico de espaciado.

---

## 1. Objetivo

Rediseñar la vista de la biblioteca de plantillas («Biblioteca de Planos»): la pantalla donde el operario elige un prototipo de bot para iniciar el ensamblaje. Debe sentirse como el **archivo técnico de planos de ingeniería** del hangar: encabezado HUD con acento cyan (es la sección «técnica/blueprint»), un toolbar opcional de búsqueda/filtro de planos, y una grilla de `BlueprintCard` con entrada escalonada. La pantalla hoy es funcional pero plana; el rediseño le agrega profundidad, ornamento HUD y estados completos (carga y vacío).

---

## 2. Archivos

- **Modificar:** `lib/features/bots_library/presentation/views/bots_library_view.dart`
- **Consumir (no crear):** `AppBackground` (prompt 08), `PageTitle` (prompt 21), `AppTextField` search (prompt 10), chips segmentados (prompt 11), `SkeletonBase` (prompt 14), `EmptyState` (prompt 15), `BlueprintCard` (prompt 42).
- **Tokens:** `app_colors.dart`, `app_dimens.dart`, `app_motion.dart`.

No se crean subcarpetas ni archivos nuevos salvo que el modelo `BotBlueprint` requiera un campo de categoría para filtrar — en ese caso es un cambio mínimo en `domain/models/blueprint.dart`, documentado abajo.

---

## 3. Estado actual

- `Scaffold` con `Stack`. Fondo: `Container` con `RadialGradient` manual (centro `surface@0.9` → `background`). Es un fondo plano de dos paradas, sin grid ni glow ambiental.
- `Padding` de `32.0` global.
- `PageTitle` con `title: "BIBLIOTECA DE PLANOS"`, `subtitle`, `accentColor: Color(0xFF00E5FF)` (hex cyan suelto), `style: PageTitleStyle.techBar`.
- `SizedBox(height: 40)` separador.
- `GridView.builder` con `SliverGridDelegateWithMaxCrossAxisExtent`: `maxCrossAxisExtent 350`, `childAspectRatio 0.8`, `crossAxisSpacing 24`, `mainAxisSpacing 24`.
- Cada ítem es un `BlueprintCard` que abre `CreateBotModal(template: bp)` en `onTap`.
- **No hay** toolbar de búsqueda/filtro, **no hay** estado de carga (el catálogo es síncrono desde `BotBlueprint.catalog`), **no hay** estado vacío. No hay escalonado de entrada.

---

## 4. Visión del rediseño

La pantalla se lee como un **plano técnico desplegado sobre una mesa de luz**. Tres capas de profundidad:

1. **Fondo ambiental** (`AppBackground`): vacío `voidBlack`/`background`, glow radial tenue cyan en la zona superior-izquierda (esta sección «emite» cyan, no oro), grid técnico sutilísimo. Nada de gradiente plano manual.
2. **Encabezado + toolbar**: el `PageTitle` techBar con barra de acento `cyan`, seguido de una fila toolbar con buscador y chips de categoría de plano. La toolbar es sticky conceptualmente (queda fija arriba; solo scrollea la grilla).
3. **Grilla de planos**: las `BlueprintCard` entran escalonadas, como si los planos se «desplegaran» uno a uno sobre la mesa.

El factor WOW: la entrada escalonada + el grid ambiental + el acento cyan coherente hacen que la pantalla se sienta como una consola de selección de prototipos, no como una grilla web genérica.

---

## 5. Especificación visual

### 5.1 Estructura de capas

```
Scaffold (backgroundColor: transparent)
└─ AppBackground(accent: AppColors.cyan, glowAlignment: Alignment.topLeft)
   └─ Padding(EdgeInsets.symmetric(horizontal: space32, vertical: space32))
      └─ Column(crossAxisAlignment: start)
         ├─ PageTitle(... style: techBar)
         ├─ SizedBox(height: space24)
         ├─ _LibraryToolbar()              // fila buscador + chips
         ├─ SizedBox(height: space24)
         └─ Expanded(child: _LibraryGrid()) // grilla o estados
```

### 5.2 Fondo

- Reemplazar el `Stack` + `Container`/`RadialGradient` manual por el widget `AppBackground` del prompt 08.
- `AppBackground` recibe el acento de la sección: **`AppColors.cyan`**. El glow radial ambiental se posiciona arriba-izquierda (`Alignment(-0.6, -0.8)` aprox., parametrizado por el prompt 08).
- El grid técnico del fondo es el `HudGridTexture` con `opacity 0.04` — ya viene dentro de `AppBackground`.

### 5.3 Padding de pantalla

- Horizontal y vertical: `space32` (token, = 32 px). Coincide con la regla de §6.1 del archivo 00 («padding de pantalla desktop: space32 horizontal»).

### 5.4 PageTitle

- `title: "BIBLIOTECA DE PLANOS"`.
- `subtitle: "Seleccione un prototipo para iniciar el ensamblaje"`.
- `accentColor: AppColors.cyan` — **eliminar el `Color(0xFF00E5FF)` hex suelto** y usar el token.
- `style: PageTitleStyle.techBar` (barra lateral vertical de acento, definida en el prompt 21).
- Tipografía del título según prompt 21 (`displayL`/`displayM` Oxanium). No redefinir tamaños acá.

### 5.5 Toolbar de planos (`_LibraryToolbar`)

Fila (`Row`, `crossAxisAlignment: center`) con dos zonas:

- **Izquierda — chips de categoría de plano.** Chips segmentados del prompt 11. El primero es `TODOS` (activo por defecto). El resto se derivan de las categorías presentes en `BotBlueprint.catalog` (`bp.category`). Cada chip: `radiusPill`, `label` Oxanium, `space8` de gap entre chips. Activo → relleno `cyan@0.12` + borde `borderGold` reemplazado por borde cyan tenue + texto `cyan`. Inactivo → transparente, borde `borderDefault`, texto `textSecondary`.
- **Derecha — buscador.** `AppTextField` variante search (prompt 10), `width: 280`, alto según token de input, `radiusM`, ícono de lupa a la izquierda, placeholder `"Buscar plano..."`. Usa `Spacer()` entre las dos zonas.

El filtrado es **local en cliente**: el texto filtra por `bp.name`/`bp.description`; el chip filtra por `bp.category`. Si `BotBlueprint` no tiene `category` tipada como enum, mantener el filtrado por string sin agregar dependencias.

### 5.6 Grilla (`_LibraryGrid`)

- `GridView.builder` con `SliverGridDelegateWithMaxCrossAxisExtent`:
  - `maxCrossAxisExtent: 350`
  - `childAspectRatio: 0.78` (ligeramente más alto que el actual 0.8 para acomodar la lista de specs del `BlueprintCard` rediseñado — ver prompt 42).
  - `crossAxisSpacing: space20`, `mainAxisSpacing: space20` (token, = 20 px; el archivo 00 §6.1 fija «gap entre cards en grilla: space20»).
- `padding: EdgeInsets.only(bottom: space32)` para que la última fila no quede pegada al borde inferior.
- Cada ítem es un `BlueprintCard` (prompt 42) con su `staggerIndex` propagado (ver §7).
- `onTap` mantiene la apertura de `CreateBotModal(template: bp)` vía `showDialog` — no cambiar esa lógica de negocio.

### 5.7 Tipografía y color

- Toda tipografía sale de los tokens de §5 del archivo 00 (`displayL`, `titleM`, `label`, `bodyS`, `mono`). Cero `TextStyle` con tamaños hardcodeados.
- Acento de toda la pantalla: `cyan` / `cyanGlow`. El oro **no** aparece en esta vista salvo dentro de un `BlueprintCard` que tenga `techColor` dorado.

---

## 6. Estados e interacciones

Matriz §9 del archivo 00 aplicada a la vista:

| Estado | Comportamiento |
|---|---|
| `default` | Toolbar + grilla con N planos. |
| `loading` | El catálogo hoy es síncrono, pero el rediseño deja preparado el estado: si en el futuro la carga es async, mostrar una grilla de **6–9 skeletons** `SkeletonBase` (prompt 14) con la misma geometría del `BlueprintCard` (radio `radiusL`, aspect ratio 0.78), con shimmer. Mientras siga síncrono, este estado no se renderiza pero el código lo contempla con un branch. |
| `empty` (sin resultados de filtro) | Cuando el filtro de búsqueda/chip no devuelve planos: `EmptyState` (prompt 15) centrado en el `Expanded`, con ícono de lupa, título `"SIN COINCIDENCIAS"`, mensaje `"Ningún plano coincide con el filtro actual"` y acción secundaria `"Limpiar filtro"` que resetea search + chip. |
| `empty` (catálogo vacío) | Si `BotBlueprint.catalog` viniera vacío: `EmptyState` con ícono de plano, título `"ARCHIVO DE PLANOS VACÍO"`, mensaje informativo. Sin acción. |
| `hover` / `pressed` / `focused` | Pertenecen al `BlueprintCard` y a los chips/buscador; ver prompts 42, 11, 10. La vista no agrega estados propios. |

Interacciones:

- Escribir en el buscador filtra en vivo (debounce `durFast` opcional, no obligatorio).
- Click en chip cambia la categoría activa; solo un chip activo a la vez.
- Tab recorre: chips → buscador → primer card → … en orden visual.

---

## 7. Animaciones

Todas las curvas/duraciones por token de §7 del archivo 00.

- **Entrada de la vista:** el `PageTitle` y la toolbar entran con fade + translateY 12 px, `easeEntrance`, `durBase`.
- **Entrada escalonada de la grilla:** cada `BlueprintCard` entra 36 ms después del anterior (fade + translateY 12 px), `easeEntrance`, `durBase` por ítem. Máximo ~10 ítems escalonados; del 11° en adelante entran sin delay adicional. El `staggerIndex` se pasa como parámetro al `BlueprintCard` (el prompt 42 lo implementa internamente con `flutter_animate`).
- **Re-filtrado:** al cambiar chip/búsqueda, la grilla hace un crossfade corto (`durFast`, `easeStandard`) entre el set anterior y el nuevo. No re-escalonar en cada tecla (sería ruidoso): el escalonado completo solo en la entrada inicial.
- **Reduced motion:** si `AppMotion.reduced` está activo → sin escalonado (todos los cards aparecen juntos), sin translateY; las transiciones se reducen a un crossfade de 120 ms. Respetar §7.3 del archivo 00.

---

## 8. Accesibilidad

- Contraste: título `displayL` (`textPrimary` sobre fondo oscuro) ≥ 12:1; subtítulo `textSecondary` ≥ 4.5:1; texto de chips ≥ 4.5:1.
- El buscador tiene `Semantics` label `"Buscar plano"`; los chips anuncian su estado seleccionado (`selected: true/false`).
- Foco visible en chips y buscador (anillo `cyan` de 2 px, prompts 10/11). Orden de foco = orden visual.
- El `EmptyState` no comunica el estado solo por ícono: lleva ícono + título + texto.
- Targets de chips ≥ 32×32 px de área de hit.
- `EmptyState` de error de filtro: el mensaje es claro y la acción «Limpiar filtro» es alcanzable por teclado.

---

## 9. Checklist de aceptación

- [ ] El `Stack` + `RadialGradient` manual fue reemplazado por `AppBackground` con acento `AppColors.cyan`.
- [ ] No queda ningún hex suelto en el archivo (en particular, `Color(0xFF00E5FF)` fue reemplazado por `AppColors.cyan`).
- [ ] Padding de pantalla = `space32` horizontal y vertical (tokens).
- [ ] `PageTitle` usa `style: PageTitleStyle.techBar` y `accentColor: AppColors.cyan`.
- [ ] Existe la toolbar con buscador (`AppTextField` search) y chips de categoría segmentados (prompt 11).
- [ ] El filtrado por texto y por chip funciona en cliente y es combinable.
- [ ] La grilla usa `maxCrossAxisExtent 350`, `childAspectRatio 0.78`, spacing `space20`.
- [ ] Las `BlueprintCard` entran escalonadas (36 ms, `easeEntrance`, `durBase`), máximo ~10.
- [ ] Estado `empty` por filtro sin resultados muestra `EmptyState` con acción «Limpiar filtro».
- [ ] Estado `empty` por catálogo vacío muestra `EmptyState` sin acción.
- [ ] El branch de `loading` con skeletons está contemplado en el código (aunque hoy no se dispare).
- [ ] `reduced-motion` desactiva escalonado y translateY.
- [ ] `onTap` de cada card sigue abriendo `CreateBotModal(template: bp)`.
- [ ] `flutter analyze` no agrega warnings nuevos. La pantalla se ve correcta en 1280×720 y en 1024×600.

---

## 10. Dependencias

- **Fundaciones:** 01 (color), 02 (tipografía), 03 (dimensiones), 04 (motion), 06 (HUD: `HudGridTexture`), 08 (`AppBackground`).
- **Componentes núcleo:** 10 (`AppTextField` search), 11 (chips segmentados), 14 (`SkeletonBase`), 15 (`EmptyState`).
- **Shell:** 21 (`PageTitle`).
- **Mismo grupo:** 42 (`BlueprintCard`) — la grilla lo consume. Ejecutar 42 antes o en paralelo.
