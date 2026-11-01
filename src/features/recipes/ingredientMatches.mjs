export const normalizeIngredient=value=>String(value||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,' ').trim();
const ignored=new Set(['de','del','la','el','las','los','un','una']);
const tokens=value=>normalizeIngredient(value).split(' ').filter(word=>word&&!ignored.has(word));
export function ingredientMatches(name,ingredients){
 const query=tokens(name);if(!query.length)return [];
 // Whole words only: sal must not match salsa. Keep descriptive words such as integral.
 return ingredients.filter(item=>{if(item.itemKind==='material')return false;const words=tokens(item.name);return query.every(word=>words.includes(word))||words.length>0&&words.every(word=>query.includes(word));})
  .sort((a,b)=>Number(normalizeIngredient(b.name)===normalizeIngredient(name))-Number(normalizeIngredient(a.name)===normalizeIngredient(name)));
}
