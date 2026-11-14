import fs from 'node:fs';
const config=JSON.parse(fs.readFileSync('capacitor.config.json','utf8'));
if(config.server?.url||config.android?.allowMixedContent||config.appId!=='com.bumbumpasteleria.costos')throw Error('Revisa la configuración segura de Android.');
if(process.argv.includes('--release')){
 const services=JSON.parse(fs.readFileSync('android/app/google-services.json','utf8'));
 if(services.project_info?.project_id!=='bum-bum-costos'||!services.client?.some(c=>c.client_info?.android_client_info?.package_name===config.appId))throw Error('La configuración Firebase no corresponde a esta app.');
 if(process.env.VITE_SUPABASE_URL!=='https://exanisbqasrzoerdghmz.supabase.co'||!process.env.VITE_SUPABASE_PUBLISHABLE_KEY)throw Error('Falta la configuración pública de Supabase para Android.');
 const key=process.env.VITE_SUPABASE_PUBLISHABLE_KEY;
 if(key.startsWith('sb_secret_')||key.split('.').length===3&&JSON.parse(Buffer.from(key.split('.')[1],'base64url')).role!=='anon')throw Error('Una credencial privada no puede incluirse en el instalador.');
}
console.log('Configuración Android comprobada.');
