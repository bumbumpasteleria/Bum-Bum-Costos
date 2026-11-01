import {supabase} from '../../supabase';
export async function eliminarReceta(id,owner){
 if(!id||!owner)throw new Error('Inicia sesión y vuelve a abrir la receta antes de eliminarla.');
 const {data,error}=await supabase.from('recipes').delete().eq('id',id).eq('owner_id',owner).select('id,owner_id').maybeSingle();
 if(error){
  if(error.code==='23503')throw new Error('La receta tiene registros relacionados que impiden eliminarla. Se conservó la receta.');
  if(error.code==='42501')throw new Error('Tu cuenta no tiene permiso para eliminar esta receta.');
  throw new Error('No se pudo confirmar la eliminación. Actualiza la página para comprobar si la receta sigue en tu cuenta antes de reintentar.');
 }
 if(!data||data.id!==id||data.owner_id!==owner)throw new Error('No se confirmó la eliminación de tu receta. Actualiza la página para revisar su estado.');
 return data.id;
}
