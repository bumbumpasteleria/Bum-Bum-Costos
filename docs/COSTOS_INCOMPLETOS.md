# Costos incompletos antes de cotizar

Integración sobre main 7686d588a4264a0903a19b6c7839cceaf28e4c76, conservando las guías, la ayuda de recetas, perfiles y eliminación de ingredientes. Publicación autorizada por la usuaria al continuar con el punto 1.

El evaluador devuelve total nulo y una explicación si falta ingrediente, precio, cantidad o una unidad compatible. Una receta vacía también está incompleta. Un precio cero explícito sigue siendo válido. El adaptador conserva el precio nulo de Supabase en lugar de transformarlo en cero.

Recetas muestra «Costo incompleto» y qué revisar. Cotizador oculta costo total, precio sugerido y ganancia estimada cuando no se puede calcular. El botón y su manejador impiden guardar una cotización incompleta. También se valida la cantidad y se rechazan importes no finitos. Las cotizaciones ya guardadas no se recalculan ni se modifican.

Se conservan factores de unidades, precio vigente, margen/recargo, escalado fijo y selección de recetarios de Encargos. No se cambian tablas, permisos, políticas, datos ni dependencias.

Validación: 36 grupos de pruebas, incluidos recorridos de la interfaz con servicios/componentes simulados para tres roles, bloqueo de cotización incompleta incluso al invocar el manejador, precio cero explícito, cantidades vacías, factores, unidades, datos inválidos, error remoto, eliminación y avisos de acceso. Compilación correcta. No se guardaron cotizaciones reales ni se alteraron ingredientes productivos para provocar errores.

La renovación visual solicitada queda en PENDIENTES_DISENO.md. Esta corrección completa el punto 1 de pendientes inmediatos, no toda la consolidación técnica del plan general.
