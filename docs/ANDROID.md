# Bum Bum Costos para Android

El proyecto Android abre la aplicación empaquetada con su propio icono y sin barra de Chrome. Utiliza las mismas cuentas y datos de Supabase. Requiere conexión para consultar y guardar datos; los borradores de esta instalación se conservan en su almacenamiento privado. Los borradores del navegador no se transfieren automáticamente. No desinstales ni borres datos de la app si tienes trabajo sin guardar en la nube.

Los PDF de cotizaciones, ventas, finanzas y gestión, y el respaldo JSON, abren el selector de Android para guardar o compartir el archivo. El usuario elige el destino. El botón Atrás navega dentro de la app; en la pantalla inicial la minimiza.

## Avisos de Android

En Mis pendientes abre **Notificaciones de la aplicación Android**, permite los avisos y selecciona una hora. Usa **Enviar notificación de prueba** y comprueba su recepción en el teléfono. Que el proveedor acepte el mensaje no garantiza su visualización: pueden impedirla la falta de conexión, permisos o ajustes del sistema.

Los avisos usan Firebase Cloud Messaging con mensajes de datos. Un servicio Android verifica la cuenta activa antes de mostrar el mensaje con el nombre de la app y un icono monocromático de melocotón. No incluye nombres de clientes, empleados ni importes. Al tocarlo abre Agenda. Cerrar sesión limpia la cuenta local antes de retirar la suscripción del servidor. Android puede impedir la recepción si la app está forzada a detenerse.

## Estado y configuración necesaria

Proyecto Firebase: `bum-bum-costos`, aplicación `com.bumbumpasteleria.costos`. La identidad está registrada; para habilitar envíos hay que instalar su configuración y la credencial de envío en el servidor. La interfaz mantiene los avisos nativos desactivados mientras falte el servicio.

- `android/app/google-services.json`: configuración descargada de la app Android en Firebase. Está excluida del repositorio. No es la credencial privada del servidor.
- `BUM_FCM_SERVICE_ACCOUNT`: secreto JSON del servicio de envío en Supabase. Debe tener únicamente los permisos necesarios para enviar FCM. Nunca va en el instalador, GitHub ni archivos públicos.
- Variables públicas `VITE_SUPABASE_URL` y `VITE_SUPABASE_PUBLISHABLE_KEY`: las mismas del sitio oficial; nunca utilizar `service_role` ni claves secretas en la compilación.

Se necesitan Node 22+, Java 21, Android SDK 36 y las herramientas de compilación. Ejecuta `npm install`, `npm run android:sync` y compila desde Android Studio. El proyecto usa Capacitor 8 con recursos web locales; no redirige al sitio ni habilita tráfico HTTP.

## Compilaciones

El flujo **Compilación Android** comprueba el proyecto nativo en cada PR, sin distribuir el APK de validación. La ejecución manual genera un APK de **prueba interna** cuando el entorno GitHub `android-interno` contiene las dos variables públicas y el secreto `GOOGLE_SERVICES_JSON`. La configuración se valida antes de compilar. Este APK de depuración no es una publicación oficial y su firma temporal no debe usarse para distribuir versiones permanentes.

Antes de una versión oficial faltan firma de lanzamiento bajo control de la propietaria, prueba en un Android real (instalación, acceso por cuenta, importación de archivos, exportación, notificación con app cerrada y cambio de cuenta), número de versión y canal de distribución. Las claves de firma deben conservarse de forma segura para permitir actualizaciones.

La versión iPhone es una etapa posterior: requiere proyecto iOS, firma y herramientas de Apple. Esta entrega no crea un instalador para iPhone.

Fuentes: [Capacitor Android](https://capacitorjs.com/docs/android), [notificaciones nativas](https://capacitorjs.com/docs/apis/push-notifications), [requisitos](https://capacitorjs.com/docs/getting-started/environment-setup).
# Mejoras de acceso y actualizaciones

La app comprueba `/android-version.json` para avisar de una compilación superior. El usuario abre la descarga; no hay instalación automática. Mantener firma estable y aumentar `versionCode` antes de anunciar una actualización. El manifiesto actual no anuncia una versión nueva.

El acceso con Google usa navegador del sistema y retorno PKCE a `com.bumbumpasteleria.costos://auth/callback`. Solo se muestra si el proveedor de Supabase está habilitado; requiere configurar el cliente Google y su secreto fuera del repositorio. El acceso continúa sujeto a aprobación de la cuenta.

