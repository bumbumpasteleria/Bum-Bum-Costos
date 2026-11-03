# Operación integral del negocio

## Recetas y producción

La ficha de receta permite registrar molde, capas, tiempos, temperatura y merma prevista. La merma prevista es una referencia: no vuelve a incrementar el costo ni modifica el rendimiento declarado. La composición vinculada incorpora proporciones de hasta tres recetas y consulta su fórmula actual; los ingredientes propios se editan por separado. Las copias escaladas existentes siguen siendo copias. El sistema rechaza ciclos y fórmulas excesivamente grandes. La producción guarda el consumo y costo histórico, aunque cambie después la receta.

Los temporizadores múltiples conservan su fecha de término o tiempo pausado por cuenta y dispositivo. Al volver a abrir la aplicación recalculan el tiempo transcurrido. No ofrecen una alarma del sistema cuando la aplicación está cerrada.

## Compras e inventario

Registra el conteo inicial en Inventario y las compras posteriores en Movimientos de inventario. Cada compra conserva artículo y proveedor, lote, vencimiento, cantidad, importe y pago inicial. Las operaciones actualizan existencias, precio, lote e historial en una sola transacción. Una respuesta repetida no registra otra compra. Los pagos posteriores no aumentan stock ni duplican compras.

La producción consume lotes disponibles por vencimiento y luego fecha de compra; también admite el conteo inicial sin lote. Los lotes vencidos o retenidos se excluyen. La merma por lote retira únicamente el lote elegido; los ajustes generales exigen motivo y verificación del saldo original. Las cantidades decimales se conservan sin redondearlas a milésimas. Cambiar un precio no revaloriza producciones anteriores.

## Directorios y agenda

Clientes y proveedores son privados por cuenta y se pueden editar o archivar. El pedido conserva una copia de los datos elegidos. La agenda reúne pedidos y preparaciones por fecha, permite adjuntar referencia visual y consolida ingredientes por artículo y proveedor. Terminar una orden descuenta una sola vez y guarda sus consumos. Su PDF terminado utiliza esos consumos históricos. No debe repetirse esa producción en Mi nevera.

La venta del encargo utiliza su total acordado y los costos históricos de sus órdenes terminadas, más los gastos adicionales declarados. No vuelve a descontar inventario ni registra cobros. Cada pedido admite una sola venta.

## Caja y rentabilidad

Configura un saldo y fecha inicial reales. Caja registra cobros, devoluciones, pagos de compra y movimientos manuales reales; una venta no se convierte automáticamente en efectivo. Los anticipos anteriores permanecen en el saldo del pedido, sin inventar su fecha de entrada a caja. Los cobros no pueden superar el saldo ni las devoluciones superar lo recibido. Los pagos de compra no pueden superar lo pendiente.

El reporte distingue flujo de caja, resultado por ventas y gastos, cuentas por cobrar actuales, compras por pagar y valor estimado del inventario. La comparación mensual incluye meses con gastos sin ventas. La contribución por producto descuenta sus costos y comisiones, sin repartir gastos generales por suposición. Los movimientos manuales se corrigen mediante una contrapartida documentada. El PDF indica los resultados parciales cuando falten datos.

## Calidad, privacidad y guardado

Los perfiles Pastelería, Panadería y Mixto conservan los datos del negocio. Los controles de calidad son criterios declarados por el usuario; no certifican inocuidad. El último control de un lote determina su retención o liberación, sin saltarse su vencimiento.

Los nuevos registros utilizan las tablas privadas y sus políticas existentes. Las operaciones verifican propietario, aprobación y referencias de la misma cuenta; los auxiliares no son ejecutables por clientes. La edición utiliza versiones para impedir sobrescrituras silenciosas. Los registros participan en el respaldo e historial existentes. Las pruebas de base de datos utilizan cuentas ficticias y terminan en ROLLBACK.

## Publicación

Aplicar 20261103_operacion_integral.sql antes de publicar el código asociado, una vez aprobada la entrega. Hasta entonces los módulos están preparados para revisión, no activos en producción. No se cambian credenciales ni políticas de acceso existentes.
