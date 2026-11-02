import { supabase } from './supabase';
import { cantidadBase, medidas } from './cloudService';
import { adaptarIngrediente } from './ingredientsService';

export const tiposProducto = ['Bizcocho','Cupcake','Galleta','Brownie','Cheesecake','Flan','Tres leches','Postre en vaso','Pan','Otro artículo'];
export const unidadesCompra = Object.keys(medidas).filter(u=>u!=='unit');
export const unidadesRendimiento = ['unidad','porción','docena','g','kg','lb','lb comercial','oz','ml','L','gal US','bandeja','caja'];
export const etiquetaArticulo = i=>`${i.name} · ${i.supplier || 'Sin proveedor registrado'}`;

export function prepararArticulo(form, kind, original) {
  const name=String(form.name||'').trim(), supplier=String(form.supplier||'').trim();
  if(!name)throw new Error('Introduce el nombre.');
  if(!supplier)throw new Error('Indica dónde compraste este artículo.');
  if(!['ingredient','material'].includes(kind))throw new Error('Tipo de artículo no válido.');
  if(!unidadesCompra.includes(form.unit))throw new Error('Selecciona una unidad válida.');
  if(String(form.price).trim()===''||String(form.quantity).trim()==='')throw new Error('Introduce precio y cantidad de compra.');
  const price=Number(form.price), quantity=Number(form.quantity),base=cantidadBase(quantity,form.unit);
  if(original && medidas[original.unit]?.[0]!==base.unit)throw new Error('Selecciona una unidad compatible con las recetas y cotizaciones existentes.');
  const cost=price/base.quantity;
  if(!Number.isFinite(price)||price<0||!Number.isFinite(cost)||cost>=1e10||(price>0&&cost<0.0000005))throw new Error('Precio fuera del rango permitido.');
  return {name,supplier,item_kind:kind,base_unit:base.unit,last_unit_cost:cost,purchase_unit:form.unit,purchase_quantity:quantity,purchase_price:price};
}

export async function guardarArticulo(form,kind,owner,original) {
  const payload=prepararArticulo(form,kind,original);
  let query=supabase.from('ingredients');
  if(original) {
    if(original.itemKind!==kind)throw new Error('No se puede cambiar el tipo de este registro.');
    query=query.update(payload).eq('id',original.id).eq('owner_id',owner).eq('item_kind',kind).eq('base_unit',medidas[original.unit]?.[0]);
  } else query=query.insert({...payload,owner_id:owner,stock_quantity:cantidadBase(form.quantity,form.unit).quantity,minimum_stock:0});
  const {data,error}=await query.select().single();
  if(error)throw error;
  return adaptarIngrediente(data);
}

export function costoMateriales(materials, cantidades) {
  return materials.reduce((sum,i)=>{
    const amount=Number(cantidades[i.id]||0);
    return sum+(Number.isFinite(amount)&&amount>0?amount*Number(i.lastUnitCost):0);
  },0);
}
export function detalleMateriales(materials,cantidades) {
  return materials.filter(i=>Number(cantidades[i.id])>0).map(i=>({id:i.id,name:i.name,supplier:i.supplier,unit:i.unit,qty:Number(cantidades[i.id]),unitCost:Number(i.lastUnitCost)}));
}

export async function eliminarIngrediente(id,owner){
 if(!id||!owner)throw new Error('No se pudo identificar el ingrediente de tu cuenta.');
 const {data,error}=await supabase.from('ingredients').delete().eq('id',id).eq('owner_id',owner).eq('item_kind','ingredient').select('id').maybeSingle();
 if(error){
  if(error.code==='23503')throw new Error('Este ingrediente está usado en una receta, compra o movimiento de inventario y no se puede eliminar.');
  if(error.code==='42501')throw new Error('Tu cuenta no tiene permiso para eliminar este ingrediente.');
  throw new Error('No se pudo confirmar la eliminación. Revisa tu conexión y actualiza la lista antes de intentar de nuevo.');
 }
 if(data?.id!==id)throw new Error('El ingrediente no se eliminó. Puede que ya no esté disponible; actualiza la lista.');
 return data.id;
}

export const etiquetaUnidad=u=>u==='kg'?'Kilos (kg)':u==='gal US'?'Galón estadounidense (3.785 L)':u;
