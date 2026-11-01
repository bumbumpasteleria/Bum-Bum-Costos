import {useDraftState} from '../drafts/Drafts';
import InlineIngredient from './InlineIngredient';
import InlineRecipeBook from './InlineRecipeBook';
import RecipeCategoryField from './RecipeCategoryField';
import IngredientMatches from './IngredientMatches.jsx';
import React,{useRef,useState} from 'react';
import {medidas} from '../../cloudService';
import {tiposProducto,unidadesCompra,unidadesRendimiento,etiquetaArticulo} from '../../catalogoService';
import './recipeEditor.css';

export default function RecipeEditor({recipe,ingredients,books,onSave,onCancel,busy,importing=false,onCreateIngredient,onCreateBook}){
 const [snapshot,,clearSnapshot]=useDraftState('recipe:'+recipe.id+':snapshot',()=>recipe);const initial=useRef(snapshot),lock=useRef(false);
 const [form,setForm,clearForm]=useDraftState('recipe:'+recipe.id+':form',()=>({name:recipe.name,category:recipe.category||'',preparation:recipe.preparation||'',bookId:recipe.bookId||'',yield:String(recipe.yield),yieldUnit:recipe.yieldUnit,productType:recipe.productType,scaling:recipe.scaling,
  lines:recipe.lines.map(line=>({...line,qty:String(line.qty),key:line.id||crypto.randomUUID()}))}));
 const [saving,setSaving]=useState(false),[error,setError]=useState('');
 const [registering,setRegistering,clearRegistering]=useDraftState('recipe:'+recipe.id+':registering',null),[creatingBook,setCreatingBook,clearCreatingBook]=useDraftState('recipe:'+recipe.id+':creatingBook',false);
 function clear(){clearForm();clearSnapshot();clearRegistering();clearCreatingBook();}
 const disabled=busy||saving;
 const registrationOpen=registering!==null||creatingBook;
 function createdIngredient(key,item){setForm(old=>({...old,lines:old.lines.map(line=>line.key===key?{...line,ingredientId:item.id,unit:medidas[line.unit]?.[0]===medidas[item.unit]?.[0]?line.unit:''}:line)}));setRegistering(null);setError('');}
 function change(key,value){setForm(old=>({...old,[key]:value}));setError('');}
 function changeLine(index,values){setForm(old=>({...old,lines:old.lines.map((line,i)=>i===index?{...line,...values}:line)}));setError('');}
 function selectIngredient(index,id){const line=form.lines[index],unit=ingredients.find(item=>item.id===id)?.unit;changeLine(index,{ingredientId:id,unit:importing?(medidas[line.unit]?.[0]===medidas[unit]?.[0]?line.unit:''):unit||'g'});}
 function add(){const ingredient=ingredients[0];if(!ingredient){setError('Registra primero un ingrediente en tu catálogo.');return;}change('lines',[...form.lines,{key:crypto.randomUUID(),ingredientId:ingredient.id,qty:'1',unit:ingredient.unit}]);}
 async function submit(event){event.preventDefault();if(registrationOpen){setError('Termina o cancela el registro abierto antes de guardar la receta.');return;}if(importing&&form.lines.some(line=>!line.unit)){setError('Selecciona la unidad de cada ingrediente de la receta. No convertimos automáticamente tazas o cucharadas a gramos.');return;}if(lock.current)return;lock.current=true;setSaving(true);setError('');try{await onSave(form,initial.current);clear();}catch(err){setError(err.message);}finally{lock.current=false;setSaving(false)}}
 return <form className="recipe-editor" onSubmit={submit} aria-label={(importing?'Revisar importación ':'Editar receta ')+recipe.name}>
  <h3>{importing?'Datos de la receta importada':'Editar receta'}</h3><p>{importing?'Elige los ingredientes de tu catálogo y completa los campos pendientes. Se creará una receta nueva.':'Los cambios actualizarán esta receta. Las cotizaciones guardadas conservarán sus importes.'}</p>
  <fieldset className="app-content" disabled={disabled}><div className="grid">
   <label>Nombre de la receta<input value={form.name} maxLength={160} required onChange={e=>change('name',e.target.value)}/></label>
   <RecipeCategoryField value={form.category} onChange={value=>change('category',value)}/><label>Recetario<select value={form.bookId} required onChange={e=>change('bookId',e.target.value)}><option value="" disabled>Seleccionar recetario</option>{form.bookId&&!books.some(b=>b.id===form.bookId)&&<option value={form.bookId} disabled>Recetario no disponible</option>}{books.map(book=><option key={book.id} value={book.id}>{book.name}</option>)}</select></label>
   <label>Rendimiento total<input type="number" min="0.001" step="any" value={form.yield} required onChange={e=>change('yield',e.target.value)}/></label>
   <label>Unidad de rendimiento<select value={form.yieldUnit} onChange={e=>change('yieldUnit',e.target.value)}>{!unidadesRendimiento.includes(form.yieldUnit)&&<option value={form.yieldUnit} disabled>{form.yieldUnit} · elegir otra</option>}{unidadesRendimiento.map(unit=><option key={unit}>{unit}</option>)}</select></label>
   <label>Tipo de producto<select value={form.productType} onChange={e=>change('productType',e.target.value)}>{tiposProducto.map(type=><option key={type}>{type}</option>)}</select></label>
   <label>Escalado<select value={form.scaling} onChange={e=>change('scaling',e.target.value)}><option value="scalable">Escalable</option><option value="fixed">Fija</option></select></label>
  </div>
  {importing&&onCreateBook&&<><button type="button" className="secondary" disabled={registering!==null} onClick={()=>setCreatingBook(v=>!v)}>{creatingBook?'Cerrar nuevo recetario':'+ Crear recetario aquí'}</button>{creatingBook&&<InlineRecipeBook onCreate={onCreateBook} onCreated={book=>{change('bookId',book.id);setCreatingBook(false)}} onCancel={()=>setCreatingBook(false)} busy={disabled}/>}</>}
  {!books.length&&<p className="warning">Crea un recetario para poder guardar la receta.</p>}
  <h4>Ingredientes de la receta</h4><p>Conserva o cambia cada ingrediente y su cantidad. Quitar una línea solo la retira de esta receta.</p>
  {form.lines.map((line,index)=>{const ingredient=ingredients.find(item=>item.id===line.ingredientId);const units=unidadesCompra.filter(unit=>medidas[unit]?.[0]===medidas[ingredient?.unit]?.[0]);return <div className="recipe-edit-line" key={line.key}>
   {importing&&line.name&&<IngredientMatches line={line} ingredients={ingredients} index={index} onSelect={id=>selectIngredient(index,id)}/>}
   {importing&&onCreateIngredient&&<><button type="button" className="secondary inline-register-action" disabled={creatingBook||registering!==null&&registering!==line.key} onClick={()=>setRegistering(line.key)}>+ Registrar ingrediente para línea {index+1}</button>{registering===line.key&&<InlineIngredient key={line.key} line={line} ingredients={ingredients} onCreate={onCreateIngredient} onCreated={item=>createdIngredient(line.key,item)} onCancel={()=>setRegistering(null)} busy={disabled}/>}</>}
   <label>Ingrediente {index+1}<select required value={line.ingredientId} onChange={e=>selectIngredient(index,e.target.value)}>{!ingredient&&<option value={line.ingredientId} disabled>{importing?'Elige ingrediente y proveedor':'Ingrediente no disponible · selecciona otro'}</option>}{ingredients.map(item=><option key={item.id} value={item.id}>{etiquetaArticulo(item)}</option>)}</select></label>
   <label>Cantidad {index+1}<input type="number" min="0.001" step="any" required value={line.qty} onChange={e=>changeLine(index,{qty:e.target.value})}/></label>
   <label>Unidad {index+1}<select required value={line.unit} onChange={e=>changeLine(index,{unit:e.target.value})}>{!units.includes(line.unit)&&<option value={line.unit} disabled>{line.unit||'Unidad no disponible'}</option>}{units.map(unit=><option key={unit}>{unit}</option>)}</select></label>
   <button type="button" className="ghost" onClick={()=>{if(registering===line.key)setRegistering(null);change('lines',form.lines.filter((_,i)=>i!==index))}} aria-label={'Quitar ingrediente '+(index+1)}>Quitar</button>
  </div>})}
  {!form.lines.length&&<p className="warning">Agrega al menos un ingrediente antes de guardar.</p>}
  <button type="button" className="secondary" onClick={add} disabled={!ingredients.length}>+ Ingrediente</button>
  <h4>Preparación</h4><label>Pasos de preparación<textarea rows={7} maxLength={20000} value={form.preparation} onChange={e=>change('preparation',e.target.value)} placeholder="Escribe los pasos, uno por línea. Puedes incluir tus tiempos, temperatura y notas."/></label><small>Opcional · hasta 20,000 caracteres. Escribe las indicaciones propias de esta receta.</small>
  {error&&<p className="form-error" role="alert">{error}</p>}
  <div className="actions"><button disabled={!books.length||!form.lines.length||registrationOpen}>{saving?'Guardando…':importing?'Guardar receta importada':'Guardar cambios de receta'}</button><button type="button" className="secondary" onClick={()=>{clear();onCancel();}}>{importing?'Volver al texto':'Cancelar edición'}</button></div>
  </fieldset>
 </form>;
}
