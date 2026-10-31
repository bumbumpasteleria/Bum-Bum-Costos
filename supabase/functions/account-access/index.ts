import {createClient} from 'npm:@supabase/supabase-js@2';
import nodemailer from 'npm:nodemailer@9';
import {validateRequest} from './validation.ts';

const site=Deno.env.get('SITE_URL')||'https://bum-bum-costos.bumbumpasteleria.workers.dev';
const adminEmail='bumbumpasteleria@gmail.com';
const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
const smtpUser=Deno.env.get('SMTP_USERNAME')?.trim();
const smtpPassword=Deno.env.get('SMTP_PASSWORD')?.replace(/\s/g,'');
const transport=nodemailer.createTransport({host:'smtp.gmail.com',port:465,secure:true,auth:{user:smtpUser,pass:smtpPassword},connectionTimeout:10000,socketTimeout:15000});
async function query(operation:any){const {data,error}=await operation;if(error)throw error;return data;}
function headers(origin:string){return {'Content-Type':'application/json','Access-Control-Allow-Origin':origin,'Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info','Access-Control-Allow-Methods':'POST,OPTIONS','Vary':'Origin'};}
async function mail(to:string,subject:string,text:string){if(!smtpUser||!smtpPassword)throw new Error('SMTP_NOT_CONFIGURED');try{await transport.sendMail({from:{name:'Bum Bum Costos',address:smtpUser},to,subject,text});}catch(error){const e=error as {code?:string;responseCode?:number};const code=['EAUTH','ECONNECTION','ETIMEDOUT','ESOCKET','EENVELOPE','EMESSAGE','EDNS'].includes(e.code||'')?e.code:'SMTP_ERROR';console.error('SMTP_DELIVERY_FAILED',code,Number.isInteger(e.responseCode)?e.responseCode:0);throw new Error('SMTP_DELIVERY_FAILED');}}
async function assertAdmin(req:Request){const token=req.headers.get('Authorization')?.replace(/^Bearer\s+/i,'');if(!token)throw new Error('UNAUTHORIZED');const {data,error}=await db.auth.getUser(token);if(error||!data.user)throw new Error('UNAUTHORIZED');const row=await query(db.from('business_admins').select('user_id').eq('user_id',data.user.id).maybeSingle());if(!row)throw new Error('FORBIDDEN');return data.user.id;}

