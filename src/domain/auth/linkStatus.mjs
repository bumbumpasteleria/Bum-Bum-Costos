export function authLinkNotice(hash='',search=''){
 const fragment=new URLSearchParams(hash.replace(/^#/,'')),query=new URLSearchParams(search.replace(/^\?/,''));
 const code=fragment.get('error_code')||query.get('error_code');
 const error=fragment.get('error')||query.get('error');
 if(code==='otp_expired')return 'Este enlace de acceso venció o ya fue utilizado. Pide a la administradora que reenvíe tu invitación y abre el correo más reciente. No necesitas solicitar otra cuenta.';
 if(code||error)return 'No se pudo activar tu acceso con este enlace. Abre el correo de invitación más reciente. Si sigue sin funcionar, pide a la administradora una nueva invitación.';
 return '';
}
// Conserva solo el aviso seguro, nunca el enlace, sus tokens o su descripción.
export const initialAuthLinkNotice=typeof window==='undefined'?'':authLinkNotice(window.location.hash,window.location.search);
