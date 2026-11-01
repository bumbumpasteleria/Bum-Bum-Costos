import {textFromItems,validatePdfFile} from './pdfRecipe.mjs';
export async function readRecipePdf(file,onProgress=()=>{}){
 validatePdfFile(file);
 const [pdfjs,{default:workerUrl}]=await Promise.all([import('pdfjs-dist/legacy/build/pdf.mjs'),import('pdfjs-dist/legacy/build/pdf.worker.min.mjs?url')]);
 pdfjs.GlobalWorkerOptions.workerSrc=workerUrl;
 const task=pdfjs.getDocument({data:new Uint8Array(await file.arrayBuffer()),isEvalSupported:false,useSystemFonts:true});
 try{const doc=await task.promise;if(doc.numPages>20)throw new Error('Selecciona un PDF de hasta 20 páginas, con una sola receta.');let pages=[];
  for(let i=1;i<=doc.numPages;i++){onProgress('Leyendo página '+i+' de '+doc.numPages+'…');const page=await doc.getPage(i);const content=await page.getTextContent();pages.push(textFromItems(content.items));page.cleanup();if(pages.join('\n').length>100000)throw new Error('El PDF contiene demasiado texto. Separa la receta en otro archivo.');}
  const text=pages.join('\n\n').trim();if(!text)throw new Error('Este PDF parece escaneado o no tiene texto legible. Usa un PDF con texto seleccionable o pega el texto de la receta abajo.');return text;
 }catch(error){if(error.name==='PasswordException')throw new Error('El PDF está protegido. Abre una copia sin contraseña para importarla.');if(error.name==='InvalidPDFException')throw new Error('No se pudo leer este PDF. Comprueba que abre correctamente.');throw error;}finally{await task.destroy();}
}
