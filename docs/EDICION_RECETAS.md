# Edición de recetas guardadas

Primera entrega de la mejora del recetario: editar en la misma pantalla nombre, recetario, rendimiento, unidad, tipo de producto, escalado e ingredientes. Guardar actualiza la receta existente; cancelar descarta el borrador.

Se conserva el identificador de la receta y de cada línea retenida. Las líneas nuevas reciben identificadores de la base. Solo se retiran las líneas omitidas de esa receta. El guardado no modifica precios, existencias ni cotizaciones históricas. Los datos adicionales del campo instructions se conservan; el texto antiguo se mantiene íntegro en legacyInstructions cuando se transforma a metadatos.

La función actualizar_receta_recetario_bum_bum trabaja en una sola transacción con SECURITY INVOKER y las políticas actuales. Solo authenticated puede ejecutarla; valida titular, recetario, ingredientes y líneas. Compara la versión abierta con la versión actual y rechaza cambios concurrentes, conservando el borrador en pantalla. Reabrir permite revisar la versión reciente.

## Estado actual

La edición está publicada y conserva IDs, verifica versiones y respeta la cuenta propietaria. Las pruebas originales se realizaron con datos ficticios y se revirtieron. Las fotos y el historial de versiones también están disponibles. La entrega integral añade composición vinculada y ficha profesional; al editar se modifican únicamente los ingredientes propios, sin copiar los heredados de subrecetas.

Acceso actualizado: Recetas → Abrir recetario → Ver recetas del recetario → Abrir receta. La edición, asignación y eliminación se realizan dentro de esa ficha. Consulta RECETARIOS_Y_EQUIVALENCIAS.md para unidades preferidas y consumo al producir.


## Actualización integral en revisión

Consulta OPERACION_INTEGRAL.md para compras por lotes, costos históricos, cobros, órdenes de trabajo y composición vinculada. Las recetas combinadas por copia se conservan; el vínculo dinámico se crea explícitamente. Los datos actuales siguen siendo privados y las operaciones de inventario no se repiten por reintentos.
