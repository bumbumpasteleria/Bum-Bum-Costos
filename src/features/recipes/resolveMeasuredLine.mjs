import {ingredientMatches,normalizeIngredient} from './ingredientMatches.mjs';
import {ingredientUnitOptions} from '../../domain/costing/ingredientQuantity.mjs';
export function resolveMeasuredLine(line,ingredients){
 const name=normalizeIngredient(line.name||''),part=/\bclaras?\b/.test(name)?'clara':/\byemas?\b/.test(name)?'yema':'';
 const egg=part||/\bhuevos?\b/.test(name);let item=ingredients.find(i=>i.id===line.ingredientId);
 if(!item&&!line.ingredientId&&name){const candidates=egg?ingredients.filter(i=>Number(i.gramsPerWhite)>0&&Number(i.gramsPerYolk)>0):ingredientMatches(line.name,ingredients);if(candidates.length===1&&(egg||candidates[0].unit==='ml'&&Number(candidates[0].gramsPerBaseUnit)>0))item=candidates[0];}
 if(!item)return line;
 let unit=line.unit;if(part){if(unit==='g')unit='g '+part;else if(unit==='unidad'||!unit&&Number(line.qty)>0)unit=part;}
 if(!ingredientUnitOptions(item).includes(unit))return line;
 return {...line,ingredientId:item.id,unit};
}
