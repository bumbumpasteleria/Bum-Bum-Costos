import fs from 'node:fs/promises';
const root=new URL('../',import.meta.url),out=new URL('public/ocr/',root);
await fs.mkdir(new URL('core/',out),{recursive:true});await fs.mkdir(new URL('lang/',out),{recursive:true});
await fs.copyFile(new URL('node_modules/tesseract.js/dist/worker.min.js',root),new URL('worker.min.js',out));
for(const file of await fs.readdir(new URL('node_modules/tesseract.js-core/',root))){if(/^tesseract-core.*\.wasm(\.js)?$/.test(file))await fs.copyFile(new URL('node_modules/tesseract.js-core/'+file,root),new URL('core/'+file,out));}
await fs.copyFile(new URL('node_modules/@tesseract.js-data/spa/4.0.0_best_int/spa.traineddata.gz',root),new URL('lang/spa.traineddata.gz',out));
await fs.writeFile(new URL('NOTICE.txt',out),'OCR: Tesseract.js and Tesseract.js-core (Apache-2.0), https://github.com/naptha/tesseract.js. Spanish language data: https://github.com/naptha/tessdata (Apache-2.0). Runtime assets are copied from pinned npm dependencies at build time.');

await fs.copyFile(new URL('node_modules/tesseract.js/LICENSE.md',root),new URL('TESSERACT-LICENSE.txt',out));
await fs.copyFile(new URL('node_modules/tesseract.js-core/LICENSE',root),new URL('CORE-LICENSE.txt',out));
