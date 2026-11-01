import {useDraftState} from '../drafts/Drafts';
import React,{useRef,useState} from 'react';
import {prepararArticulo,unidadesCompra} from '../../catalogoService';
import {medidas} from '../../cloudService';
import {normalizeIngredient} from './ingredientMatches.mjs';
import './inlineRegistration.css';

export default function InlineIngredient({line,ingredients,onCreate,onCreated,onCancel,busy}){
 const [form,setForm,clearForm]=useDraftState('inline-ingredient:'+(line.key||line.name),()=>({name:line.name||'',supplier:'',price:'',quantity:'',unit:unidadesCompra.includes(line.unit)?line.unit:''}));
 const [error,setError]=useState(''),[saving,setSaving]=useState(false);const lock=useRef(false);
 function change(key,value){setForm(old=>({...old,[key]:value}));setError('');}
 async function save(event){event?.preventDefault();event?.stopPropagation();if(lock.current||busy)return;lock.current=true;setSaving(true);setError('');
  try{const payload=prepararArticulo(form,'ingredient');
   if(line.unit&&medidas[line.unit]&&medidas[line.unit][0]!==payload.base_unit)throw Error('La unidad de compra debe ser compatible con la unidad de esta línea de la receta.');
   if(ingredients.some(item=>normalizeIngredient(item.name)===normalizeIngredient(form.name)&&normalizeIngredient(item.supplier)===normalizeIngredient(form.supplier)))throw Error('Ya tienes este nombre y proveedor registrados. Cancela y selecciónalo en tu catálogo.');
   const saved=await onCreate(form);if(!saved?.id)throw Error('No se pudo confirmar el ingrediente. Revisa tu catálogo antes de reintentar.');clearForm();onCreated(saved);
  }catch(err){setError(err.message||'No se pudo guardar. Conservamos lo que escribiste.');}finally{lock.current=false;setSaving(false);}
 }
 return <div className="inline-registration" role="group" aria-label={'Registrar ingrediente para '+(line.name||'esta línea')} onKeyDown={e=>{if(e.key==='Enter'){e.preventDefault();e.stopPropagation();save(e);}}}>
 <h4>Registra este ingrediente aquí</h4><p>Se guardará en tu catálogo y quedará seleccionado en esta línea. La receta se guarda después. Si cancelas la receta, el ingrediente registrado permanecerá en tu catálogo.</p>
 <fieldset className="app-content" disabled={busy||saving}><div className="grid">
 <label>Nombre del ingrediente nuevo<input value={form.name} onChange={e=>change('name',e.target.value)} maxLength={160}/></label>
 <label>Proveedor del ingrediente nuevo<input value={form.supplier} onChange={e=>change('supplier',e.target.value)} maxLength={160}/></label>
 <label>Precio total de compra RD$<input type="number" min="0" step="any" value={form.price} onChange={e=>change('price',e.target.value)}/></label>
 <label>Cantidad comprada<input type="number" min="0.001" step="any" value={form.quantity} onChange={e=>change('quantity',e.target.value)}/></label>
 <label>Unidad de la compra<select value={form.unit} onChange={e=>change('unit',e.target.value)}><option value="" disabled>Selecciona una unidad</option>{unidadesCompra.map(unit=><option key={unit}>{unit}</option>)}</select></label>
 </div><small>Ejemplo: 1 kg por RD$100. El sistema calcula el precio por gramo. La cantidad que usa tu receta se conserva.</small>
 {error&&<p role="alert" className="form-error">{error}</p>}
 <div className="actions"><button type="button" onClick={save} disabled={!onCreate}>{saving?'Guardando ingrediente…':'Guardar ingrediente y vincular'}</button><button type="button" className="secondary" onClick={()=>{clearForm();onCancel();}}>Cancelar registro de ingrediente</button></div></fieldset></div>;
}
