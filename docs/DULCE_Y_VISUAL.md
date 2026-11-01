# Dulce y visual

Implementación del diseño seleccionado por la usuaria: crema #fcf8f5, vino #8a3450, rosa suave #f8e9ed y Manrope. No cambia el modelo de datos ni los servicios de autenticación, aprobación, correo o costos.

## Cambios

- Entrada pública e inicio de sesión con nombre protagonista, sin el logo anterior, dos paneles en escritorio y una columna en celular. Se conserva la solicitud completa de negocio, estados pendientes, alertas de invitación y configuración de contraseña existente.
- Menú lateral en escritorio y barra inferior en celular (Inicio, Recetas, Ingredientes, Más). Más abre todas las opciones, incluidas las administrativas solo para quien ya tenga ese rol. Se conserva la protección de borradores durante edición.
- Pantalla principal con accesos a crear receta, ingredientes, cotizar y convertir. Resumen con datos reales de la cuenta, sin cifras demostrativas ni métricas financieras nuevas. Ventas registradas suma los montos brutos cargados; no representa utilidad ni un período seleccionado.
- Tres recetas más recientes de la lista cargada. Ver receta filtra por nombre, abre su ficha y la desplaza a la vista. Los recetarios, materiales y decoraciones conservan accesos y recuentos.
- Manrope incluida localmente con su licencia SIL OFL (origen: google/fonts/ofl/manrope). font-display:swap y tipografía de sistema como respaldo. Sin solicitudes de fuentes a terceros al abrir la app.
- Nuevo icono vectorial bb. y PNG de 192/512, además de apple-touch-icon de 180. Manifiesto y theme-color coordinados; archivos anteriores de logo conservados. Un icono ya instalado puede tardar en actualizarse según el dispositivo.

## Verificación

69 pruebas de aplicación/componentes/servicios y compilación de producción. Las regresiones cubren crear/editar/eliminar recetas, guías, ingredientes, cotizador y separación lógica por cuenta mediante servicios simulados. Pruebas nuevas de accesos del inicio, ficha desplegada, cifras reales, estado vacío, autenticación sin cambiar su llamada, error sin conceder sesión, fuente y manifiesto.

Navegador con la App real y un servicio simulado, sin acceso a cuentas ni correos: escritorio, celular 390 px, entrada, inicio de sesión, formulario de solicitud, menú completo, barra inferior, recetas y acceso a ficha. Se corrigió un conflicto de CSS que hacía ocupar toda la pantalla a la barra inferior móvil. No se ingresaron contraseñas reales ni se enviaron solicitudes.

Los cambios son de presentación y navegación. No se ejecutaron migraciones ni se editaron registros reales. PDF de recetas, finanzas/ventas en PDF, inventario y demás ampliaciones siguen pendientes. Publicación sujeta a la aprobación acordada.
