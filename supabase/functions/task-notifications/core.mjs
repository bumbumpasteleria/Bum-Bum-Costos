export function validateSubscription(value){
 if(!value||typeof value!=='object')throw Error('Suscripción no válida.');let url;try{url=new URL(value.endpoint)}catch{throw Error('Destino de notificaciones no válido.')}
 const hosts=['fcm.googleapis.com','updates.push.services.mozilla.com','web.push.apple.com'];
 if(url.protocol!=='https:'||url.username||url.password||url.port||value.endpoint.length>4096||!hosts.some(h=>url.hostname===h||h==='web.push.apple.com'&&url.hostname.endsWith('.push.apple.com')))throw Error('Servicio de notificaciones no admitido.');
 if(!/^[A-Za-z0-9_-]{87}$/.test(value.keys?.p256dh||'')||!/^[A-Za-z0-9_-]{22}$/.test(value.keys?.auth||''))throw Error('Claves de suscripción no válidas.');
 return {endpoint:url.href,keys:{p256dh:value.keys.p256dh,auth:value.keys.auth}};
}
export function digestText(preparations,deliveries){const parts=[];if(preparations)parts.push(preparations===1?'1 preparación pendiente':preparations+' preparaciones pendientes');if(deliveries)parts.push(deliveries===1?'1 entrega pendiente':deliveries+' entregas pendientes');return parts.length?parts.join(' y ')+'. Abre Agenda para revisar los detalles.':'Tu dispositivo está listo para recibir recordatorios de Bum Bum Costos.';}
export function validHour(value){if(!Number.isInteger(value)||value<0||value>23)throw Error('Elige una hora válida.');return value;}
