# 62 — QA · Consistencia Cross-Screen

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.
> **Este es un prompt de AUDITORÍA**, no de rediseño. No introduce diseño nuevo: verifica que todo lo construido en los prompts 01–61 sea coherente y corrige las desviaciones.

---

## 1. Objetivo

Auditar la **coherencia milimétrica** (principio §3.1.6 del archivo 00) de toda la aplicación tras ejecutar los 61 prompts anteriores. La inconsistencia mata el factor premium más rápido que cualquier otra cosa: este control es el penúltimo filtro antes del pase final de pulido. El resultado debe ser una app donde cada pantalla parece dibujada por la misma mano.

---

## 2. Alcance de la auditoría

Se auditan **todas** las pantallas, modales y overlays de la app:

- **Shell:** custom title bar, sidebar, `MainLayout`, transiciones de ruta, page titles.
- **Login:** panel izquierdo (branding/Rive) + panel derecho (formulario).
- **Dashboard:** layout/fondo, panel HUD de crédito, botón de acción inteligente, toolbar, bot card, estados vacío/carga.
- **Bot detail:** layout + tabs, RiveBotDisplay + HUD de estado, y las 5 tabs (Dashboard, Config, Knowledge, Mood, Embed), acciones flotantes y overlays épicos.
- **Chat:** panel terminal, burbujas de mensaje, status indicator.
- **Biblioteca:** bots library view, blueprint card.
- **Tienda:** store view, product card.
- **Ajustes:** settings view, change password dialog.
- **Billing:** shell + tab bar y sus 4 tabs; digital card; plan picker; subscription summary; y **todos los modales**: add card, formularios de pasarela, manage cards, payment checkout, quota paywall, proration preview, cancel flow, reactivate flow; auto-pay settings card; invoice list; trial + dunning banners.
- **Conectividad:** connectivity HUD.

---

## 3. Procedimiento paso a paso

Recorrer la app pantalla por pantalla en el orden de §2. En **cada** pantalla, abrir todos sus estados (default, hover, pressed, focused, loading, disabled, error, empty, modales abiertos) y verificar:

### Paso 1 — Tokens de color
- Cero hex literales en el código (`Color(0xFF…)`, `Colors.white.withOpacity`, etc.). Todo color sale de `AppColors`/tokens del prompt 01.
- El oro (`gold`) solo aparece en: acción primaria, valor/dinero, estado destacado, branding. Nunca como texto de párrafo ni borde de caja secundaria.
- Los colores semánticos (`success`/`warning`/`danger`/`info`) se usan con el mismo significado en toda la app.
- Buscar restos del `danger` viejo (`#FF003C`) o derivados (`0xCC/0x99/0x66 FF003C`).

### Paso 2 — Radios
- Inputs/botones usan `radiusM`; cards/paneles `radiusL`; modales `radiusXL`; badges/chips `radiusPill`. Verificar que no haya radios sueltos (8, 10, 16 hardcodeados) salvo que correspondan a un token.

### Paso 3 — Grosores de borde
- Hairline = `borderSubtle`/`borderDefault` (mismo grosor visual); hover/foco = `borderStrong`/`borderGold`. Verificar que no convivan bordes de 1, 1.5 y 2 px arbitrarios para el mismo rol.

### Paso 4 — Set de iconos
- Toda la app usa el set unificado del prompt 05, mismo grosor de trazo. Cero emojis. Cero PNG donde puede haber vector. Verificar que el mismo concepto use el mismo ícono en todas las pantallas (ej. «descargar», «editar», «cerrar»).

### Paso 5 — Escala tipográfica
- Cada texto usa un token de la escala §5 (`displayXL`…`numericTicker`). Cero `TextStyle` ad-hoc con tamaños sueltos. Cero `fontFamily: 'Courier'` (debe ser el token mono / JetBrains Mono). Números tabulares en toda cifra que se alinea o anima.

### Paso 6 — Espaciados (ritmo 4 px)
- Todo padding, margen y gap es un token de la escala 4 px (`space2`…`space64`). Cero magic numbers (13, 18, 28 sueltos). Verificar ritmo coherente: padding de card `space20`/`space24`, gap de grilla `space20`, padding de pantalla `space32` horizontal.

