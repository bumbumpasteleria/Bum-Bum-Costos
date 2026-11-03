import {validDate} from '../reports/finance.mjs';
export function preparationDate(delivery,days){const n=Number(days);if(!validDate(delivery)||!Number.isInteger(n)||n<0||n>365)throw Error('Revisa la fecha de entrega y los días de anticipación.');const date=new Date(delivery+'T12:00:00Z');date.setUTCDate(date.getUTCDate()-n);const result=date.toISOString().slice(0,10);if(!validDate(result))throw Error('La fecha de preparación no es válida.');return result;}
export function pendingPreparations(works){return works.filter(w=>['planned','preparing'].includes(w.details.status)).sort((a,b)=>a.details.date.localeCompare(b.details.date)||a.id.localeCompare(b.id));}
export function duePreparations(works,date){return pendingPreparations(works).filter(w=>w.details.date<=date);}
