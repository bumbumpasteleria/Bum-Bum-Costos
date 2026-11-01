export const stockNumber=value=>value==null?null:Number(value);
export function stockLabel(quantity,unit){const plurals={'porción':'porciones',unidad:'unidades',bandeja:'bandejas',vaso:'vasos',caja:'cajas'};return Number(quantity).toLocaleString('es-DO',{maximumFractionDigits:3})+' '+(Number(quantity)===1?unit:(plurals[unit]||unit));}
export function minimumReached(quantity,minimum){return Number.isFinite(quantity)&&Number.isFinite(minimum)&&quantity<=minimum;}
export function availableBatches(batches,day){return batches.filter(b=>Number(b.remaining_quantity)>0&&b.prepared_on<=day&&(!b.expires_on||b.expires_on>=day));}
export function fridgeSummary(products,batches,day){return products.map(product=>{
 const lots=availableBatches(batches.filter(b=>b.product_id===product.id),day);
 const quantity=lots.reduce((sum,b)=>sum+Number(b.remaining_quantity),0);
 return {...product,quantity,lots,pending:minimumReached(quantity,Number(product.minimum_quantity))};
});}
export function nonnegative(value,label='Cantidad'){
 if(value==null||String(value).trim()==='')throw Error('Introduce '+label.toLowerCase()+'.');
 const n=Number(value);if(!Number.isFinite(n)||n<0||n>=1e9)throw Error(label+' fuera del rango permitido.');return n;
}
