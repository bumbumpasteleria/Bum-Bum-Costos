export function unitPrice(value){
 if(value==null||String(value).trim()==='')throw Error('Indica el precio de venta por unidad.');
 const text=String(value).trim().replace(',','.');
 if(!/^\d+(?:\.\d{1,2})?$/.test(text))throw Error('El precio admite hasta dos decimales.');
 const n=Number(text);if(!Number.isFinite(n)||n<0||n>=1e9)throw Error('Precio de venta no válido.');return n;
}
export function saleTotal(quantity,price){
 if(quantity==null||String(quantity).trim()==='')throw Error('Indica la cantidad vendida.');
 const q=Number(quantity);if(!Number.isFinite(q)||q<.001||q>=1e9||Math.abs(q*1000-Math.round(q*1000))>1e-6)throw Error('Cantidad no válida: usa hasta tres decimales.');
 const cents=Math.round(unitPrice(price)*100);const total=Math.round((q*cents)+1e-8)/100;
 if(total>=1e12)throw Error('El total es demasiado grande.');return total;
}
export const priceLabel=value=>value==null?'Sin precio de venta':('RD$ '+Number(value).toLocaleString('es-DO',{minimumFractionDigits:2,maximumFractionDigits:2}));
