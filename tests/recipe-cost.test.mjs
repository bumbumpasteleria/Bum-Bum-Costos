import test from 'node:test';import assert from 'node:assert/strict';
import {assessRecipeCost} from '../src/domain/costing/recipeCost.mjs';
const flour={id:'flour',name:'Harina',unit:'g',lastUnitCost:0.2};
const line=(qty=250,unit='g',ingredientId='flour')=>({qty,unit,ingredientId});
const cost=(lines,ingredients=[flour])=>assessRecipeCost({lines},ingredients);
test('costos completos conservan factores y precios vigentes',()=>{
 assert.equal(cost([line()]).total,50);assert.equal(cost([line(1,'kg')]).total,200);
 assert.equal(cost([line(1,'lb')]).total,453.59237*.2);
 assert.equal(cost([line(250),line(100)]).total,70);
 assert.equal(cost([line(1,'docena')],[{...flour,unit:'unidad',lastUnitCost:5}]).total,60);
 assert.equal(cost([line(1,'L')],[{...flour,unit:'ml'}]).total,200);
});
test('ingrediente ausente no produce subtotal aparentemente completo',()=>{
 const r=cost([line(),line(20,'g','missing')]);assert.equal(r.total,null);assert.equal(r.complete,false);assert.match(r.issues[0],/no está disponible/);
});
test('unidades incompatibles y desconocidas devuelven diagnóstico',()=>{
 for(const unit of ['ml','unknown','toString']){const r=cost([line(1,unit)]);assert.equal(r.total,null);assert.match(r.issues[0],/unidad/);}
});
test('cantidades vacías, negativas, no finitas y cero bloquean el costo',()=>{
 for(const quantity of [null,undefined,'', ' ',NaN,Infinity,-1,0,false,{},'abc'])assert.equal(cost([{ingredientId:'flour',qty:quantity,unit:'g'}]).complete,false);
});
test('precio faltante o inválido no equivale a gratis; cero explícito sí',()=>{
 for(const price of [null,undefined,'', ' ',NaN,Infinity,-1,false])assert.equal(cost([line()],[{...flour,lastUnitCost:price}]).complete,false);
 const free=cost([line()],[{...flour,lastUnitCost:0}]);assert.equal(free.complete,true);assert.equal(free.total,0);
});
test('compatibilidad con registros antiguos y unidad omitida',()=>{
 assert.equal(cost([{ingredientId:'flour',qty:250}],[{id:'flour',unit:'g',price:100,packageQty:500}]).total,50);
 assert.equal(cost([line()],[{id:'flour',unit:'g',price:100,packageQty:0}]).total,null);
});
test('receta vacía y desbordamientos nunca se muestran como costo válido',()=>{
 for(const lines of [[],null,undefined])assert.equal(cost(lines).total,null);
 assert.equal(cost([line(1e308,'kg')]).complete,false);
 assert.equal(cost([line(1e308),line(1e308)],[{...flour,lastUnitCost:1}]).complete,false);
});
test('evaluación no modifica receta ni ingredientes',()=>{
 const lines=Object.freeze([Object.freeze(line())]),ingredients=Object.freeze([Object.freeze({...flour})]);assert.equal(cost(lines,ingredients).total,50);
});

test('adaptador de nube conserva precio ausente y distingue el cero explícito',async()=>{
 const {readFile}=await import('node:fs/promises');const source=(await readFile(new URL('../src/ingredientsService.js',import.meta.url),'utf8')).replace(/import \{ supabase \} from '\.\/supabase';/, 'const supabase = {};');
 const {adaptarIngrediente}=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
 for(const raw of [null,undefined]){const ingredient=adaptarIngrediente({id:'flour',name:'Harina',base_unit:'g',last_unit_cost:raw});assert.equal(ingredient.lastUnitCost,null);assert.equal(cost([line()],[ingredient]).complete,false);}
 assert.equal(cost([line()],[adaptarIngrediente({id:'flour',base_unit:'g',last_unit_cost:0})]).total,0);
});
