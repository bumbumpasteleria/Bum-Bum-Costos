export function coverFor(recipe,info){
 const photo=info?.details?.photo;
 if(typeof photo==='string'&&/^data:image\/(jpeg|png|webp);base64,/.test(photo))return {src:photo,illustrative:false};
 const text=[recipe?.name,recipe?.productType,recipe?.category].join(' ').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
 const kind=/suspiro|merengue|cobertura/.test(text)?'suspiro':/tres\s*leches/.test(text)?'tres-leches':'vanilla';
 return {src:'/visual/'+kind+'.webp',illustrative:true};
}
