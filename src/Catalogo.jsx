import {useDraftState} from './features/drafts/Drafts';
import './catalogo.css';
import React,{useRef,useState} from 'react';
import { medidas } from './cloudService';
import { etiquetaArticulo,unidadesCompra } from './catalogoService';

const vacio=()=>({name:'',supplier:'',price:'',quantity:'',unit:'g'});
const dinero=n=>'RD$ '+Number(n).toLocaleString('es-DO',{minimumFractionDigits:2,maximumFractionDigits:6});
export default function Catalogo({kind,items,onSave,onDelete,busy}) {
  const material=kind==='material',nombre=material?'material':'ingrediente';
  const [form,setForm]=useDraftState('catalog:'+kind+':form',()=>({...vacio(),unit:material?'unidad':'g'})),[original,setOriginal]=useDraftState('catalog:'+kind+':original',null),[error,setError]=useState(''),[saving,setSaving]=useState(false),[deleting,setDeleting]=useState(null),[deleteError,setDeleteError]=useState('');
  const formRef=useRef(null),lock=useRef(false);
  const proveedores=[...new Set(items.map(i=>i.supplier).filter(Boolean))];
  const unidades=unidadesCompra.filter(u=>!original||medidas[u][0]===medidas[original.unit]?.[0]);
  function change(e){setForm(actual=>({...actual,[e.target.name]:e.target.value}));setError('');}
  function limpiar(){setOriginal(null);setError('');setForm({...vacio(),unit:material?'unidad':'g'});}
  function editar(item,otroProveedor=false){setError('');setOriginal(otroProveedor?null:item);setForm({name:item.name,supplier:otroProveedor?'':item.supplier||'',price:otroProveedor?'':String(item.purchasePrice??item.price),quantity:String(item.purchaseQuantity??item.packageQty??1),unit:item.purchaseUnit||item.unit});formRef.current?.scrollIntoView({behavior:'smooth',block:'start'});}
  async function guardar(e){e.preventDefault();if(lock.current)return;lock.current=true;setSaving(true);setError('');try{await onSave(form,kind,original);limpiar();}catch(err){setError('No se pudo confirmar el guardado: '+err.message);}finally{lock.current=false;setSaving(false);}}
  async function eliminar(item){if(lock.current)return;lock.current=true;setSaving(true);setDeleteError('');try{await onDelete(item);if(original?.id===item.id)limpiar();setDeleting(null);}catch(err){setDeleteError(err.message);}finally{lock.current=false;setSaving(false)}}
  return <>
    <h2>{material?'Materiales gastables y empaques':'Ingredientes'}</h2>
    <section ref={formRef} className="catalog-form">
      <h3>{original?'Editar '+nombre:'Registrar '+nombre}</h3>
      <p>Cada proveedor se registra por separado para conservar su precio. {material?'Añade cajas, bases, bolsas y otros consumibles al cotizador.':'Elige el proveedor que usarás al armar la receta.'}</p>
      <form onSubmit={guardar}>
        <fieldset disabled={busy||saving} className="app-content">
          <div className="grid">
            <label>Nombre del {nombre}<input name="name" value={form.name} onChange={change} required placeholder={material?'Caja para postres':'Harina de trigo'}/></label>
            <label>Proveedor o lugar de compra<input name="supplier" value={form.supplier} onChange={change} list={'proveedores-'+kind} required placeholder="Tienda o distribuidor"/></label>
            <datalist id={'proveedores-'+kind}>{proveedores.map(p=><option key={p} value={p}/>)}</datalist>
            <label>Precio de compra RD$<input name="price" type="number" min="0" step="0.01" value={form.price} onChange={change} required/></label>
            <label>Cantidad de esa compra<input name="quantity" type="number" min="0.001" step="any" value={form.quantity} onChange={change} required/></label>
            <label>Unidad de compra<select name="unit" value={form.unit} onChange={change}>{unidades.map(u=><option key={u} value={u}>{u}</option>)}</select></label>
          </div>
          {original&&<p>La unidad debe ser compatible con la registrada. Cambiar precio o proveedor conserva el inventario y las referencias existentes.</p>}
          {error&&<p role="alert" className="form-error">{error}</p>}
          <div className="actions"><button type="submit">{saving?'Guardando…':original?'Guardar cambios':'Guardar '+nombre}</button><button type="button" className="secondary" onClick={limpiar}>{original?'Cancelar edición':'Limpiar formulario'}</button></div>
        </fieldset>
      </form>
    </section>
    <section><h3>{material?'Materiales registrados':'Ingredientes registrados'}</h3>{!items.length&&<p>Todavía no hay {material?'materiales':'ingredientes'} registrados.</p>}{items.map(item=><div className="entry catalog-entry" key={item.id}>
      <span><b>{item.name}</b><small>{item.supplier||'Sin proveedor registrado'}</small><small>{item.purchaseUnit?`${dinero(item.purchasePrice)} por ${item.purchaseQuantity} ${item.purchaseUnit}`:'Costo unitario registrado'} · {dinero(item.lastUnitCost)}/{item.unit}</small></span>
      <button type="button" className="ghost" disabled={busy||saving} aria-label={'Editar '+etiquetaArticulo(item)} onClick={()=>editar(item)}>Editar</button>
      <button type="button" className="ghost" disabled={busy||saving} onClick={()=>editar(item,true)}>Otro proveedor</button>
      {!material&&onDelete&&<button type="button" className="ghost catalog-delete-button" disabled={busy||saving} aria-label={'Eliminar '+etiquetaArticulo(item)} onClick={()=>{setDeleting(item.id);setDeleteError('')}}>Eliminar</button>}
      {deleting===item.id&&<div className="catalog-delete-panel"><strong>¿Eliminar {etiquetaArticulo(item)}?</strong><p>Se eliminará este registro de tu cuenta. Esta acción no se puede deshacer.</p>{deleteError&&<p role="alert" className="form-error">{deleteError}</p>}<div className="actions"><button type="button" className="catalog-delete-button" disabled={busy||saving} onClick={()=>eliminar(item)}>{saving?'Eliminando…':'Confirmar eliminación'}</button><button type="button" className="secondary" disabled={busy||saving} onClick={()=>{setDeleting(null);setDeleteError('')}}>Cancelar</button></div></div>}
    </div>)}</section>
  </>;
}
