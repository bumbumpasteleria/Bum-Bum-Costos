# Edición de recetas guardadas

Primera entrega de la mejora del recetario: editar en la misma pantalla nombre, recetario, rendimiento, unidad, tipo de producto, escalado e ingredientes. Guardar actualiza la receta existente; cancelar descarta el borrador.

Se conserva el identificador de la receta y de cada línea retenida. Las líneas nuevas reciben identificadores de la base. Solo se retiran las líneas omitidas de esa receta. El guardado no modifica precios, existencias ni cotizaciones históricas. Los datos adicionales del campo instructions se conservan; el texto antiguo se mantiene íntegro en legacyInstructions cuando se transforma a metadatos.

La función actualizar_receta_recetario_bum_bum trabaja en una sola transacción con SECURITY INVOKER y las políticas actuales. Solo authenticated puede ejecutarla; valida titular, recetario, ingredientes y líneas. Compara la versión abierta con la versión actual y rechaza cambios concurrentes, conservando el borrador en pantalla. Reabrir permite revisar la versión reciente.

## Validación

- 48 grupos de pruebas de aplicación, conversiones, costos, catálogo y edición.
- Compilación de producción.
- Prueba SQL transaccional con cuentas sintéticas: conservar IDs, añadir/quitar líneas, rechazo de datos ajenos, sesión anónima y valores inválidos, conflicto concurrente, preservación de precios/existencias/cotización/metadata/texto antiguo. Ejecutada con ROLLBACK; se confirmó la ausencia de la función y de las cuentas sintéticas después.
- Navegador con la aplicación real y un servicio simulado sin conexión a cuentas: error conserva borrador, guardar cambia rendimiento e ingredientes y recalcula RD$50 a RD$130; cancelar conserva la receta. Formulario revisado a 390 px y escritorio.

## Publicación pendiente

La migración 20261031_editar_receta.sql todavía NO está aplicada persistentemente. Requiere aprobación antes de aplicarla y publicar la aplicación. Primero aplicar la función compatible con la versión anterior, luego publicar la interfaz y comprobar el flujo con una receta de prueba autorizada. Las pruebas simuladas no sustituyen esa comprobación final en producción.

La preparación con fotos, subrecetas e historial de versiones queda para futuras entregas. El rediseño completo sigue registrado en PENDIENTES_DISENO.md.
