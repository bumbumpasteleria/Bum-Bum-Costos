# Plan vigente de Bum Bum Costos

Revisión del 2 de noviembre de 2026. Este documento distingue el estado actual de las notas históricas de auditoría. El plan original pide entregas progresivas, sin fusionar ni publicar sin aprobación.

## Entrega preparada en PR24

- Renovación Dulce y visual e icono BB con melocotón, manteniendo el logo del negocio en cotizaciones.
- Áreas independientes Recetarios, Nueva receta y Costos de productos; recetas visibles solo dentro de su libro, con edición en su ficha.
- Revisión automática al leer PDF/foto, creación de ingredientes durante importación y selección explícita de coincidencias/proveedores.
- Materiales en las fórmulas, cotizaciones completas, presentación privada del negocio y precios por canal con comisión y margen.
- Equivalencias propias de unidades/líquidos a gramos; conservación de gramos en recetas y descuento de unidades/ml al producir, con operación atómica e idempotente.
- Fichas privadas de costo final por producto, mano de obra y gastos adicionales, con versiones y respaldos. Traslado explícito de costos por unidad a precios de venta.
- Guías actualizadas. Validación con cuentas ficticias; no se usaron contraseñas ni se alteraron datos reales de las usuarias.

Está implementado en la rama, aún no publicado. Requiere aplicar las dos migraciones de esta entrega y publicar la interfaz después de la aprobación.

## Funciones existentes que deben conservarse

Acceso aprobado y perfiles privados, personas con acceso, ingredientes por proveedor, materiales, edición/eliminación con referencias protegidas, recetarios por uso, cotizador de Encargos, escalado y combinación de recetas, conversiones con referencias, borradores por cuenta, compras por mínimos, inventario, Mi nevera, lotes, ventas, producción pendiente, gastos, pedidos/anticipos, reportes financieros y de ventas en PDF, respaldos y versiones de recetas.

La existencia de estas funciones no certifica cada dispositivo de cada usuaria. Se siguen verificando mediante pruebas y flujos de revisión sin acceder a sesiones ajenas.

## Próximas entregas del plan original

1. Formulación profesional: moldes, tiempos y temperaturas estructurados, merma y rendimiento, referencias entre subrecetas con historial seguro. La combinación actual genera una copia escalada, no un vínculo dinámico de fórmulas.
2. Herramientas técnicas: adaptación entre moldes, porcentajes panaderos/hidratación/prefermentos, rendimiento, porciones, concentraciones y temporizadores. Las equivalencias culinarias sin fuente verificada exigirán calibración; no se inventarán densidades.
3. Inventario detallado: lotes y vencimientos de materias primas, historial de compras/precios y movimientos, mermas y ajustes documentados. Los lotes de producto terminado ya existen.
4. Gestión comercial: directorio de clientes y proveedores reutilizable, referencias visuales de encargos, calendario y órdenes de trabajo con ingredientes consolidados. La agenda actual de pedidos es una lista filtrable por fecha, no un calendario completo.
5. Finanzas ampliadas: cuentas por cobrar vinculadas a cobros reales, flujo de caja separado de utilidad, compras y gastos sin duplicación, comparaciones mensuales y rentabilidad por producto. No confundir el valor del inventario con efectivo disponible.
6. Control de calidad y configuración de perfiles Pastelería/Panadería/Mixto, con criterios definidos por el negocio, sin inferir inocuidad ni fechas de consumo seguras.

Cada entrega incluirá guía, pruebas de cálculo y permisos, revisión visual móvil/escritorio y PR. Los cambios de base de datos se probarán en transacciones reversibles antes de su aplicación permanente. No se sustituye una función existente por una maqueta ni se marca como completada una función solo documentada.
