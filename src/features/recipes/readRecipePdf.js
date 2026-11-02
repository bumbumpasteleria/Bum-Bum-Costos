import {textFromItems,validatePdfFile} from './pdfRecipe.mjs';
export async function readRecipePdf(file,onProgress=()=>{},signal){
 validatePdfFile(file);
 const [pdfjs,{default:workerUrl}]=await Promise.all([import('pdfjs-dist/legacy/build/pdf.mjs'),import('pdfjs-dist/legacy/build/pdf.worker.min.mjs?url')]);
 pdfjs.GlobalWorkerOptions.workerSrc=workerUrl;
 const task=pdfjs.getDocument({data:new Uint8Array(await file.arrayBuffer()),isEvalSupported:false,useSystemFonts:true});
 let scanner,scanned=0;
 try{const doc=await task.promise;if(doc.numPages>20)throw new Error('Selecciona un PDF de hasta 20 páginas, con una sola receta.');let pages=[];
  for(let i=1;i<=doc.numPages;i++){if(signal?.aborted)throw Error('Lectura cancelada. Tu texto anterior se conserva.');onProgress('Leyendo página '+i+' de '+doc.numPages+'…');const page=await doc.getPage(i);const content=await page.getTextContent();let text=textFromItems(content.items);if(text.trim().length<40){if(++scanned>10)throw Error('Divide el PDF escaneado en archivos de hasta 10 páginas.');if(!scanner){const {scanWorker}=await import('./readScan');scanner=await scanWorker(onProgress,signal);}const original=page.getViewport({scale:1});const viewport=page.getViewport({scale:Math.min(2,1800/Math.max(original.width,original.height))});const canvas=document.createElement('canvas');canvas.width=Math.ceil(viewport.width);canvas.height=Math.ceil(viewport.height);await page.render({canvasContext:canvas.getContext('2d'),viewport}).promise;text=await scanner.recognize(canvas);canvas.width=canvas.height=0;}pages.push(text);page.cleanup();if(pages.join('\n').length>100000)throw new Error('El PDF contiene demasiado texto. Separa la receta en otro archivo.');}
  const text=pages.join('\n\n').trim();if(!text)throw new Error('Este PDF parece escaneado o no tiene texto legible. Usa un PDF con texto seleccionable o pega el texto de la receta abajo.');return text;
 }catch(error){if(error.name==='PasswordException')throw new Error('El PDF está protegido. Abre una copia sin contraseña para importarla.');if(error.name==='InvalidPDFException')throw new Error('No se pudo leer este PDF. Comprueba que abre correctamente.');throw error;}finally{await scanner?.close();await task.destroy();}
}
