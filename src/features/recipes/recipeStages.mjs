export function stagesFromInstructions(text){try{const value=JSON.parse(text);return Array.isArray(value.stages)?value.stages:[];}catch{return [];}}
export function stagePayload(stages,lines){
 if(!Array.isArray(stages)||stages.length>20)throw Error('Puedes registrar hasta 20 etapas.');
 const ids=new Set();return stages.map(stage=>{const name=String(stage.name||'').trim(),preparation=String(stage.preparation||'');if(!stage.id||ids.has(stage.id)||!name||name.length>100||preparation.length>10000)throw Error('Cada etapa necesita un nombre de hasta 100 caracteres e instrucciones de hasta 10,000 caracteres.');ids.add(stage.id);return {id:stage.id,name,preparation,lineIndexes:lines.flatMap((line,index)=>line.stageId===stage.id?[index]:[])};});
}
export function editorStageLines(lines,stages){return lines.map(line=>({...line,stageId:stages.find(stage=>stage.lineIds?.includes(line.id)||stage.id===line.stageId)?.id||''}));}
