# Invitaciones e información de cuentas

Base: main 3cadf3c0e71d9dcc9b60ee70fb36d56b23231994.

Revisión de producción: ambas usuarias están aprobadas, sin confirmación ni primer ingreso. Supabase tiene vencimiento de enlace de correo de 3600 segundos y Site URL oficial correcta. No se cambiaron ajustes de autenticación. Se reenviaron las dos invitaciones con autorización expresa; la aplicación confirmó ambos envíos. La creación efectiva de contraseña corresponde a cada usuaria y no se ha verificado todavía.

Cambios: avisos de error de enlace en inicio público (fragmento y consulta, sin reproducir descripciones ni tokens); instrucciones de activación con plazo y contraseña mínima; ficha plegable por persona con datos del formulario original, o perfil si no hay solicitud. La API administrativa solo añade campos explícitos de negocio/formulario; no devuelve metadatos de Auth, hash de IP ni credenciales y conserva validación de sesión y rol. No cambia RLS ni el acceso entre cuentas.

Pruebas: 12 grupos de conversiones y avisos de acceso; compilación; pruebas de servidor con sustitutos de Supabase que comprueban acceso anónimo/usuario bloqueado, admin permitido, campos de formulario y exclusión de datos privados. No se consumieron enlaces personales ni se establecieron contraseñas reales.

Publicación requiere actualizar frontend y desplegar account-access. Mantener secreto SMTP y configuración actuales. La mejora de costos queda en PR independiente.
