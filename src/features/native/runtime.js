import {App} from '@capacitor/app';
import {registerPlugin} from '@capacitor/core';
const Device=registerPlugin('BumDevice');
export async function startNativeRuntime(){
 const open=async()=>{const pending=await Device.consumeAgenda();if(pending.open){sessionStorage.setItem('bum-native-agenda',pending.target||'Agenda y cobros');window.dispatchEvent(new Event('bum-native-agenda'))}};
 await open();await App.addListener('appStateChange',({isActive})=>{if(isActive)void open()});
 await App.addListener('backButton',({canGoBack})=>{if(canGoBack)window.history.back();else void App.minimizeApp()});
}
