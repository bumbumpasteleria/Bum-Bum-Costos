import {buildQuote} from '../../domain/costing/quote.mjs';
export function productCost(recipe,catalog,form){
 if(!['fixed','hourly'].includes(form.laborMode))throw Error('Selecciona cómo calcular la mano de obra.');
 const cost=buildQuote({recipe,catalog,quantity:form.quantity,laborMode:form.laborMode,labor:form.labor,hours:form.laborMode==='hourly'?form.hours:1,extra:form.extra,method:'markup',pct:0});
 const produced=Number(recipe.yield)*cost.factor;if(!Number.isFinite(produced)||produced<=0)throw Error('Completa el rendimiento de la receta antes de calcular su costo final.');
 const parts={baseCost:(cost.ingredientsCost+cost.recipeMaterialsCost)/produced,labor:cost.laborCost/produced,packaging:Number(form.extra.pack||0)/produced,other:cost.expenses.filter(e=>e.key!=='pack').reduce((sum,e)=>sum+e.cost,0)/produced};
 return {cost,produced,unitCost:cost.totalCost/produced,parts};
}
