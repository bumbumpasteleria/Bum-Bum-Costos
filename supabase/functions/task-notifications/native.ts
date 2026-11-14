import {SignJWT,importPKCS8} from 'npm:jose@6.1.0';
const hash=async(value:string)=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(value)))).map(n=>n.toString(16).padStart(2,'0')).join('');
export function nativeSettings(){try{const s=JSON.parse(Deno.env.get('BUM_FCM_SERVICE_ACCOUNT')||'null');return s?.type==='service_account'&&s.project_id==='bum-bum-costos'&&typeof s.private_key==='string'&&typeof s.client_email==='string'?s:null}catch{return null}}
export async function nativeIdentity(value:any,requireToken=false){
 if(value?.platform!=='android'||!/^[0-9a-f-]{36}$/i.test(value.deviceId)||!/^[0-9a-f-]{72}$/i.test(value.proof)||requireToken&&(typeof value.token!=='string'||value.token.length<30||value.token.length>4096||!/^[\w:.-]+$/.test(value.token)))throw Error('Dispositivo no válido.');
 return {id:await hash('android:'+value.deviceId),proofHash:await hash(value.proof)};
}
let cached:{token:string,until:number}|null=null;
async function accessToken(){
 if(cached&&cached.until>Date.now())return cached.token;
 const s=nativeSettings();if(!s)throw Error('Servicio Android sin configurar.');
 const assertion=await new SignJWT({scope:'https://www.googleapis.com/auth/firebase.messaging'}).setProtectedHeader({alg:'RS256'}).setIssuer(s.client_email).setAudience('https://oauth2.googleapis.com/token').setIssuedAt().setExpirationTime('50m').sign(await importPKCS8(s.private_key,'RS256'));
 const response=await fetch('https://oauth2.googleapis.com/token',{method:'POST',body:new URLSearchParams({grant_type:'urn:ietf:params:oauth:grant-type:jwt-bearer',assertion}),signal:AbortSignal.timeout(10000)});const result=await response.json();if(!response.ok||!result.access_token)throw Error('No se pudo autenticar el envío Android.');cached={token:result.access_token,until:Date.now()+40*60000};return cached.token;
}
export async function sendNative(row:any,body:string,tag:string){
 const response=await fetch('https://fcm.googleapis.com/v1/projects/bum-bum-costos/messages:send',{method:'POST',headers:{Authorization:'Bearer '+await accessToken(),'Content-Type':'application/json'},body:JSON.stringify({message:{token:row.subscription.token,data:{ownerId:row.owner_id||row.ownerId,body,tag},android:{priority:'high',ttl:'3600s'}}}),signal:AbortSignal.timeout(10000)});
 if(!response.ok){const result=await response.json().catch(()=>({}));const invalid=result.error?.details?.some((d:any)=>d.errorCode==='UNREGISTERED');throw Object.assign(Error('No se pudo entregar el aviso Android.'),{statusCode:invalid?410:response.status})}
}
export async function nativeAction(db:any,query:any,owner:string,body:any,ready:boolean){
 const action=body.action;if(action==='native_config')return {ready:ready&&Boolean(nativeSettings())};
 if(!['native_subscribe','native_status','native_unsubscribe','native_test'].includes(action))throw Error('Acción no disponible.');
 const identity=await nativeIdentity(body.subscription,action==='native_subscribe');
 const existing=await query(db.from('push_subscriptions').select('*').eq('id',identity.id).maybeSingle());
 if(existing&&existing.subscription.proofHash!==identity.proofHash)throw Error('La identidad del dispositivo cambió.');
 if(action==='native_subscribe'){
  if(!ready||!nativeSettings())throw Error('Estamos terminando de configurar los avisos de Android.');
  if(!Number.isInteger(body.hour)||body.hour<0||body.hour>23)throw Error('Selecciona una hora válida.');
  const devices=await query(db.from('push_subscriptions').select('id').eq('owner_id',owner).eq('enabled',true));if(devices.length>=10&&!devices.some((d:any)=>d.id===identity.id))throw Error('Esta cuenta ya tiene diez dispositivos con avisos activos.');
  await query(db.from('push_subscriptions').upsert({id:identity.id,owner_id:owner,subscription:{platform:'android',proofHash:identity.proofHash,token:body.subscription.token},enabled:true,hour:body.hour,last_sent_day:existing?.owner_id===owner?existing.last_sent_day:null,claimed_until:null,updated_at:new Date().toISOString()}));return {enabled:true,hour:body.hour};
 }
 if(!existing||existing.owner_id!==owner)return {enabled:false,hour:9};
 if(action==='native_status')return {enabled:existing.enabled,hour:existing.hour};
 if(action==='native_unsubscribe'){await query(db.from('push_subscriptions').update({enabled:false}).eq('id',identity.id).eq('owner_id',owner));return {enabled:false}}
 if(!existing.enabled)throw Error('Activa primero las notificaciones.');
 if(existing.last_test_at&&Date.now()-new Date(existing.last_test_at).getTime()<60000)throw Error('Espera un minuto antes de enviar otra prueba.');
 let claim=db.from('push_subscriptions').update({last_test_at:new Date().toISOString()}).eq('id',identity.id).eq('owner_id',owner);claim=existing.last_test_at?claim.eq('last_test_at',existing.last_test_at):claim.is('last_test_at',null);if(!(await query(claim.select('id'))).length)throw Error('Ya se está enviando una prueba.');
 await sendNative(existing,'Tu dispositivo está listo para recibir los avisos de Bum Bum Costos.','bum-prueba');return {sent:true};
}
