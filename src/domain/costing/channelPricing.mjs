export const saleChannels=['Directa','Uber Eats','PedidosYa'];
export function channelPricePlan({baseCost,packaging=0,labor=0,other=0,commission=0,margin=0}){
 const values=[baseCost,packaging,labor,other,commission,margin];
 if(values.some(v=>v==null||String(v).trim()===''||!Number.isFinite(Number(v))||Number(v)<0||Number(v)>=1e9))throw Error('Completa costos y porcentajes válidos.');
 const [base,pack,work,others,fee,profit]=values.map(Number);if(fee>=100||profit>=100||fee+profit>=100)throw Error('Comisión y margen deben sumar menos de 100%.');
 const cost=base+pack+work+others,price=Math.ceil((cost/(1-(fee+profit)/100))*100-1e-8)/100;
 if(price>=1e9)throw Error('Precio fuera del rango permitido.');
 return {cost,price,commissionAmount:price*fee/100,profit:price*(1-fee/100)-cost};
}
export function saleChannelDefaults(product,channel){const plan=product?.channel_prices?.[channel];return {unitPrice:plan?.price??product?.sale_price??'',commission:String(plan?.commission??0),perUnitExtras:plan?Number(plan.packaging)+Number(plan.labor)+Number(plan.other):0,extra:'0'};}
