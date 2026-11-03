# Plan vigente de Bum Bum Costos

Revisión del 2 de noviembre de 2026. Este documento distingue el estado actual de las notas históricas de auditoría. El plan original pide entregas progresivas, sin fusionar ni publicar sin aprobación.

## Entrega publicada en PR24

- Renovación Dulce y visual e icono BB con melocotón, manteniendo el logo del negocio en cotizaciones.
- Áreas independientes Recetarios, Nueva receta y Costos de productos; recetas visibles solo dentro de su libro, con edición en su ficha.
- Revisión automática al leer PDF/foto, creación de ingredientes durante importación y selección explícita de coincidencias/proveedores.
- Materiales en las fórmulas, cotizaciones completas, presentación privada del negocio y precios por canal con comisión y margen.
- Equivalencias propias de unidades/líquidos a gramos; conservación de gramos en recetas y descuento de unidades/ml al producir, con operación atómica e idempotente.
- Fichas privadas de costo final por producto, mano de obra y gastos adicionales, con versiones y respaldos. Traslado explícito de costos por unidad a precios de venta.
- Guías actualizadas. Validación con cuentas ficticias; no se usaron contraseñas ni se alteraron datos reales de las usuarias.

Publicada con aprobación de la usuaria el 2 de noviembre de 2026. Ambas migraciones aplicadas, PR24 fusionado y Cloudflare producción correcto. Comprobadas las áreas Recetarios y Costos de productos en la aplicación oficial.

## Funciones existentes que deben conservarse

Acceso aprobado y perfiles privados, personas con acceso, ingredientes por proveedor, materiales, edición/eliminación con referencias protegidas, recetarios por uso, cotizador de Encargos, escalado y combinación de recetas, conversiones con referencias, borradores por cuenta, compras por mínimos, inventario, Mi nevera, lotes, ventas, producción pendiente, gastos, pedidos/anticipos, reportes financieros y de ventas en PDF, respaldos y versiones de recetas.

La existencia de estas funciones no certifica cada dispositivo de cada usuaria. Se siguen verificando mediante pruebas y flujos de revisión sin acceder a sesiones ajenas.

## Herramientas publicadas en PR25

Adaptación entre moldes, porcentajes panaderos y rendimiento medido, con borradores privados por cuenta y dispositivo. Publicadas con aprobación y verificadas en el enlace oficial.

## Entrega integral en revisión

Los seis bloques solicitados están implementados en esta entrega: fichas profesionales y subrecetas vinculadas; temporizadores; compras, lotes y movimientos de materias primas; directorios, calendario y órdenes de trabajo; caja, cobros y rentabilidad; controles de calidad y perfiles de negocio. Véase OPERACION_INTEGRAL.md para los flujos y límites concretos.

La validación incluye pruebas automatizadas, operaciones reversibles en Supabase con cuentas ficticias, revisión de los nuevos flujos y PDF. La publicación permanente requiere aprobar conjuntamente la migración y el PR. No se marca esta entrega como publicada antes de verificar producción.
