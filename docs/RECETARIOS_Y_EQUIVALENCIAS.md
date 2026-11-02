# Recetarios y equivalencias de ingredientes

## Recetas por recetario

Hay tres áreas distintas. Recetarios muestra primero los libros privados; sus recetas solo aparecen al abrir el libro y desplegar Recetas guardadas. Dentro de Abrir receta están consulta, foto/notas, edición, asignación y eliminación. La búsqueda y categorías se aplican al recetario abierto. Inicio muestra recetarios, sin listar recetas fuera de ellos.

Nueva receta permite seleccionar el recetario destino y elegir escribir o importar un PDF/foto. No mezcla formularios con recetas actuales. El acceso Agregar receta a este recetario lleva a esa área con el libro seleccionado. Las ediciones pendientes siguen disponibles dentro de la receta.

Costos de productos reúne la ficha final: ingredientes y materiales según precios actuales, mano de obra fija o por horas, empaques adicionales, acabados, transporte y otros gastos. Muestra costo completo y por unidad de rendimiento. No se repiten aquí los materiales ya registrados en la fórmula. Cada receta tiene una ficha privada product_cost, con ID propio, versiones y respaldo; un índice evita duplicados por cuenta y receta. Guardar no cambia ventas ni lotes anteriores.

Los productos existentes en Mi nevera muestran sus precios por canal en esta área. Usar costos de la ficha del producto copia explícitamente base, mano de obra y extras por unidad, conservando margen y comisión. Si la unidad de venta difiere del rendimiento, exige una equivalencia confirmada. Mi nevera enlaza a esta área. El Cotizador conserva los encargos particulares.

La lectura de PDF o foto abre automáticamente la revisión, con el recetario de origen seleccionado. No guarda hasta confirmar Guardar receta importada. Se conservan el texto y las revisiones pendientes en los borradores existentes de la cuenta. Los nombres, cantidades y equivalencias deben revisarse. La lectura de un PDF con texto se verificó con un archivo real de ejemplo; no se ha recibido el archivo particular reportado por la usuaria.

Los recetarios pueden cambiar nombre y uso. La asignación y edición comprueban el propietario y los valores previos. Eliminar un recetario requiere confirmación y solo admite vacíos; la base bloquea la operación si tiene recetas, aunque el estado de otra sesión sea distinto. No se borran recetas al eliminar un recetario.

Proporcional (antes Escalable) ajusta todos los ingredientes a una proporción. Por tandas completas (antes Fija) redondea hacia arriba al cotizar. La calculadora explícita de Herramientas sigue permitiendo fracciones y combinaciones.

## Gramos, unidades y líquidos

Cada artículo/proveedor puede registrar una equivalencia propia en Usar este artículo en gramos: cantidad y unidad de referencia y peso medido en gramos. Ejemplos: 1 unidad de huevo sin cáscara pesa 50 g; 100 ml de un líquido pesan 103 g. Se almacena el cociente grams_per_base_unit. No se presupone peso de huevos, agua u otros líquidos, ni se copia una equivalencia al crear otro proveedor.

La receta guarda measurement_quantity y measurement_unit además de quantity_base. Por ejemplo, 125 g de huevo a 50 g/unidad conservan 125 g en pantalla y representan 2,5 unidades para costo e inventario. Los guardados y ediciones, importaciones, fichas, cotizaciones y calculadora comparten la conversión. La combinación agrupa por ID, conserva proveedores separados y permite sumar gramos con unidades equivalentes sin perder el formato de gramos solicitado.

Una función y un trigger validan y calculan las cantidades base en el servidor; no confían en la conversión enviada por el navegador. Las líneas anteriores sin unidades preferidas conservan su comportamiento. La edición verifica también las unidades y cantidades previas para evitar sobrescribir cambios de otra sesión. Cambiar una equivalencia conserva los gramos de las recetas y aplica la equivalencia actual a los futuros cálculos y producciones.

## Consumo al producir

Registrar una preparación terminada descuenta los ingredientes y materiales del inventario. Guardar una receta no consume existencias. El registro bloquea producto, receta, líneas e ingredientes en un orden estable; valida las existencias y guarda lote, costo y consumos en una sola transacción. Si falta algo, se revierte todo. Un reintento con el mismo ID no descuenta dos veces. Las fracciones de unidades se conservan cuando la receta usa parte de su peso.

El lote guarda production_details con cantidades base y costo unitario del momento. Los lotes y ventas anteriores conservan sus importes, y no hay descuentos retroactivos. Mi nevera actualiza los datos de inventario de la aplicación; la lista de compras utiliza los mínimos existentes. El usuario debe completar las existencias reales antes de producir. Los respaldos existentes exportan y restauran las columnas nuevas mediante la infraestructura privada ya existente.

Aplicar 20261102_materiales_y_canales.sql y después 20261102_recetarios_y_equivalencias.sql antes de publicar. Ambas migraciones se probaron juntas con rollback, usuarios ficticios y aislamiento por cuenta; no cambian RLS ni credenciales.
