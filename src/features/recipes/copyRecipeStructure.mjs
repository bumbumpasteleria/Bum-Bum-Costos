// Copies are independent formulas: keep each stage's own lines, including repeated ingredients.
export function copyRecipeStructure(recipe,factor,recipes=[],namespace,{groupRoot=false}={}){
 const stages=[],lines=[];let serial=0,budget=0;
 const make=(name,preparation)=>{if(stages.length>=20)throw Error('La combinación supera 20 etapas. Reduce las preparaciones para conservar sus instrucciones.');const id=namespace.slice(0,24)+(++serial).toString(16).padStart(12,'0');const stage={id,name:String(name).slice(0,100),preparation:preparation||''};stages.push(stage);return id;};
 function visit(node,multiple,path=[]){if(++budget>2000||path.includes(node.id)||path.length>30)throw Error('Revisa los vínculos de las recetas antes de copiarlas.');const root=path.length===0,own=node.ownLines||node.lines||[],mapping=new Map();
  for(const stage of node.stages||[])mapping.set(stage.id,make(root&&!groupRoot?stage.name:node.name+' · '+stage.name,stage.preparation));
  const generalLines=own.filter(line=>!(node.stages||[]).some(stage=>stage.lineIds?.includes(line.id)||stage.id===line.stageId));
  let general='';if((!root||groupRoot)&&(generalLines.length||node.preparation))general=make(node.name,node.preparation);
  for(const line of own){const source=(node.stages||[]).find(stage=>stage.lineIds?.includes(line.id)||stage.id===line.stageId);const qty=Number(line.qty)*multiple;if(!Number.isFinite(qty)||qty<=0)throw Error('Revisa las cantidades de la receta.');lines.push({ingredientId:line.ingredientId,qty,unit:line.unit,stageId:source?mapping.get(source.id):general});if(lines.length>5000)throw Error('La combinación tiene demasiados ingredientes.');}
  for(const part of node.subrecipes||[]){const child=recipes.find(r=>r.id===part.recipeId);if(!child||!Number.isFinite(Number(part.factor))||Number(part.factor)<=0)throw Error('Una subreceta no está disponible. Actualiza antes de guardar.');visit(child,multiple*Number(part.factor),[...path,node.id]);}
 }
 visit(recipe,Number(factor));return {lines,stages,preparation:groupRoot?'':recipe.preparation||''};
}
export function combineRecipeStructures(parts,recipes,namespace){let lines=[],stages=[];for(const [index,part] of parts.entries()){const subspace=namespace.slice(0,20)+(index+1).toString(16).padStart(3,'0')+namespace.slice(23);const result=copyRecipeStructure(part.recipe,part.factor,recipes,subspace,{groupRoot:true});lines.push(...result.lines);stages.push(...result.stages);}if(stages.length>20)throw Error('La combinación supera 20 etapas. Reduce las preparaciones para conservar sus instrucciones.');return {lines,stages,preparation:''};}
