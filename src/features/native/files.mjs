export const nativeDevice=()=>typeof window!=='undefined'&&Boolean(window.Capacitor?.isNativePlatform?.());
export async function saveBlob(blob,name){
 if(!nativeDevice()){const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);return;}
 const [{Filesystem,Directory},{Share}]=await Promise.all([import('@capacitor/filesystem'),import('@capacitor/share')]);
 const data=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(String(reader.result).split(',')[1]);reader.onerror=()=>reject(Error('No se pudo preparar el archivo.'));reader.readAsDataURL(blob)});
 const path='exports/'+crypto.randomUUID()+'/'+name.replace(/[^a-zA-Z0-9._-]/g,'_');
 const file=await Filesystem.writeFile({path,data,directory:Directory.Cache,recursive:true});
 await Share.share({title:name,files:[file.uri],dialogTitle:'Guardar o compartir documento'});
}
export async function savePdf(doc,name){if(!nativeDevice()){doc.save(name);return;}await saveBlob(doc.output('blob'),name);}
