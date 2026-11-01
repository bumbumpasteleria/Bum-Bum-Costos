import React,{useRef,useState} from 'react';
import './recipeDelete.css';
export default function DeleteRecipe({recipe,onDelete,busy}){
 const [confirm,setConfirm]=useState(false),[saving,setSaving]=useState(false),[error,setError]=useState('');const lock=useRef(false);
 async function remove(){if(lock.current||busy)return;lock.current=true;setSaving(true);setError('');try{await onDelete(recipe);}catch(err){setError(err.message);}finally{lock.current=false;setSaving(false);}}
 if(!confirm)return <button type="button" className="ghost recipe-delete-button" disabled={busy} aria-label={'Eliminar receta '+recipe.name} onClick={()=>{setError('');setConfirm(true)}}>Eliminar receta</button>;
 return <div className="recipe-delete-panel" role="group" aria-label={'Confirmar eliminación de '+recipe.name}><strong>¿Eliminar la receta «{recipe.name}»?</strong><p>Se eliminarán esta receta, su preparación y sus líneas de ingredientes. Los ingredientes del catálogo, las cotizaciones y las ventas guardadas se conservarán. Esta acción no se puede deshacer.</p>{error&&<p role="alert" className="form-error">{error}</p>}<div className="actions"><button type="button" className="recipe-delete-button" disabled={busy||saving} onClick={remove}>{saving?'Eliminando…':'Sí, eliminar receta'}</button><button type="button" className="secondary" disabled={busy||saving} onClick={()=>{setConfirm(false);setError('')}}>Cancelar eliminación</button></div></div>;
}
