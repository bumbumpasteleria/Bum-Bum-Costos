// Decimal factors are retained as rational numbers. Rounding is presentation-only.
const gcd=(a,b)=>{a=a<0n?-a:a;while(b){[a,b]=[b,a%b];}return a||1n;};
export function rational(n,d=1n){if(!d)throw Error('División por cero.');if(d<0n){n=-n;d=-d;}const g=gcd(n,d);return {n:n/g,d:d/g};}
export function decimal(value){
 const s=String(value).trim().replace(',','.');
 if(s.length>32||!/^[-+]?(?:\d+(?:\.\d*)?|\.\d+)$/.test(s))throw Error('Escribe un número sin separadores de miles. Puedes usar punto o coma decimal.');
 const negative=s[0]==='-',clean=s.replace(/^[-+]/,''),[whole,fraction='']=clean.split('.');
 if(fraction.length>12)throw Error('La entrada admite hasta 12 decimales.');
 const result=rational(BigInt((whole||'0')+fraction)*(negative?-1n:1n),10n**BigInt(fraction.length));
 if(result.n>1000000000000n*result.d||result.n< -1000000000000n*result.d)throw Error('La cantidad máxima es 1 billón (10¹²).');
 return result;
}
export const multiply=(a,b)=>rational(a.n*b.n,a.d*b.d);
export const divide=(a,b)=>rational(a.n*b.d,a.d*b.n);
export const add=(a,b)=>rational(a.n*b.d+b.n*a.d,a.d*b.d);
const negate=a=>rational(-a.n,a.d);
export function formatDecimal(value,places=4){
 if(!Number.isInteger(places)||places<0||places>12)throw Error('Elige entre 0 y 12 decimales.');
 const scale=10n**BigInt(places),negative=value.n<0n,abs=negative?-value.n:value.n;
 const rounded=(abs*scale*2n+value.d)/(2n*value.d),whole=rounded/scale,tail=(rounded%scale).toString().padStart(places,'0');
 return `${negative&&rounded?'-':''}${whole}${places?'.'+tail:''}`;
}
const unit=(id,label,group,factor,system)=>({id,label,group,factor,system});
export const UNITS=[
 unit('mg','Miligramos (mg)','mass','0.001','SI'),unit('g','Gramos (g)','mass','1','SI'),unit('kg','Kilos (kg)','mass','1000','SI'),
 unit('oz','Onzas de masa (oz)','mass','28.349523125','Internacional avoirdupois'),unit('lb','Libras de masa (lb)','mass','453.59237','Internacional avoirdupois'),
 unit('ml','Mililitros (mL)','volume','1','Métrico'),unit('L','Litros (L)','volume','1000','Métrico'),
 unit('us-floz','Onza líquida estadounidense','volume','29.5735295625','EE. UU. customary'),
 unit('us-cup','Taza estadounidense (8 fl oz US)','volume','236.5882365','EE. UU. customary'),
 unit('us-tbsp','Cucharada estadounidense','volume','14.78676478125','EE. UU. customary'),
 unit('us-tsp','Cucharadita estadounidense','volume','4.92892159375','EE. UU. customary'),
 unit('us-pint','Pinta estadounidense','volume','473.176473','EE. UU. customary'),unit('us-gallon','Galón estadounidense (3.785411784 L)','volume','3785.411784','EE. UU. customary'),
 unit('imp-floz','Onza líquida imperial','volume','28.4130625','Imperial británico'),unit('imp-pint','Pinta imperial','volume','568.26125','Imperial británico'),unit('imp-gallon','Galón imperial','volume','4546.09','Imperial británico'),
 unit('metric-tbsp','Cucharada de 15 mL','volume','15','Convención culinaria declarada'),unit('metric-tsp','Cucharadita de 5 mL','volume','5','Convención culinaria declarada'),
 unit('label-cup','Taza de etiquetado de 240 mL','volume','240','Etiquetado nutricional FDA'),
 unit('metric-cup','Taza métrica de 250 mL','volume','250','Convención culinaria declarada de 250 mL'),
 unit('C','Celsius (°C)','temperature',null,'Temperatura'),unit('F','Fahrenheit (°F)','temperature',null,'Temperatura'),unit('K','Kelvin (K)','temperature',null,'Temperatura')
];
export const getUnit=id=>UNITS.find(u=>u.id===id);
export function convertExact(amount,from,to){
 const a=getUnit(from),b=getUnit(to);if(!a||!b||a.group!==b.group)throw Error('Selecciona unidades de la misma magnitud. Onza de masa y onza líquida son distintas.');
 const value=decimal(amount);
 if(a.group!=='temperature'){
  if(value.n<0n)throw Error('La masa y el volumen no pueden ser negativos.');
  return multiply(value,divide(decimal(a.factor),decimal(b.factor)));
 }
 const kelvin=a.id==='K'?value:a.id==='C'?add(value,decimal('273.15')):add(multiply(add(value,decimal('-32')),rational(5n,9n)),decimal('273.15'));
 if(kelvin.n<0n)throw Error('La temperatura no puede ser inferior al cero absoluto.');
 return b.id==='K'?kelvin:b.id==='C'?add(kelvin,decimal('-273.15')):add(multiply(add(kelvin,decimal('-273.15')),rational(9n,5n)),decimal('32'));
}
export const REFERENCE_LABELS={'ref-cup':'Taza de referencia de la fuente','ref-tbsp':'Cucharada de referencia de la fuente'};
export function ingredientUnits(ingredient){return ingredient.kind==='density'?UNITS.filter(u=>['mass','volume'].includes(u.group)):[...UNITS.filter(u=>u.group==='mass'),{id:ingredient.refUnit,label:REFERENCE_LABELS[ingredient.refUnit],group:'reference'}];}
export function convertIngredient(amount,from,to,ingredient){
 if(!ingredient)throw Error('Selecciona una referencia o registra tu calibración.');
 const allowed=ingredientUnits(ingredient);if(!allowed.some(u=>u.id===from)||!allowed.some(u=>u.id===to))throw Error('Esta referencia culinaria no define mililitros. Para convertir a mL, registra una densidad calibrada.');
 const input=decimal(amount);if(input.n<0n)throw Error('La cantidad no puede ser negativa.');
 let result;
 if(ingredient.kind==='density'){
  const density=divide(decimal(ingredient.massG),decimal(ingredient.volumeMl));if(density.n<=0n)throw Error('La densidad debe ser positiva.');
  const a=getUnit(from),b=getUnit(to);
  if(a.group===b.group)result=convertExact(amount,from,to);
  else if(a.group==='mass')result=divide(divide(convertExact(amount,from,'g'),density),decimal(b.factor));
  else result=divide(multiply(convertExact(amount,from,'ml'),density),decimal(b.factor));
 }else{
  const gramsPerReference=divide(decimal(ingredient.massG),decimal(ingredient.referenceQty));
  if(gramsPerReference.n<=0n)throw Error('La equivalencia debe ser positiva.');
  const grams=from===ingredient.refUnit?multiply(input,gramsPerReference):convertExact(amount,from,'g');
  result=to===ingredient.refUnit?divide(grams,gramsPerReference):divide(grams,decimal(getUnit(to).factor));
 }
 return result;
}
export function recipeQuantity(result,outputUnit,target){
 const to=target.unit==='fl oz'?'us-floz':target.unit;
 if(!getUnit(outputUnit)||!getUnit(to)||getUnit(outputUnit).group!==getUnit(to).group||getUnit(to).group==='temperature')throw Error('El resultado debe estar en una unidad de masa o volumen compatible con ese ingrediente.');
 const normalized=multiply(result,divide(decimal(getUnit(outputUnit).factor),decimal(getUnit(to).factor)));
 const base=multiply(normalized,decimal(getUnit(to).factor));
 if(base.n*1000n<base.d)throw Error('El recetario admite al menos 0.001 en su unidad base.');
 const qty=Number(normalized.n)/Number(normalized.d);if(!Number.isFinite(qty)||qty<=0||qty>1e12)throw Error('La cantidad no cabe en el recetario.');
 return {ingredientId:target.id,qty,unit:target.unit};
}
