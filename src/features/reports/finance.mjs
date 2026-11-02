export function cents(value){if(value==null||String(value).trim()==='')throw Error('Falta un importe.');const n=Number(value);if(!Number.isFinite(n)||n<0||n>1e10)throw Error('Importe no válido.');return Math.round(n*100);}
export function validDate(value){return /^\d{4}-\d{2}-\d{2}$/.test(value)&&!Number.isNaN(Date.parse(value+'T12:00:00Z'))&&new Date(value+'T12:00:00Z').toISOString().slice(0,10)===value;}
export const money=c=>'RD$ '+(c/100).toLocaleString('es-DO',{minimumFractionDigits:2,maximumFractionDigits:2});
export function report(sales,expenses,{from,to,channel='Todos'}){
 if(!validDate(from)||!validDate(to)||from>to)throw Error('Revisa las fechas del período.');
 const warnings=[],rows=[],costs=[];const included=(date,c)=>date>=from&&date<=to&&(channel==='Todos'||c===channel);
 for(const sale of sales){if(!validDate(sale.date)){warnings.push('Venta sin fecha válida: '+(sale.description||sale.id));continue;}if(!included(sale.date,sale.channel))continue;
  try{const gross=cents(sale.gross),pct=Number(sale.commission);if(!Number.isFinite(pct)||pct<0||pct>100)throw Error('Comisión no válida');const commission=Math.round(gross*pct/100),production=cents(sale.productionCost),extra=cents(sale.extra??0);rows.push({...sale,gross,commission,production,extra,net:gross-commission,result:gross-commission-production-extra});}catch{warnings.push('Revisar importes de venta: '+(sale.description||sale.id));}}
 for(const expense of expenses){if(!validDate(expense.date)){warnings.push('Gasto sin fecha válida: '+expense.description);continue;}if(!included(expense.date,expense.channel||'General'))continue;try{costs.push({...expense,amount:cents(expense.amount)});}catch{warnings.push('Revisar importe de gasto: '+expense.description);}}
 rows.sort((a,b)=>a.date.localeCompare(b.date));costs.sort((a,b)=>a.date.localeCompare(b.date));
 const sum=key=>rows.reduce((n,r)=>n+r[key],0),gross=sum('gross'),commission=sum('commission'),production=sum('production'),extra=sum('extra'),expensesTotal=costs.reduce((n,r)=>n+r.amount,0);
 if([gross,commission,production,extra,expensesTotal].some(n=>!Number.isSafeInteger(n)))throw Error('El total supera el rango de cálculo seguro. Reduce el período.');
 const channels=[...new Set(rows.map(r=>r.channel))].map(name=>({name,count:rows.filter(r=>r.channel===name).length,gross:rows.filter(r=>r.channel===name).reduce((a,r)=>a+r.gross,0)}));
 return {from,to,channel,rows,expenses:costs,warnings,channels,count:rows.length,gross,commission,net:gross-commission,production,extra,expensesTotal,result:gross-commission-production-extra-expensesTotal};
}
