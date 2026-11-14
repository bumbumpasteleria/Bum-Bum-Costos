import {App} from '@capacitor/app';
import {registerPlugin} from '@capacitor/core';
const Device=registerPlugin('BumDevice');
export async function startNativeRuntime(){
 const open=async()=>{if((await Device.consumeAgenda()).open){sessionStorage.setItem('bum-native-agenda','1');window.dispatchEvent(new Event('bum-native-agenda'))}};
 await open();await App.addListener('appStateChange',({isActive})=>{if(isActive)void open()});
 await App.addListener('backButton',({canGoBack})=>{if(canGoBack)window.history.back();else void App.minimizeApp()});
}