### Paso 7 — Curvas y duraciones de animación
- Toda animación usa tokens de `app_motion.dart` (curvas y duraciones de §7). Mismas curvas para el mismo rol (entradas `easeEntrance`, salidas `easeExit`, press `durInstant`). Sin `Duration`/`Curve` hardcodeados.

### Paso 8 — Lenguaje HUD coherente
- Brackets, scanlines, dividers, reactor bars y tickers se usan con **criterio jerárquico**: brackets solo en paneles principales/modales/encabezados; scanlines sutilísimas y opcionales; dividers para separar bloques de sección. Verificar que el ornamento subraye la jerarquía y no esté repartido por igual en cada caja (lo que lo diluiría).

### Paso 9 — Elevación y glow
- Sombras solo de la escala (`elev0`…`elev3`). Un elemento = una sombra + opcionalmente un glow; nunca dos glows. El glow aparece solo donde hay energía/foco/estado.

### Paso 10 — Estados y navegación
- Todos los componentes interactivos implementan la matriz §9 de forma consistente (mismo tratamiento de hover/pressed/focused/disabled).
- La estructura de shell (sidebar + title bar) se mantiene idéntica entre pantallas; las transiciones de ruta son las mismas.

Para cada hallazgo: anotar pantalla/archivo/línea, qué token o patrón se violó, y aplicar la corrección reemplazando el valor suelto por el token correcto.

---

## 4. Criterios de aprobación

La auditoría se aprueba cuando:

- Cero hex literales y cero magic numbers de espaciado/radio en todo el código de UI.
- Cada pantalla usa exclusivamente tokens de color, tipografía, dimensión y motion del archivo 00.
- El set de iconos es único y consistente; cero emojis, cero PNG evitables.
- El oro está reservado según §3.1.2; los colores semánticos son consistentes.
- El ornamento HUD respeta jerarquía (no saturado, no ausente donde corresponde).
- La matriz de estados §9 está aplicada de forma uniforme.
- El shell y las transiciones son idénticos entre pantallas.

---

## 5. Checklist

- [ ] Las ~25+ pantallas/modales de §2 fueron recorridas, cada una en todos sus estados.
- [ ] Paso 1 — colores por token; cero hex; oro reservado; sin restos de `#FF003C`.
- [ ] Paso 2 — radios por token.
- [ ] Paso 3 — grosores de borde consistentes.
- [ ] Paso 4 — set de iconos único; cero emojis; mismo ícono por concepto.
- [ ] Paso 5 — escala tipográfica por token; cero `'Courier'`; números tabulares.
- [ ] Paso 6 — espaciados en ritmo 4 px; cero magic numbers.
- [ ] Paso 7 — curvas/duraciones por token de `app_motion.dart`.
- [ ] Paso 8 — lenguaje HUD usado con jerarquía coherente.
- [ ] Paso 9 — elevación de la escala; un glow máximo por elemento.
- [ ] Paso 10 — estados y shell consistentes.
- [ ] `flutter analyze` sin warnings nuevos tras las correcciones.

---

## 6. Entregable

Un informe con dos secciones:

1. **Inconsistencias encontradas** — tabla con columnas: Pantalla/Componente · Archivo:línea · Tipo (color/radio/borde/icono/tipografía/espaciado/motion/HUD/estado) · Descripción · Valor suelto encontrado.
2. **Correcciones aplicadas** — por cada inconsistencia: el reemplazo realizado (valor suelto → token), con confirmación de que `flutter analyze` sigue limpio y la pantalla compila en 1280×720 y 1024×600.

Si quedan inconsistencias sin resolver, listarlas explícitamente como deuda con su justificación; la auditoría no se considera aprobada hasta que el listado de deuda esté vacío o justificado por escrito.

---

## 7. Dependencias

- **Todos los prompts 01–61** deben estar ejecutados: esta auditoría verifica su coherencia conjunta.
- Apoyo de referencia: 01–08 (definición de todos los tokens), 09–17 (componentes núcleo), 18–21 (shell).
