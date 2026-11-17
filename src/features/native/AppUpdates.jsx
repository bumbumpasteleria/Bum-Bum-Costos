import React,{useEffect,useState} from 'react';
import {App} from '@capacitor/app';import {registerPlugin} from '@capacitor/core';
import {availableUpdate} from './updatePolicy.mjs';
const Device=registerPlugin('BumDevice');
const native=()=>Boolean(window.Capacitor?.isNativePlatform?.());
export default function AppUpdates(){
 const [update,setUpdate]=useState(null),[message,setMessage]=useState('');
 useEffect(()=>{if(!native())return;let active=true,last=0;const abort=new AbortController();let listener;const check=async()=>{if(Date.now()-last<3600000)return;last=Date.now();try{const info=await App.getInfo(),response=await fetch('https://bum-bum-costos.bumbumpasteleria.workers.dev/android-version.json',{cache:'no-store',signal:abort.signal});if(!response.ok)return;const result=availableUpdate(await response.json(),info.build);if(active)setUpdate(result);}catch{}};void check();void App.addListener('appStateChange',({isActive})=>{if(isActive)void check()}).then(x=>{if(active)listener=x;else void x.remove()});return()=>{active=false;abort.abort();void listener?.remove()};},[]);
 if(!update)return null;
 return <aside className="app-update-notice" aria-label="Actualización de la aplicación"><strong>Hay una actualización disponible · {update.version}</strong><p>Tus datos guardados en la nube se conservan. Guarda tus formularios antes de instalarla.</p><button type="button" onClick={async()=>{try{await Device.openExternal({url:update.downloadUrl});}catch{setMessage('No se pudo abrir la descarga. Intenta nuevamente.');}}}>Descargar actualización</button>{message&&<p role="alert">{message}</p>}</aside>;
}
