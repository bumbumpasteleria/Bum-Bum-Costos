import {supabase} from './supabase';
export async function accountAction(action,data={}){
 const {data:result,error}=await supabase.functions.invoke('account-access',{body:{action,...data}});
 if(error){let message='No se pudo completar la solicitud. Intenta más tarde.';try{message=(await error.context.json()).error||message;}catch{}throw new Error(message);}
 return result;
}
