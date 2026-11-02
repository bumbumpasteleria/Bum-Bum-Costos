# Inventario, compras, nevera y producción

El inventario de ingredientes y materiales conserva sus identificadores, precios y proveedores. Cantidad disponible y mínimo se editan en la unidad base del artículo. Compras incluye cada artículo cuando disponible <= mínimo; se retira al superar ese mínimo. Un valor desconocido no se trata como cero. No se crea una compra ni se modifica el precio al reponer.

Mi nevera registra productos privados vinculados a recetas y lotes de producción con cantidad obtenida, veces de receta, fecha de preparación y vencimiento opcional. El usuario selecciona una unidad de venta estable (porciones, unidades, bandejas, vasos o cajas). El costo de ingredientes de la receta se congela por lote. Los lotes vencidos se muestran, pero no se cuentan para venta o reposición. El mínimo genera una lista de pendientes de Producción, no un registro de producción automática.

Ventas conserva la modalidad general y añade ventas de nevera. El servidor descuenta lotes por vencimiento más cercano, después por fecha y ID. Venta y descuento se confirman en una transacción. Los bloqueos por producto serializan ventas, ajustes y preparaciones; una insuficiencia revierte todo. Los IDs del borrador hacen idempotentes los reintentos. Cambiar los datos de una operación ya registrada produce conflicto. No se permite aumentar un lote por encima de lo preparado originalmente: una reposición se registra como lote nuevo. Los ajustes requieren cantidad previa y motivo.

Las ventas de nevera no descuentan también los ingredientes del inventario. El costo de lote corresponde a ingredientes; otros gastos se registran aparte en la venta. No se calcula una fecha de vencimiento sanitaria ni un costo completo de negocio por suposición.

## Borradores

Los formularios de negocio, importación, calculadora y cotizador guardan borradores locales por cuenta. Sobreviven a cambios de módulo, cierre y recarga en el mismo dispositivo. No reemplazan registros en nube, no se sincronizan entre dispositivos y no contienen contraseñas, archivos PDF ni tokens. El guardado ocurre en cada cambio; si el almacenamiento no está disponible, aparece un aviso. Las colecciones antiguas de localStorage se conservan. Las ediciones de receta conservan su versión inicial para detectar conflictos tras reabrir un borrador.

## Publicación

1. Revisar y autorizar la migración `supabase/migrations/20261101_nevera.sql` antes de publicar la interfaz.
2. La migración crea únicamente tres tablas nuevas privadas y cuatro funciones de operación. No modifica las políticas existentes ni las cuentas. Las funciones usan SECURITY DEFINER para mantener el libro de movimientos sin conceder UPDATE directo a clientes; comprueban cuenta aprobada y propietario en todas las operaciones. Las lecturas usan RLS por cuenta aprobada. Anónimos no reciben acceso.
3. La prueba `supabase/tests/nevera.sql` se ejecuta dentro del BEGIN de la migración, reemplazando su COMMIT; termina en ROLLBACK. Crea únicamente identidades ficticias temporales y no conserva registros.
4. Publicar la interfaz aprobada, comprobar carga de las pantallas vacías y las guías con la cuenta administradora. No crear ventas, recetas o productos ficticios en producción.

Verificación realizada: compilación; pruebas automatizadas de interfaz, cálculo y persistencia; ensayo real en Supabase revertido de producción, costos por lote, reintentos, venta insuficiente, ajustes obsoletos y separación de cuentas. La vista local utiliza ejemplos sin conexión a cuentas reales.
