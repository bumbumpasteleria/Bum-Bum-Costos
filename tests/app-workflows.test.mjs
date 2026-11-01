import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
import {transformWithEsbuild} from 'vite';
import {MODULE_GUIDES} from '../src/features/help/guides.mjs';
const root=new URL('../src/',import.meta.url);
const full=await readFile(new URL('main.jsx',root),'utf8');
const source=full.slice(full.indexOf('const blank='),full.indexOf('function AppProtegida'));
const compiled=(await transformWithEsbuild(source,'main.jsx',{loader:'jsx',format:'cjs'})).code;
const booksCode=(await transformWithEsbuild(await readFile(new URL('recetariosService.js',root),'utf8'),'recetariosService.js',{format:'cjs'})).code;
const nodes=x=>x&&typeof x==='object'?[x,...(x.children||[]).flat(Infinity).flatMap(nodes)]:[];
const text=x=>typeof x==='string'||typeof x==='number'?String(x):x&&typeof x==='object'?(x.children||[]).flat(Infinity).map(text).join(''):'';
function setup(owner,isAdmin=false){
 let hooks=[],index=0,effects=[],calls=[],signouts=0,downloads=0;
 const empty={ingredients:[],materials:[],recipes:[],books:[],decorations:[],quotes:[],sales:[],settings:{}};
 const react={createElement:(type,props,...children)=>({type,props:props||{},children}),Fragment:'fragment'};
 const serviceModule={exports:{}};vm.runInNewContext(booksCode,{module:serviceModule,exports:serviceModule.exports,require:()=>({supabase:{}})});
 const marker=name=>Object.assign(()=>null,{displayName:name});
 const ctx={React:react,console,setTimeout:fn=>fn(),structuredClone,Intl,Date,Math,Number,Object,crypto:globalThis.crypto,Blob,
 URL:{createObjectURL:()=> 'blob:test',revokeObjectURL(){}},document:{createElement:()=>({click(){downloads++}})},
 FormData:class{constructor(form){this.values=form.values}get(key){return this.values[key]}},
 useState(initial){const i=index++;if(!hooks[i])hooks[i]={value:typeof initial==='function'?initial():initial};return [hooks[i].value,v=>hooks[i].value=typeof v==='function'?v(hooks[i].value):v]},
 useRef(initial){const i=index++;return hooks[i]??(hooks[i]={current:initial})},
 useEffect(fn,deps){const i=index++;if(!hooks[i]||deps.some((d,j)=>d!==hooks[i].deps[j])){hooks[i]={deps};effects.push(fn)}},
 supabase:{auth:{signOut:async()=>{signouts++;return {error:null}}}},
 cargarDatos:async()=>structuredClone(empty),
 guardarArticulo:async(form,kind,actor)=>{calls.push({type:'catalog',actor});return {id:crypto.randomUUID(),...form,itemKind:kind,unit:kind==='material'?'unidad':'g',lastUnitCost:1}},
 guardarRecetario:async(form,actor)=>{calls.push({type:'book',actor});return {id:crypto.randomUUID(),...form}},
 asignarRecetario:async(id,bookId,actor)=>{calls.push({type:'assign',actor});return {id,recipe_book_id:bookId}},
 guardarRegistro:async(type,item,actor)=>{calls.push({type,actor,item:structuredClone(item)});return item},
 tiposProducto:['Bizcocho','Galleta'],unidadesRendimiento:['unidad','g'],etiquetaArticulo:i=>i.name,
 costoMateriales:(items,qty)=>items.reduce((sum,i)=>sum+(qty[i.id]||0)*i.lastUnitCost,0),detalleMateriales:()=>[],
 ...serviceModule.exports,
 ModuleGuide:marker('ModuleGuide'),Catalogo:marker('Catalogo'),Recetarios:marker('Recetarios'),AsignarRecetario:marker('AsignarRecetario'),RecipeReadiness:marker('RecipeReadiness'),Tools:marker('Tools'),Solicitudes:marker('Solicitudes'),PersonasConAcceso:marker('PersonasConAcceso')};
 // Sustituir solo las operaciones remotas, conservar filtros reales del recetario.
 ctx.guardarRecetario=async(form,actor)=>{calls.push({type:'book',actor});return {id:crypto.randomUUID(),...form}};
 ctx.asignarRecetario=async(id,bookId,actor)=>({id,recipe_book_id:bookId});
 vm.createContext(ctx);vm.runInContext(compiled+';this.renderApp=App;',ctx);
 let tree;
 function render(){index=0;tree=ctx.renderApp({session:{user:{id:owner,email:owner+'@example.invalid'}},profile:{},isAdmin});return tree}
 function button(label){return nodes(tree).find(n=>n.type==='button'&&text(n)===label)}
 function component(name){return nodes(tree).find(n=>typeof n.type==='function'&&n.type.displayName===name)}
 async function boot(){render();for(const fn of effects.splice(0))fn();await new Promise(resolve=>setImmediate(resolve));render()}
 function go(tab){if(!button(tab)){const menu=nodes(tree).find(n=>n.type==='button'&&text(n).includes('Menú'));menu.props.onClick();render()}button(tab).props.onClick();render();assert.equal(component('ModuleGuide').props.module,tab);assert.ok(MODULE_GUIDES[tab]?.steps.length);}
 function field(label,value){const row=nodes(tree).find(n=>n.type==='label'&&typeof n.children[0]==='string'&&n.children[0]===label);const control=nodes(row).find(n=>n.type==='select'||n.type==='input');control.props.onChange({target:{value}});render()}
 async function submit(values){const form=nodes(tree).find(n=>n.type==='form');assert.ok(form);await form.props.onSubmit({preventDefault(){},currentTarget:{values,reset(){}}});render()}
 return {boot,go,render,button,component,field,submit,calls,get tree(){return tree},get signouts(){return signouts},get downloads(){return downloads}};
}
for(const [owner,admin] of [['administradora',true],['usuaria-a',false],['usuaria-b',false]])test('flujo completo de interfaz compartida: '+owner,async()=>{
 const app=setup(owner,admin);await app.boot();app.go('Recetas');
 assert.equal(app.component('RecipeReadiness').props.hasIngredients,false);assert.equal(app.button('+ Ingrediente'),undefined);
 app.component('RecipeReadiness').props.onIngredients();app.render();assert.equal(app.component('Catalogo').props.kind,'ingredient');
 await app.component('Catalogo').props.onSave({name:'Harina',price:100,quantity:100},'ingredient');app.render();app.go('Recetas');
 assert.equal(app.component('RecipeReadiness').props.hasIngredients,true);assert.equal(app.component('RecipeReadiness').props.hasBooks,false);
 await app.component('Recetarios').props.onSave({name:'Encargos',usage:'orders'});app.render();assert.equal(app.component('RecipeReadiness'),undefined);
 assert.ok(app.button('+ Ingrediente'));app.button('+ Ingrediente').props.onClick();app.render();
 const select=nodes(app.tree).find(n=>n.type==='select'&&n.props.name==='bookId');const book=nodes(select).find(n=>n.type==='option'&&n.props.value);assert.ok(book);
 await app.submit({name:'Galleta',bookId:book.props.value,productType:'Galleta',yield:'12',yieldUnit:'unidad',scaling:'scalable'});
 const saved=app.calls.find(c=>c.type==='recipes');assert.equal(saved.item.lines.length,1);assert.equal(saved.item.lines[0].qty,1);assert.equal(saved.item.bookId,book.props.value);
 app.go('Materiales');await app.component('Catalogo').props.onSave({name:'Caja'},'material');app.render();
 app.go('Decoraciones');await app.submit({name:'Perlas',type:'Otros',price:'10'});assert.ok(app.calls.some(c=>c.type==='decorations'));
 app.go('Cotizador');app.field('Recetario de encargos',book.props.value);app.field('Receta o artículo',saved.item.id);assert.equal(app.button('Guardar cotización').props.disabled,false);await app.button('Guardar cotización').props.onClick();app.render();assert.ok(app.calls.some(c=>c.type==='quotes'));
 app.go('Ventas');await app.submit({date:'2026-10-31',channel:'Directa',description:'Pedido',gross:'100',commission:'0',productionCost:'50',extra:'0'});assert.ok(app.calls.some(c=>c.type==='sales'));
 app.go('Herramientas');assert.equal(app.component('Tools').props.owner,owner);
 app.go('Respaldo');app.button('Descargar respaldo JSON').props.onClick();assert.equal(app.downloads,1);
 app.go('Inicio');const menu=nodes(app.tree).find(n=>n.type==='button'&&text(n).includes('Menú'));menu.props.onClick();app.render();assert.equal(!!app.button('Personas con acceso'),admin);assert.equal(!!app.button('Solicitudes'),admin);
 await app.button('Cerrar sesión').props.onClick();assert.equal(app.signouts,1);assert.ok(app.calls.every(c=>c.actor===owner));
});

test('guías reales disponibles por pantalla y ayuda administrativa reservada',async()=>{
 const react={createElement:(type,props,...children)=>({type,props:props||{},children})};const m={exports:{}};
 const code=(await transformWithEsbuild(await readFile(new URL('features/help/ModuleGuide.jsx',root),'utf8'),'ModuleGuide.jsx',{loader:'jsx',format:'cjs'})).code;
 vm.runInNewContext(code,{module:m,exports:m.exports,require:path=>path==='react'?react:path.includes('guides')?{MODULE_GUIDES}:{}});
 const Guide=m.exports.default;
 for(const [module,data] of Object.entries(MODULE_GUIDES)){
  const view=Guide({module,isAdmin:true});assert.equal(view.type,'details');assert.notEqual(view.props.open,true);assert.match(text(view),/Ejemplo:/);assert.ok(text(view).includes(data.steps[0]));
  if(data.adminOnly)assert.equal(Guide({module,isAdmin:false}),null);else assert.ok(Guide({module,isAdmin:false}));
 }
});
