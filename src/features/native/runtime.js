import {supabase} from '../../supabase';
import {authCodeFromUrl} from './googleAuth.mjs';
import {App} from '@capacitor/app';
import {registerPlugin} from '@capacitor/core';
const Device=registerPlugin('BumDevice');
export async function startNativeRuntime(){
 const receive=async value=>{try{const code=authCodeFromUrl(value);if(code){const {error}=await supabase.auth.exchangeCodeForSession(code);if(error)throw error;}}catch{window.dispatchEvent(new Event('bum-auth-error'))}};
 await App.addListener('appUrlOpen',({url})=>{void receive(url)});const launch=await App.getLaunchUrl();if(launch?.url)await receive(launch.url);
 const open=async()=>{const pending=await Device.consumeAgenda();if(pending.open){sessionStorage.setItem('bum-native-agenda',pending.target||'Agenda y cobros');window.dispatchEvent(new Event('bum-native-agenda'))}};
 await open();await App.addListener('appStateChange',({isActive})=>{if(isActive)void open()});
 await App.addListener('backButton',({canGoBack})=>{if(canGoBack)window.history.back();else void App.minimizeApp()});
}
