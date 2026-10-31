# Herramientas: primera entrega y fuentes

Consulta de fuentes: 31 de octubre de 2026. Esta entrega no modifica tablas, credenciales, RLS, existencias ni fórmulas de costos.

## Qué está implementado

- Nueva opción Herramientas dentro de la aplicación autenticada, conservando Personas con acceso y Solicitudes.
- Conversión de masa, volumen y temperatura; intercambio de unidades, copia, 0–12 decimales y atajos de horno.
- Núcleo puro en `src/domain/measurements/conversions.mjs`: factores decimales completos representados como fracciones `BigInt`; no se redondea durante los cálculos. El formato redondea al valor más próximo, con empates alejándose de cero. Se admite punto o coma decimal, sin separadores de miles; entrada de hasta 12 decimales y magnitud máxima 10¹². No se aceptan temperaturas por debajo del cero absoluto.
- Referencias iniciales para 14 ingredientes, con fuente, medida original, condiciones y fecha de consulta. Se distinguen conversiones matemáticas, densidad de referencia y equivalencias culinarias aproximadas.
- Densidades calibradas del negocio: nombre, masa en gramos, volumen en mL, fuente/método, condiciones y fecha.
- Favoritos y preferencias por usuario; almacenamiento nuevo `bum-bum-tools:v1:<uuid>`, sin reemplazar colecciones anteriores. Cada cuenta ve sus propias preferencias en este dispositivo. Hasta 30 favoritos, calibraciones y estándares. No se sincronizan entre dispositivos ni forman parte del respaldo comercial actual.
- Consulta de cantidades de una receta. Transferencia explícita del resultado compatible al formulario de una receta **nueva**, usando el UUID del ingrediente. La transferencia no depende de los decimales visibles y no guarda en Supabase hasta completar y guardar el formulario existente. Las referencias sin mL no pueden enviar un volumen inventado a una receta.
- Sección independiente de libras comerciales: estándares propios de molde, diámetro/lados, altura, capas, mezcla, rendimiento, porciones y equivalencia de negocio. Estimación proporcional desde el estándar guardado; no hay equivalencia comercial universal ni adaptación geométrica automática.
- Herramientas se mantiene fuera del formulario global bloqueado durante cargas fallidas de datos comerciales. La calculadora pura sigue disponible; consultar recetas requiere que esos datos se hayan cargado.

## Factores y convenciones

