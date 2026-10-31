import {decimal} from '../../domain/measurements/conversions.mjs';
export const storageKey=owner=>`bum-bum-tools:v1:${owner}`;
export const defaultPreferences=()=>({kind:'mass',amount:'1',from:'lb',to:'g',places:4,ingredientId:'flour',calibrations:[],favorites:[],standards:[]});
const text=(v,max)=>String(v??'').trim().slice(0,max);
const positive=v=>{const n=decimal(v);if(n.n<=0n)throw Error('Las medidas deben ser mayores que cero.');return String(v).trim().replace(',','.');};
export function calibration(input){
 const data={id:text(input.id,80),name:text(input.name,100),kind:'density',massG:positive(input.massG),volumeMl:positive(input.volumeMl),source:text(input.source,300),conditions:text(input.conditions,500),date:text(input.date,10),sourceName:'Calibración de tu negocio'};
 if(!data.id||!data.name||!data.source||!data.conditions||!/^\d{4}-\d{2}-\d{2}$/.test(data.date))throw Error('Completa nombre, fuente o método, condiciones y fecha.');
 return data;
}
export function commercialStandard(input){
 const result={id:text(input.id,80),name:text(input.name,100),shape:text(input.shape,20),commercialQty:positive(input.commercialQty),height:positive(input.height),layers:positive(input.layers),mixtureG:positive(input.mixtureG),yieldG:positive(input.yieldG),portions:positive(input.portions),equivalence:text(input.equivalence,500),date:text(input.date,10)};
 if(!['round','square','rectangle'].includes(result.shape)||!result.id||!result.name||!result.equivalence||!/^\d{4}-\d{2}-\d{2}$/.test(result.date))throw Error('Completa el estándar y su equivalencia comercial.');
 for(const key of result.shape==='round'?['diameter']:result.shape==='square'?['width']:['width','length'])result[key]=positive(input[key]);
 if(!Number.isInteger(Number(result.layers))||!Number.isInteger(Number(result.portions)))throw Error('Capas y porciones deben ser números enteros.');
 return result;
}
export function loadPreferences(storage,owner){
 try{const raw=JSON.parse(storage.getItem(storageKey(owner)));if(!raw||typeof raw!=='object')return defaultPreferences();
  const defaults=defaultPreferences(),clean={...defaults};
  for(const k of ['kind','amount','from','to','ingredientId'])if(typeof raw[k]==='string'&&raw[k].length<100)clean[k]=raw[k];
  if(Number.isInteger(raw.places)&&raw.places>=0&&raw.places<=12)clean.places=raw.places;
  const read=(list,validate)=>Array.isArray(list)?list.slice(0,30).flatMap(r=>{try{return [validate(r)]}catch{return []}}):[];
  clean.calibrations=read(raw.calibrations,calibration);clean.standards=read(raw.standards,commercialStandard);
  clean.favorites=read(raw.favorites,r=>{if(!['mass','volume','temperature','ingredient'].includes(r.kind)||!['amount','from','to','ingredientId'].every(k=>typeof r[k]==='string'&&r[k].length<100))throw Error();return {kind:r.kind,amount:r.amount,from:r.from,to:r.to,ingredientId:r.ingredientId};});
  return clean;
 }catch{return defaultPreferences();}
}
export function savePreferences(storage,owner,value){storage.setItem(storageKey(owner),JSON.stringify(value));}

