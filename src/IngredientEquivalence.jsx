import React from 'react';
import {medidas} from './cloudService';
import {etiquetaUnidad} from './catalogoService';
export default function IngredientEquivalence({form,onChange}){
 const base=medidas[form.unit]?.[0];if(!['unit','ml'].includes(base))return null;
 const options=Object.keys(medidas).filter(u=>u!=='unit'&&medidas[u][0]===base);
 return <details className="equivalence-fields"><summary>Usar este artículo en gramos</summary><p>Indica un peso medido para este ingrediente y proveedor. En la receta podrás escribir gramos; al producir se descontará la cantidad equivalente del inventario.</p><div className="grid"><label>Cantidad de referencia<input type="number" min="0.001" step="any" value={form.equivalenceQuantity??'1'} onChange={e=>onChange('equivalenceQuantity',e.target.value)}/></label><label>Unidad de referencia<select value={form.equivalenceUnit||form.unit} onChange={e=>onChange('equivalenceUnit',e.target.value)}>{options.map(u=><option key={u} value={u}>{etiquetaUnidad(u)}</option>)}</select></label><label>Esta cantidad pesa (g)<input type="number" min="0.001" step="any" placeholder={base==='unit'?'Peso de un huevo sin cáscara':'Peso del líquido medido'} value={form.equivalenceGrams??''} onChange={e=>onChange('equivalenceGrams',e.target.value)}/></label></div><small>Ejemplo: 1 unidad de huevo pesa 50 g, o 100 ml de un líquido pesan 103 g. Usa tus propias mediciones; no se asigna un peso automático.</small></details>;
}
