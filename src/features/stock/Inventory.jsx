import React,{useRef,useState} from 'react';
import {useDraftState} from '../drafts/Drafts';
import {minimumReached} from './stock.mjs';
import {saveInventory} from './stockService';
const num=n=>Number(n).toLocaleString('es-DO',{maximumFractionDigits:3});
function Item({item,owner,onSaved,busy}){
 const [open,setOpen]=useState(false),[error,setError]=useState(''),[saving,setSaving]=useState(false);const lock=useRef(false);
 const fresh=()=>({quantity:String(item.stockQuantity??''),minimum:String(item.minimumStock??''),expectedQuantity:item.stockQuantity,expectedMinimum:item.minimumStock});
 const [form,setForm]=useDraftState('inventory:'+item.id,fresh);
 async function save(e){e.preventDefault();if(lock.current)return;lock.current=true;setSaving(true);setError('');try{const saved=await saveInventory({...item,stockQuantity:form.expectedQuantity,minimumStock:form.expectedMinimum},form,owner);onSaved(saved);setForm({quantity:String(saved.stockQuantity),minimum:String(saved.minimumStock),expectedQuantity:saved.stockQuantity,expectedMinimum:saved.minimumStock});setOpen(false);}catch(err){setError(err.message)}finally{lock.current=false;setSaving(false)}}
 return <article className="stock-card"><div><h3>{item.name}</h3><p>{item.supplier||'Sin proveedor'} · {item.itemKind==='material'?'Material':'Ingrediente'}</p><strong>{item.stockQuantity==null?'Sin cantidad registrada':num(item.stockQuantity)+' '+item.unit}</strong><p>Mínimo: {item.minimumStock==null?'Sin definir':num(item.minimumStock)+' '+item.unit}</p>{minimumReached(item.stockQuantity,item.minimumStock)&&<span className="stock-badge">{item.stockQuantity===0?'Agotado':'Reponer'}</span>}</div>
 <button type="button" className="secondary" onClick={()=>setOpen(!open)}>{open?'Cerrar ajuste':'Actualizar existencias'}</button>{open&&<button type="button" className="ghost" onClick={()=>{setForm(fresh());setError('');}}>Descartar ajuste y usar existencias actuales</button>}
 {open&&<form onSubmit={save}><fieldset disabled={busy||saving} className="app-content"><label>Cantidad disponible ({item.unit})<input type="number" min="0" step="any" value={form.quantity} onChange={e=>setForm({...form,quantity:e.target.value})} required/></label><label>Mínimo para reponer ({item.unit})<input type="number" min="0" step="any" value={form.minimum} onChange={e=>setForm({...form,minimum:e.target.value})} required/></label><p>Coloca lo que tienes ahora. Los precios se conservan.</p><button>Guardar existencias</button></fieldset></form>}{error&&<p role="alert">{error}</p>}</article>;
}
export default function Inventory({ingredients,materials,owner,onSaved,busy,shopping=false}){
 const [search,setSearch]=useState('');const all=[...ingredients,...materials];
 const items=all.filter(i=>(!shopping||minimumReached(i.stockQuantity,i.minimumStock))&&(i.name+' '+(i.supplier||'')).toLocaleLowerCase('es').includes(search.toLocaleLowerCase('es')));
 return <><h2>{shopping?'Lista de compras':'Inventario'}</h2><p>{shopping?'Ingredientes y materiales que llegaron a su mínimo. Al reponer por encima del mínimo, salen de esta lista.':'Registra lo que tienes y el mínimo para cada ingrediente o material, separado por proveedor.'}</p><label>Buscar artículo o proveedor<input type="search" value={search} onChange={e=>setSearch(e.target.value)}/></label>{!items.length&&<section>{shopping?'No hay artículos pendientes de reponer. Comprueba que tus existencias y mínimos estén registrados.':'No hay artículos para esta búsqueda. Registra tus ingredientes y materiales primero.'}</section>}<div className="stock-grid">{items.map(item=><Item key={item.id} {...{item,owner,onSaved,busy}}/>)}</div><p>Las ventas de productos preparados descuentan de Mi nevera. Este inventario de ingredientes se ajusta al registrar tus existencias.</p></>;
}
