export function validateImage(file){if(!file||!['image/jpeg','image/png','image/webp'].includes(file.type))throw Error('Selecciona una foto JPG, PNG o WebP.');if(!file.size||file.size>10*1024*1024)throw Error('La foto debe pesar como máximo 10 MB.');}
function check(signal){if(signal?.aborted)throw Error('Lectura cancelada. Tu texto anterior se conserva.');}
export async function scanWorker(onProgress,signal){
 check(signal);const {createWorker}=await import('tesseract.js');let worker;
 const abort=()=>worker?.terminate();signal?.addEventListener('abort',abort,{once:true});
 try{worker=await createWorker('spa',1,{workerPath:new URL('/ocr/worker.min.js',location.origin).href,corePath:new URL('/ocr/core/',location.origin).href,langPath:new URL('/ocr/lang',location.origin).href,logger:m=>{if(!signal?.aborted)onProgress('Reconociendo texto… '+Math.round((m.progress||0)*100)+' %');}});check(signal);
 return {async recognize(canvas){check(signal);const {data}=await worker.recognize(canvas);check(signal);return data.text;},async close(){signal?.removeEventListener('abort',abort);await worker.terminate();}};
 }catch(e){signal?.removeEventListener('abort',abort);await worker?.terminate();check(signal);throw e;}
}
export async function readRecipeImage(file,onProgress=()=>{},signal){
 validateImage(file);check(signal);let bitmap,reader;
 try{bitmap=await createImageBitmap(file,{imageOrientation:'from-image'});const scale=Math.min(1,1800/Math.max(bitmap.width,bitmap.height));const canvas=document.createElement('canvas');canvas.width=Math.max(1,Math.round(bitmap.width*scale));canvas.height=Math.max(1,Math.round(bitmap.height*scale));canvas.getContext('2d').drawImage(bitmap,0,0,canvas.width,canvas.height);reader=await scanWorker(onProgress,signal);const text=(await reader.recognize(canvas)).trim();if(!text)throw Error('No se reconoció texto. Usa una foto de frente, con buena luz y letras legibles.');if(text.length>100000)throw Error('La imagen contiene demasiado texto. Separa la receta.');return text;}finally{bitmap?.close();await reader?.close();}
}
