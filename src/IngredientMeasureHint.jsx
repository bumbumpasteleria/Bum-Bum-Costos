import React from 'react';
import {ingredientBaseQuantity,recipeMeasures} from './domain/costing/ingredientQuantity.mjs';
export default function IngredientMeasureHint({item,line}){
 if(!item)return null;const base=recipeMeasures[item.unit]?.[0];
 if(['unit','ml'].includes(base)&&!(Number(item.gramsPerBaseUnit)>0))return <small>Para usar gramos, registra el peso de referencia de este artículo en Ingredientes.</small>;
 if(recipeMeasures[line.unit]?.[0]===base||!line.qty)return null;
 try{const value=ingredientBaseQuantity(line.qty,line.unit,item);return <small>Equivale a {new Intl.NumberFormat('es-DO',{maximumFractionDigits:6}).format(value.quantity)} {value.unit==='unit'?'unidades':value.unit} del inventario. La receta conserva {line.qty} {line.unit}.</small>}catch{return null}
}
