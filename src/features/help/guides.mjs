export const MODULE_GUIDES = {
  "Inicio": {
    "title": "Tu punto de partida",
    "steps": [
      "En computadora, usa el menú lateral. En celular, usa los accesos inferiores o pulsa Más para ver todos los módulos.",
      "Empieza por Ingredientes y registra tus compras con su precio y unidad.",
      "Pulsa Crear receta para abrir Recetas. Desde Tu recetario puedes abrir una receta guardada y consultar su ficha.",
      "Usa el Cotizador para encargos y registra tus ventas cuando las realices."
    ],
    "example": "Puedes tener un recetario «Galletas para apps» y otro «Postres por encargo».",
    "tip": "Cada cuenta tiene su propio espacio. Cierra sesión cuando termines en un equipo compartido."
  },
  "Ingredientes": {
    "title": "Registra lo que usas para cocinar",
    "steps": [
      "Escribe el nombre y dónde lo compraste.",
      "Coloca el precio total pagado y la cantidad de esa compra.",
      "Selecciona la unidad: g, kg, lb, ml u otra disponible.",
      "Pulsa Guardar ingrediente. Después podrás elegirlo al armar una receta. Para borrar un registro, pulsa Eliminar y confirma en la misma pantalla."
    ],
    "example": "Si compraste 1 kg de harina por RD$150, coloca precio 150, cantidad 1 y unidad kg.",
    "tip": "No se puede eliminar un ingrediente usado en recetas, compras o movimientos. Editar actualiza ese registro. Otro proveedor crea una variante independiente para conservar su precio. No cambies gramos por mililitros: requieren una equivalencia del ingrediente."
  },
  "Materiales": {
    "title": "Añade empaques y consumibles",
    "steps": [
      "Registra cajas, bases, bolsas u otros materiales.",
      "Indica el proveedor, precio total, cantidad comprada y unidad.",
      "Guarda el material. Usa Editar para actualizarlo u Otro proveedor para una variante.",
      "En el Cotizador, selecciona cuántos materiales llevará el encargo."
    ],
    "example": "Un paquete de 10 cajas por RD$200: precio 200, cantidad 10 y unidad unidad. Cada caja costará RD$20.",
    "tip": "No repitas el mismo empaque en Materiales y en Otros gastos de empaque de la cotización."
  },
  "Recetas": {
    "title": "Arma una receta paso a paso",
    "steps": [
      "Para traer una receta que ya tienes, pulsa Importar PDF, carga un archivo con texto y pulsa Revisar receta.",
      "Comprueba nombre, preparación, rendimiento e ingredientes. Los nombres incompletos muestran opciones de tu catálogo con proveedor y precio; elige la que usaste.",
      "Si falta un ingrediente, pulsa Registrar ingrediente para esa línea. Indica nombre, proveedor, precio total, cantidad comprada y unidad. Guardar ingrediente y vincular conserva la cantidad que usa la receta.",
      "Si aún no tienes recetario, pulsa Crear recetario aquí, escribe su nombre y elige Encargos, Apps de envío o Uso general.",
      "Al terminar la revisión, pulsa Guardar receta importada. Registrar ingredientes o recetarios no guarda todavía la receta.",
      "Para crear una receta manualmente, registra primero sus ingredientes en Ingredientes.",
      "Crea un recetario con nombre y uso: Encargos, Apps de envío o Uso general. Dentro de él, escribe una categoría como Masas, Rellenos, Coberturas o una nueva. Usa el filtro de categorías para organizar la lista.",
      "Completa nombre, recetario, rendimiento total, unidad y tipo de artículo.",
      "Pulsa + Ingrediente, elige uno de tu catálogo y escribe su cantidad y unidad. Repite por cada ingrediente.",
      "Pulsa Guardar receta. Usa los filtros para encontrarla por uso o recetario.",
      "Para cambiar una receta guardada, pulsa Editar receta. Ajusta los campos y sus ingredientes y pulsa Guardar cambios de receta. Cancelar edición conserva la receta anterior.",
      "Busca por nombre y combina los filtros de uso y recetario. Abre Ver ingredientes y costos para consultar cantidades, proveedor y costo por unidad de rendimiento sin editar.",
      "Para escribir la preparación, guarda primero la receta y pulsa Editar receta. Completa Pasos de preparación y guarda los cambios. Luego podrás leerlos en Ver ingredientes y costos.",
      "Para borrar una receta, pulsa Eliminar receta, revisa su nombre y confirma Sí, eliminar receta. Cancelar eliminación la conserva. El borrado es definitivo; sus ingredientes del catálogo y cotizaciones guardadas se conservan."
    ],
    "example": "Si la mezcla produce 12 galletas, el rendimiento es 12 y la unidad es unidad. Las cantidades de ingredientes corresponden a toda esa mezcla.",
    "tip": "Si + Ingrediente no tiene opciones, falta registrar ingredientes. El costo utiliza el precio vigente del proveedor elegido. Si aparece Costo incompleto, revisa el precio, la cantidad y las unidades indicadas. Solo los recetarios de Encargos aparecen en el Cotizador. Si otra sesión modificó la receta, cancela la edición y vuelve a abrirla para revisar la versión más reciente antes de guardar. Los ingredientes y recetarios creados durante la importación permanecen guardados aunque canceles la receta. La cantidad de compra es distinta de la cantidad usada en la receta; no se convierten tazas a gramos automáticamente."
  },
  "Decoraciones": {
    "title": "Prepara tu catálogo de decoraciones",
    "steps": [
      "Escribe el nombre de la decoración y elige su tipo.",
      "Coloca el costo por una unidad y guarda.",
      "En el Cotizador, selecciona la cantidad que llevará el encargo."
    ],
    "example": "Si cada topper cuesta RD$50, registra 50 como costo por unidad. Dos toppers sumarán RD$100.",
    "tip": "Aquí registras el costo de la decoración; el precio de venta se calcula en el Cotizador."
  },
  "Cotizador": {
    "title": "Calcula un encargo",
    "steps": [
      "Elige un recetario de Encargos y luego una receta.",
      "Indica cuántos rendimientos completos de esa receta necesitas.",
      "Agrega materiales, decoraciones, mano de obra y otros gastos.",
      "Elige Margen sobre venta o Recargo sobre costo y su porcentaje.",
      "Revisa el costo y el precio sugerido; después pulsa Guardar cotización."
    ],
    "example": "Si tu receta rinde 12 galletas y necesitas 24, coloca 2 en Cantidad de rendimientos.",
    "tip": "Las recetas de Apps de envío no aparecen aquí. Si no hay opciones, crea un recetario de Encargos y asigna la receta. Margen y recargo son métodos distintos. No podrás guardar una cotización si la receta muestra Costo incompleto."
  },
  "Ventas": {
    "title": "Registra una venta real",
    "steps": [
      "Selecciona la fecha y el canal de venta.",
      "Escribe una descripción y el monto bruto vendido.",
      "Indica la comisión en porcentaje, el costo de producción y otros gastos.",
      "Pulsa Registrar venta y revisa la ganancia estimada de la lista."
    ],
    "example": "Una venta de RD$100 con comisión 10%, costo de producción RD$50 y otros gastos RD$5 deja una ganancia estimada de RD$35.",
    "tip": "El costo de producción se introduce manualmente. Registrar una venta no descuenta ingredientes ni genera una producción automáticamente."
  },
  "Respaldo": {
    "title": "Descarga una copia de tus registros",
    "steps": [
      "Espera a que terminen de cargar tus datos.",
      "Pulsa Descargar respaldo JSON.",
      "Guarda el archivo en una carpeta que puedas encontrar después."
    ],
    "example": "Puedes conservar una copia antes de reorganizar tus recetarios.",
    "tip": "La restauración todavía no está disponible. El archivo no es una copia completa de Supabase y no incluye los favoritos y calibraciones locales de Herramientas. Para usar otro dispositivo, inicia sesión con tu misma cuenta."
  },
  "Herramientas": {
    "title": "Convierte una medida rápidamente",
    "steps": [
      "En la calculadora de recetas, elige hasta tres recetas. Indica cuánto rinde cada receta completa y usa ×2, ½, ¼ o una cantidad final deseada.",
      "Consulta cada ingrediente ajustado y la suma total. El mismo ingrediente de proveedores distintos conserva cantidades separadas.",
      "Para Apps, puedes guardar una porción o la combinación completa como receta nueva. Indica su rendimiento (por ejemplo seis bandejas), categoría y recetario de destino. La fórmula original se conserva.",
      "Elige Temperatura, Peso, Líquidos o Ingredientes.",
      "Escribe la cantidad y selecciona las unidades De y A.",
      "Lee el resultado. Puedes intercambiar las unidades o copiarlo.",
      "Abre las opciones de abajo solo si necesitas favoritos, medidas propias o usar cantidades de una receta."
    ],
    "example": "En Temperatura, 180 °C equivalen a 356 °F. En Ingredientes, elige cuál estás midiendo: una taza de harina no pesa lo mismo que una de azúcar.",
    "tip": "Las equivalencias de ingredientes pueden ser aproximadas. Favoritos y medidas propias se guardan solo en este dispositivo, separados por cuenta. No hace falta conectar una receta para convertir."
  },
  "Solicitudes": {
    "title": "Revisa las solicitudes nuevas",
    "adminOnly": true,
    "steps": [
      "Lee los datos del dueño y del negocio.",
      "Pulsa Aprobar y crear cuenta si autorizas el acceso, o Rechazar solicitud.",
      "Las solicitudes resueltas salen de esta lista. Las aprobadas aparecen en Personas con acceso."
    ],
    "example": "Una cuenta aprobada recibe por correo su enlace personal para crear su contraseña.",
    "tip": "Solo la administradora ve este módulo. La persona debe abrir la invitación más reciente dentro de una hora; no necesita compartirte su contraseña."
  },
  "Personas con acceso": {
    "title": "Consulta quién puede ingresar",
    "adminOnly": true,
    "steps": [
      "Revisa la lista de personas aprobadas y el estado de su contraseña.",
      "Abre Ver información del negocio para consultar el formulario de esa persona.",
      "Si falta crear la contraseña y el enlace venció, pulsa Reenviar invitación.",
      "Pídele abrir el correo más reciente y guardar su contraseña de al menos 12 caracteres."
    ],
    "example": "Contraseña configurada significa que la persona completó ese paso. Falta crear su contraseña indica que aún necesita activarla.",
    "tip": "La ficha muestra los datos recibidos; No proporcionado indica que ese campo no se completó. Cada persona conserva su espacio privado. Las funciones administrativas no se comparten con usuarios normales."
  }
};
