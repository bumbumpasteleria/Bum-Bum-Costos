# Gestión, reportes y recuperación

Finanzas y Reportes de ventas filtran por fecha y canal. El PDF refleja los datos del filtro: venta bruta, comisiones, ingresos netos, costo de producción y otros gastos. Finanzas añade gastos del negocio y resultado registrado; este resultado no equivale al efectivo disponible. Los gastos de canal General se incluyen solamente al consultar Todos, para evitar asignarlos a un canal arbitrariamente. Un registro inválido se señala y se excluye explícitamente del cálculo. La descarga espera a terminar la carga de datos.

Los gastos se corrigen o anulan conservando su historial y versión. Pedidos registra cliente, entrega, anticipo, saldo y estado; el anticipo no puede superar el total. Los pedidos entregados o cancelados salen de la vista Activos y se consultan con sus filtros. Registrar o entregar un pedido no crea una venta ni descuenta nevera: la venta real se registra en Ventas.

Las fichas de recetas guardan foto reducida, notas, alérgenos declarados e indicaciones propias de conservación. Cada cuenta consulta únicamente sus registros. Las fotografías se reducen en el navegador, sin un servicio externo de imágenes.

## Recuperación

Respaldo descarga los registros privados en formato JSON v2. Revisa el resumen antes de confirmar una recuperación. Solo se añaden registros ausentes; no se sustituyen precios, existencias ni ventas actuales. Las líneas solo se recuperan junto con su receta ausente. Una copia antigua se adapta cuando sus identificadores y estructura lo permiten; si no registra existencias, se pide contarlas en Inventario. No se restauran cuentas, contraseñas, permisos ni borradores locales. No se deben compartir las copias.

Las versiones de recetas se conservan desde la instalación de esta actualización, antes de editar o eliminar. Recuperar una versión existente reemplaza su fórmula y conserva el estado anterior en el historial. Requiere que sus ingredientes y recetario sigan disponibles. La operación compara la versión actual para evitar sobrescribir cambios simultáneos.

## Publicación y validación

Antes de publicar la interfaz, aplicar con autorización las migraciones `20261102_gestion_completa.sql` y `20261102_galones.sql`. La primera añade cuatro tablas privadas con lectura por propietario aprobado y funciones de escritura con validación explícita de cuenta, propietario y versión. Los clientes no reciben escritura directa en los historiales. La segunda amplía unidades de compra y rendimiento con galón estadounidense, sin modificar cantidades existentes. No cambia el registro de usuarios ni los permisos de administración.

Para comprobar ambas migraciones sin persistir cambios, unir sus cuerpos dentro de un solo BEGIN, omitir ambos COMMIT y añadir `supabase/tests/gestion_completa.sql`, que finaliza con ROLLBACK. Usa cuentas ficticias distintas para probar aislamiento, reintentos, conflictos, recuperación atómica, permisos y unidades. El redondeo de existencias respeta la precisión de la columna existente. El factor de conversión es 3785.411784 ml por galón estadounidense.

Ejecutar `npm test` y `npm run build`. El reconocimiento OCR se prueba con una imagen ficticia en base64 y datos españoles locales. El paso prebuild copia las dependencias OCR a public/ocr, sin subirlas al repositorio. Revisar los PDF renderizados, las fotos y los formularios en computadora y celular antes de fusionar.
