# Bum Bum Costos: auditoría y plan de evolución

Fecha: 31 de octubre de 2026. Base de esta etapa: `main`, commit `eb5e3587faa867bde915fbe984c3fbce11303da0`.

## Alcance y límites de la revisión

Se revisaron el código React, los servicios de acceso a Supabase, `package.json`, las migraciones y los archivos de pruebas SQL disponibles. Esta auditoría describe lo comprobable en esos archivos; no constituye una inspección completa del esquema, de todas las políticas ni de los datos actuales de producción. La presencia de una prueba en el repositorio no significa que se haya ejecutado durante esta auditoría. Los resultados ejecutados para la nueva calculadora deben consignarse en su entrega y PR.

El PR #6, «Mostrar personas con acceso y limpiar solicitudes resueltas», ya forma parte de la versión oficial y de la base de esta etapa. Añade la vista administrativa de personas aprobadas y limita Solicitudes a pendientes o aprobaciones en proceso, conservando los registros resueltos en Supabase. Esta implementación debe preservarse.

La primera calculadora puede incorporarse de forma aislada, sin modificar inventario, fórmulas de costo, credenciales, tablas existentes ni RLS. No es necesario reescribir la aplicación ni implementar todas las funciones solicitadas simultáneamente.

## Estado actual comprobado

| Área | Funcionalidad en el código | Límite actual |
| --- | --- | --- |
| Acceso | Supabase Auth, inicio y cierre de sesión, solicitud, aprobación, invitación y establecimiento inicial de contraseña | Los espacios pertenecen a usuarios individuales; no hay membresías de empleados dentro de un mismo negocio |
| Administración | Solicitudes pendientes y Personas con acceso; reenvío de invitaciones pendientes de completar | No gestión general de roles de negocio ni edición completa de perfiles |
| Catálogo | Ingredientes y materiales, proveedor por registro, presentación y precio de compra, edición mediante formulario | Proveedor como texto y variantes independientes; sin catálogo normalizado ni historial de precios |
| Recetas | Recetarios por uso, líneas con UUID de ingrediente, rendimiento y costos según precios vigentes | Creación, asignación de recetario y consulta; sin edición profesional, pasos, versiones ni subrecetas |
| Cotizador | Recetas de Encargos, tipo de artículo, materiales, decoraciones, mano de obra, extras, margen o recargo | Sin clientes, pedidos, dimensiones, edición de cotizaciones ni impresión/compartir |
| Ventas | Bruto, comisión, costo declarado y ganancia estimada | Costo manual; sin conexión transaccional con producción o existencias |
| Inventario | Columnas de existencias/mínimos y referencias a tablas de compras y movimientos en migraciones | Sin interfaz operativa ni consumo automático en los servicios revisados |
| Respaldo | Exportación JSON del estado cargado | Sin restauración; no es una copia completa del esquema y datos de Supabase |
| Herramientas | Incorporación en esta etapa de la calculadora profesional | El resto de calculadoras y gestión avanzada se implementarán por fases |

## Hallazgos prioritarios

### Antes de conectar inventario y producción

1. **Esquema inicial incompleto en el repositorio.** Las migraciones disponibles alteran tablas previas, pero no incluyen todas sus definiciones originales. Antes de introducir operaciones transaccionales, debe obtenerse un esquema reproducible sin datos ni secretos y revisarse mediante lectura autorizada: tablas, claves foráneas, restricciones, índices y políticas. No debe suponerse que lo no versionado falta en producción.
2. **El adaptador omite existencias.** `src/ingredientsService.js`, en `adaptarIngrediente`, no devuelve `stock_quantity` ni `minimum_stock`. `src/cloudService.js` carga los artículos mediante ese adaptador. Por ello el estado exportado desde la aplicación no incluye toda la información necesaria para recuperar un inventario.
3. **Costo vigente e histórico son distintos.** `recipeCost`, en `src/main.jsx`, calcula con el precio actual del ingrediente. Las cotizaciones guardan importes y detalle de materiales, pero no una versión íntegra de la receta y los precios de todos sus ingredientes. Las ventas reciben costos manuales. Se requieren versiones e instantáneas para análisis históricos fiables.
4. **No hay transacción de producción ni protección contra doble consumo.** La interfaz revisada no descuenta inventario por pedidos. La implementación futura debe registrar producción y movimientos en una operación SQL atómica, con una clave única de idempotencia y reversión trazable.
5. **El aislamiento actual es por persona.** El modelo usa `owner_id` asociado a `auth.uid()`. No debe transformarse silenciosamente en un negocio compartido ni aceptar un negocio elegido libremente por el cliente. La colaboración entre empleados exige membresías, migración y políticas aprobadas.

### Precisión y mantenibilidad

