import {supabase} from '../../supabase';
import {prepararEdicionReceta} from './recipesService';
import {adaptarReceta} from '../../cloudService';
export async function guardarRecetaImportada(form,id,owner,ingredients,books){
 if(!owner||!id)throw new Error('Inicia sesión antes de guardar.');
 const args=prepararEdicionReceta(form,{id,editSnapshot:{},lines:[],preparation:''},ingredients,books);
 delete args.p_original;
 const {data,error}=await supabase.rpc('guardar_receta_organizada_bum_bum',args);
 if(error){if(error.code==='PGRST202')throw new Error('La importación todavía no está habilitada en la nube. Conserva el PDF e intenta cuando la administradora publique la actualización.');if(error.code==='P0001')throw new Error(error.message);throw new Error('No se pudo confirmar el guardado. Revisa la lista antes de reintentar; se conservará este borrador.');}
 if(!data||data.id!==id||data.owner_id!==owner)throw new Error('No se pudo confirmar la receta de tu cuenta. Revisa la lista antes de reintentar.');
 return adaptarReceta(data);
}
