// Conserva las unidades y factores históricos del recetario.
const units={g:['mass',1],kg:['mass',1000],lb:['mass',453.59237],oz:['mass',28.349523125],mg:['mass',.001],ml:['volume',1],L:['volume',1000],'fl oz':['volume',29.5735295625],unidad:['count',1],docena:['count',12]};
const numeric=value=>(typeof value==='number'||typeof value==='string'&&value.trim()!=='')&&Number.isFinite(Number(value))?Number(value):null;
export function assessRecipeCost(recipe,ingredients){
 const issues=[];let sum=0;
 if(!Array.isArray(recipe?.lines)||!recipe.lines.length)return {complete:false,total:null,issues:['La receta no tiene ingredientes.']};
 for(const [index,line] of recipe.lines.entries()){
  const prefix='Ingrediente '+(index+1)+': ';
  const ingredient=ingredients.find(item=>item.id===line?.ingredientId);
  if(!ingredient){issues.push(prefix+'no está disponible en tu catálogo.');continue;}
  const name=ingredient.name||prefix;
  const quantity=numeric(line.qty);
  if(quantity===null||quantity<=0){issues.push(name+': revisa la cantidad de la receta.');continue;}
  const from=units[line.unit||ingredient.unit],to=units[ingredient.unit];
  if(!from||!to||from[0]!==to[0]){issues.push(name+': la unidad de la receta no coincide con la del ingrediente.');continue;}
  let cost;
  // Un costo explícito inválido nunca se sustituye silenciosamente por otro precio.
  if(Object.hasOwn(ingredient,'lastUnitCost'))cost=numeric(ingredient.lastUnitCost);
  else {const price=numeric(ingredient.price),pack=numeric(ingredient.packageQty);cost=price!==null&&pack!==null&&pack>0?price/pack:null;}
  if(cost===null||cost<0||!Number.isFinite(cost)){issues.push(name+': revisa el precio del ingrediente.');continue;}
  const amount=quantity*from[1]/to[1]*cost;
  if(!Number.isFinite(amount)||!Number.isFinite(sum+amount)){issues.push(name+': el costo está fuera del rango permitido.');continue;}
  sum+=amount;
 }
 return {complete:issues.length===0,total:issues.length?null:sum,issues};
}
