export const normalizeRecipeSearch=value=>String(value||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLocaleLowerCase('es').trim();
export function matchesRecipeName(recipe,query){return normalizeRecipeSearch(recipe.name).includes(normalizeRecipeSearch(query));}
