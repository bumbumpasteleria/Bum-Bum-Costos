import {saveEntry} from '../business/entriesService';
import React from 'react';
import RecipeEditor from './RecipeEditor';
import {useDraftState} from '../drafts/Drafts';
export default function NewStagedRecipe({bookId,ingredients,books,onSave,onCancel,busy,onCreateIngredient,simple=false,initialLines=[],onClearLegacy=()=>{}}){
 const [id,,clear]=useDraftState((simple?'new-recipe:':'new-staged-recipe:')+bookId,()=>crypto.randomUUID());
 const [legacy,setLegacy]=useDraftState('form:recipe',{}),migrate=simple&&(legacy.name||initialLines.length);
 const recipe={id,name:migrate?legacy.name||'':'',category:migrate?legacy.category||'':'',bookId:migrate?legacy.bookId||bookId:bookId,yield:migrate?legacy.yield||'':'',yieldUnit:migrate?legacy.yieldUnit||'unidad':'unidad',productType:migrate?legacy.productType||'Otro artículo':'Otro artículo',scaling:migrate?legacy.scaling||'scalable':'scalable',preparation:migrate?legacy.preparation||'':'',lines:migrate?initialLines:[],stages:simple?[]:[{id,name:'Primera preparación',preparation:''}]};
 function finished(){if(migrate){setLegacy({});onClearLegacy()}clear();onCancel()}
 return <section>{migrate&&<p role="status">Recuperamos lo que ya estabas escribiendo. Revisa el formulario antes de guardar.</p>}<RecipeEditor recipe={recipe} ingredients={ingredients} books={books} importing creating busy={busy} onCreateIngredient={onCreateIngredient} onSaveDraft={async form=>{await saveEntry('recipe_draft',id,{form,archived:false},0);window.dispatchEvent(new Event('bum-recipe-drafts-updated'));finished();}} onCancel={onCancel} onSave={async form=>{await onSave(form,id);finished();}}/></section>;
}
