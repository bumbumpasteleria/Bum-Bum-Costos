import React from 'react';
import {ingredientMatches} from './ingredientMatches.mjs';
import {medidas} from '../../cloudService';
import './ingredientMatches.css';
const price=item=>item.lastUnitCost!=null&&Number.isFinite(Number(item.lastUnitCost))&&Number(item.lastUnitCost)>=0?'RD$ '+Number(item.lastUnitCost).toLocaleString('es-DO',{maximumFractionDigits:6})+' / '+item.unit:'Precio pendiente';
export default function IngredientMatches({line,ingredients,onSelect,index}){
 const matches=ingredientMatches(line.name,ingredients);
 return <div className="ingredient-matches"><p><b>En tu receta: {line.name}</b>{line.raw&&<small>{line.raw}</small>}</p>
 <p>{matches.length>1?`Encontramos ${matches.length} opciones. ¿Cuál ingrediente y proveedor usaste?`:matches.length===1?'Encontramos esta opción. Comprueba que sea la que usaste.':!ingredients.length?'Todavía no tienes ingredientes. Registra este ingrediente aquí para vincularlo.':'No encontramos un nombre parecido. Puedes elegir otro ingrediente en la lista de abajo.'}</p>
 <div className="ingredient-match-options">{matches.map(item=>{const incompatible=!!medidas[line.unit]&&medidas[line.unit][0]!==medidas[item.unit]?.[0];return <button type="button" className="ingredient-match-option" key={item.id} aria-label={`Usar ${item.name}, proveedor ${item.supplier||'sin registrar'}, ingrediente ${index+1}`} aria-pressed={line.ingredientId===item.id} disabled={incompatible} onClick={()=>onSelect(item.id)}><b>{item.name}</b><span>Proveedor: {item.supplier||'Sin proveedor registrado'}</span><span>{price(item)}</span><small>{incompatible?'Unidad incompatible: revisa la medida de la receta.':line.ingredientId===item.id?'Seleccionado':'Elegir este ingrediente'}</small></button>})}</div>
 </div>;
}
