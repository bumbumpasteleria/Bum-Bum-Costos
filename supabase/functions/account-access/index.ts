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
  if(action==='list'){const page=Math.max(0,Math.min(10000,Math.floor(Number(body.page)||0)));const data=await query(db.from('account_requests').select('*').in('status',['pending','approving']).order('created_at',{ascending:false}).order('id').range(page*50,page*50+49));return Response.json({requests:data},{headers:h});}
  if(action==='people'){
   const page=Math.max(0,Math.min(10000,Math.floor(Number(body.page)||0)));
   const profiles=await query(db.from('business_profiles').select('id,owner_name,business_name,password_required,created_at').eq('status','approved').order('created_at',{ascending:false}).order('id').range(page*50,page*50+50));
   const visible=profiles.slice(0,50),ids=visible.map((p:any)=>p.id);
   if(!ids.length)return Response.json({people:[],hasMore:false},{headers:h});
   const [requests,admins]=await Promise.all([
    query(db.from('account_requests').select('id,auth_user_id,invitation_sent').eq('status','approved').in('auth_user_id',ids)),
    query(db.from('business_admins').select('user_id').in('user_id',ids))
   ]);
   const people=await Promise.all(visible.map(async(p:any)=>{
    const result=await db.auth.admin.getUserById(p.id);if(result.error)throw result.error;
    const request=requests.find((r:any)=>r.auth_user_id===p.id);
    return {...p,email:result.data.user.email||'',is_admin:admins.some((a:any)=>a.user_id===p.id),request_id:request?.id||null,invitation_sent:request?.invitation_sent??null};
   }));
   return Response.json({people,hasMore:profiles.length>50},{headers:h});
  }
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
  try{await mail(row.email,'Tu solicitud ha sido aprobada — Bum Bum Costos',`Hola, ${row.owner_name}.\n\n¡Tu solicitud ha sido aprobada! Ya puedes comenzar a usar Bum Bum Costos para ${row.business_name}.\n\nPRIMER INGRESO\n1. Abre este enlace personal para activar tu acceso y crear tu contraseña:\n${linkData.properties.action_link}\n2. Guarda tu contraseña. Después podrás entrar con este correo: ${row.email}.\n\nENLACE DE LA APLICACIÓN\n${site}\n\nCÓMO AÑADIRLA A TU CELULAR\nAndroid: abre el enlace de la aplicación en Chrome, toca el menú de tres puntos y elige Añadir a pantalla de inicio. Si aparece Instalar, confirma; si aparece Crear acceso directo, selecciona Añadir.\n\niPhone: abre el enlace de la aplicación en Safari, toca Compartir y luego Añadir a pantalla de inicio. Si aparece Abrir como app web, déjalo activado y pulsa Añadir.\n\nAñade a tu pantalla el enlace de la aplicación, después de completar el primer ingreso. Podrás abrir Bum Bum Costos desde su icono. Necesitas conexión a internet para guardar y consultar tus datos en la nube.\n\nEl enlace de activación es personal: no lo compartas. Si caduca, pide a la administradora una nueva invitación.\n\n¡Bienvenida a Bum Bum Costos!`);await query(db.from('account_requests').update({invitation_sent:true}).eq('id',row.id));return Response.json({ok:true},{headers:h});}
  catch{return Response.json({ok:true,warning:'Cuenta aprobada, pero no se pudo enviar la invitación. Usa Reenviar invitación.'},{headers:h});}
 }catch(error){const msg=String((error as Error).message||error);const status=msg==='UNAUTHORIZED'?401:msg==='FORBIDDEN'?403:msg.includes('RATE_LIMIT')?429:400;return Response.json({error:status===401?'Inicia sesión.':status===403?'Solo la administradora puede realizar esta acción.':status===429?'Hay demasiadas solicitudes. Intenta más tarde.':'No se pudo completar la operación. Revisa los datos o intenta de nuevo.'},{status,headers:h});}
});

