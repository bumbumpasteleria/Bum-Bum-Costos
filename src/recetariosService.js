import { supabase } from './supabase';

export const usosRecetario={orders:'Encargos',delivery:'Apps de envío',general:'Uso general'};
export const usoReceta=(recipe,books)=>books.find(b=>b.id===recipe.bookId)?.usage||'unassigned';
export const nombreRecetario=(id,books)=>books.find(b=>b.id===id)?.name||'Sin recetario';
export function filtrarRecetas(recipes,books,{usage='all',bookId='all',productType='Todos',ordersOnly=false}={}){
  return recipes.filter(r=>(!ordersOnly||usoReceta(r,books)==='orders')&&(usage==='all'||usoReceta(r,books)===usage)&&(bookId==='all'||(bookId==='unassigned'?!r.bookId:r.bookId===bookId))&&(productType==='Todos'||r.productType===productType));
}
export async function guardarRecetario({name,usage},owner,id,original){
  if(!name?.trim())throw new Error('Escribe el nombre del recetario.');
  if(!Object.hasOwn(usosRecetario,usage))throw new Error('Selecciona un uso válido.');
  const values={name:name.trim(),usage};
  let query=supabase.from('recipe_books');
  query=id?query.update(values).eq('id',id).eq('owner_id',owner):query.insert({...values,owner_id:owner});
  if(id&&original)query=query.eq('name',original.name).eq('usage',original.usage);
  const {data,error}=await query.select().single();if(error){if(error.code==='PGRST116')throw new Error('El recetario cambió o ya no está disponible. Actualiza la lista antes de guardar.');if(error.code==='23505')throw new Error('Ya tienes un recetario con ese nombre.');throw error;}return data;
}
export async function asignarRecetario(recipeId,bookId,owner,originalBookId){
  let query=supabase.from('recipes').update({recipe_book_id:bookId}).eq('id',recipeId).eq('owner_id',owner);if(originalBookId!==undefined)query=originalBookId===null?query.is('recipe_book_id',null):query.eq('recipe_book_id',originalBookId);
  const {data,error}=await query.select('id,recipe_book_id').single();
  if(error)throw new Error(error.code==='PGRST116'?'La asignación cambió. Actualiza la receta antes de moverla de nuevo.':error.message);return data;
}

export async function eliminarRecetario(book,owner){
 if(!owner||!book?.id)throw Error('No se pudo identificar el recetario.');
 const {data,error}=await supabase.rpc('bum_delete_recipe_book',{p_id:book.id,p_original:{name:book.name,usage:book.usage}});if(error)throw Error(error.code==='PGRST202'?'La eliminación de recetarios aún no está publicada.':error.message);if(data!==book.id)throw Error('No se pudo confirmar la eliminación. Actualiza los recetarios.');return data;
}
