# Importar recetas desde PDF

En Recetas, pulsa Importar PDF. Selecciona un PDF con texto (10 MB, 20 páginas como máximo y una receta por archivo), o pega el texto. Pulsa Revisar receta y corrige nombre, cantidades, unidades, rendimiento y preparación. Asigna cada línea a un ingrediente y proveedor de tu catálogo. Si usas tazas o cucharadas, indica una equivalencia válida para ese ingrediente. No se inventan precios ni densidades.

El archivo se procesa localmente y no se sube a Supabase. Solo Guardar receta importada crea una receta nueva en el recetario elegido, con la preparación y sus ingredientes en una transacción. Los PDF escaneados requieren texto seleccionable o pegado; esta versión no incorpora OCR. El reconocimiento de texto es una ayuda y requiere revisión, especialmente en tablas o varias columnas.

Despliegue: aplicar primero supabase/migrations/20261101_importar_receta_pdf.sql, con autorización de la administradora. No modifica políticas ni las funciones previas. La función nueva es SECURITY INVOKER y solo ejecutable por authenticated. A continuación publicar la aplicación. No se aplicó la migración automáticamente desde este PR.
