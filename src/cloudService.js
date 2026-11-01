import {readPreparation} from './features/recipes/recipePreparation.mjs';
import { supabase } from './supabase';
import { adaptarIngrediente } from './ingredientsService';

export const medidas = {g:['g',1],kg:['g',1000],lb:['g',453.59237],oz:['g',28.349523125],mg:['g',.001],ml:['ml',1],L:['ml',1000],'fl oz':['ml',29.5735295625],unidad:['unit',1],unit:['unit',1],docena:['unit',12]};
export function cantidadBase(cantidad, unidad) {
  const medida=medidas[unidad], valor=Number(cantidad);
  if(!medida || !Number.isFinite(valor) || valor<=0) throw new Error('Introduce una cantidad y unidad válidas.');
  const resultado=valor*medida[1];
  if(!Number.isFinite(resultado)||resultado<0.001) throw new Error('La cantidad mínima es 0.001 en la unidad base.');
  return {unit:medida[0],quantity:resultado};
}
async function resultado(query) {const {data,error}=await query;if(error)throw error;return data;}
function metadata(text){try{const value=JSON.parse(text);return value?.bumBum===1?value:{}}catch{return {}}}
export const adaptarReceta=r=>({id:r.id,name:r.name,category:metadata(r.instructions).category||'',preparation:readPreparation(r.instructions),bookId:r.recipe_book_id||null,productType:metadata(r.instructions).productType||'Otro artículo',yield:Number(r.yield_quantity),yieldUnit:r.yield_unit,scaling:metadata(r.instructions).scaling||'scalable',lines:(r.recipe_lines||[]).map(l=>({id:l.id,ingredientId:l.ingredient_id,qty:Number(l.quantity_base),unit:l.ingredients?.base_unit==='unit'?'unidad':l.ingredients?.base_unit})),editSnapshot:{name:r.name,recipe_book_id:r.recipe_book_id||null,yield_quantity:String(r.yield_quantity),yield_unit:r.yield_unit,instructions:r.instructions??null,lines:(r.recipe_lines||[]).map(l=>({id:l.id,ingredient_id:l.ingredient_id,quantity_base:String(l.quantity_base)}))}});
const decoracion=r=>({id:r.id,name:r.name,type:r.description||'Otros',price:Number(r.unit_cost)});
const cotizacion=r=>({...r.details,id:r.id,date:r.details?.date||r.created_at?.slice(0,10),totalCost:Number(r.total_cost),price:Number(r.quoted_price),method:r.pricing_method});
const venta=r=>({...r.details,id:r.id,date:r.sold_at?.slice(0,10),channel:r.channel,gross:Number(r.gross_amount),productionCost:r.details?.productionCost??Number(r.cost_amount),commission:r.details?.commission??(Number(r.gross_amount)?Number(r.commission_amount)/Number(r.gross_amount)*100:0),extra:r.details?.extra||0});
export async function cargarDatos(owner) {
  const tables=['ingredients','recipes','decorations','quotes','sales','recipe_books'];
  async function leer(table,select='*'){const rows=[];for(let start=0;;start+=500){let query=supabase.from(table).select(select).eq('owner_id',owner);if(table!=='recipe_lines')query=query.order('created_at');const page=await resultado(query.order('id').range(start,start+499));rows.push(...page);if(page.length<500)return rows;}}
  const [datos,lineas]=await Promise.all([Promise.all(tables.map(table=>leer(table))),leer('recipe_lines','*, ingredients(base_unit)')]);
  datos[1]=datos[1].map(r=>({...r,recipe_lines:lineas.filter(l=>l.recipe_id===r.id)}));
  const articulos=datos[0].map(adaptarIngrediente);
  return {ingredients:articulos.filter(i=>i.itemKind==='ingredient'),materials:articulos.filter(i=>i.itemKind==='material'),recipes:datos[1].map(adaptarReceta),decorations:datos[2].map(decoracion),quotes:datos[3].map(cotizacion),sales:datos[4].map(venta),books:datos[5],settings:{}};
}
export async function guardarRegistro(tipo, item, owner, ingredients) {
  const valores=tipo==='recipes'?[item.yield]:tipo==='decorations'?[item.price]:tipo==='quotes'?[item.totalCost,item.price,item.pct]:[item.gross,item.commission,item.productionCost,item.extra];
  if(valores.some(v=>!Number.isFinite(v)||v<0))throw new Error('Introduce importes válidos y no negativos.');
  if(tipo==='recipes') {
    const lines=item.lines.map(line=>{const ingrediente=ingredients.find(i=>i.id===line.ingredientId);if(!ingrediente)throw new Error('Ingrediente no disponible.');const converted=cantidadBase(line.qty,line.unit||ingrediente.unit);if(converted.unit!==medidas[ingrediente.unit]?.[0])throw new Error('Unidad incompatible con el ingrediente.');return {ingredient_id:line.ingredientId,quantity_base:converted.quantity};});
    if(!item.bookId)throw new Error('Selecciona un recetario.');
    await resultado(supabase.rpc('guardar_receta_organizada_bum_bum',{p_category:String(item.category||'').trim(),p_preparation:item.preparation||'',p_id:item.id,p_name:item.name,p_yield:item.yield,p_yield_unit:item.yieldUnit,p_scaling:item.scaling,p_lines:lines,p_product_type:item.productType,p_book_id:item.bookId}));
    return item;
  }
  if(tipo==='sales'&&item.fridgeProductId){const data=await resultado(supabase.rpc('bum_fridge_sale',{p_sale:item}));return venta(data);}
  let payload;
  if(tipo==='decorations')payload={name:item.name,unit_cost:item.price,description:item.type};
  else if(tipo==='quotes')payload={details:item,pricing_method:item.method,total_cost:item.totalCost,quoted_price:item.price};
  else if(tipo==='sales') {const commission=item.gross*item.commission/100;payload={sold_at:item.date+'T12:00:00Z',channel:item.channel,details:item,gross_amount:item.gross,commission_amount:commission,net_amount:item.gross-commission,cost_amount:item.productionCost+item.extra};}
  else throw new Error('Esta operación no está disponible.');
  const data=await resultado(supabase.from(tipo).insert({...payload,id:item.id,owner_id:owner}).select().single());
  return tipo==='decorations'?decoracion(data):tipo==='quotes'?cotizacion(data):venta(data);
}
export async function editarIngredienteNube(ingrediente,{name,price,quantity,unit},owner) {
  if(!name.trim())throw new Error('Introduce un nombre.');
  const converted=cantidadBase(quantity,unit),precio=Number(price);
  if(converted.unit!==medidas[ingrediente.unit]?.[0])throw new Error('La unidad debe ser compatible con las recetas existentes.');
  const cost=precio/converted.quantity;
  if(!Number.isFinite(precio)||precio<0||!Number.isFinite(cost)||cost>=1e10||(precio>0&&cost<0.0000005))throw new Error('Precio fuera del rango permitido.');
  const current=await resultado(supabase.from('ingredients').select('id,base_unit').eq('id',ingrediente.id).eq('owner_id',owner).single());
  if(current.base_unit!==converted.unit)throw new Error('La unidad cambió. Recarga e intenta de nuevo.');
  const data=await resultado(supabase.from('ingredients').update({name:name.trim(),last_unit_cost:cost}).eq('id',ingrediente.id).eq('owner_id',owner).eq('base_unit',converted.unit).select().single());
  return adaptarIngrediente(data);
}
