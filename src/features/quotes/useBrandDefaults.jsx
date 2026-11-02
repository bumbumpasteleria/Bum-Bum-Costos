import {useEffect,useState} from 'react';
import {brandDefaults} from './brandDefaults.mjs';
export function useBrandDefaults(user,profile){
 const initial=()=>({loading:brandDefaults(user,profile).bumBum,defaults:brandDefaults(user,profile),error:''});const [state,setState]=useState(initial);
 useEffect(()=>{let active=true;const controller=new AbortController(),defaults=brandDefaults(user,profile);
  if(!defaults.bumBum){setState({loading:false,defaults,error:''});return()=>controller.abort();}
  (async()=>{try{const response=await fetch('/brand/bum-bum-business.png',{signal:controller.signal,cache:'force-cache'});if(!response.ok)throw Error('Logo no disponible');const blob=await response.blob();if(blob.size>180000)throw Error('El logo supera el tamaño esperado');const logo=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(String(reader.result).replace(/^data:[^;]+;base64,/, 'data:image/png;base64,'));reader.onerror=()=>reject(Error('No se pudo leer el logo'));reader.readAsDataURL(blob);});if(active)setState({loading:false,defaults:{...defaults,logo},error:''});}catch(e){if(active)setState({loading:false,defaults,error:'No se pudo cargar el logo de Bum Bum. Actualiza la página para volver a intentarlo.'});}})();
  return()=>{active=false;controller.abort();};
 },[user?.email,profile.business_name,profile.phone,profile.location]);return state;
}
