import React,{useState,useRef} from 'react';
import {usosRecetario} from './recetariosService';

export default function Recetarios({books,onSave,busy}){
  const [name,setName]=useState(''),[usage,setUsage]=useState('orders'),[editing,setEditing]=useState(null),[error,setError]=useState('');
  const lock=useRef(false);
  function reset(){setName('');setUsage('orders');setEditing(null);setError('');}
  async function submit(e){e.preventDefault();if(lock.current)return;lock.current=true;setError('');try{await onSave({name,usage},editing);reset();}catch(err){setError(err.message);}finally{lock.current=false;}}
  return <section id="crear-recetario"><h3>{editing?'Editar recetario':'Crear recetario'}</h3><p>Separa tus fórmulas por uso. Solo los recetarios de Encargos estarán disponibles en el cotizador.</p><form onSubmit={submit}><div className="grid"><label>Nombre del recetario<input value={name} onChange={e=>setName(e.target.value)} required placeholder="Ej.: Galletas para apps"/></label><label>Uso del recetario<select value={usage} onChange={e=>setUsage(e.target.value)}>{Object.entries(usosRecetario).map(([id,label])=><option key={id} value={id}>{label}</option>)}</select></label></div>{editing&&<p>Cambiar el uso afecta qué recetas aparecen en el cotizador. Las recetas y sus costos se conservan.</p>}{error&&<p role="alert" className="form-error">{error}</p>}<div className="actions"><button disabled={busy}>{editing?'Guardar recetario':'Crear recetario'}</button>{editing&&<button disabled={busy} type="button" className="secondary" onClick={reset}>Cancelar</button>}</div></form><div>{books.map(book=><div className="entry" key={book.id}><span><b>{book.name}</b><small>{usosRecetario[book.usage]}</small></span><button disabled={busy} type="button" className="ghost" onClick={()=>{setEditing(book.id);setName(book.name);setUsage(book.usage);setError('')}}>Editar recetario</button></div>)}</div></section>;
}

export function AsignarRecetario({recipe,books,onAssign,busy}){
  const [error,setError]=useState('');
  const lock=useRef(false);
  async function submit(e){e.preventDefault();if(lock.current)return;const bookId=String(new FormData(e.currentTarget).get('bookId'));if(bookId===recipe.bookId)return;lock.current=true;setError('');try{await onAssign(recipe.id,bookId);}catch(err){setError(err.message);}finally{lock.current=false;}}
  return <form onSubmit={submit} className="assign-book"><label>Recetario para {recipe.name}<select key={recipe.bookId||'none'} name="bookId" required defaultValue={recipe.bookId||''} disabled={busy}><option value="" disabled>Seleccionar recetario</option>{books.map(b=><option key={b.id} value={b.id}>{b.name} · {usosRecetario[b.usage]}</option>)}</select></label><button disabled={busy||!books.length} className="ghost">Asignar recetario</button>{error&&<p role="alert" className="form-error">{error}</p>}</form>;
}
