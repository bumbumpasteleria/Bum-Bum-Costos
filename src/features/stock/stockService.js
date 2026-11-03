import {supabase} from '../../supabase';
import {adaptarIngrediente} from '../../ingredientsService';
import {nonnegative} from './stock.mjs';
export async function saveInventory(item,form,owner){
 if(!owner||!item?.id)throw Error('No se pudo identificar el artículo de tu cuenta.');
 const quantity=nonnegative(form.quantity),minimum=nonnegative(form.minimum,'Existencia mínima');
 const {data,error}=await supabase.rpc('bum_inventory_adjust',{p_id:form.id||crypto.randomUUID(),p_item:item.id,p_quantity:quantity,p_minimum:minimum,p_expected:item.stockQuantity??null,p_expected_minimum:item.minimumStock??null,p_reason:form.reason||'Conteo físico'});if(error)throw error;
 if(data?.id!==item.id||data.owner_id!==owner)throw Error('No se pudo confirmar el ajuste de tu cuenta. Actualiza el inventario.');
 return adaptarIngrediente(data);
}
async function read(table,owner){const result=[];for(let start=0;;start+=500){let query=supabase.from(table).select('*').eq('owner_id',owner);if(table==='business_entries')query=query.eq('kind','quality');const {data,error}=await query.order('created_at').order('id').range(start,start+499);if(error)throw error;result.push(...data);if(data.length<500)return result;}}
export async function loadFridge(owner){const [products,batches,movements,quality]=await Promise.all(['fridge_products','fridge_batches','fridge_movements','business_entries'].map(table=>read(table,owner)));const checks=quality.slice().sort((a,b)=>b.updated_at.localeCompare(a.updated_at)||b.id.localeCompare(a.id));return {products,batches:batches.map(b=>({...b,qualityBlocked:checks.find(q=>q.details.lotId===b.id)?.details.result==='blocked'})),movements};}
export async function fridgeMutation(action,args){
 const {data,error}=await supabase.rpc('bum_fridge_'+action,args);if(error)throw error;return data;
}