6. **Unidades duplicadas.** Existen factores en `src/main.jsx` y `src/cloudService.js`. La onza líquida actual usa el factor estadounidense, pero se presenta como `fl oz` sin identificar sistema. La calculadora debe distinguir explícitamente masa, volumen estadounidense, imperial y métrico. Su núcleo debe ser independiente y no cambiar los costos existentes en esta etapa.
7. **Edición de precio y stock correctamente separados.** `catalogoService.guardarArticulo` conserva las existencias al editar precio/presentación/proveedor. Solo el alta inicial establece stock. `actualizarPrecioIngrediente` actualiza únicamente el costo. Esta separación debe mantenerse.
8. **Proveedor como variante independiente.** Las recetas apuntan al registro concreto de ingrediente/proveedor. Es funcional, pero duplica el artículo lógico. El modelo futuro separará artículo, proveedor y oferta/presentación, conservando referencias mediante un procedimiento explícito.
9. **Costo incompleto puede parecer cero.** En `src/main.jsx`, un ingrediente ausente se omite y una conversión incompatible aporta cero. La función `n` también transforma entradas no numéricas o negativas en cero. Una futura revisión debe mostrar «Costo incompleto» o un error, sin modificar incidentalmente las fórmulas durante el PR de Herramientas.
10. **Metadatos de receta dentro de texto.** `recipes.instructions` contiene JSON de escalado y tipo de producto. El adaptador no conserva una preparación convencional ni campos desconocidos. La expansión debe añadir estructuras explícitas sin sobrescribir instrucciones existentes.
11. **Configuración sin persistencia sincronizada.** `cargarDatos` devuelve `settings: {}`. Preferencias, favoritos y calibraciones de Herramientas deben indicar claramente dónde se guardan. El almacenamiento de este dispositivo debe separarse por usuario; si se promete sincronización, se requieren tablas privadas y aprobación de la migración correspondiente.
12. **Reproducibilidad de dependencias y pruebas.** `package.json` utiliza rangos de versiones y no dispone de un script general de pruebas en la base revisada. Las dependencias del servicio también usan versiones mayores abiertas. Se recomienda mantener un archivo de bloqueo y una comprobación automatizada de compilación/pruebas, sin mezclar actualizaciones mayores con la calculadora.
13. **Pantallas y carga global acopladas.** `main.jsx` reúne navegación, recetas, cotizaciones, ventas y respaldos. Su contenido se deshabilita ante fallos de carga de datos. Las conversiones puras deben poder funcionar sin depender de que carguen ventas o cotizaciones; los controles que usan recetas sí deben reflejar su disponibilidad.

## Controles positivos encontrados

- Los servicios principales filtran por propietario y el guardado atómico de recetas verifica referencias a ingredientes de la misma cuenta.
- Las funciones de receta son `security invoker`; el recetario valida pertenencia mediante función y trigger.
- La aprobación añade una política restrictiva adicional a las tablas de negocio, conservando la protección de propiedad existente.
- Las acciones administrativas del servicio verifican la sesión mediante `auth.getUser` y el rol en `business_admins`.
- Solicitudes y perfiles no permiten al público leer otras cuentas ni autoaprobarse.
- Las credenciales de correo y servicio se obtienen en servidor. La solicitud pública no pide contraseña.
- Existen pruebas SQL de aislamiento entre dos cuentas, receta atómica y bloqueo de cuentas pendientes. Deben mantenerse y ampliar su cobertura al crecer el modelo.

Estos controles no sustituyen la revisión del esquema real antes de modificar seguridad o introducir negocios compartidos.

## Arquitectura propuesta

Conservar React + Vite, Supabase y Cloudflare. Separar gradualmente las responsabilidades sin una reescritura total:

```text
src/
  app/                   navegación, sesión, límites de error
  shared/
    ui/                  formularios, avisos, búsqueda y resultados
    validation/
  domain/
    measurements/        unidades y cálculos puros
    costing/             reglas de costo e instantáneas
  features/
    tools/
    recipes/
    catalog/
    inventory/
    quotes/
    orders/
    production/
    finance/
    settings/
  data/                  repositorios y adaptadores de Supabase
```

El núcleo de conversiones no debe importar React ni Supabase. El catálogo de equivalencias debe conservar medida original, fuente, fecha de referencia, condiciones y clasificación: definición exacta, densidad medida o equivalencia culinaria aproximada. Mostrar más decimales no convierte una equivalencia aproximada en exacta. No confundir la libra comercial de bizcocho con una unidad universal de masa.

La integración inicial con recetas debe ser consultiva y explícita. No debe reescribir cantidades, precios ni costos automáticamente. Cada módulo debe validar su entrada, manejar errores y tener pruebas de sus reglas de dominio.

## Organización futura de datos

Las siguientes entidades son una propuesta, no migraciones autorizadas o aplicadas. Mantener tablas e identificadores actuales durante la primera implementación.