Masa internacional avoirdupois: **1 lb = 453.59237 g**, **1 oz = 28.349523125 g**, **1 lb = 16 oz**. Los prefijos SI dan kg = 1000 g y mg = 0.001 g. Fuente: [NIST Handbook 44 (2026), Appendix C](https://www.nist.gov/document/2026-nist-handbook-44-appendix-c), tablas métricas y avoirdupois.

Volumen estadounidense customary: galón = 3785.411784 mL; onza líquida = 29.5735295625 mL; taza de ocho onzas líquidas = 236.5882365 mL. Cucharada = media onza líquida y cucharadita = un tercio de cucharada. Se conservan los decimales completos de esas relaciones; no se usa el valor redondeado de 30 mL. Fuente: [NIST Appendix C](https://www.nist.gov/document/2026-nist-handbook-44-appendix-c), tablas de volumen líquido; relaciones culinarias declaradas en el selector.

Volumen imperial británico: galón = 4546.09 mL, pinta = galón/8 y onza líquida = galón/160 = 28.4130625 mL. Fuentes: [UK Units of Measurement Regulations 1994](https://www.legislation.gov.uk/uksi/1994/2867/made) y notas británicas del [NIST Appendix C](https://www.nist.gov/document/2026-nist-handbook-44-appendix-c). No se ofrece una «taza imperial» genérica ni se confunden onzas líquidas con onzas de masa.

Medidas culinarias seleccionables, definidas por su capacidad nominal: cucharada de 15 mL, cucharadita de 5 mL, taza métrica de 250 mL y taza de etiquetado FDA de 240 mL. Son convenciones explícitas; no garantizan la capacidad de un utensilio real. Referencias: [NIST Metric Kitchen](https://www.nist.gov/pml/owm/metric-si/metric-kitchen/metric-kitchen-cooking-measurement-equivalencies), [FDA, equivalencias domésticas](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/guidance-industry-guidelines-determining-metric-equivalents-household-measures) y [Healthdirect Australia, taza culinaria de 250 mL](https://www.healthdirect.gov.au/healthy-living/food-and-nutrition/drinking-water-and-your-health). No se intercambian silenciosamente las tres tazas.

Temperatura: `F = C × 9/5 + 32`, `C = (F − 32) × 5/9`, `K = C + 273.15`. Fuentes: [NIST Guide to SI, Appendix B.9](https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9). Los atajos 160, 170, 180 y 200 °C dan 320, 338, 356 y 392 °F. No convierten instrucciones de horno convencional en instrucciones de horno con ventilación.

## Referencias por ingrediente

Las siguientes son **equivalencias culinarias aproximadas** de [King Arthur Baking, Ingredient Weight Chart](https://www.kingarthurbaking.com/learn/ingredient-weight-chart). Se conserva su medida publicada; una taza de esa tabla **no se convierte automáticamente a mL**. Son referencias para cocinar, no densidades físicas certificadas.

| Ingrediente | Medida original | Masa publicada |
| --- | --- | --- |
| Harina de uso general | 1 taza | 120 g |
| Harina de pan | 1 taza | 120 g |
| Azúcar granulada | 1 taza | 198 g |
| Azúcar morena compactada | 1 taza | 213 g |
| Azúcar glas sin tamizar | 1 taza | 113 g |
| Mantequilla | 8 cucharadas / ½ taza | 113 g |
| Aceite vegetal | 1 taza | 198 g |
| Leche fresca | 1 taza | 227 g |
| Miel | 1 cucharada | 21 g |
| Cocoa sin azúcar | ½ taza | 42 g |
| Crema de leche | 1 taza | 227 g |
| Chocolate picado | 1 taza | 170 g |
| Maicena | ¼ taza | 28 g |

Marca, compactación, utensilio y forma de llenado pueden cambiar el resultado. La tabla no publica una temperatura para esas equivalencias. El chocolate picado no representa chocolate fundido; la crema requiere identificar el producto. Para ingredientes distintos o conversiones de esos productos a mL se solicita una calibración; no se deduce densidad a partir de una ficha nutricional.

El ingrediente número 14 es **agua pura libre de aire a 20 °C**, con densidad de referencia **0.99820675 g/mL**, de [NIST GLP 10, abril de 2013, página 5](https://www.nist.gov/system/files/documents/2017/05/09/GLP_10_20130424.pdf). Es un valor de referencia con condiciones, no una identidad matemática ni una promesa para toda agua potable/mineral. Su fecha bibliográfica es 2013; la consulta de la referencia es de 2026.

## Verificación y límites de esta entrega

`npm test` ejecuta 10 grupos de pruebas con Node: masa, sistemas de volumen, ida y vuelta racional de todos los pares de masa/volumen, temperaturas y cero absoluto, entradas inválidas y redondeo, referencias culinarias, agua/calibración, transferencia al recetario, preferencias entre cuentas y estándares comerciales. También se ejecutó `npm run build` con éxito; no se actualizaron dependencias. El entorno local usa npm desde su paquete oficial porque no estaba en PATH.

Comprobación visual local con datos de ejemplo: pantalla de 390 × 844, media taza de harina → 60 g con aviso aproximado; precisión visible, guardar favorito y copiar; atajo 180 °C → 356 °F; intercambio; recarga conserva la configuración y la calibración; consulta de una receta y preparación de 250 g mediante el callback de transferencia. No se escribió ni sustituyó una receta real. No se ejecutaron de nuevo las pruebas SQL de producción, ya que esta entrega no modifica su esquema ni sus políticas.

La auditoría y el plan por fases están en [AUDITORIA_Y_PLAN.md](./AUDITORIA_Y_PLAN.md). Quedan para etapas posteriores: sincronización privada de preferencias, historial/edición avanzada de recetas, proveedores normalizados, compras/inventario transaccional, lotes, producción, pedidos, finanzas, calidad y el resto de calculadoras técnicas. El módulo no adapta moldes automáticamente ni implementa todavía porcentajes panaderos, concentraciones o sustituciones.

