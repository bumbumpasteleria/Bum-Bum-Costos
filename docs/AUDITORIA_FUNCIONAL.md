# Auditoría funcional y guías de uso

Base: main 9240c85517cf44a7e782bb7644207dc00e03ae3e. Revisión del 31 de octubre de 2026, hora de Santo Domingo.

## Hallazgo de recetas

La usuaria que reportó el problema tenía contraseña y recetario, pero cero ingredientes. «+ Ingrediente» elige registros del catálogo; con el catálogo vacío solo aparecía un aviso general y parecía no responder. La administradora tenía ingredientes pero ningún recetario. La otra usuaria tenía pendiente crear contraseña. No se encontró una denegación de permisos en el guardado.

Ahora Nueva receta muestra pasos visibles cuando falta catálogo o recetario, con acceso a Registrar ingrediente y al formulario de recetario. Al completar ambos requisitos aparece el formulario habitual. No se crean datos de ejemplo ni se alteran recetas existentes.

## Base de producción: pruebas realizadas

Se inspeccionaron las tres funciones reales de recetas y su permiso de ejecución, tablas y restricciones. Se ejecutó una transacción bajo ROLE authenticated con los identificadores de las tres cuentas aprobadas. Cada operación de esta tabla pasó para administradora, usuaria A y usuaria B:

| Operación | Resultado en las tres cuentas |
| --- | --- |
| Crear ingrediente y editar precio conservando stock | Pasó |
| Crear y editar material | Pasó |
| Crear y editar recetarios | Pasó |
| Guardar receta, líneas y verificar costo | Pasó |
| Asignar receta a otro recetario propio | Pasó |
| Guardar decoración | Pasó |
| Guardar cotización | Pasó |
| Guardar venta | Pasó |
| Leer registros propios y no leer ajenos | Pasó |

La transacción terminó en ROLLBACK. El resultado fue OK y no se conservaron registros transitorios. No se modificaron políticas, contraseñas ni permisos. Esto verifica la autorización de la base; no inicia sesión ni consume invitaciones de esas personas.

## Interfaz y servicios

- Se abrieron las pantallas oficiales de Ingredientes, Materiales, Recetas, Decoraciones, Cotizador, Ventas, Respaldo, Herramientas, Solicitudes y Personas con acceso con la sesión administradora, sin errores de carga. La ficha desplegable y el estado actualizado de contraseña se comprobaron después de publicar PR9 y desplegar account-access.
- Pruebas sobre manejadores reales de App con componentes y remotos simulados recorren tres roles: catálogo vacío, acceso a Ingredientes, alta de ingrediente y recetario, añadir ingrediente y guardar receta, materiales, decoración, cotización de Encargos, venta, Herramientas, respaldo y cierre de sesión. Cada guardado conserva el propietario correcto.
- Las regresiones de catálogo y cuentas con sustituto de Supabase verificaron proveedores, presentaciones, precios sin alterar stock/IDs, empaques, error remoto, controles administrativos y exclusión de datos privados. No enviaron correos.
- npm test: 23 grupos correctos. npm run build correcto.
- QA local de componentes reales: las once guías abren y muestran su ejemplo; Registrar ingrediente navega al módulo correcto. Revisión visual en escritorio y 390 × 844.

## Límites

No se utilizaron sesiones ni contraseñas de las usuarias: no se certifican sus navegadores particulares. La cuenta con activación pendiente debe crear contraseña antes de entrar. Administración permanece exclusiva de la administradora. El cotizador sigue limitado a Encargos.

Inventario operativo, producción, restauración de respaldos y edición profesional de recetas siguen pendientes según el plan. La corrección de costos incompletos permanece en PR8 independiente.

## Ayuda por módulo

Once guías en «¿Cómo se usa?», con pasos, ejemplo y límites reales. Cerradas inicialmente y reiniciadas al cambiar de pantalla; disponibles aunque falle la carga comercial. Las guías administrativas solo se muestran a la administradora. Texto completo en GUIA_DE_USO.md. Sin tablas, dependencias o permisos nuevos.

## Eliminar ingredientes

Botón solo en Ingredientes, con confirmación y cancelación dentro de la lista. El borrado remoto filtra por ID, cuenta y tipo ingrediente y exige el ID de la fila eliminada antes de actualizar React. Se bloquean referencias en recetas guardadas o en el borrador; las claves foráneas reales sin cascada también rechazan referencias de recetas, compras y movimientos. Los errores no retiran el ingrediente de la lista. No se amplían permisos ni se cambia RLS.

Se verificó en una transacción reversible para las tres cuentas que un fixture propio libre se elimina, uno usado conserva ingrediente/receta/líneas y no se puede eliminar un fixture ajeno. Final ROLLBACK confirmado. No se eliminó ningún ingrediente real de las usuarias. Pruebas locales cubren confirmación, cancelación, errores, propiedad, tipo, borrador y actualización solo después de confirmación remota.
