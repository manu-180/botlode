# 65 — QA · Pase Final de Pulido «Factor WOW»

> Depende de `00_README_VISION_Y_SISTEMA_DE_DISENO.md`. Leelo completo antes de ejecutar.
> Si este prompt y el archivo 00 se contradicen, **gana el 00**.
> **Este es el último archivo del plan.** Es un prompt de AUDITORÍA y pulido final: no agrega features, eleva lo que ya existe del nivel «correcto» al nivel «premium».

---

## 1. Objetivo

Hacer el barrido final pantalla por pantalla buscando lo que separa una UI «correcta» de una UI **premium con factor WOW**: profundidad real, glow con propósito, jerarquía nítida, micro-interacciones en cada elemento clickeable, alineación óptica milimétrica, densidad con aire, ornamento HUD que subraya sin saturar, transiciones suaves y estados vacío/carga/error pulidos. Tras los QA 62–64 (consistencia, accesibilidad, motion), este pase responde la pregunta final: **¿se siente caro, preciso, vivo y silencioso?**

---

## 2. Alcance de la auditoría

Todas las pantallas, modales y overlays del prompt 62 §2. Cada una se evalúa con la rúbrica WOW de §3 y se itera hasta aprobar.

---

## 3. Procedimiento paso a paso

Recorrer cada pantalla y puntuarla con la **Rúbrica WOW**. Cada criterio se puntúa 0 / 1 / 2:
**0** = ausente o plano · **1** = presente pero mejorable · **2** = premium, sin objeción.

### Rúbrica WOW (8 criterios por pantalla)

1. **Profundidad** — Ningún fondo plano. Todas las capas presentes: vacío base + glow radial ambiental + textura/grid sutil. Las superficies flotan con elevación clara. *(0: fondo de un color · 2: sistema de capas completo y legible.)*
2. **Glow con propósito** — La emisión aparece **solo** donde hay energía, foco o estado (botón primario, unidad activa, dato destacado). Cero glow decorativo gratuito. *(0: glow repartido sin criterio o ausente donde hay energía · 2: cada glow comunica algo.)*
3. **Jerarquía** — Un **único CTA primario** por pantalla; el oro reservado. El ojo encuentra de inmediato qué es lo importante. *(0: varios CTAs compiten / oro disperso · 2: jerarquía inequívoca.)*
4. **Micro-interacciones** — **Cada** elemento clickeable tiene hover y press visibles (borde, elevación, glow, escala 0.97). Nada «muerto» al pasar el mouse. *(0: elementos sin feedback · 2: toda la pantalla responde.)*
5. **Alineación óptica** — Bordes, baselines, centros de íconos y números alineados milimétricamente. Corrección óptica donde haga falta (no solo matemática). *(0: desalineaciones visibles · 2: todo encaja.)*
6. **Densidad con aire** — Densa en datos pero cada bloque respira; ritmo 4 px coherente. Ni apretado ni vacío. *(0: amontonado o disperso · 2: densidad equilibrada.)*
7. **Ornamento HUD** — Brackets, scanlines, dividers y tickers subrayan la jerarquía sin saturar. Presentes en momentos jerárquicos, ausentes donde diluirían. *(0: HUD por todos lados o ausente · 2: ornamento con criterio.)*
8. **Estados y transiciones** — Vacío, carga y error pulidos en todas partes; transiciones de pantalla y de modal suaves. Sin estados «sin terminar». *(0: estados crudos / saltos bruscos · 2: todo estado se siente diseñado.)*

**Puntaje por pantalla:** 16 máximo. **Umbral de aprobación: ≥ 14**, y **ningún criterio en 0**.

### Iteración

- Para cada pantalla que no alcance el umbral: anotar qué criterios cayeron, aplicar los ajustes (siempre con tokens del archivo 00), y **re-puntuar**.
- Repetir hasta que **toda** pantalla pase. El pase final no termina con pantallas por debajo del umbral.

### Foco de pulido recomendado