Deno.serve(async req=>{
 const origin=req.headers.get('Origin')||site;
 const allowed=(Deno.env.get('ALLOWED_ORIGINS')||site).split(',').map(s=>s.trim());
 const h=headers(origin);if(!allowed.includes(origin))return new Response('Origen no permitido',{status:403});
 if(req.method==='OPTIONS')return new Response(null,{headers:h});
 if(req.method!=='POST')return Response.json({error:'Método no permitido'},{status:405,headers:h});
 try{
  const raw=await req.text();if(raw.length>12000)return Response.json({error:'Solicitud demasiado extensa'},{status:413,headers:h});
  const body=JSON.parse(raw),action=body.action;
  if(action==='request'){
   if(!smtpUser||!smtpPassword)return Response.json({error:'Las solicitudes aún no están habilitadas. Intenta más tarde.'},{status:503,headers:h});
   const data=validateRequest(body.data||{});
   const ip=req.headers.get('x-forwarded-for')||'unknown';
   const digest=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')+ip));
   const ipHash=Array.from(new Uint8Array(digest),b=>b.toString(16).padStart(2,'0')).join('');
   const id=await query(db.rpc('bum_submit_account_request',{p_data:data,p_ip_hash:ipHash}));
   if(id){try{await mail(adminEmail,'Nueva solicitud de cuenta — Bum Bum Costos',`Dueño: ${data.ownerName}\nNegocio: ${data.businessName}\nCorreo: ${data.email}\nUbicación: ${data.location}\nTipo: ${data.businessType}\nDescripción: ${data.description}\n\nRevisa y aprueba desde ${site} (menú Solicitudes).`);await query(db.from('account_requests').update({admin_notified:true}).eq('id',id));}catch{console.error('No se pudo notificar una solicitud; permanece en la bandeja de administración.');}}
   return Response.json({message:'Solicitud recibida. Si corresponde, recibirás una invitación cuando la administradora la apruebe.'},{headers:h});
  }
  const adminId=await assertAdmin(req);
  if(action==='list'){const page=Math.max(0,Math.min(10000,Number(body.page)||0));const data=await query(db.from('account_requests').select('*').order('created_at',{ascending:false}).range(page*50,page*50+49));return Response.json({requests:data},{headers:h});}
  if(action==='test-email'){await mail(adminEmail,'Prueba de correo — Bum Bum Costos','La conexión de correo de Bum Bum Costos está lista.');return Response.json({ok:true},{headers:h});}
  if(!/^[0-9a-f-]{36}$/i.test(body.id||''))throw new Error('Solicitud no válida.');
  if(action==='reject'){await query(db.from('account_requests').update({status:'rejected',reviewed_by:adminId,reviewed_at:new Date().toISOString()}).eq('id',body.id).eq('status','pending').select('id').single());return Response.json({ok:true},{headers:h});}
  if(action!=='approve'&&action!=='resend')throw new Error('Acción no válida.');
  let row=await query(db.from('account_requests').select('*').eq('id',body.id).single());
  if(action==='approve'){
   if(row.status==='approving'){
    if(Date.now()-Date.parse(row.reviewed_at)<300000)throw new Error('Aprobación en proceso.');
    row=await query(db.from('account_requests').update({reviewed_by:adminId,reviewed_at:new Date().toISOString()}).eq('id',row.id).eq('status','approving').eq('reviewed_at',row.reviewed_at).select().single());
   }else row=await query(db.from('account_requests').update({status:'approving',reviewed_by:adminId,reviewed_at:new Date().toISOString()}).eq('id',row.id).eq('status','pending').select().single());
  }
  else if(row.status!=='approved')throw new Error('La cuenta aún no está aprobada.');
  let linkData;
  try{
   const existingUser=await query(db.rpc('bum_request_approved_user',{p_request_id:row.id}));
   const result=await db.auth.admin.generateLink({type:existingUser?'magiclink':'invite',email:row.email,options:{redirectTo:site}});if(result.error)throw result.error;linkData=result.data;
   await query(db.from('account_requests').update({status:'approved',auth_user_id:linkData.user.id,invitation_sent:false}).eq('id',row.id));
  }catch(error){if(action==='approve')await db.from('account_requests').update({status:'pending'}).eq('id',row.id).eq('status','approving');throw error;}
  try{await mail(row.email,'Tu cuenta fue aprobada — Bum Bum Costos',`Hola, ${row.owner_name}.\n\nTu solicitud para ${row.business_name} fue aprobada. Abre este enlace personal para ingresar y establecer tu contraseña:\n\n${linkData.properties.action_link}\n\nNo compartas este enlace. Si caduca, solicita una nueva invitación a la administradora.`);await query(db.from('account_requests').update({invitation_sent:true}).eq('id',row.id));return Response.json({ok:true},{headers:h});}
  catch{return Response.json({ok:true,warning:'Cuenta aprobada, pero no se pudo enviar la invitación. Usa Reenviar invitación.'},{headers:h});}
 }catch(error){const msg=String((error as Error).message||error);const status=msg==='UNAUTHORIZED'?401:msg==='FORBIDDEN'?403:msg.includes('RATE_LIMIT')?429:400;return Response.json({error:status===401?'Inicia sesión.':status===403?'Solo la administradora puede realizar esta acción.':status===429?'Hay demasiadas solicitudes. Intenta más tarde.':'No se pudo completar la operación. Revisa los datos o intenta de nuevo.'},{status,headers:h});}
});

