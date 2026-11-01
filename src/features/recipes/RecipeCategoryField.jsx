import React,{useRef} from 'react';
export const DEFAULT_CATEGORIES=['Masas','Rellenos','Coberturas','Postres','Decoraciones'];
export default function RecipeCategoryField({value,onChange,categories=[]}){
 const id=useRef('categories-'+crypto.randomUUID());
 return <label>Categoría de la receta<input name="category" value={value} onChange={onChange?e=>onChange(e.target.value):undefined} maxLength={80} list={id.current} placeholder="Ej.: Masas, Rellenos o una categoría nueva"/><datalist id={id.current}>{[...new Set([...DEFAULT_CATEGORIES,...categories].filter(Boolean))].map(category=><option key={category} value={category}/>)}</datalist><small>Elige una sugerencia o escribe otra. Se organiza dentro del recetario elegido.</small></label>;
}
