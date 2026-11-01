# Consulta visual y búsqueda de recetas

Ficha desplegable en cada receta con rendimiento, costo total de ingredientes, costo por unidad de rendimiento, cantidades originales y proveedor elegido. Los subtotales usan la misma evaluación de costos que el total; una receta incompleta no presenta costo total o unitario aparentemente válido. El costo por rendimiento no es un precio de venta y no incluye materiales, decoraciones, mano de obra ni otros gastos.

Búsqueda por nombre insensible a mayúsculas y acentos, combinada con los filtros existentes de uso y recetario. Durante una edición se deshabilita para conservar visible el borrador. La consulta no guarda ni cambia datos y solo recibe el catálogo privado ya cargado por la aplicación. Sin nuevas llamadas, tablas ni cambios de permisos.

Validación: 52 pruebas (regresiones de aplicación y cuatro pruebas de ficha/búsqueda), compilación de producción y navegador con datos simulados. Se comprobó búsqueda sin resultados, búsqueda por mayúsculas/espacios, ficha con costo RD$50 y RD$4.17 por unidad, y distribución de escritorio y 390 px. No se probaron cuentas ajenas ni se modificaron datos reales. Publicación pendiente de aprobación.
