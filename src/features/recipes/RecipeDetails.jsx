import React from 'react';
import {assessRecipeCost} from '../../domain/costing/recipeCost.mjs';
import {etiquetaArticulo} from '../../catalogoService';
import RecipeCostStatus from './RecipeCostStatus';
import './recipeDetails.css';
export default function RecipeDetails({recipe,ingredients,format,defaultOpen=false}){
 const assessment=assessRecipeCost(recipe,ingredients);
 const yieldValid=String(recipe.yield??'').trim()!==''&&Number.isFinite(Number(recipe.yield))&&Number(recipe.yield)>0;
 const rawPerUnit=assessment.complete&&yieldValid?assessment.total/Number(recipe.yield):null;
 const perUnit=Number.isFinite(rawPerUnit)?rawPerUnit:null;
 return <details className="recipe-details" open={defaultOpen||undefined}><summary>Ver ingredientes y costos de {recipe.name}</summary><div className="recipe-details-body">
  <div className="recipe-details-summary"><div><small>Rendimiento de la receta</small><strong>{recipe.yield} {recipe.yieldUnit}</strong></div><div><small>Costo de ingredientes y materiales</small><RecipeCostStatus assessment={assessment} format={format}/></div>{perUnit!==null&&<div><small>Costo por {recipe.yieldUnit}</small><strong>{format(perUnit)}</strong></div>}</div>
  <h4>Ingredientes y materiales para toda la receta</h4>{recipe.lines?.some(l=>['g clara','g yema','clara','yema'].includes(l.unit))&&<p>Las claras y yemas del mismo artículo se aprovechan juntas en esta receta: se necesitan los huevos de la parte que más requiere, además de los huevos enteros. No se guardan sobrantes separados automáticamente.</p>}<ul className="recipe-details-lines">{(recipe.lines||[]).map((line,index)=>{const ingredient=ingredients.find(item=>item.id===line.ingredientId);const cost=assessment.lineCosts?.[index]!=null?{complete:true,total:assessment.lineCosts[index]}:assessRecipeCost({lines:[line]},ingredients);return <li key={line.id||index}><div><strong>{ingredient?(ingredient.itemKind==='material'?'Material: ':'')+etiquetaArticulo(ingredient):'Ingrediente no disponible'}</strong><span>{line.qty} {line.unit||ingredient?.unit||'Unidad no disponible'}</span></div><span>{cost.complete?format(cost.total):'Revisar costo'}</span></li>})}</ul>
  {rawPerUnit!==null&&!Number.isFinite(rawPerUnit)&&<p className="warning">El costo por unidad está fuera del rango permitido. Revisa el rendimiento.</p>}
  {!yieldValid&&<p className="warning">Revisa el rendimiento para calcular el costo por unidad.</p>}
  {!!recipe.stages?.length&&<section><h4>Etapas de esta receta</h4>{recipe.stages.map((stage,index)=><details key={stage.id}><summary>{index+1}. {stage.name}</summary><ul>{(recipe.ownLines||recipe.lines||[]).filter(line=>stage.lineIds?.includes(line.id)).map(line=><li key={line.id}>{ingredients.find(i=>i.id===line.ingredientId)?.name||'Ingrediente no disponible'} · {line.qty} {line.unit}</li>)}</ul><p className="recipe-preparation-text">{stage.preparation||'Sin instrucciones adicionales.'}</p></details>)}</section>}
  <h4>Preparación</h4>{recipe.preparation?.trim()?<p className="recipe-preparation-text">{recipe.preparation}</p>:<p className="recipe-details-note">Aún no has escrito la preparación. Agrégala desde Editar receta.</p>}
  <p className="recipe-details-note">Costos con los precios actuales del proveedor elegido. Incluyen los ingredientes y materiales registrados en la receta; materiales adicionales, decoraciones y mano de obra se agregan en el Cotizador. Consulta esta ficha sin modificar la receta.</p>
 </div></details>;
}
