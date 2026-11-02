export const recipeMeasures={g:['g',1],kg:['g',1000],lb:['g',453.59237],oz:['g',28.349523125],mg:['g',.001],ml:['ml',1],L:['ml',1000],'gal US':['ml',3785.411784],'fl oz':['ml',29.5735295625],unidad:['unit',1],unit:['unit',1],docena:['unit',12]};
export function ingredientBaseQuantity(quantity,unit,item,{minimum=false}={}){
 const n=Number(quantity),from=recipeMeasures[unit||item?.unit],to=recipeMeasures[item?.unit];
 if(String(quantity??'').trim()===''||!Number.isFinite(n)||n<=0||!from||!to)throw Error('Revisa la cantidad y unidad de '+(item?.name||'este ingrediente')+'.');
 let amount=n*from[1];
 if(from[0]!==to[0]){
  const weight=Number(item.gramsPerBaseUnit);
  if(from[0]!=='g'||!['unit','ml'].includes(to[0]))throw Error('La unidad no es compatible con '+item.name+'.');if(!Number.isFinite(weight)||weight<=0)throw Error('Registra la equivalencia en gramos de '+item.name+' en Ingredientes antes de usar esa unidad.');
  amount=n*from[1]/weight;
 }
 if(!Number.isFinite(amount)||amount<=0||(minimum&&amount<.001))throw Error('La cantidad equivalente de '+item.name+' debe ser al menos 0.001 en inventario.');
 return {unit:to[0],quantity:amount};
}
export function ingredientUnitOptions(item){
 const base=recipeMeasures[item?.unit]?.[0],weight=Number(item?.gramsPerBaseUnit);
 return Object.keys(recipeMeasures).filter(u=>u!=='unit'&&(recipeMeasures[u][0]===base||(recipeMeasures[u][0]==='g'&&['unit','ml'].includes(base)&&Number.isFinite(weight)&&weight>0)));
}
export function recipeLinePayload(line,item){
 const unit=line.unit||item.unit,base=ingredientBaseQuantity(line.qty,unit,item,{minimum:true});
 return {ingredient_id:item.id,quantity_base:base.quantity,measurement_quantity:Number(line.qty),measurement_unit:unit};
}
