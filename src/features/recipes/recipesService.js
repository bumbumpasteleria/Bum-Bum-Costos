import {supabase} from '../../supabase';
import {adaptarReceta,cantidadBase,medidas} from '../../cloudService';
import {tiposProducto,unidadesRendimiento} from '../../catalogoService';

export async function obtenerReceta(id,owner){
 if(!id||!owner)throw new Error('No se pudo identificar tu receta.');
 const {data,error}=await supabase.from('recipes').select('*').eq('id',id).eq('owner_id',owner).single();
 if(error||!data||data.owner_id!==owner)throw new Error('No se pudo abrir la receta. Actualiza la lista e intenta de nuevo.');
 const lines=[];
 for(let start=0;;start+=500){
  const result=await supabase.from('recipe_lines').select('*, ingredients(base_unit)').eq('recipe_id',id).eq('owner_id',owner).order('id').range(start,start+499);
  if(result.error)throw new Error('No se pudieron cargar los ingredientes de la receta. Intenta de nuevo.');
  lines.push(...result.data);if(result.data.length<500)break;
 }
 return adaptarReceta({...data,recipe_lines:lines});
}

export function prepararEdicionReceta(form,original,ingredients,books){
 if(!original?.id||!original.editSnapshot)throw new Error('Vuelve a abrir la receta antes de editarla.');
 const name=String(form.name||'').trim(),yieldValue=String(form.yield??'').trim(),amount=Number(yieldValue);
 if(!name||name.length>160)throw new Error('Escribe un nombre de hasta 160 caracteres.');
 if(!yieldValue||!Number.isFinite(amount)||amount<=0)throw new Error('El rendimiento debe ser mayor que cero.');
 if(!unidadesRendimiento.includes(form.yieldUnit))throw new Error('Selecciona una unidad de rendimiento válida.');
 if(!tiposProducto.includes(form.productType))throw new Error('Selecciona un tipo de producto válido.');
 if(!['fixed','scalable'].includes(form.scaling))throw new Error('Selecciona el tipo de escalado.');
 if(!books.some(book=>book.id===form.bookId))throw new Error('Selecciona un recetario de tu cuenta.');
 if(!Array.isArray(form.lines)||!form.lines.length)throw new Error('Agrega al menos un ingrediente.');
 const seen=new Set();
 const lines=form.lines.map(line=>{
  const ingredient=ingredients.find(item=>item.id===line.ingredientId);
  if(!ingredient||ingredient.itemKind==='material')throw new Error('Selecciona un ingrediente disponible de tu catálogo.');
  const converted=cantidadBase(line.qty,line.unit||ingredient.unit);
  if(converted.unit!==medidas[ingredient.unit]?.[0])throw new Error('La unidad no es compatible con '+ingredient.name+'.');
  const result={ingredient_id:ingredient.id,quantity_base:converted.quantity};
  if(line.id){
   if(seen.has(line.id)||!original.lines.some(row=>row.id===line.id))throw new Error('Las líneas de la receta cambiaron. Vuelve a abrirla.');
   seen.add(line.id);result.id=line.id;
  }
  return result;
 });
 return {p_id:original.id,p_name:name,p_yield:amount,p_yield_unit:form.yieldUnit,p_scaling:form.scaling,p_product_type:form.productType,p_book_id:form.bookId,p_lines:lines,p_original:original.editSnapshot};
}

export async function actualizarReceta(form,original,owner,ingredients,books){
 if(!owner)throw new Error('Inicia sesión antes de guardar.');
 const args=prepararEdicionReceta(form,original,ingredients,books);
 const {data,error}=await supabase.rpc('actualizar_receta_recetario_bum_bum',args);
 if(error){
  if(error.code==='PGRST202')throw new Error('La edición de recetas aún no está habilitada. La administradora debe publicar la actualización.');
  if(error.code==='P0001')throw new Error(error.message);
  if(error.code==='42501')throw new Error('Tu cuenta no tiene permiso para actualizar esta receta.');
  if(error.code==='23503')throw new Error('No se pudo cambiar una línea con referencias. La receta se conservó.');
  throw new Error('No se pudo confirmar el guardado. Vuelve a abrir la receta para comprobar su estado antes de reintentar.');
 }
 if(!data||data.id!==original.id||data.owner_id!==owner)throw new Error('No se pudo confirmar la receta de tu cuenta. Actualiza la lista.');
 return adaptarReceta(data);
}
