import React,{useRef,useState} from 'react';
import {medidas} from '../../cloudService';
import {tiposProducto,unidadesCompra,unidadesRendimiento,etiquetaArticulo} from '../../catalogoService';
import './recipeEditor.css';

export default function RecipeEditor({recipe,ingredients,books,onSave,onCancel,busy}){
 const initial=useRef(recipe),lock=useRef(false);
 const [form,setForm]=useState(()=>({name:recipe.name,bookId:recipe.bookId||'',yield:String(recipe.yield),yieldUnit:recipe.yieldUnit,productType:recipe.productType,scaling:recipe.scaling,
  lines:recipe.lines.map(line=>({...line,qty:String(line.qty),key:line.id||crypto.randomUUID()}))}));
 const [saving,setSaving]=useState(false),[error,setError]=useState('');
 const disabled=busy||saving;
 function change(key,value){setForm(old=>({...old,[key]:value}));setError('');}
 function changeLine(index,values){setForm(old=>({...old,lines:old.lines.map((line,i)=>i===index?{...line,...values}:line)}));setError('');}
 function add(){const ingredient=ingredients[0];if(!ingredient){setError('Registra primero un ingrediente en tu catálogo.');return;}change('lines',[...form.lines,{key:crypto.randomUUID(),ingredientId:ingredient.id,qty:'1',unit:ingredient.unit}]);}
 async function submit(event){event.preventDefault();if(lock.current)return;lock.current=true;setSaving(true);setError('');try{await onSave(form,initial.current);}catch(err){setError(err.message);}finally{lock.current=false;setSaving(false)}}
 return <form className="recipe-editor" onSubmit={submit} aria-label={'Editar receta '+recipe.name}>
  <h3>Editar receta</h3><p>Los cambios actualizarán esta receta. Las cotizaciones guardadas conservarán sus importes.</p>
  <fieldset className="app-content" disabled={disabled}><div className="grid">
   <label>Nombre de la receta<input value={form.name} maxLength={160} required onChange={e=>change('name',e.target.value)}/></label>
   <label>Recetario<select value={form.bookId} required onChange={e=>change('bookId',e.target.value)}><option value="" disabled>Seleccionar recetario</option>{form.bookId&&!books.some(b=>b.id===form.bookId)&&<option value={form.bookId} disabled>Recetario no disponible</option>}{books.map(book=><option key={book.id} value={book.id}>{book.name}</option>)}</select></label>
   <label>Rendimiento total<input type="number" min="0.001" step="any" value={form.yield} required onChange={e=>change('yield',e.target.value)}/></label>
   <label>Unidad de rendimiento<select value={form.yieldUnit} onChange={e=>change('yieldUnit',e.target.value)}>{!unidadesRendimiento.includes(form.yieldUnit)&&<option value={form.yieldUnit} disabled>{form.yieldUnit} · elegir otra</option>}{unidadesRendimiento.map(unit=><option key={unit}>{unit}</option>)}</select></label>
   <label>Tipo de producto<select value={form.productType} onChange={e=>change('productType',e.target.value)}>{tiposProducto.map(type=><option key={type}>{type}</option>)}</select></label>
   <label>Escalado<select value={form.scaling} onChange={e=>change('scaling',e.target.value)}><option value="scalable">Escalable</option><option value="fixed">Fija</option></select></label>
  </div>
  {!books.length&&<p className="warning">Crea un recetario en el formulario de arriba para poder guardar los cambios.</p>}
  <h4>Ingredientes de la receta</h4><p>Conserva o cambia cada ingrediente y su cantidad. Quitar una línea solo la retira de esta receta.</p>
  {form.lines.map((line,index)=>{const ingredient=ingredients.find(item=>item.id===line.ingredientId);const units=unidadesCompra.filter(unit=>medidas[unit]?.[0]===medidas[ingredient?.unit]?.[0]);return <div className="recipe-edit-line" key={line.key}>
   <label>Ingrediente {index+1}<select value={line.ingredientId} onChange={e=>changeLine(index,{ingredientId:e.target.value,unit:ingredients.find(item=>item.id===e.target.value)?.unit||'g'})}>{!ingredient&&<option value={line.ingredientId} disabled>Ingrediente no disponible · selecciona otro</option>}{ingredients.map(item=><option key={item.id} value={item.id}>{etiquetaArticulo(item)}</option>)}</select></label>
   <label>Cantidad {index+1}<input type="number" min="0.001" step="any" required value={line.qty} onChange={e=>changeLine(index,{qty:e.target.value})}/></label>
   <label>Unidad {index+1}<select value={line.unit} onChange={e=>changeLine(index,{unit:e.target.value})}>{!units.includes(line.unit)&&<option value={line.unit} disabled>{line.unit||'Unidad no disponible'}</option>}{units.map(unit=><option key={unit}>{unit}</option>)}</select></label>
   <button type="button" className="ghost" onClick={()=>change('lines',form.lines.filter((_,i)=>i!==index))} aria-label={'Quitar ingrediente '+(index+1)}>Quitar</button>
  </div>})}
  {!form.lines.length&&<p className="warning">Agrega al menos un ingrediente antes de guardar.</p>}
  <button type="button" className="secondary" onClick={add} disabled={!ingredients.length}>+ Ingrediente</button>
  {error&&<p className="form-error" role="alert">{error}</p>}
  <div className="actions"><button disabled={!books.length||!form.lines.length}>{saving?'Guardando cambios…':'Guardar cambios de receta'}</button><button type="button" className="secondary" onClick={onCancel}>Cancelar edición</button></div>
  </fieldset>
 </form>;
}
