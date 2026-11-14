# Responsables y notificaciones

Cada preparación y entrega de Agenda, artículo de Compras y producto de Producción permite **Asignar responsable**. Se guarda el nombre del empleado; cambiarlo no modifica cantidades ni existencias. La asignación permanece ligada al registro y se conserva en el historial y el respaldo privado. No crea una cuenta para el empleado.

En **Mis pendientes → Notificaciones en mi teléfono**, cada usuario activa este dispositivo y elige una hora de 00:00 a 23:00, en República Dominicana. El servicio envía un resumen diario si hay preparaciones o entregas pendientes, incluso con la app cerrada. El envío se comprueba cada 15 minutos; la recepción depende de conexión, permisos y ajustes del sistema. El botón **Enviar notificación de prueba** permite comprobar cada dispositivo.

En iPhone se requiere iOS 16.4 o posterior y abrir la aplicación añadida a la pantalla de inicio desde Safari. En Android se puede utilizar Chrome. No se solicita permiso sin pulsar Activar. Desactivar o cerrar sesión retira la suscripción del dispositivo. No se envían nombres de clientes, empleados, fotos ni importes en los mensajes.

Los temporizadores siguen funcionando en el dispositivo y requieren la app abierta para mostrar su aviso. No se presentan como alarmas del sistema.

## Operación del servicio

`task-notifications` verifica la sesión y la aprobación en cada acción de usuario. El despachador solo admite una credencial aleatoria interna, inaccesible a clientes, distinta de las claves de la cuenta. Las claves VAPID se generan en el servidor una sola vez. Endpoints y claves se guardan con RLS y sin privilegios de cliente. No se exportan en respaldos de negocio.

La función autentica sus rutas internamente; se configura `verify_jwt = false` en la pasarela para admitir el disparo del programador con su credencial interna. Esto no habilita acciones anónimas de usuario ni el despacho público. El código de despliegue se genera uniendo core.mjs e index.ts; nunca contiene valores de claves.

`bum_push_claim` reclama los avisos con bloqueo y una reserva temporal para evitar despachos simultáneos. El día de envío impide repetir un resumen por dispositivo el mismo día. Los servicios que devuelven 404/410 desactivan el destino; otros errores se reintentan después. Un corte después de entregar al proveedor y antes de confirmar la base puede provocar un reenvío; la etiqueta del aviso agrupa el resumen del día.

El worker comprueba la cuenta activa antes de mostrar o abrir el aviso. No intercepta peticiones ni almacena datos de negocio. El enlace abre Agenda dentro de la aplicación oficial.

Fuentes: [Apple: Web Push](https://developer.apple.com/documentation/usernotifications/sending-web-push-notifications-in-web-apps-and-browsers), [Supabase: programar funciones](https://supabase.com/docs/guides/functions/schedule-functions), [web-push](https://github.com/web-push-libs/web-push).

## Revisión de funcionamiento y textos

Se revisaron formularios, guías, navegación, estados vacíos y mensajes de los módulos. Se corrigió el mensaje de creación de receta, la recuperación de versiones, los nombres de movimientos, la presentación de unidades, singular/plural y las instrucciones que enviaban a Agenda para crear pedidos o a Mi nevera para configurar comisiones. La búsqueda de borradores omite categorías sin resultados.

Mi nevera abre la ficha de costo solicitada y refresca inventario tras producir. Una preparación con receta eliminada muestra una explicación y bloquea el descuento hasta revisarla. No se modifican fórmulas, precios, existencias ni documentos aportados por usuarios durante esta revisión.

## Avisos por situación de la aplicación

Cada cuenta elige preparaciones, entregas, ingredientes y materiales por reponer, productos de nevera en el mínimo, lotes vencidos o próximos a vencer, saldos de encargos y solicitudes de acceso. Las solicitudes están restringidas a administración en el servidor y en la interfaz. No se incluyen clientes, empleados ni importes en los mensajes.

Se comprueban a partir de la hora diaria de cada dispositivo, con revisión cada 15 minutos. Cada tipo de aviso se envía como máximo una vez al día por dispositivo. No es un sistema de alarmas instantáneas. Los lotes se incluyen desde 3 días antes de su fecha registrada y mientras conserven cantidad; no se inventan fechas. Las existencias por reponer excluyen lotes vencidos o retenidos por calidad, como las listas de la aplicación. Los cobros se incluyen si el pedido tiene entrega para hoy o atrasada y saldo pendiente.

Al pulsar el aviso se abre su módulo mediante una lista cerrada de destinos. Cambiar de cuenta evita mostrar avisos de la anterior. Las preferencias son privadas y no cambian existencias ni pedidos. `bum_notice_claim` reserva dispositivos con bloqueo, consulta sus datos por propietario y excluye avisos ya confirmados para ese día. `bum_notice_ack` confirma cada tipo por separado; los errores no confirman envío. Un fallo entre entrega y confirmación puede provocar reintento; la etiqueta agrupa el mismo aviso.
