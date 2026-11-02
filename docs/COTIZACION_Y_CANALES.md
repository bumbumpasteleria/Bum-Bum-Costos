# Recetas con materiales, cotización y precios para apps

Los materiales se conservan en el mismo catálogo privado y se vinculan como líneas de la receta, con su identificador, proveedor y cantidad en unidad base. Se suman en edición, consulta, calculadora, combinaciones y producción. Una fracción de receta ajusta también sus materiales: revisa si el empaque final realmente puede fraccionarse. Cambiar una receta no recalcula lotes ni cotizaciones anteriores.

El cotizador sigue reservado a Encargos. Detalla ingredientes, materiales incluidos en receta, materiales adicionales, decoraciones, mano de obra fija o por horas, rellenos/coberturas adicionales, empaque adicional, entrega y otros gastos. La ganancia se calcula mediante margen sobre venta o recargo sobre costo. Los campos de materiales adicionales son cantidades extra, no la cantidad total del encargo. No repitas un empaque incluido en una receta en otra sección de costos.

Cliente, contacto, entrega, validez, condiciones y desglose quedan guardados con la cotización. El PDF para cliente contiene producto, cantidad y precio final; no revela costos internos ni ganancia. El PDF interno muestra el desglose completo. Las cotizaciones anteriores conservan sus importes sin inventar un desglose histórico.

Mi nevera permite configurar Directa, Uber Eats y PedidosYa por separado. Indica costo base por unidad, empaques, mano de obra y otros gastos adicionales por unidad, comisión del canal y margen deseado sobre venta. El costo propuesto es el promedio de lotes disponibles y puede corregirse como estimación. No se inventa una tasa de comisión y no se impone un precio sugerido: el usuario lo elige.

Precio sugerido = costo total por unidad / (1 - comisión/100 - margen/100), redondeado hacia arriba al centavo. La suma de comisión y margen debe ser menor a 100%. La estimación supone comisión sobre venta bruta. Si la plataforma cobra otros conceptos, regístralos entre los gastos adicionales. Ventas usa el canal para proponer precio y porcentaje, y multiplica los gastos adicionales por la cantidad. Permite ajustarlos para la venta y mantiene los importes históricos. El cálculo real de lotes al vender puede diferir del costo promedio utilizado al proponer el precio.

## Activación

Revisar y autorizar `20261102_materiales_y_canales.sql` antes de publicar. Amplía las validaciones de tipo de artículo en las funciones existentes, conservando sus comprobaciones de propietario y concurrencia; añade channel_prices a los productos y una función validada de actualización por cuenta aprobada. No cambia RLS, roles ni los registros existentes. El respaldo exporta automáticamente el nuevo campo. La prueba `supabase/tests/materiales_y_canales.sql` sustituye COMMIT por pruebas y ROLLBACK: guardar y editar receta con materiales, costo de lotes y ventas, precios de canales, conflictos, recuperación y aislamiento entre cuentas.

## Identidad del negocio

En Logo y presentación de mi negocio se guarda nombre, contacto, ubicación, web, color y logo de cada cuenta. El logo se reduce localmente a JPEG sobre fondo blanco, sin deformarlo; se admite JPG, PNG o WebP de hasta 10 MB y el resultado guardado no supera 250 KB. Los PDF utilizan esta presentación con un encabezado de color y logo proporcionado por el usuario. No se reemplaza por el icono de la aplicación. Los importes históricos permanecen intactos aunque se cambie la presentación.

La presentación se guarda como quote_brand en los registros privados y versionados existentes, con ID igual al propietario. La migración amplía su tipo permitido y delega los registros anteriores en el validador privado previo; no altera sus reglas. Los respaldos ya incluyen los registros de negocio y por tanto conservan esta presentación.
