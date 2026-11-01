import {supabase} from '../../supabase';
import {adaptarIngrediente} from '../../ingredientsService';
import {nonnegative} from './stock.mjs';
export async function saveInventory(item,form,owner){
 if(!owner||!item?.id)throw Error('No se pudo identificar el artículo de tu cuenta.');
 const payload={stock_quantity:nonnegative(form.quantity),minimum_stock:nonnegative(form.minimum,'Existencia mínima')};
 let query=supabase.from('ingredients').update(payload).eq('id',item.id).eq('owner_id',owner).eq('base_unit',item.unit==='unidad'?'unit':item.unit);
 for(const [field,value] of [['stock_quantity',item.stockQuantity],['minimum_stock',item.minimumStock]])query=value==null?query.is(field,null):query.eq(field,value);
 const {data,error}=await query.select().maybeSingle();if(error)throw error;
 if(data?.id!==item.id)throw Error('Las existencias cambiaron. Actualiza la lista antes de guardar.');
 return adaptarIngrediente(data);
}
async function read(table,owner){const result=[];for(let start=0;;start+=500){const {data,error}=await supabase.from(table).select('*').eq('owner_id',owner).order('created_at').order('id').range(start,start+499);if(error)throw error;result.push(...data);if(data.length<500)return result;}}
export async function loadFridge(owner){const [products,batches,movements]=await Promise.all(['fridge_products','fridge_batches','fridge_movements'].map(table=>read(table,owner)));return {products,batches,movements};}
export async function fridgeMutation(action,args){
 const {data,error}=await supabase.rpc('bum_fridge_'+action,args);if(error)throw error;return data;
}
