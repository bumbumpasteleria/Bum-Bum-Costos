# Edición de recetas y precisión de cantidades

Las cantidades convertidas se guardan en PostgreSQL con precisión decimal. Al volver a abrir una receta para editarla, la copia de comparación debe conservar esos valores exactos. Convertirlos a Number y luego a texto podía producir un falso conflicto, aunque no existiera otra edición.

La lectura de edición solicita rendimiento, cantidad base y cantidad de medición también como texto mediante selecciones PostgREST con `::text`. La copia de comparación usa esos campos; la presentación y los cálculos siguen utilizando números. No se relaja la comparación del servidor ni se reintenta sobrescribiendo una versión ajena.

Una franja visible permite volver a la receta en edición o pausarla, conservando su borrador local y desbloqueando la creación manual y la importación. Cancelar edición conserva su significado anterior: descarta el formulario de esa edición. Tras actualizar, si había un formulario abierto en la versión anterior, conserva sus cambios antes de cancelarlo y vuelve a abrir la receta para obtener una copia exacta.

Android 1.1.1 usa la firma permanente de 1.1.0 y aumenta el código de versión de 2 a 3. No requiere desinstalar 1.1.0. La descarga pública se anuncia solo después de generar y verificar el APK.

Verificación: regresión con decimales que pierden precisión al convertirse a Number, pruebas existentes de rechazo de conflictos reales y revisión de apertura del editor sin modificar recetas reales.

Referencia: https://docs.postgrest.org/en/stable/references/api/tables_views.html#casting-columns
