export function quantity(value,label,{zero=false,max=1e9}={}){
 if(value==null||String(value).trim()==='')throw Error('Completa '+label+'.');
 const s=String(value).trim();if(s.length>80||!/^\d+(?:[.,]\d+)?$/.test(s))throw Error('Revisa '+label+'.');
 const n=Number(s.replace(',','.'));if(!Number.isFinite(n)||n>max||n<0||(!zero&&n===0))throw Error('Revisa '+label+'.');return n;
}
export function panVolume(pan){
 const height=quantity(pan.height,'la altura útil',{max:200}),fill=quantity(pan.fill,'el llenado',{max:100}),count=quantity(pan.count,'la cantidad de moldes',{max:10000});
 if(!Number.isInteger(count))throw Error('La cantidad de moldes debe ser entera.');
 let area;if(pan.shape==='round'){const d=quantity(pan.diameter,'el diámetro',{max:500});area=Math.PI*(d/2)**2;}
 else if(pan.shape==='square'){area=quantity(pan.width,'el lado',{max:500})**2;}
 else if(pan.shape==='rectangle'){area=quantity(pan.width,'el ancho',{max:500})*quantity(pan.length,'el largo',{max:500});}
 else throw Error('Selecciona la forma del molde.');
 const volume=area*height*fill/100*count;if(!Number.isFinite(volume)||volume<=0)throw Error('Las dimensiones son demasiado pequeñas para calcular el volumen.');return volume;
}
export function adaptPans(from,to){const original=panVolume(from),target=panVolume(to),factor=target/original;if(!Number.isFinite(factor)||factor<=0)throw Error('Revisa las dimensiones: el factor está fuera del rango de cálculo.');return {original,target,factor};}
export function bakerFormula(rows,target){
 if(!Array.isArray(rows)||!rows.length)throw Error('Agrega ingredientes a la fórmula.');
 let flour=0,water=0,total=0;const lines=rows.map(row=>{if(!String(row.name||'').trim())throw Error('Completa el nombre de cada ingrediente.');if(!['flour','water','other'].includes(row.kind))throw Error('Clasifica cada ingrediente.');const grams=quantity(row.grams,'los gramos de '+row.name,{zero:true});if(row.kind==='flour')flour+=grams;if(row.kind==='water')water+=grams;total+=grams;return {...row,grams};});
 if(!flour)throw Error('Indica el peso de al menos una harina.');
 const wanted=quantity(target,'el peso de masa deseado'),factor=wanted/total;
 return {flour,water,total,factor,hydration:water/flour*100,lines:lines.map(row=>({...row,percentage:row.grams/flour*100,adjusted:row.grams*factor}))};
}
export function measuredYield(raw,finished,portion){
 const input=quantity(raw,'el peso inicial'),output=quantity(finished,'el peso final',{zero:true}),unit=quantity(portion,'el peso por porción');
 if(output>input)throw Error('El peso final supera el inicial. Incluye primero todas las adiciones en el peso inicial.');
 // Count whole portions as decimal fractions, without rounding a near-boundary weight up.
 const decimal=value=>{const [a,b='']=String(value).trim().replace(',','.').split('.');return {n:BigInt(a+b),d:10n**BigInt(b.length)}};
 const a=decimal(finished),b=decimal(portion),whole=Number(a.n*b.d/(a.d*b.n));if(!Number.isSafeInteger(whole))throw Error('El número de porciones es demasiado grande. Revisa el peso por porción.');
 const ratio=output/input,remainder=Number(a.n*b.d-BigInt(whole)*b.n*a.d)/Number(a.d*b.d);
 return {input,output,ratio,loss:input-output,lossPct:(1-ratio)*100,whole,remainder};
}
