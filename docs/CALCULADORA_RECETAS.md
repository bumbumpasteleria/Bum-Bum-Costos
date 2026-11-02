# Calculadora de recetas y categorías

En Herramientas, selecciona hasta tres recetas, de cualquier recetario de tu cuenta. Por cada una, revisa el rendimiento de la receta completa. Puedes multiplicar o reducir con ×2, ×3, ½, ¼ o una fracción como 1/4. También puedes indicar la cantidad final deseada. Se ajustan todos los ingredientes con el mismo factor, sin modificar la receta guardada.

Ejemplo: si una receta completa rinde 2 lb y quieres media libra, el factor es 0,25. Si quieres la mitad de la receta completa, el factor es 0,5 y el resultado rinde 1 lb. Las unidades físicas de masa se convierten entre sí. Una libra comercial solo se escala con el rendimiento que declara el negocio; no se convierte a gramos. Porciones, cajas y bandejas no se convierten automáticamente a peso.

La suma agrupa por ID de ingrediente, conserva proveedores separados y muestra cantidades en unidades base. Los costos usan los precios actuales; si falta uno no se muestra un total aparentemente completo. Los precios no incluyen empaques, mano de obra, entregas ni otros gastos del Cotizador.

Puedes guardar cada porción como receta independiente o combinar ½ receta de masa con ¼ de relleno y una cobertura. Para la combinación indica un nombre, rendimiento propio (por ejemplo 6 bandejas), unidad, categoría y recetario. Para Apps de envío elige el recetario de ese uso. Los IDs de los ingredientes se conservan, de modo que sus precios siguen actualizándose. Los ingredientes de las recetas base se expanden a las cantidades resultantes: no se crea un vínculo dinámico con sus fórmulas. Cambiar después las cantidades de una fórmula base no altera la copia. Las instrucciones se copian; revisa cantidades mencionadas dentro del texto, moldes, tiempos y temperatura.

Dentro de cada recetario se organizan las recetas por categoría. Se sugieren Masas, Rellenos, Coberturas, Postres y Decoraciones; puedes escribir otra hasta 80 caracteres. Se asignan al crear o editar una receta, al importar PDF y al guardar desde la calculadora. Las recetas anteriores quedan sin categoría hasta asignarla. No cambia su recetario ni sus ingredientes.

## Publicación

Primero habilitar supabase/migrations/20261101_categorias_recetas.sql. Añade dos funciones SECURITY INVOKER para crear/editar con categoría y preparación en la misma transacción, respetando las validaciones, concurrencia y políticas actuales. No reemplaza las funciones anteriores. Ejecutar supabase/tests/categorias_recetas.sql dentro de la transacción de la migración, en vez del COMMIT, para probar con fixtures y ROLLBACK. Publicar la aplicación solo después de habilitar las funciones.

Para encontrar el guardado conjunto, elige las recetas y pulsa Ir a crear una receta combinada para Apps. El formulario también aparece abierto debajo de Todo lo que necesitas. Puedes usar 1/2 o los botones de fracciones para cada receta.
