# Revisión de uso y funcionamiento

## Cambios preparados

| Área | Problema observado | Mejora |
| --- | --- | --- |
| Inicio | Había accesos, pero faltaba una síntesis del trabajo del día | Tarjetas de preparaciones, entregas y encargos por cobrar, con datos de la cuenta |
| Navegación móvil | Ventas y Agenda exigían abrir grupos del menú | Accesos inferiores a Inicio, Recetarios, Ventas y Agenda; Más conserva los demás módulos |
| Guardado | La disponibilidad de red podía confundirse con guardado confirmado | Indicador separado de conexión, carga y guardado; los mensajes de cada formulario siguen confirmando la operación |
| Pendientes | Solo podían cancelarse algunas preparaciones independientes | Confirmación en la propia tarea y recuperación desde Trabajos retirados, sin borrar el pedido ni tocar inventario |
| Receta borrada | Un pendiente huérfano podía quedar bloqueado por la validación de su receta | Operación privada para retirar la tarea conservando campos e historial; recuperar exige receta válida |
| Inicio de sesión | Faltaban identificadores de formulario para gestores de contraseñas | Campos con nombre, identificador, autocompletado y teclado de correo |
| Google | El proveedor no estaba configurado | Acceso preparado con PKCE y retorno a Android; el botón solo aparece si Supabase confirma que Google está habilitado |
| Android | Mostraba instrucciones para instalar desde Chrome aunque ya estuviera instalada | Esas instrucciones se ocultan en la versión nativa |
| Actualizaciones | No había forma de anunciar una nueva compilación | Aviso para Android con botón de descarga, número de compilación superior y enlace restringido al repositorio oficial |
| Apariencia y acceso | Espacios y controles poco uniformes en celular | Tarjetas coherentes, controles táctiles, foco visible, texto de campos de 16 px y respeto por movimiento reducido |

## Verificación y límites

- Las 212 pruebas automáticas finales y la compilación web pasaron. Android se valida también en la integración continua de la propuesta.
- La prueba SQL usa dos cuentas sintéticas y una transacción revertida. Comprueba retiro de tarea con receta ausente, versión, historial, protección de otra cuenta y bloqueo de producción terminada.
- La función de retiro ya está habilitada en Supabase; no requiere borrar ni modificar registros reales al publicarse.
- La distribución se inspeccionó a 390 × 844: resumen del día al principio, navegación inferior y confirmación de retiro en la misma pantalla. La vista de revisión usa únicamente datos sintéticos.
- No se eliminaron ni modificaron recetas, ingredientes, pedidos, cobros o existencias reales para probar estas mejoras.
- La revisión de código y las pruebas automatizadas no equivalen a probar cada combinación posible en cada teléfono. El inicio de sesión Google, el gestor de contraseñas, la descarga/instalación y la entrega de notificaciones requieren comprobación en dispositivo real.
- La versión Android anterior utiliza firma temporal de depuración. La distribución estable y las actualizaciones compatibles requieren una clave de firma permanente y un número de compilación creciente.
- El autocompletado depende de la configuración y el gestor de contraseñas del teléfono; la app no copia ni almacena contraseñas en borradores.
- No se habilita registro público por añadir Google: se conserva el control de aprobación de cuentas.

## Operación de futuras actualizaciones

El manifiesto público `/android-version.json` contiene el identificador de la app, versión, número de compilación y URL del instalador. Se consulta al abrir Android y, como máximo una vez por hora, al volver a la app. Solo propone compilaciones superiores y descargas HTTPS del repositorio oficial. No descarga ni instala en segundo plano. Cada publicación debe mantener la firma, incrementar el número y verificar el APK antes de actualizar el manifiesto.

## Configuración pendiente de Google

Crear un cliente web OAuth de Google con retorno a `https://exanisbqasrzoerdghmz.supabase.co/auth/v1/callback`, guardar su secreto directamente en el proveedor Google de Supabase y permitir el retorno nativo exacto `com.bumbumpasteleria.costos://auth/callback`. Conservar la URL oficial y los retornos de invitación existentes. No activar registro público, omitir validación de nonce ni solicitar acceso a Gmail/Drive.

Referencias oficiales: [Google con Supabase](https://supabase.com/docs/guides/auth/social-login/auth-google), [retorno a aplicaciones móviles](https://supabase.com/docs/guides/auth/native-mobile-deep-linking), [configuración de acceso](https://supabase.com/docs/guides/auth/general-configuration).
