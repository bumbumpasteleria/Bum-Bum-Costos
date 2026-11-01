export const PREPARATION_LIMIT=20000;
export function readPreparation(instructions){
 if(typeof instructions!=='string'||!instructions)return '';
 try{const meta=JSON.parse(instructions);if(meta&&typeof meta==='object'&&!Array.isArray(meta)){if(typeof meta.preparation==='string')return meta.preparation;if(typeof meta.legacyInstructions==='string')return meta.legacyInstructions;}return '';}catch{return instructions;}
}
export function validatePreparation(value){if(typeof value!=='string'||value.length>PREPARATION_LIMIT)throw new Error('La preparación debe ser texto de hasta 20,000 caracteres.');return value;}
