export const nativeAuthRedirect='com.bumbumpasteleria.costos://auth/callback';
export function authCodeFromUrl(value){
 let u;try{u=new URL(value)}catch{return null}
 if(u.protocol!=='com.bumbumpasteleria.costos:'||u.host!=='auth'||u.pathname!=='/callback'||u.username||u.password||u.hash)return null;
 if(u.searchParams.has('error'))throw Error('No se completó el acceso con Google. Puedes volver a intentarlo o usar tu contraseña.');
 const code=u.searchParams.get('code');return code&&code.length<=4096?code:null;
}
