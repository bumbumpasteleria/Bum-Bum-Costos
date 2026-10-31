import test from 'node:test';
import assert from 'node:assert/strict';
import {UNITS,decimal,formatDecimal,convertExact,convertIngredient,multiply,divide,recipeQuantity} from '../src/domain/measurements/conversions.mjs';
import {INGREDIENT_REFERENCES} from '../src/features/tools/references.mjs';
import {calibration,commercialStandard,defaultPreferences,loadPreferences,savePreferences,storageKey} from '../src/features/tools/storage.mjs';
const show=(n,a,b,p=12)=>formatDecimal(convertExact(n,a,b),p);
test('masa: definiciones completas de libra, onza, kg y mg',()=>{
 assert.equal(show('1','lb','g',5),'453.59237');assert.equal(show('1','oz','g',9),'28.349523125');
 assert.equal(show('1','lb','oz',0),'16');assert.equal(show('1','kg','g',0),'1000');assert.equal(show('1','g','mg',0),'1000');
});
test('volúmenes US, imperial y etiquetado no son intercambiables',()=>{
 assert.equal(show('1','us-floz','ml',10),'29.5735295625');assert.equal(show('1','imp-floz','ml',7),'28.4130625');
 assert.equal(show('1','us-cup','ml',7),'236.5882365');assert.equal(show('1','label-cup','ml',0),'240');
 assert.equal(show('1','us-gallon','ml',6),'3785.411784');assert.equal(show('1','imp-gallon','ml',2),'4546.09');
 assert.equal(show('1','us-tbsp','us-tsp',0),'3');assert.equal(show('1','us-cup','us-tbsp',0),'16');
 assert.equal(show('1','metric-tbsp','ml',0),'15');assert.equal(show('1','metric-tsp','ml',0),'5');assert.equal(show('1','metric-cup','ml',0),'250');
 assert.throws(()=>convertExact('1','oz','us-floz'),/misma magnitud/);
});
test('factores conservan ida y vuelta racional sin redondeo',()=>{
 for(const group of ['mass','volume'])for(const from of UNITS.filter(u=>u.group===group))for(const to of UNITS.filter(u=>u.group===group)){
  const result=convertExact('1.23456789',from.id,to.id);
  const inverse=multiply(result,divide(decimal(to.factor),decimal(from.factor)));
  assert.deepEqual(inverse,decimal('1.23456789'),`${from.id} → ${to.id}`);
 }
 const r=convertExact('1','us-tsp','ml');formatDecimal(r,0);assert.equal(formatDecimal(r,11),'4.92892159375');
});
test('temperatura: fórmulas, horno y cero absoluto',()=>{
 for(const [c,f] of [[160,320],[170,338],[180,356],[200,392],[-40,-40]])assert.equal(show(c,'C','F',0),String(f));
 assert.equal(show('0','C','K',2),'273.15');assert.equal(show('-459.67','F','K',2),'0.00');
 assert.equal(show('0','K','C',2),'-273.15');assert.throws(()=>convertExact('-0.001','K','C'),/cero absoluto/);
 assert.throws(()=>convertExact('-273.150001','C','F'),/cero absoluto/);
});
test('entrada española, límites y redondeo solo de presentación',()=>{
 assert.equal(show('1,5','kg','g',0),'1500');assert.equal(show('0','g','kg',2),'0.00');
 assert.equal(formatDecimal(decimal('1.005'),2),'1.01');assert.equal(formatDecimal(decimal('-1.005'),2),'-1.01');assert.equal(formatDecimal(decimal('-0.001'),0),'0');
 for(const s of ['','1,234.56','NaN','Infinity','1e3','1/2','0.1234567890123','1000000000001'])assert.throws(()=>convertExact(s,'g','kg'));
 assert.throws(()=>convertExact('-1','g','kg'));assert.throws(()=>formatDecimal(decimal('1'),13));
});
test('equivalencias culinarias usan la medida publicada; no inventan densidades',()=>{
 const flour=INGREDIENT_REFERENCES.find(i=>i.id==='flour'),butter=INGREDIENT_REFERENCES.find(i=>i.id==='butter');
 assert.equal(formatDecimal(convertIngredient('0.5','ref-cup','g',flour),0),'60');
 assert.equal(formatDecimal(convertIngredient('120','g','ref-cup',flour),2),'1.00');
 assert.equal(formatDecimal(convertIngredient('0.5','ref-cup','g',butter),0),'113');
 assert.throws(()=>convertIngredient('1','ref-cup','ml',flour),/no define mililitros/);
 assert.equal(INGREDIENT_REFERENCES.length,14);
 for(const row of INGREDIENT_REFERENCES){assert.ok(row.source.startsWith('https://'));assert.ok(row.conditions);assert.ok(row.date);}
});
test('agua y calibración: g/mL con condiciones y sin redondeo del factor',()=>{
 const water=INGREDIENT_REFERENCES.find(i=>i.id==='water');assert.equal(formatDecimal(convertIngredient('100','ml','g',water),6),'99.820675');
 const own=calibration({id:'own',name:'Mi jarabe',massG:'250',volumeMl:'200',source:'Medición propia',conditions:'20 °C',date:'2026-10-31'});
 assert.equal(formatDecimal(convertIngredient('100','ml','g',own),2),'125.00');assert.equal(formatDecimal(convertIngredient('125','g','ml',own),2),'100.00');
 assert.throws(()=>calibration({...own,volumeMl:'0'}));assert.throws(()=>calibration({...own,conditions:''}));
});
test('el recetario recibe cantidades sin depender de decimales visibles',()=>{
 const r=convertExact('1','oz','g');formatDecimal(r,0);
 assert.deepEqual(recipeQuantity(r,'g',{id:'ingredient-id',unit:'g'}),{ingredientId:'ingredient-id',qty:28.349523125,unit:'g'});
 assert.throws(()=>recipeQuantity(r,'g',{id:'other',unit:'ml'}));assert.throws(()=>recipeQuantity(decimal('0.0001'),'g',{id:'i',unit:'g'}));
});
test('preferencias separadas por usuario; almacenamiento roto no bloquea herramientas',()=>{
 const map=new Map(),storage={getItem:k=>map.get(k),setItem:(k,v)=>map.set(k,v)};
 const p={...defaultPreferences(),places:8,amount:'2',favorites:[{kind:'mass',amount:'1',from:'lb',to:'g',ingredientId:'flour'}]};
 savePreferences(storage,'owner-a',p);assert.equal(loadPreferences(storage,'owner-a').places,8);assert.equal(loadPreferences(storage,'owner-b').amount,'1');
 map.set(storageKey('owner-a'),'{broken');assert.deepEqual(loadPreferences(storage,'owner-a'),defaultPreferences());
 assert.deepEqual(loadPreferences({getItem(){throw Error('denied')}},'owner-a'),defaultPreferences());
});
test('libra comercial requiere un estándar propio, sin masa universal precargada',()=>{
 assert.equal(defaultPreferences().standards.length,0);
 const record={id:'standard',name:'Mi negocio',shape:'round',diameter:'20',height:'8',layers:'2',commercialQty:'1',mixtureG:'900',yieldG:'800',portions:'12',equivalence:'Mi referencia medida',date:'2026-10-31'};
 assert.equal(commercialStandard(record).mixtureG,'900');assert.throws(()=>commercialStandard({...record,equivalence:''}));assert.throws(()=>commercialStandard({...record,layers:'1.5'}));
});

