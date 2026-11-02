import test from 'node:test';import assert from 'node:assert/strict';import {coverFor} from '../src/features/layout/coverAssets.mjs';import {readFile} from 'node:fs/promises';
test('las portadas priorizan la foto de la ficha y distinguen las referencias',()=>{
 const photo='data:image/jpeg;base64,/9j/test';assert.deepEqual(coverFor({name:'Receta propia'},{details:{photo}}),{src:photo,illustrative:false});
 assert.deepEqual(coverFor({name:'Tres leches'}),{src:'/visual/tres-leches.webp',illustrative:true});assert.equal(coverFor({name:'Suspiro italiano'}).src,'/visual/suspiro.webp');assert.equal(coverFor({name:'Masa de vainilla'}).src,'/visual/vanilla.webp');
 assert.equal(coverFor({name:'Otra'},{details:{photo:'https://otro.example/foto'}}).illustrative,true);
});
test('el icono de instalación corresponde al monograma con melocotón y tiene dimensiones válidas',async()=>{
 const root=new URL('../public/',import.meta.url),m=JSON.parse(await readFile(new URL('manifest.webmanifest',root),'utf8'));
 for(const icon of m.icons){const b=await readFile(new URL(icon.src.slice(1).split('?')[0],root)),size=Number(icon.sizes.split('x')[0]);assert.equal(b.readUInt32BE(16),size);assert.equal(b.readUInt32BE(20),size);assert.match(icon.src,/bb-peach/);}
 const logo=await readFile(new URL('brand/bum-bum-business.png',root));assert.ok(logo.length<180000);assert.deepEqual([...logo.subarray(0,8)],[137,80,78,71,13,10,26,10]);
});

