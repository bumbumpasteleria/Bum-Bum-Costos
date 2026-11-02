import {ingredientBaseQuantity,recipeMeasures} from './ingredientQuantity.mjs';
import {assessRecipeCost} from './recipeCost.mjs';
const units={g:['mass',1],kg:['mass',1000],lb:['mass',453.59237],oz:['mass',28.349523125],mg:['mass',.001],ml:['volume',1],L:['volume',1000],'gal US':['volume',3785.411784],'fl oz':['volume',29.5735295625],unidad:['count',1],docena:['count',12]};
export function positiveAmount(value){
 const text=String(value??'').trim().replace(',','.');let amount;
 if(/^\d+\/\d+$/.test(text)){const [a,b]=text.split('/').map(Number);amount=a/b;}
 else if(/^(?:\d+(?:\.\d+)?|\.\d+)$/.test(text))amount=Number(text);
 else throw Error('Escribe una cantidad positiva, como 0,5 o 1/4.');
 if(!Number.isFinite(amount)||amount<=0)throw Error('La cantidad debe ser mayor que cero.');return amount;
}
export function compatibleYieldUnits(unit){const from=units[unit];return from?Object.keys(units).filter(u=>units[u][0]===from[0]):[unit];}
export function scaleRecipe(recipe,entry,ingredients){
 if(!recipe)throw Error('Selecciona una receta.');
 const base=positiveAmount(entry.baseYield),baseUnit=entry.baseUnit;
 if(!baseUnit)throw Error('Selecciona la unidad del rendimiento original.');
 let factor,output,outputUnit;
 if(entry.mode==='target'){
  output=positiveAmount(entry.target);outputUnit=entry.targetUnit;
  if(!compatibleYieldUnits(baseUnit).includes(outputUnit))throw Error('Las unidades de rendimiento no son compatibles.');
  factor=output*(units[outputUnit]?.[1]||1)/(base*(units[baseUnit]?.[1]||1));
 }else{factor=positiveAmount(entry.factor);output=base*factor;outputUnit=baseUnit;}
 if(!Number.isFinite(factor)||!Number.isFinite(output)||output<=0)throw Error('Revisa las cantidades: el resultado está fuera de rango.');
 if(!recipe.lines?.length)throw Error('Esta receta no tiene ingredientes.');
 const lines=recipe.lines.map(line=>{const ingredient=ingredients.find(i=>i.id===line.ingredientId);if(!ingredient)throw Error('Hay un ingrediente que ya no está en tu catálogo.');const qty=positiveAmount(line.qty)*factor,unit=line.unit||ingredient.unit;ingredientBaseQuantity(qty,unit,ingredient);if(!Number.isFinite(qty)||qty<=0)throw Error('La cantidad de '+ingredient.name+' queda fuera del rango admitido.');return {ingredientId:line.ingredientId,qty,unit};});
 return {factor,yield:output,yieldUnit:outputUnit,lines,cost:assessRecipeCost({lines},ingredients)};
}
export function combineScaledRecipes(results,ingredients){
 const grouped=new Map();
 for(const result of results)for(const line of result.lines){const item=ingredients.find(i=>i.id===line.ingredientId);if(!item)throw Error('Ingrediente no disponible.');const unit=recipeMeasures[line.unit],base=ingredientBaseQuantity(line.qty,line.unit,item),old=grouped.get(line.ingredientId),qty=(old?.baseQty||0)+base.quantity;if(!Number.isFinite(qty))throw Error('El total de ingredientes está fuera de rango.');const asGrams=unit[0]==='g'||old?.asGrams;let amount=qty,displayUnit=base.unit==='unit'?'unidad':base.unit;if(asGrams&&base.unit!=='g'){amount=qty*Number(item.gramsPerBaseUnit);displayUnit='g';}grouped.set(line.ingredientId,{ingredientId:line.ingredientId,qty:amount,unit:displayUnit,baseQty:qty,asGrams});}
 const lines=[...grouped.values()].map(({baseQty,asGrams,...line})=>line);return {lines,cost:assessRecipeCost({lines},ingredients)};
}
