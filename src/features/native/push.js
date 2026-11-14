import {registerPlugin} from '@capacitor/core';
import {PushNotifications} from '@capacitor/push-notifications';
import {pushRequest} from '../business/pushNotifications';
const Device=registerPlugin('BumDevice');
let tokenPromise;
async function identity(){return Device.identity()}
async function token(){
 if(tokenPromise)return tokenPromise;
 tokenPromise=new Promise((resolve,reject)=>{let handles=[],timer;const stop=()=>{clearTimeout(timer);handles.forEach(h=>void h.remove());tokenPromise=null};
 (async()=>{handles.push(await PushNotifications.addListener('registration',result=>{stop();resolve(result.value)}));handles.push(await PushNotifications.addListener('registrationError',()=>{stop();reject(Error('No se pudo registrar este teléfono. Revisa la conexión e intenta nuevamente.'))}));timer=setTimeout(()=>{stop();reject(Error('El registro tardó demasiado. Intenta nuevamente.'))},20000);await PushNotifications.register()})().catch(()=>{stop();reject(Error('No se pudo iniciar el servicio de notificaciones de Android.'))});});return tokenPromise;
}
const subscription=(device,value)=>({platform:'android',deviceId:device.deviceId,proof:device.proof,...(value?{token:value}:{})});
export async function nativePushStatus(owner){const device=await identity();await Device.setOwner({owner});const config=await pushRequest('native_config');if(!config.ready)return {ready:false,enabled:false,hour:9};const result=await pushRequest('native_status',{subscription:subscription(device)});if(result.enabled&&(await PushNotifications.checkPermissions()).receive==='granted')await pushRequest('native_subscribe',{subscription:subscription(device,await token()),hour:result.hour});return {...result,ready:true};}
export async function enableNativePush(owner,hour){if((await PushNotifications.requestPermissions()).receive!=='granted')throw Error('Permite los avisos de Bum Bum Costos en Ajustes → Aplicaciones → Notificaciones.');const device=await identity();await Device.setOwner({owner});await pushRequest('native_subscribe',{subscription:subscription(device,await token()),hour});}
export async function testNativePush(){await pushRequest('native_test',{subscription:subscription(await identity())});}
export async function disableNativePush(){const device=await identity();await Device.setOwner({owner:''});try{await pushRequest('native_unsubscribe',{subscription:subscription(device)})}finally{await PushNotifications.unregister().catch(()=>{})}}
