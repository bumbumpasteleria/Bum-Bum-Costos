export function taskTransition(row,restore=false){
 const d=row?.details;
 if(!row?.id||!Number.isInteger(row.version)||!d||d.productionId||d.consumptions||d.productionCost!=null)throw Error('Una preparación terminada conserva su historial y no se puede eliminar de esta forma.');
 if(restore?d.status!=='cancelled':!['planned','preparing'].includes(d.status))throw Error('El trabajo cambió. Actualiza la lista antes de continuar.');
 return {...d,status:restore?'planned':'cancelled'};
}
