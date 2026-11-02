export const MODULE_GUIDES = {
  "Inicio": {
    "title": "Tu punto de partida",
    "steps": [
      "En computadora, usa el menú lateral. En celular, usa los accesos inferiores o pulsa Más para ver todos los módulos.",
      "Empieza por Ingredientes y registra tus compras con su precio y unidad.",
      "Pulsa Crear receta para abrir Nueva receta. En Mis recetarios abre el libro que quieras consultar; sus recetas se muestran dentro. Costear un producto abre el área de costos finales.",
      "Usa el Cotizador para encargos y registra tus ventas cuando las realices.",
      "El borrador de trabajo se conserva al cambiar de módulo o recargar, en este dispositivo y para esta cuenta. Guardar confirma el registro en la nube; cancelar o limpiar descarta el formulario correspondiente.",
      "Abre Finanzas para gastos y reportes; Pedidos para encargos; Respaldo para recuperar registros o versiones de recetas."
    ],
    "example": "Puedes tener un recetario «Galletas para apps» y otro «Postres por encargo».",
    "tip": "Cada cuenta tiene su propio espacio. Cierra sesión cuando termines en un equipo compartido. Los borradores no se sincronizan entre dispositivos. No guardamos contraseñas ni el archivo PDF como borrador."
  },
  "Ingredientes": {
    "title": "Registra lo que usas para cocinar",
    "steps": [
      "Escribe el nombre y dónde lo compraste.",
      "Coloca el precio total pagado y la cantidad de esa compra. Es el precio de compra, no el precio de venta del postre.",
      "Selecciona la unidad: gramos, Kilos (kg), libras, mililitros o Galón estadounidense (3.785 L), entre otras. Un galón equivale exactamente a 3785.411784 ml.",
      "Pulsa Guardar ingrediente. Abre Ver ingredientes registrados para ver la lista; vuelve a pulsar para cerrarla. La lista empieza cerrada. Después podrás elegirlo al armar una receta. Para borrar un registro, pulsa Eliminar y confirma en la misma pantalla.",
      "El borrador de trabajo se conserva al cambiar de módulo o recargar, en este dispositivo y para esta cuenta. Guardar confirma el registro en la nube; cancelar o limpiar descarta el formulario correspondiente.",
      "Para usar gramos de un ingrediente comprado por unidades o volumen, abre Usar este artículo en gramos. Indica cantidad y unidad de referencia y cuánto pesa en gramos: por ejemplo, 1 unidad pesa 50 g o 100 ml pesan 103 g. Guarda el ingrediente. La equivalencia es propia de ese artículo y proveedor; al crear otro proveedor debes medir y registrar la suya."
    ],
    "example": "Si compraste 1 kg de harina por RD$150, coloca precio 150, cantidad 1 y unidad kg.",
    "tip": "No se puede eliminar un ingrediente usado en recetas, compras o movimientos. Editar actualiza ese registro. Otro proveedor crea una variante independiente para conservar su precio. No cambies gramos por mililitros: requieren una equivalencia del ingrediente. Los borradores no se sincronizan entre dispositivos. No guardamos contraseñas ni el archivo PDF como borrador."
  },
  "Materiales": {
    "title": "Añade empaques y consumibles",
    "steps": [
      "Registra cajas, bases, bolsas u otros materiales.",
      "Indica el proveedor, precio total de compra, cantidad comprada y unidad. El costo por material se calcula desde esa compra.",
      "Guarda el material. Abre Ver materiales registrados para desplegar la lista y vuelve a pulsar para cerrarla. La lista empieza cerrada. Usa Editar para actualizarlo u Otro proveedor para una variante.",
      "En el Cotizador, selecciona cuántos materiales llevará el encargo.",
      "El borrador de trabajo se conserva al cambiar de módulo o recargar, en este dispositivo y para esta cuenta. Guardar confirma el registro en la nube; cancelar o limpiar descarta el formulario correspondiente."
    ],
    "example": "Un paquete de 10 cajas por RD$200: precio 200, cantidad 10 y unidad unidad. Cada caja costará RD$20.",
    "tip": "No repitas el mismo empaque en Materiales y en Otros gastos de empaque de la cotización. Los borradores no se sincronizan entre dispositivos. No guardamos contraseñas ni el archivo PDF como borrador."
  },
  "Recetas": {
    "title": "Consulta tus recetas dentro de sus recetarios",
    "steps": [
      "Al entrar aparecen tus recetarios. Pulsa Abrir recetario junto al nombre que quieras usar. Las recetas no se muestran fuera de su libro.",
      "Para crear uno, pulsa + Crear o gestionar recetarios, escribe nombre y uso y pulsa Crear recetario. Dentro de un recetario, Editar este recetario permite cambiar nombre o uso. Solo puedes eliminar recetarios vacíos; mueve sus recetas antes de confirmar el borrado.",
      "Dentro del recetario, pulsa Ver recetas del recetario. Puedes buscar por nombre y filtrar por categoría dentro de ese libro.",
      "Pulsa Abrir receta junto al nombre. Dentro están la consulta de ingredientes y costos básicos, foto y notas, Asignar recetario, Editar receta y Eliminar receta. La edición aparece dentro de esa misma ficha.",
      "Guardar cambios de receta conserva su ID y las cotizaciones anteriores. Si otra sesión modificó la receta, vuelve a abrirla antes de guardar. Cancelar edición conserva la versión guardada.",
      "Para mover una receta, elige otro recetario dentro de su ficha y pulsa Asignar recetario. Para eliminar, revisa el nombre y confirma. Puede bloquearse si hay referencias; el catálogo y cotizaciones anteriores se conservan.",
      "Para ingresar otra, pulsa Agregar receta a este recetario: abre el área Nueva receta con el destino seleccionado. Allí puedes subir PDF/foto o escribirla.",
      "Para sumar mano de obra y gastos, pulsa Calcular costo final de la receta. Se abrirá Costos de productos con ese artículo seleccionado.",
      "En Foto, conservación y notas guarda tu fotografía para las portadas. Sin foto se muestra una imagen de referencia identificada. Las indicaciones de conservación y alérgenos las completas tú."
    ],
    "example": "Si la mezcla produce 12 galletas, el rendimiento es 12 y la unidad es unidad. Las cantidades de ingredientes corresponden a toda esa mezcla.",
    "tip": "Si + Ingrediente no tiene opciones, falta registrar ingredientes. El costo utiliza el precio vigente del proveedor elegido. Si aparece Costo incompleto, revisa el precio, la cantidad y las unidades indicadas. Solo los recetarios de Encargos aparecen en el Cotizador. Si otra sesión modificó la receta, cancela la edición y vuelve a abrirla para revisar la versión más reciente antes de guardar. Los ingredientes y recetarios creados durante la importación permanecen guardados aunque canceles la receta. La cantidad de compra es distinta de la cantidad usada en la receta; no se convierten tazas a gramos automáticamente. Los borradores no se sincronizan entre dispositivos. No guardamos contraseñas ni el archivo PDF como borrador. Los alérgenos e indicaciones los completas tú; la aplicación no los deduce. En Respaldo puedes consultar las versiones anteriores guardadas desde esta actualización."
  },
  "Decoraciones": {
    "title": "Prepara tu catálogo de decoraciones",
    "steps": [
      "Escribe el nombre de la decoración y elige su tipo.",
      "Coloca el costo por una unidad y guarda.",
      "En el Cotizador, selecciona la cantidad que llevará el encargo.",
      "El borrador de trabajo se conserva al cambiar de módulo o recargar, en este dispositivo y para esta cuenta. Guardar confirma el registro en la nube; cancelar o limpiar descarta el formulario correspondiente."
    ],
    "example": "Si cada topper cuesta RD$50, registra 50 como costo por unidad. Dos toppers sumarán RD$100.",
    "tip": "Aquí registras el costo de la decoración; el precio de venta se calcula en el Cotizador. Los borradores no se sincronizan entre dispositivos. No guardamos contraseñas ni el archivo PDF como borrador."
  },
  "Cotizador": {
    "title": "Calcula un encargo",
    "steps": [
      "Elige un recetario de Encargos y luego una receta.",
      "Indica cuántos rendimientos completos de esa receta necesitas.",
      "Revisa los ingredientes y materiales incluidos en la receta. Añade solo los materiales adicionales del encargo, decoraciones, mano de obra fija o por horas, rellenos adicionales, entrega y otros gastos.",
      "Elige Margen sobre venta o Recargo sobre costo y su porcentaje.",
      "Abre Logo y presentación de mi negocio, sube tu logo, elige el color y guarda nombre y contacto. Un PNG con transparencia conserva el fondo transparente para integrarlo en la cotización. La cuenta de Bum Bum ya tiene precargados su logo original y la paleta crema, vino y rosa; las demás cuentas conservan su propia identidad. Se conserva en tu cuenta y se aplica a los PDF que generes. Completa cliente, contacto, entrega, validez y notas si los necesitas. Revisa el desglose de artículos y costos y pulsa Guardar cotización. En cotizaciones guardadas, abre Ver cotización completa. PDF para cliente muestra el producto y precio final; PDF interno con costos incluye desglose y ganancia.",
      "El borrador de trabajo se conserva al cambiar de módulo o recargar, en este dispositivo y para esta cuenta. Guardar confirma el registro en la nube; cancelar o limpiar descarta el formulario correspondiente."
    ],
    "example": "Si tu receta rinde 12 galletas y necesitas 24, coloca 2 en Cantidad de rendimientos.",
    "tip": "Las recetas de Apps de envío no aparecen aquí. Si no hay opciones, crea un recetario de Encargos y asigna la receta. Margen y recargo son métodos distintos. No podrás guardar una cotización si la receta muestra Costo incompleto. Los borradores no se sincronizan entre dispositivos. No guardamos contraseñas ni el archivo PDF como borrador."
  },
  "Ventas": {
    "title": "Registra una venta real",
    "steps": [
      "Elige Venta general o encargo para registrar los importes habituales, o Producto de Mi nevera para descontar porciones o unidades.",
      "Para nevera, selecciona producto y cantidad vendida. El precio de venta registrado se propone automáticamente y el total se calcula como cantidad × precio. Puedes ajustar ese precio para esta venta sin cambiar el producto. Completa fecha, canal, comisión y otros gastos.",
      "Pulsa Registrar venta. El guardado y el descuento son una sola operación: si no hay suficientes productos vigentes, no se registra ninguno de los dos.",
      "Las ventas generales requieren que indiques su costo de producción. Las ventas de nevera toman el costo de ingredientes y materiales de los lotes consumidos. Seleccionar el canal propone su precio, comisión y gastos adicionales guardados; los gastos por unidad se multiplican por la cantidad vendida. Puedes corregirlos para esta venta.",
      "En Reportes de ventas puedes filtrar por fecha o canal y descargar un PDF. En Finanzas registra los gastos adicionales del negocio."
    ],
    "example": "Una venta de RD$100 con comisión 10%, costo de producción RD$50 y otros gastos RD$5 deja una ganancia estimada de RD$35.",
    "tip": "Registra tus ventas diarias. Los lotes vencidos no se venden. Si se interrumpe la conexión, el formulario se conserva; reintentar el mismo registro evita duplicar la venta de nevera."
  },
  "Respaldo": {
    "title": "Copia y recupera tus registros",
    "steps": [
      "Descarga un respaldo JSON completo desde tu cuenta. Incluye fotos, gastos, pedidos, nevera e historiales; no contiene contraseñas.",
      "Para recuperar, selecciona el archivo de esta misma cuenta y revisa las cantidades por colección antes de confirmar.",
      "La recuperación añade registros que faltan y conserva los actuales. No reemplaza precios o existencias ya registrados. Las líneas de receta se recuperan junto con una receta ausente completa.",
      "Las copias antiguas se convierten para revisión. Si no guardaban inventario, se señala que las cantidades deben contarse de nuevo; no incluyen módulos creados después de esa copia.",
      "En Versiones de recetas puedes revisar y recuperar una versión anterior. Desde esta actualización, editar o eliminar conserva versiones. Confirma la recuperación solo después de revisarla."
    ],
    "example": "Si eliminaste una receta y tienes una copia, puedes recuperarla sin reemplazar tus ventas ni ingredientes actuales.",
    "tip": "Conserva las copias en un lugar privado. Límite por archivo: 25 MB. La restauración es una sola operación: ante un error, no se confirma parcialmente. Para recuperar una versión de receta deben seguir disponibles su recetario e ingredientes."
  },
  "Herramientas": {
    "title": "Convierte medidas y planifica tu preparación",
    "steps": [
      "En Planifica tu preparación, abre Moldes, Panificación o Rendimiento. Cada herramienta se abre por separado y conserva su borrador en este dispositivo para tu cuenta.",
      "En Moldes, indica forma, medidas interiores en cm, altura útil, llenado en porcentaje y cantidad, tanto del origen como del destino. El resultado es un factor geométrico. Para aplicarlo, usa ese factor en Ajustar o combinar recetas. No convierte volumen de molde a gramos ni modifica la receta.",
      "En Panificación, escribe nombres y gramos; clasifica todas las harinas y el agua. La suma de harinas es 100 %. Indica el peso de masa deseado para obtener los gramos ajustados de cada ingrediente. Leche y huevos van en Otros, sin suponer su contenido de agua. Para un prefermento, separa su harina y agua sin repetir el peso total.",
      "En Rendimiento, escribe peso inicial, peso final aprovechable y gramos por porción. Se muestran merma, rendimiento, porciones completas y sobrante. Incluye todas las adiciones en el peso inicial; no calcula una merma estándar ni registra movimientos de inventario.",
      "En la calculadora de recetas, elige hasta tres recetas. Indica cuánto rinde cada receta completa y usa ×2, ½, ¼ o una cantidad final deseada.",
      "Consulta cada ingrediente ajustado y la suma total. El mismo ingrediente de proveedores distintos conserva cantidades separadas.",
      "Para Apps, puedes guardar una porción o la combinación completa como receta nueva. Para encontrar el formulario, pulsa Ir a crear una receta combinada para Apps, después de elegir las recetas. Indica su rendimiento (por ejemplo seis bandejas), categoría y recetario de destino. La fórmula original se conserva.",
      "Elige Temperatura, Peso, Líquidos o Ingredientes.",
      "Escribe la cantidad y selecciona las unidades De y A.",
      "Lee el resultado. Puedes intercambiar las unidades o copiarlo.",
      "Abre las opciones de abajo solo si necesitas favoritos, medidas propias o usar cantidades de una receta.",
      "El borrador de trabajo se conserva al cambiar de módulo o recargar, en este dispositivo y para esta cuenta. Guardar confirma el registro en la nube; cancelar o limpiar descarta el formulario correspondiente."
    ],
    "example": "En Temperatura, 180 °C equivalen a 356 °F. En Ingredientes, elige cuál estás midiendo: una taza de harina no pesa lo mismo que una de azúcar.",
    "tip": "Las equivalencias de ingredientes pueden ser aproximadas. Favoritos y medidas propias se guardan solo en este dispositivo, separados por cuenta. No hace falta conectar una receta para convertir. Los borradores no se sincronizan entre dispositivos. No guardamos contraseñas ni el archivo PDF como borrador."
  },
  "Solicitudes": {
    "title": "Revisa las solicitudes nuevas",
    "adminOnly": true,
    "steps": [
      "Lee los datos del dueño y del negocio.",
      "Pulsa Aprobar y crear cuenta si autorizas el acceso, o Rechazar solicitud.",
      "Las solicitudes resueltas salen de esta lista. Las aprobadas aparecen en Personas con acceso.",
      "Usa Buscar en esta página por nombre, negocio, correo o ubicación. Filtra por estado y limpia los filtros para volver a ver todos los registros. La búsqueda corresponde a la página actual; usa Anterior o Siguiente para otras páginas."
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
      "Pídele abrir el correo más reciente y guardar su contraseña de al menos 12 caracteres.",
      "Usa Buscar en esta página por nombre, negocio, correo o ubicación. Filtra por estado y limpia los filtros para volver a ver todos los registros. La búsqueda corresponde a la página actual; usa Anterior o Siguiente para otras páginas."
    ],
    "example": "Contraseña configurada significa que la persona completó ese paso. Falta crear su contraseña indica que aún necesita activarla.",
    "tip": "La ficha muestra los datos recibidos; No proporcionado indica que ese campo no se completó. Cada persona conserva su espacio privado. Las funciones administrativas no se comparten con usuarios normales."
  },
  "Inventario": {
    "title": "Lo que tienes para preparar",
    "steps": [
      "Revisa cada ingrediente y material, separado por proveedor.",
      "Pulsa Actualizar existencias e indica la cantidad disponible y el mínimo para reponer. Selecciona la unidad compatible que prefieras, por ejemplo kilos o galones; se guarda su equivalencia en la unidad base. Cero es válido.",
      "Guarda existencias. La lista de Compras se actualiza inmediatamente. Si otra sesión cambió cantidades, actualiza y revisa el ajuste antes de guardarlo.",
      "Después de registrar producción en Mi nevera, las existencias de ingredientes y materiales se actualizan automáticamente. Cambiar o guardar una receta no descuenta inventario. Las cantidades pueden incluir fracciones de unidad cuando se utilizan por peso."
    ],
    "example": "Harina: quedan 500 g, mínimo 500 g. Aparece en Compras.",
    "tip": "El mínimo es la señal para reponer, no una cantidad de compra sugerida. Los precios se conservan; las ventas de nevera no descuentan ingredientes automáticamente."
  },
  "Compras": {
    "title": "Qué necesitas reponer",
    "steps": [
      "Aquí aparecen ingredientes y materiales con cantidad disponible igual o menor a su mínimo.",
      "Cada proveedor aparece por separado. Los artículos sin existencias o mínimo registrados requieren completarlos en Inventario.",
      "Cuando repongas, pulsa Actualizar existencias y registra la cantidad real. Al superar el mínimo, el artículo sale de Compras.",
      "Los consumos registrados al producir actualizan las existencias; si un artículo llega a su mínimo, aparece en esta lista."
    ],
    "example": "Si una caja tiene mínimo 5 y quedan 5 unidades, aparece pendiente; si registras 20, deja de aparecer.",
    "tip": "Esta lista se calcula desde tu inventario en la nube. No borres el artículo ni cambies su precio para marcarlo como comprado."
  },
  "Mi nevera": {
    "title": "Tus productos listos para vender",
    "steps": [
      "Añade un producto vinculado a una receta, selecciona si lo contarás por porción, unidad, bandeja, vaso o caja y define su mínimo y precio de venta por esa unidad. El precio es anterior a las comisiones. Pulsa Ver costo final y precios para abrir Costos de productos y configurar precios por canal.",
      "Registra una preparación terminada: producto, cantidad obtenida, veces que usaste la receta, fecha y vencimiento opcional.",
      "En Costos de productos, abre el cálculo de precios por canal y elige Directa, Uber Eats o PedidosYa. Revisa el costo base por unidad, añade únicamente empaques, mano de obra y gastos adicionales, e introduce la comisión real y margen deseado. Usa el precio sugerido o escribe otro y guarda el canal. Comisión y margen deben sumar menos de 100%. Consulta la cantidad disponible y abre Ver lotes, mínimo y precio. Los lotes vencidos se muestran, pero no cuentan como disponibles. Dentro de Ver lotes, mínimo y precio puedes actualizar el precio y el mínimo. Las ventas anteriores conservan sus importes; los productos antiguos no reciben un precio inventado.",
      "Para consumo propio, pérdidas o correcciones, usa Ajustar lote, indica cuánto queda y el motivo. Registra otro lote para nuevas preparaciones.",
      "En Ventas, elige Producto de Mi nevera y la cantidad vendida. La venta descuenta primero los lotes que vencen antes.",
      "La portada utiliza la foto guardada en la ficha de la receta vinculada. Si no hay foto, verás una imagen de referencia; las cantidades y estados siempre proceden de tus lotes.",
      "Registrar una preparación descuenta ingredientes y materiales del inventario en una sola operación. Las recetas en gramos se convierten con la equivalencia de cada artículo. Si faltan existencias, no se guarda el lote ni se descuenta nada. Repetir el mismo intento no descuenta dos veces. Los lotes anteriores conservan su costo y no se descuentan retroactivamente. Abre Ver ingredientes descontados dentro de un lote nuevo para consultar su consumo.",
      "Mi nevera se dedica a existencias, lotes, producción y precio registrado. La ficha completa con mano de obra y gastos se gestiona en Costos de productos."
    ],
    "example": "Una receta completa produce 12 porciones de tres leches: cantidad 12, veces 1. Vendes 3 y quedan 9.",
    "tip": "Cada cuenta tiene sus propios productos y lotes en la nube. Las fechas de vencimiento las decides tú. El costo del lote incluye ingredientes y materiales de la receta al producirlo; añade otros gastos de venta aparte. Los lotes conservan su costo aunque luego cambies precios."
  },
  "Producción": {
    "title": "Lo que necesitas volver a preparar",
    "steps": [
      "Consulta los productos preparados cuya disponibilidad llegó al mínimo definido en Mi nevera.",
      "Revisa el producto y registra una preparación terminada con su cantidad, receta utilizada y fechas.",
      "Al reponer por encima del mínimo, desaparece de los pendientes. Las ventas y los vencimientos pueden volver a incluirlo."
    ],
    "example": "Mínimo de tres leches: 3 porciones. Quedan 3; aparece Preparar más. Preparas 12 y queda repuesto.",
    "tip": "Esta pantalla refleja reposición de productos preparados. No registra producción ficticia ni descuenta ingredientes al abrirla."
  },
  "Finanzas": {
    "title": "Conoce el resultado de tu negocio",
    "steps": [
      "Selecciona Desde, Hasta y el canal. Hoy y Este mes preparan las fechas rápidamente.",
      "Revisa ventas brutas, comisiones, costo de producción, otros gastos de ventas y gastos del negocio.",
      "Registra gastos adicionales como alquiler, servicios o mantenimiento. No repitas ingredientes ni comisiones que ya estén incluidos en la venta.",
      "Usa Corregir para ajustar un gasto. Anular gasto pide confirmación y conserva su historial.",
      "Pulsa Descargar finanzas en PDF. El documento contiene el período, resumen y detalle, incluso si necesita varias páginas."
    ],
    "example": "Ventas por RD$1,000 menos comisiones, producción y gastos registrados dan el resultado del período.",
    "tip": "El resultado depende de datos completos; no equivale al efectivo disponible ni incluye gastos que no hayas registrado. Por canal se incluyen solo sus gastos asignados; los generales aparecen en Todos."
  },
  "Reportes de ventas": {
    "title": "Consulta y descarga tus ventas",
    "steps": [
      "Elige las fechas y el canal del reporte.",
      "Revisa el número de ventas, importes brutos, comisiones y costos registrados.",
      "Pulsa Descargar ventas en PDF para obtener el resumen y todas las ventas del período."
    ],
    "example": "Puedes descargar solo las ventas de PedidosYa de este mes.",
    "tip": "La descarga espera la carga de datos. Los registros con importes o fechas inválidos se señalan para revisión en pantalla y PDF."
  },
  "Pedidos": {
    "title": "Organiza tus encargos y entregas",
    "steps": [
      "Crea un pedido con cliente, contacto opcional, fecha, descripción, total y anticipo. Puedes tomar una cotización guardada como punto de partida.",
      "Vincula opcionalmente una receta de Encargos; las recetas exclusivas de Apps no se muestran en esta selección.",
      "Actualiza su estado: Pendiente, En preparación, Listo, Entregado o Cancelado.",
      "Busca por cliente o descripción y filtra la agenda por fecha y estado. Los entregados y cancelados se conservan en Todos."
    ],
    "example": "Un encargo de RD$2,000 con anticipo de RD$500 muestra RD$1,500 de saldo.",
    "tip": "Guardar el pedido no registra una venta ni descuenta productos de la nevera. Registra el ingreso real una sola vez en Ventas para evitar duplicados. El borrador se conserva en este dispositivo."
  },
  "Nueva receta": {
    "title": "Añade una receta a un recetario",
    "steps": [
      "Esta área es solo para ingresar recetas. Elige Recetario destino; si aún no tienes ninguno, crea uno aquí con nombre y uso.",
      "Elige Subir receta en PDF o foto o Escribir nueva receta. Las recetas actuales se consultan en Recetarios y no se mezclan con este formulario.",
      "Al subir un PDF o foto, se lee y aparece directamente la revisión. Comprueba nombre, rendimiento, preparación, cantidades, unidades y proveedor antes de Guardar receta importada. Puedes cancelar la revisión y corregir el texto reconocido.",
      "Se acepta una receta por archivo: PDF con texto o escaneado, JPG, PNG o WebP de hasta 10 MB. PDF: hasta 20 páginas, con un máximo de 10 escaneadas. Se procesa en tu dispositivo; el archivo no se guarda como borrador.",
      "Los nombres incompletos ofrecen coincidencias de tu catálogo. Si hay varias marcas o proveedores, elige el que usaste. Si falta un ingrediente, pulsa Registrar ingrediente para esa línea; guardar el ingrediente no guarda todavía la receta.",
      "Para escribir una receta, completa nombre, recetario, categoría, rendimiento y tipo de artículo. Añade alimentos con + Ingrediente y consumibles con + Material o empaque; ambos forman parte del costo.",
      "Proporcional permite media receta, el doble u otra proporción. Por tandas completas redondea hacia arriba al cotizar: 1,5 tandas cuentan como 2. La calculadora de Herramientas permite ajustar una proporción expresamente.",
      "Puedes usar gramos de ingredientes comprados por unidades o volumen si registraste su equivalencia en Ingredientes. La receta conserva los gramos; los costos y la producción utilizan la cantidad equivalente de inventario. No se supone el peso de huevos ni de líquidos.",
      "Comprueba el recetario elegido y pulsa Guardar receta importada o Guardar receta. Después abre Recetarios, ese recetario y Ver recetas del recetario para consultarla.",
      "Los borradores se conservan por cuenta en este dispositivo. El archivo no se guarda; se conserva el texto reconocido y el formulario de revisión."
    ],
    "example": "Si la mezcla produce 12 galletas, el rendimiento es 12 y la unidad es unidad. Las cantidades de ingredientes corresponden a toda esa mezcla.",
    "tip": "Si + Ingrediente no tiene opciones, falta registrar ingredientes. El costo utiliza el precio vigente del proveedor elegido. Si aparece Costo incompleto, revisa el precio, la cantidad y las unidades indicadas. Solo los recetarios de Encargos aparecen en el Cotizador. Si otra sesión modificó la receta, cancela la edición y vuelve a abrirla para revisar la versión más reciente antes de guardar. Los ingredientes y recetarios creados durante la importación permanecen guardados aunque canceles la receta. La cantidad de compra es distinta de la cantidad usada en la receta; no se convierten tazas a gramos automáticamente. Los borradores no se sincronizan entre dispositivos. No guardamos contraseñas ni el archivo PDF como borrador. Los alérgenos e indicaciones los completas tú; la aplicación no los deduce. En Respaldo puedes consultar las versiones anteriores guardadas desde esta actualización."
  },
  "Costos de productos": {
    "title": "Calcula el costo del artículo terminado",
    "steps": [
      "Elige un recetario y la receta o producto. También puedes entrar desde Calcular costo final dentro de una receta abierta o Ver costo final y precios en Mi nevera.",
      "Indica cuántas veces usas la receta. Se suman ingredientes y materiales con los precios actuales. La receta guardada se conserva.",
      "Añade mano de obra como monto fijo o como horas por tarifa, y los gastos adicionales de empaque, acabados, entrega u otros. No repitas los materiales ya incluidos en la receta; añade los consumibles de inventario a la receta si deben descontarse al producir.",
      "Revisa costo completo, cantidad obtenida y costo por porción o unidad de rendimiento. Guardar costo del producto conserva esta ficha privada. Los cambios de ingredientes actualizan el cálculo actual; el último costo guardado queda indicado para comparar.",
      "Si el producto ya está en Mi nevera, abre Precios de venta por canal. Si su unidad de venta es distinta del rendimiento, indica cuántas porciones o unidades del rendimiento lleva cada unidad vendida; no se supone una equivalencia.",
      "En el canal elegido, pulsa Usar costos de la ficha del producto para trasladar costo base, mano de obra, empaque y otros gastos sin duplicarlos. Introduce la comisión real de la aplicación y el margen deseado, elige el precio y guarda el canal.",
      "En Ventas se usan el precio del canal y los gastos adicionales por unidad. El costo real de ingredientes corresponde a los lotes vendidos, por lo que una venta de un lote antiguo puede tener otra ganancia.",
      "Para un encargo particular usa el Cotizador. Para cambiar cantidades, ingredientes o preparación usa la receta dentro de Recetarios. Actualizar costos recarga las fichas; Descartar cambios recupera la última guardada."
    ],
    "example": "Una receta rinde 12 porciones. Ingredientes y materiales RD$42, mano de obra RD$240 y gastos RD$18: costo completo RD$300, o RD$25 por porción.",
    "tip": "El costo completo no es el precio de venta. La comisión y el margen se aplican al calcular el precio de cada canal. Cada cuenta conserva sus propias fichas y su historial."
  }
};
