import React,{useRef,useState} from 'react';
export default function DeleteRecipeBook({book,count,onDelete,busy}){
 const [confirm,setConfirm]=useState(false),[saving,setSaving]=useState(false),[error,setError]=useState('');const lock=useRef(false);
 if(count)return <small>Para eliminar este recetario, mueve primero sus recetas a otro.</small>;
 return confirm?<div className="warning"><p>¿Eliminar el recetario vacío «{book.name}»? Esta acción no se puede deshacer.</p>{error&&<p role="alert">{error}</p>}<button type="button" disabled={busy||saving} onClick={async()=>{if(lock.current)return;lock.current=true;setSaving(true);try{await onDelete(book);}catch(e){setError(e.message)}finally{lock.current=false;setSaving(false)}}}>Sí, eliminar recetario vacío</button><button className="ghost" type="button" disabled={saving} onClick={()=>setConfirm(false)}>Cancelar eliminación</button></div>:<button className="ghost" type="button" disabled={busy} onClick={()=>setConfirm(true)}>Eliminar recetario {book.name}</button>;
}

