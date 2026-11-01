# Comprobaciones automáticas

GitHub Actions ejecuta las pruebas y la compilación en propuestas hacia main, en cada cambio de main y bajo ejecución manual. El trabajo se llama «Pruebas y compilación». Una prueba fallida impide ejecutar la compilación dentro de ese trabajo.

Usa Node.js 24 y acciones oficiales fijadas por commit. El token tiene solo lectura de contenido, no persiste credenciales y no usa secretos, sesiones ni datos de Supabase. El flujo no aplica migraciones, no envía correos y no publica la aplicación. Cloudflare conserva su comprobación de despliegue separada.

Antes de publicar, comprobar que el trabajo esté verde y que Cloudflare termine correctamente. Este archivo no convierte la comprobación en un requisito obligatorio de fusión: esa protección se configura aparte en las reglas de GitHub. No se cambiaron reglas de acceso ni de rama.

El proyecto todavía no tiene archivo de bloqueo de dependencias. Se usa npm install, igualando los rangos declarados en package.json; las versiones resueltas pueden cambiar entre ejecuciones. Incorporar un bloqueo validado y alinear el instalador de Cloudflare queda pendiente de una entrega específica.

Las pruebas automatizadas incluyen simulaciones de interfaz y servicios; no equivalen a iniciar sesión como las usuarias ni a probar correos, permisos reales o SQL de producción. Esas verificaciones se documentan por separado en cada entrega.
