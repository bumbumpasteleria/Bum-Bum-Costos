import {assessRecipeCost} from './recipeCost.mjs';
export function quoteNumber(value,label){if(value==null||String(value).trim()==='')throw Error('Completa '+label+'.');const n=Number(value);if(!Number.isFinite(n)||n<0||n>=1e10)throw Error('Revisa '+label+'.');return n;}
export function buildQuote({recipe,catalog,quantity,materials={},decorations=[],decors={},labor=0,laborMode='fixed',hours=1,extra={},method='margin',pct=35}){
 if(!recipe)throw Error('Elige una receta para cotizar.');const assessment=assessRecipeCost(recipe,catalog);if(!assessment.complete)throw Error(assessment.issues.join(' '));
 const qty=quoteNumber(quantity,'la cantidad');if(!qty)throw Error('La cantidad debe ser mayor que cero.');const factor=recipe.scaling==='fixed'?Math.ceil(qty):qty;
 const recipeLines=recipe.lines.map(line=>{const item=catalog.find(i=>i.id===line.ingredientId),cost=assessRecipeCost({lines:[line]},catalog).total*factor;return {id:item.id,name:item.name,supplier:item.supplier,kind:item.itemKind||'ingredient',quantity:Number(line.qty)*factor,unit:line.unit||item.unit,cost};});
 const materialLines=catalog.filter(i=>i.itemKind==='material').flatMap(item=>{const q=quoteNumber(materials[item.id]??0,'la cantidad de '+item.name);if(!q)return [];const unitCost=quoteNumber(item.lastUnitCost,'el costo de '+item.name);return [{id:item.id,name:item.name,supplier:item.supplier,kind:'material',quantity:q,unit:item.unit,cost:q*unitCost}];});
 const decorLines=decorations.flatMap(item=>{const q=quoteNumber(decors[item.id]??0,'la cantidad de '+item.name);return q?[{id:item.id,name:item.name,quantity:q,unit:'unidad',cost:q*quoteNumber(item.price,'el costo de '+item.name)}]:[];});
 const ingredientsCost=recipeLines.filter(l=>l.kind!=='material').reduce((s,l)=>s+l.cost,0),recipeMaterialsCost=recipeLines.filter(l=>l.kind==='material').reduce((s,l)=>s+l.cost,0),additionalMaterialsCost=materialLines.reduce((s,l)=>s+l.cost,0),decorationCost=decorLines.reduce((s,l)=>s+l.cost,0);
 const laborCost=quoteNumber(labor,'la mano de obra')*(laborMode==='hourly'?quoteNumber(hours,'las horas'):1);
 const expenses=Object.entries(extra).map(([key,value])=>({key,cost:quoteNumber(value,'los gastos adicionales')}));
 const totalCost=ingredientsCost+recipeMaterialsCost+additionalMaterialsCost+decorationCost+laborCost+expenses.reduce((s,e)=>s+e.cost,0),percent=quoteNumber(pct,'el porcentaje');
 if(!['margin','markup'].includes(method)||percent>95)throw Error('Revisa el método y porcentaje de ganancia.');
 const price=method==='margin'?totalCost/(1-percent/100):totalCost*(1+percent/100);
 if(!Number.isFinite(price)||price>=1e12)throw Error('El importe es demasiado grande.');
 return {recipeLines,materialLines,decorLines,ingredientsCost,recipeMaterialsCost,additionalMaterialsCost,decorationCost,laborCost,expenses,totalCost,price,profit:price-totalCost,factor,quantity:qty,method,pct:percent};
}
