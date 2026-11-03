import {saveEntry} from '../business/entriesService';
import React from 'react';
import RecipeEditor from './RecipeEditor';
import {useDraftState} from '../drafts/Drafts';
export default function NewStagedRecipe({bookId,ingredients,books,onSave,onCancel,busy,onCreateIngredient}){
 const [id,,clear]=useDraftState('new-staged-recipe:'+bookId,()=>crypto.randomUUID());
 const recipe={id,name:'',category:'',bookId,yield:'',yieldUnit:'unidad',productType:'Otro artículo',scaling:'scalable',preparation:'',lines:[],stages:[{id:id,name:'Primera preparación',preparation:''}]};
 return <section><h3>Nueva receta por etapas</h3><RecipeEditor recipe={recipe} ingredients={ingredients} books={books} importing creating busy={busy} onCreateIngredient={onCreateIngredient} onSaveDraft={async form=>{await saveEntry('recipe_draft',id,{form,archived:false},0);window.dispatchEvent(new Event('bum-recipe-drafts-updated'));clear();onCancel();}} onCancel={onCancel} onSave={async form=>{await onSave(form,id);clear();onCancel();}}/></section>;
}