Mientras se recorre, prestar atención especial a:
- Botones primarios: ¿emiten? ¿el gradiente de oro y el `glowGold` están vivos en hover?
- Fondos: ¿se ve el glow radial ambiental y el grid, o quedó negro plano?
- Listas/grillas: ¿el escalonado de entrada se siente, las cards tienen hover?
- Modales: ¿el scrim, el blur, los brackets y la elevación dan sensación de «flotar»?
- Números y datos: ¿los tickers cuentan, las cifras son tabulares y están alineadas?
- Estados vacío/error: ¿tienen ícono, mensaje útil y acción, o son texto pelado?
- Transiciones de ruta: ¿el fade + slide direccional se siente intencional?

---

## 4. Criterios de aprobación

- Toda pantalla puntúa ≥ 14/16 en la rúbrica WOW, sin ningún criterio en 0.
- Ningún fondo plano en toda la app.
- El glow comunica energía/foco/estado en el 100 % de los casos; cero glow gratuito.
- Una sola acción primaria por pantalla; el oro reservado.
- Toda pantalla compila y se ve correctamente en 1280×720 y 1024×600.
- Los QA 62, 63 y 64 ya aprobados (consistencia, accesibilidad, motion).

---

## 5. Checklist

- [ ] Las ~25+ pantallas/modales fueron puntuadas con la rúbrica WOW.
- [ ] Toda pantalla alcanza ≥ 14/16, ningún criterio en 0.
- [ ] Profundidad — cero fondos planos en toda la app.
- [ ] Glow — cero emisión decorativa; toda emisión con propósito.
- [ ] Jerarquía — un CTA primario por pantalla; oro reservado.
- [ ] Micro-interacciones — hover y press en cada elemento clickeable.
- [ ] Alineación óptica verificada.
- [ ] Densidad con aire — ritmo 4 px coherente.
- [ ] Ornamento HUD con criterio jerárquico.
- [ ] Estados vacío/carga/error pulidos en todas las pantallas.
- [ ] Transiciones de pantalla y modal suaves.
- [ ] Las pantallas que no pasaron fueron iteradas y re-puntuadas hasta aprobar.
- [ ] `flutter analyze` sin warnings nuevos.

---

## 6. Entregable

Un informe de cierre del plan con:

1. **Rúbrica completada** — tabla con una fila por pantalla y los 8 criterios puntuados (0/1/2), el subtotal /16, y el estado (APROBADA / ITERAR).
2. **Ajustes finales aplicados** — por cada pantalla que necesitó iteración: qué criterios cayeron, qué ajustes se hicieron, y el puntaje tras re-evaluar.
3. **Confirmación final** — declaración de que toda pantalla aprobó (≥ 14/16, ningún 0) y de que los QA 62–64 están aprobados.

---

## Recordatorio — Definition of Done global (archivo 00 §14)

El plan completo está terminado cuando, para **cada** prompt 01–65:

- Todos los archivos listados fueron modificados/creados.
- El componente usa **solo tokens** del archivo 00 (cero hex sueltos, cero magic numbers).
- Todos los estados aplicables de §9 están implementados.
- Las animaciones usan tokens de §7 y respetan reduced-motion.
- Cumple las reglas de accesibilidad de §10.
- El checklist de aceptación del prompt está 100 % verde.
- `flutter analyze` no agrega warnings nuevos.
- La app compila y se ve correctamente en 1280×720 y en el mínimo 1024×600.

Y, por encima de todo: **el factor WOW no es opcional.** Si una pantalla se ve «correcta pero plana», no está lista. Profundidad, glow con propósito, movimiento con causa y coherencia milimétrica son requisitos, no extras. Este pase final no se cierra hasta que toda la app se sienta **cara, precisa, viva y silenciosa**.

---

## 7. Dependencias

- **Todos los prompts 01–64** ejecutados y aprobados — este es el cierre del plan.
- Referencia transversal: archivo 00 completo (§3 principios, §3.1 no negociables, §3.2 anti-patrones, §14 Definition of Done).
