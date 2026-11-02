import test from 'node:test';import assert from 'node:assert/strict';
import {buildQuote} from '../src/domain/costing/quote.mjs';
import {channelPricePlan,saleChannelDefaults} from '../src/domain/costing/channelPricing.mjs';
import {scaleRecipe} from '../src/domain/costing/scaleRecipes.mjs';
const catalog=[{id:'flour',name:'Harina',supplier:'A',unit:'g',lastUnitCost:.2,itemKind:'ingredient'},{id:'box',name:'Caja',supplier:'B',unit:'unidad',lastUnitCost:2,itemKind:'material'}];
const recipe={name:'Galletas',scaling:'scalable',yield:12,yieldUnit:'unidad',lines:[{ingredientId:'flour',qty:250,unit:'g'},{ingredientId:'box',qty:12,unit:'unidad'}]};
test('materiales de receta se incluyen una vez y los adicionales se detallan por separado',()=>{
 const q=buildQuote({recipe,catalog,quantity:2,materials:{box:1},decorations:[{id:'d',name:'Topper',price:5}],decors:{d:2},labor:20,laborMode:'hourly',hours:2,extra:{delivery:10,pack:0},method:'markup',pct:25});
 assert.equal(q.ingredientsCost,100);assert.equal(q.recipeMaterialsCost,48);assert.equal(q.additionalMaterialsCost,2);assert.equal(q.decorationCost,10);assert.equal(q.laborCost,40);assert.equal(q.totalCost,210);assert.equal(q.price,262.5);assert.equal(q.recipeLines[1].quantity,24);assert.equal(recipe.lines[1].qty,12);
});
test('media receta reduce materiales y costos, y costos incompletos impiden una cotización',()=>{
 const r=scaleRecipe(recipe,{mode:'factor',factor:'1/2',baseYield:12,baseUnit:'unidad'},catalog);assert.equal(r.lines[1].qty,6);assert.equal(r.cost.total,37);
 assert.throws(()=>buildQuote({recipe,catalog:[catalog[0]],quantity:1}),/catálogo/);assert.throws(()=>buildQuote({recipe,catalog,quantity:1,labor:-1}),/mano de obra/);
});
test('precio para apps considera comisión sobre venta y margen, no un recargo sobre costo',()=>{
 const p=channelPricePlan({baseCost:50,packaging:10,labor:0,other:0,commission:30,margin:20});assert.equal(p.price,120);assert.equal(p.commissionAmount,36);assert.equal(p.profit,24);
 assert.throws(()=>channelPricePlan({baseCost:50,commission:70,margin:30}),/menos de 100/);
});
test('cada canal conserva precio, comisión y gastos por unidad propios',()=>{
 const product={sale_price:50,channel_prices:{'PedidosYa':{price:120,commission:30,packaging:10,labor:2,other:3}}};
 assert.deepEqual(saleChannelDefaults(product,'PedidosYa'),{unitPrice:120,commission:'30',perUnitExtras:15,extra:'0'});assert.equal(saleChannelDefaults(product,'Directa').unitPrice,50);
});

test('PDF para cliente no contiene costos ni ganancia; PDF interno sí los incluye',async()=>{const {createQuotePdf}=await import('../src/features/quotes/quotePdf.mjs');const breakdown=buildQuote({recipe,catalog,quantity:1});const q={id:'ejemplo',date:'2026-11-02',recipeName:recipe.name,qty:1,customer:'Cliente ficticio',price:breakdown.price,breakdown};const client=(await createQuotePdf(q,'Negocio ficticio')).output(),internal=(await createQuotePdf(q,'Negocio ficticio',{internal:true})).output();assert.ok(client.includes('Cliente ficticio'));assert.ok(!client.includes('Costo total'));assert.ok(!client.includes('Ganancia estimada'));assert.ok(internal.includes('Costo total'));assert.ok(internal.includes('Ganancia estimada'));const branded=(await createQuotePdf(q,'Nombre inicial',{branding:{businessName:'Nombre personalizado',phone:'Contacto de marca',color:'#225577'}})).output();assert.ok(branded.includes('Nombre personalizado'));assert.ok(branded.includes('Contacto de marca'));});
