# Importar recetas desde PDF

En Recetas, pulsa Importar PDF. Selecciona un PDF con texto (10 MB, 20 páginas como máximo y una receta por archivo), o pega el texto. Pulsa Revisar receta y corrige nombre, cantidades, unidades, rendimiento y preparación. Asigna cada línea a un ingrediente y proveedor de tu catálogo. Si usas tazas o cucharadas, indica una equivalencia válida para ese ingrediente. No se inventan precios ni densidades.

El archivo se procesa localmente y no se sube a Supabase. Solo Guardar receta importada crea una receta nueva en el recetario elegido, con la preparación y sus ingredientes en una transacción. Los PDF escaneados requieren texto seleccionable o pegado; esta versión no incorpora OCR. El reconocimiento de texto es una ayuda y requiere revisión, especialmente en tablas o varias columnas.

Despliegue: aplicar primero supabase/migrations/20261101_importar_receta_pdf.sql, con autorización de la administradora. No modifica políticas ni las funciones previas. La función nueva es SECURITY INVOKER y solo ejecutable por authenticated. A continuación publicar la aplicación. No se aplicó la migración automáticamente desde este PR.

## Nombres incompletos y proveedores

Si el PDF dice «harina», se muestran ingredientes como «Harina La Blanquita» y «Harina de trigo». Cada opción muestra proveedor y precio por unidad del catálogo. Si hay varias opciones, incluso una coincidencia exacta junto con otras marcas, debes elegir una. Una coincidencia parcial nunca se vincula por sí sola. Los nombres sin coincidencias pueden asignarse con la lista completa. No se mezclan registros de distintos proveedores ni se crean precios.

## Registrar sin salir del importador

En cada línea, Registrar ingrediente abre los campos de nombre, proveedor, precio total, cantidad comprada y unidad de compra. Guardar ingrediente y vincular lo registra en tu catálogo privado y selecciona su ID para esa línea, conservando la cantidad de la receta. Una compra de 1 kg puede usarse en una receta de 250 g. Si la unidad de la receta no se reconoció, debes seleccionarla explícitamente; no se convierten tazas a gramos por suposición. Los nombres y proveedores idénticos ya registrados se señalan para elegir el registro existente.

Puedes crear un recetario sin salir. Mientras un registro está abierto, el guardado final de receta queda bloqueado. Los errores conservan los formularios. Los ingredientes y recetarios se guardan por separado antes de guardar la receta, y permanecen en tu catálogo si luego cancelas la importación. No se requieren cambios de base de datos ni permisos.

## Retomar un borrador

El texto extraído, las correcciones y los registros abiertos se conservan al cambiar de módulo o recargar en el mismo dispositivo y cuenta. El archivo PDF no se almacena como borrador. Guardar confirma la receta en la nube. Cancelar la revisión descarta sus correcciones y conserva el texto original para volver a revisarlo.
