# Costos incompletos: primera mejora de consolidación

Base: main 3cadf3c0e71d9dcc9b60ee70fb36d56b23231994.

Antes, el cálculo omitía ingredientes ausentes y unidades incompatibles como si no costaran nada. Ahora el evaluador puro devuelve total nulo y motivos específicos si falta catálogo, precio, cantidad o una unidad compatible. Una receta sin ingredientes también está incompleta. Un precio cero explícito sigue siendo válido. El adaptador conserva el costo nulo de Supabase en vez de convertirlo a cero.

Recetas muestra «Costo incompleto» y los datos que hay que revisar. Cotizador oculta total, sugerencia y ganancia ante receta incompleta; el botón y su manejador bloquean el guardado. También se valida la cantidad y se rechazan importes no finitos. Se conservan los factores de unidades, margen/recargo, escalado fijo, recetarios de Encargos y cotizaciones históricas. No se modifica ninguna fila ni política de Supabase.

Validación: npm test (19 grupos), npm run build y regresiones existentes de recetarios, cuentas y personas con sustitutos de Supabase. No se han creado cotizaciones reales ni probado este cambio con la cuenta productiva. Las pruebas nuevas cubren compatibilidad, datos ausentes/incorrectos, gratuidad explícita, desbordamientos y evaluación sin mutación.

Esto completa solo la primera corrección de la fase 2. Siguen pendientes: esquema reproducible, CI, respaldo/restauración, consolidación de otros costos y ampliación del recetario. La renovación visual integral permanece al final.