| Etapa | Entidades propuestas | Integridad y propósito |
| --- | --- | --- |
| Herramientas sincronizadas | `tool_preferences`, `favorite_conversions`, `ingredient_calibrations`, `commercial_cake_standards` | Privadas por cuenta; fuente/condiciones de calibración; sin equivalencia comercial universal precargada |
| Catálogo profesional | `suppliers`, `items`, `supplier_items`, `purchase_presentations`, `price_history` | Separar artículo lógico y oferta del proveedor; preservar IDs o mapearlos explícitamente |
| Recetario | `recipe_versions`, `recipe_version_lines`, `recipe_steps`, `recipe_equipment` | Versiones inmutables al cerrar producción/cotización; ingredientes o subrecetas con detección de ciclos |
| Inventario | `purchase_orders`, `purchase_lines`, `lots`, `inventory_movements` | Compra, existencia y costo unitario separados; movimientos trazables y saldo reconciliable |
| Pedidos | `customers`, `orders`, `order_lines`, `order_payments` | Entrega, anticipos, saldos, estados y referencias |
| Producción | `production_batches`, `production_consumptions`, `finished_goods`, `production_tasks` | Consumo atómico exactamente una vez por operación; reversión y merma registradas |
| Finanzas y calidad | `expenses`, `receivables`, `cash_entries`, `quality_checks` | Diferenciar ingreso, utilidad, efectivo e inventario; auditoría y reportes |
| Negocios con empleados | `businesses`, `business_members` | Rol y membresía activa; migración aprobada, claves entre entidades del mismo negocio y pruebas RLS |

Una compra recibida debe crear entradas y actualizar el saldo de inventario dentro de una transacción. Una producción confirmada debe consumir sus lotes e ingredientes una sola vez y guardar la versión/costos utilizados. La venta debe enlazar el producto/pedido y sus importes sin volver a consumir los mismos ingredientes. No se debe inferir existencia a partir de la cantidad de la última compra.

## Plan por fases

| Fase | Prioridad y complejidad | Entrega y criterio de salida |
| --- | --- | --- |
| 1. Herramientas y conversiones | Alta; acotada | Masa, volumen por sistema y temperatura; equivalencias verificadas y calibración propia; precisión documentada, decimales de presentación, copia/favoritos/preferencias e integración consultiva. Pruebas y compilación ejecutadas. Sin cambios productivos |
| 2. Consolidación técnica | Alta; media | Esquema reproducible, separación de módulos, CI de pruebas/build, errores de costo incompleto y procedimiento de respaldo/restauración verificado |
| 3. Recetario profesional | Alta; alta | Preparación, fotografía privada, tiempos/temperaturas, moldes, merma, porciones, versiones, escalado y subrecetas. Preservar recetas previas y evitar ciclos |
| 4. Compras e inventario | Alta; alta; depende de 2 | Recepción, precios históricos, lotes, vencimientos, mínimos, mermas y ajustes. Transacciones, concurrencia e idempotencia probadas |
| 5. Clientes, pedidos y producción | Alta; alta; depende de 3 y 4 | Anticipos/saldos, estados, calendario, órdenes de trabajo, lista consolidada y consumo de ingredientes exactamente una vez |
| 6. Cotizaciones y canales | Media; media/alta | Guardar, duplicar, editar, imprimir y compartir; dimensiones, indirectos, merma, comisiones y descuentos. Conservar la decisión vigente de cotizador exclusivo de Encargos |
| 7. Ventas, finanzas y reportes | Media; alta; depende de registros anteriores | Gastos, caja, rentabilidad por producto, cuentas por cobrar, comparaciones y descargas. Conciliar ingreso, utilidad, efectivo e inventario |
| 8. Herramientas técnicas y calidad | Progresiva; variable | Moldes, porcentaje panadero, hidratación, porciones, rendimientos y temporizadores. Concentraciones/sustituciones solo con referencias y límites específicos |
| 9. Equipos dentro de un negocio | Posterior; alta | Membresías y roles con migración/RLS autorizadas, revisión de acceso cruzado y plan de recuperación antes de ofrecer colaboración compartida |

Los perfiles de Pastelería, Panadería y Mixto deben ajustar accesos de navegación, plantillas y preferencias, sin duplicar recetas o inventario. La navegación evolucionará hacia Inicio, Recetas, Ingredientes e inventario, Herramientas, Cotizaciones, Pedidos y producción, Ventas y finanzas y Configuración, manteniendo formularios simples y la pantalla inicial despejada.

## Condiciones de publicación y seguridad

- Trabajar en rama independiente; no modificar `main` directamente.
- No fusionar ni desplegar a producción sin aprobación de la usuaria.
- No borrar, reemplazar o migrar datos existentes sin procedimiento seguro y autorización cuando corresponda.
- No cambiar credenciales ni RLS como efecto secundario de una calculadora.
- Documentar qué pruebas se ejecutaron y sus límites; no sustituir ejecución por una inspección del código.
- Guardar fuentes y advertencias junto con las equivalencias; ingredientes sin verificación deben quedar pendientes o requerir calibración.
- Para cada módulo conectado, probar validación, aislamiento por cuenta, integridad referencial y recuperación antes de ampliar su uso.


## Pendiente solicitado: renovación visual integral

Al finalizar las mejoras funcionales, renovar la interfaz completa para que se sienta como una aplicación moderna: tipografía actual, navegación clara en celular, tarjetas e iconos visuales, botones cómodos y una jerarquía simple. Mantener las tareas principales visibles y las opciones avanzadas en segundo plano. Incluir inicio, catálogo, recetarios, cotizador, ventas y administración, conservando el funcionamiento y los datos. Esta renovación global queda pendiente; la primera simplificación visual se aplica a Herramientas.
