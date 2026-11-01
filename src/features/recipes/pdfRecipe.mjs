import {ingredientMatches,normalizeIngredient} from './ingredientMatches.mjs';
// Deliberately conservative: unsupported measures stay unresolved for human review.
export const normalize=value=>String(value||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,' ').trim();
const aliases={g:'g',gr:'g',gramo:'g',gramos:'g',kg:'kg',kilogramo:'kg',kilogramos:'kg',lb:'lb',libra:'lb',libras:'lb',oz:'oz',onza:'oz',onzas:'oz',mg:'mg',ml:'ml',mililitro:'ml',mililitros:'ml',l:'L',litro:'L',litros:'L',unidad:'unidad',unidades:'unidad',ud:'unidad',uds:'unidad',docena:'docena',docenas:'docena'};
const fractions={'½':'.5','¼':'.25','¾':'.75','⅓':'1/3','⅔':'2/3','⅛':'.125','⅜':'.375','⅝':'.625','⅞':'.875'};
export function parseQuantity(value){
 if(!String(value).trim())return NaN;
 let s=String(value).trim().replace(/(\d)\s*([½¼¾⅓⅔⅛⅜⅝⅞])/g,'$1 $2').replace(/[½¼¾⅓⅔⅛⅜⅝⅞]/g,c=>fractions[c]).replace(',','.');
 const parts=s.split(/\s+/);if(parts.length>2)return NaN;
 const values=parts.map(p=>{if(/^\d+\/\d+$/.test(p)){const [a,b]=p.split('/').map(Number);return b?a/b:NaN;}return /^(?:\d+(?:\.\d+)?|\.\d+)$/.test(p)?Number(p):NaN;});
 return values.reduce((a,b)=>a+b,0);
}
export function parseIngredient(raw,ingredients=[]){
 const cleaned=raw.trim().replace(/^(?:[•●*]\s*|-\s+)/,''),quantity=cleaned.match(/^(\d+\s+\d+\/\d+|\d+\s*[½¼¾⅓⅔⅛⅜⅝⅞]|\d+\/\d+|\d+(?:[.,]\d+)?|[½¼¾⅓⅔⅛⅜⅝⅞])\s*/);
 let name=cleaned,qty='',unit='';
 if(quantity){qty=String(parseQuantity(quantity[1]));const rest=cleaned.slice(quantity[0].length);const measure=rest.match(/^([a-záéíóúñ]+)\.?\s+/i);if(measure&&aliases[normalize(measure[1])]){unit=aliases[normalize(measure[1])];name=rest.slice(measure[0].length).replace(/^de\s+/i,'');}else name=rest;}
 const candidates=ingredientMatches(name,ingredients);
 return {raw,name,qty,unit,ingredientId:candidates.length===1&&normalizeIngredient(candidates[0].name)===normalizeIngredient(name)?candidates[0].id:'',ambiguous:candidates.length>1};
}
export function parseRecipeText(text,ingredients=[]){
 if(typeof text!=='string'||text.length>100000)throw new Error('Usa una receta de hasta 100,000 caracteres.');
 const rows=text.split(/\r?\n/).map(s=>s.trim()).filter(Boolean);let section='',name='',preparation=[],lines=[],unclassified=[],yieldValue='',yieldUnit='unidad';
 for(const row of rows){const normalized=normalize(row);
  if(/^(ingredientes|ingredients)\s*:?$/i.test(row)){section='ingredients';continue;}
  if(/^(preparaci[oó]n|elaboraci[oó]n|procedimiento|instrucciones|instructions|preparation)\s*:?$/i.test(row)){section='preparation';continue;}
  const yieldMatch=row.match(/^(?:rendimiento|rinde|porciones)\s*:?\s*(\d+(?:[.,]\d+)?)\s*(.*)$/i);
  if(yieldMatch){yieldValue=yieldMatch[1].replace(',','.');const u=normalize(yieldMatch[2]);yieldUnit=/^porcion/.test(u)?'porción':aliases[u]||'';continue;}
  if(section==='preparation'){preparation.push(row);continue;}
  if(!name&&section!=='ingredients'&&!/^\d/.test(row)){name=row.replace(/^receta\s*:\s*/i,'');continue;}
  if(section==='ingredients'||/^[•●*]?\s*(?:\d|[½¼¾⅓⅔⅛⅜⅝⅞])/.test(row)){lines.push(parseIngredient(row,ingredients));continue;}
  if(normalized)unclassified.push(row);
 }
 return {name:name.slice(0,160),yield:yieldValue,yieldUnit,productType:'Otro artículo',scaling:'scalable',bookId:'',preparation:preparation.join('\n'),lines,unclassified};
}
export function textFromItems(items){
 const lines=[];let current=[],y=null;
 for(const item of items){if(typeof item.str!=='string')continue;const nextY=item.transform?.[5];if(current.length&&y!=null&&nextY!=null&&Math.abs(y-nextY)>3){lines.push(current.join(' '));current=[];}current.push(item.str);y=nextY;if(item.hasEOL){lines.push(current.join(' '));current=[];y=null;}}
 if(current.length)lines.push(current.join(' '));return lines.join('\n');
}
export function validatePdfFile(file){if(!file||!file.name?.toLowerCase().endsWith('.pdf'))throw new Error('Selecciona un archivo PDF.');if(file.size>10*1024*1024)throw new Error('El PDF debe pesar como máximo 10 MB.');if(!file.size)throw new Error('El PDF está vacío.');}
