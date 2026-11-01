# Preparación de recetas

Campo opcional de texto de hasta 20,000 caracteres en Editar receta y lectura en la ficha desplegable. Primero se crea la receta con el flujo actual; luego se añade su preparación desde Editar. Conserva saltos de línea y texto literal, sin interpretar HTML. Se pueden escribir tiempos y temperaturas propios como texto; no hay cálculos, temporizadores, fotos, versiones ni campos técnicos nuevos en esta entrega.

Se guarda preparation dentro de los metadatos existentes de instructions. Lee también instrucciones antiguas de texto y legacyInstructions. Una preparación vacía explícita permanece vacía: no vuelve a mostrar el texto antiguo automáticamente. El original se conserva en legacyInstructions al transformar texto antiguo. Se preservan campos desconocidos.

La nueva función actualizar_receta_preparacion_bum_bum llama a la función de edición vigente dentro de la misma transacción, reutilizando sus bloqueos, comprobación de concurrencia, validación de referencias y RLS. Después añade preparation y devuelve la receta canónica. SECURITY INVOKER, solo authenticated, sin tablas ni cambios de RLS. El RPC anterior se mantiene compatible y conserva preparation al guardar desde clientes anteriores.

Validación: 56 pruebas y compilación (96 módulos). SQL ejecutado con cuentas sintéticas dentro de una transacción deshecha: texto/saltos, campo vacío, límite, conflicto, acceso ajeno, preservación de IDs/líneas, stock/precio, cotización y texto antiguo. Se verificó ausencia de la nueva función y cuentas al finalizar. Navegador con App real y servicio simulado: escribir, guardar y consultar los pasos conservando costo de RD$50; revisión de escritorio y 390 px. Sin cambios a recetas reales.

Publicación pendiente de aprobación: aplicar primero la nueva función compatible y luego publicar la interfaz. No se aplicó la migración persistentemente ni se publicó el frontend. Fotografías, tiempos estructurados, versiones y subrecetas quedan pendientes.
