export const recipeMeasures={g:['g',1],kg:['g',1000],lb:['g',453.59237],oz:['g',28.349523125],mg:['g',.001],ml:['ml',1],L:['ml',1000],'gal US':['ml',3785.411784],'fl oz':['ml',29.5735295625],unidad:['unit',1],unit:['unit',1],docena:['unit',12]};
export const eggMeasures={'g clara':['white',1],'g yema':['yolk',1],clara:['white',0],yema:['yolk',0]};
export const eggPart=unit=>eggMeasures[unit]?.[0]||'';
export function ingredientBaseQuantity(quantity,unit,item,{minimum=false}={}){
 const n=Number(quantity);if(eggMeasures[unit]){const [part,grams]=eggMeasures[unit],weight=Number(part==='white'?item?.gramsPerWhite:item?.gramsPerYolk);if(String(quantity??'').trim()===''||!Number.isFinite(n)||n<=0||recipeMeasures[item?.unit]?.[0]!=='unit'||!Number.isFinite(weight)||weight<=0)throw Error('Completa la equivalencia de claras y yemas de este huevo.');const result=grams?n/weight:n;if(!Number.isFinite(result)||result<=0||(minimum&&result<.001))throw Error('Revisa la cantidad equivalente de huevo.');return {unit:'unit',quantity:result};}
 const from=recipeMeasures[unit||item?.unit],to=recipeMeasures[item?.unit];
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
 return [...Object.keys(recipeMeasures).filter(u=>u!=='unit'&&(recipeMeasures[u][0]===base||(recipeMeasures[u][0]==='g'&&['unit','ml'].includes(base)&&Number.isFinite(weight)&&weight>0))),...(base==='unit'&&Number(item?.gramsPerWhite)>0&&Number(item?.gramsPerYolk)>0?Object.keys(eggMeasures):[])];
}
export function recipeLinePayload(line,item){
 const unit=line.unit||item.unit,base=ingredientBaseQuantity(line.qty,unit,item,{minimum:true});
 return {ingredient_id:item.id,quantity_base:base.quantity,measurement_quantity:Number(line.qty),measurement_unit:unit};
}

// A recipe can use both parts from the same purchased egg. Pair parts within this preparation.
export function allocatedIngredientQuantities(lines,ingredients){
 const groups=new Map(),amounts=lines.map(line=>{const item=ingredients.find(i=>i.id===line.ingredientId);if(!item)throw Error('Ingrediente no disponible.');const q=ingredientBaseQuantity(line.qty,line.unit||item.unit,item).quantity,part=eggPart(line.unit);if(part){const group=groups.get(item.id)||{white:0,yolk:0};group[part]+=q;groups.set(item.id,group)}return q;});
 return amounts.map((q,index)=>{const line=lines[index],part=eggPart(line.unit),g=groups.get(line.ingredientId);return part?q*Math.max(g.white,g.yolk)/(g.white+g.yolk):q});
}
export function ingredientRequirements(lines,ingredients){const amounts=allocatedIngredientQuantities(lines,ingredients),result=new Map();for(const [index,line]of lines.entries()){const item=ingredients.find(i=>i.id===line.ingredientId),old=result.get(item.id)||{ingredientId:item.id,quantity:0,unit:recipeMeasures[item.unit][0]};old.quantity+=amounts[index];if(!Number.isFinite(old.quantity))throw Error('Cantidad fuera de rango.');result.set(item.id,old)}return [...result.values()]}
export function preferredRecipeUnit(item){return recipeMeasures[item?.unit]?.[0]==='ml'&&Number(item?.gramsPerBaseUnit)>0?'g':item?.unit||'g'}
