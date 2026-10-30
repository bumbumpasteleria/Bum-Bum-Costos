import { supabase } from './supabase';

export const usosRecetario={orders:'Encargos',delivery:'Apps de envío',general:'Uso general'};
export const usoReceta=(recipe,books)=>books.find(b=>b.id===recipe.bookId)?.usage||'unassigned';
export const nombreRecetario=(id,books)=>books.find(b=>b.id===id)?.name||'Sin recetario';
export function filtrarRecetas(recipes,books,{usage='all',bookId='all',productType='Todos',ordersOnly=false}={}){
  return recipes.filter(r=>(!ordersOnly||usoReceta(r,books)==='orders')&&(usage==='all'||usoReceta(r,books)===usage)&&(bookId==='all'||(bookId==='unassigned'?!r.bookId:r.bookId===bookId))&&(productType==='Todos'||r.productType===productType));
}
export async function guardarRecetario({name,usage},owner,id){
  if(!name?.trim())throw new Error('Escribe el nombre del recetario.');
  if(!Object.hasOwn(usosRecetario,usage))throw new Error('Selecciona un uso válido.');
  const values={name:name.trim(),usage};
  let query=supabase.from('recipe_books');
  query=id?query.update(values).eq('id',id).eq('owner_id',owner):query.insert({...values,owner_id:owner});
  const {data,error}=await query.select().single();if(error){if(error.code==='23505')throw new Error('Ya tienes un recetario con ese nombre.');throw error;}return data;
}
export async function asignarRecetario(recipeId,bookId,owner){
  const {data,error}=await supabase.from('recipes').update({recipe_book_id:bookId}).eq('id',recipeId).eq('owner_id',owner).select('id,recipe_book_id').single();
  if(error)throw error;return data;
}
