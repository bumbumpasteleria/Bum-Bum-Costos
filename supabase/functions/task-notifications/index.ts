import {noticeText,validatePreferences} from './notices.mjs';
import {nativeAction,sendNative} from './native.ts';
import {createClient} from 'npm:@supabase/supabase-js@2';
import webpush from 'npm:web-push@3.6.7';
import {validateSubscription,digestText,validHour} from './core.mjs';
const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
const site='https://bum-bum-costos.bumbumpasteleria.workers.dev';
async function query(p:PromiseLike<{data:any,error:any}>){const {data,error}=await p;if(error)throw Error('No se pudo completar la operación.');return data;}
async function config(){let row=await query(db.from('push_service_config').select('*').eq('id',1).single());if(!row.vapid&&row.ready){await query(db.from('push_service_config').update({vapid:webpush.generateVAPIDKeys()}).eq('id',1).is('vapid',null));row=await query(db.from('push_service_config').select('*').eq('id',1).single())}return row;}
async function send(row:any,keys:{publicKey:string,privateKey:string},body:string,tag:string,target='Agenda y cobros'){if(row.subscription?.platform==='android'){await sendNative(row,body,tag,target);return;}await webpush.sendNotification(validateSubscription(row.subscription),JSON.stringify({ownerId:row.owner_id||row.ownerId,title:'Bum Bum Costos',body,tag,target}),{vapidDetails:{subject:'mailto:bumbumpasteleria@gmail.com',...keys},TTL:3600,timeout:10000,urgency:'normal',contentEncoding:'aes128gcm'});}
async function dispatch(settings:any){const rows=await query(db.rpc('bum_notice_claim',{p_limit:20}));let sent=0,failed=0;await Promise.all(rows.map(async(row:any)=>{let failedRow=false;for(const event of row.events){try{await send(row,settings.vapid,noticeText(event.kind,event.count),'bum-'+event.kind+'-'+row.day,event.target);await query(db.rpc('bum_notice_ack',{p_id:row.id,p_owner:row.ownerId,p_kind:event.kind,p_day:row.day}));sent++;}catch(error){failed++;failedRow=true;if((error as {statusCode?:number}).statusCode===404||(error as {statusCode?:number}).statusCode===410){await query(db.from('push_subscriptions').update({enabled:false}).eq('id',row.id).eq('owner_id',row.ownerId));break;}}}await query(db.from('push_subscriptions').update({claimed_until:failedRow?new Date(Date.now()+15*60000).toISOString():null}).eq('id',row.id).eq('owner_id',row.ownerId));}));return {sent,failed};}
Deno.serve(async req=>{
 const origin=req.headers.get('Origin');const headers={'Content-Type':'application/json','Access-Control-Allow-Origin':origin==='https://localhost'?origin:site,'Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info','Access-Control-Allow-Methods':'POST,OPTIONS','Vary':'Origin'};const response=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers});
 if(origin&&![site,'https://localhost'].includes(origin))return response({error:'Origen no permitido.'},403);if(req.method==='OPTIONS')return new Response(null,{status:204,headers});if(req.method!=='POST')return response({error:'Método no permitido.'},405);
 try{
  const text=await req.text();if(text.length>16000)return response({error:'Solicitud demasiado grande.'},413);const body=JSON.parse(text||'{}');
  if(body.action==='dispatch'){
   const row=await query(db.from('push_service_config').select('*').eq('id',1).single());if(req.headers.get('x-bum-cron')!==row.cron_token)return response({error:'No autorizado.'},401);
   if(!row.ready)return response({sent:0,failed:0,ready:false});return response(await dispatch(await config()));
  }
  const token=req.headers.get('Authorization')?.replace(/^Bearer\s+/i,'');if(!token)return response({error:'Inicia sesión.'},401);const {data,error}=await db.auth.getUser(token);if(error||!data.user)return response({error:'Inicia sesión nuevamente.'},401);const owner=data.user.id;
  const profile=await query(db.from('business_profiles').select('status,password_required').eq('id',owner).single());if(profile.status!=='approved'||profile.password_required)return response({error:'Cuenta no autorizada.'},403);
  if(['preferences_get','preferences_set'].includes(body.action)){
   const admin=Boolean(await query(db.from('business_admins').select('user_id').eq('user_id',owner).maybeSingle()));
   if(body.action==='preferences_set'){const preferences=validatePreferences(body.preferences,admin);await query(db.from('push_preferences').upsert({owner_id:owner,preferences}));return response({preferences,isAdmin:admin})}
   const saved=await query(db.from('push_preferences').select('preferences').eq('owner_id',owner).maybeSingle());return response({preferences:validatePreferences(saved?.preferences||{},admin),isAdmin:admin});
  }
  if(typeof body.action==='string'&&body.action.startsWith('native_'))return response(await nativeAction(db,query,owner,body,Boolean((await config()).ready)));
  if(body.action==='config'){const c=await config();return response(c.ready?{ready:true,publicKey:c.vapid.publicKey}:{ready:false});}
  if(body.action==='subscribe'&&!(await config()).ready)return response({error:'El servicio de recordatorios todavía se está configurando. Tus pendientes siguen en Agenda.'},503);
  if(!['subscribe','status','unsubscribe','test'].includes(body.action))return response({error:'Acción no disponible.'},400);
  const subscription=validateSubscription(body.subscription);const id=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(subscription.endpoint)))).map(n=>n.toString(16).padStart(2,'0')).join('');
  const existing=await query(db.from('push_subscriptions').select('*').eq('id',id).maybeSingle());
  // A subscription's cryptographic keys prove possession of this browser endpoint when accounts change.
  if(existing&&JSON.stringify(existing.subscription.keys)!==JSON.stringify(subscription.keys))return response({error:'La suscripción cambió. Desactívala y vuelve a activarla.'},409);
  if(body.action==='subscribe'){
   const devices=await query(db.from('push_subscriptions').select('id').eq('owner_id',owner).eq('enabled',true));if(devices.length>=10&&!devices.some((d:any)=>d.id===id))return response({error:'Esta cuenta ya tiene diez dispositivos con avisos activos.'},409);
   const hour=validHour(body.hour??9),same=existing?.owner_id===owner;
   await query(db.from('push_subscriptions').upsert({id,owner_id:owner,subscription,enabled:true,hour,last_sent_day:same?existing.last_sent_day:null,claimed_until:null,updated_at:new Date().toISOString()}));return response({enabled:true,hour});
  }
  if(!existing||existing.owner_id!==owner)return response({enabled:false});
  if(body.action==='status')return response({enabled:existing.enabled,hour:existing.hour});
  if(body.action==='unsubscribe'){await query(db.from('push_subscriptions').update({enabled:false}).eq('id',id).eq('owner_id',owner));return response({enabled:false});}
  if(!existing.enabled)return response({error:'Activa primero las notificaciones.'},400);
  if(existing.last_test_at&&Date.now()-new Date(existing.last_test_at).getTime()<60000)return response({error:'Espera un minuto antes de enviar otra prueba.'},429);
  // Claim the test slot before delivery to prevent parallel retries from sending duplicates.
  let claim=db.from('push_subscriptions').update({last_test_at:new Date().toISOString()}).eq('id',id).eq('owner_id',owner);claim=existing.last_test_at?claim.eq('last_test_at',existing.last_test_at):claim.is('last_test_at',null);if(!(await query(claim.select('id'))).length)return response({error:'Ya se está enviando una prueba.'},409);
  await send(existing,(await config()).vapid,digestText(0,0),'bum-prueba');return response({sent:true});
 }catch(error){console.error('PUSH_OPERATION_FAILED',Number((error as {statusCode?:number}).statusCode)||0);return response({error:Number((error as {statusCode?:number}).statusCode)===410?'El dispositivo dejó de aceptar avisos. Desactívalos y actívalos nuevamente.':'No se pudo completar la solicitud de notificaciones. Intenta nuevamente.'},400);}
});
