import React,{createContext,useContext,useRef,useState,useEffect,useCallback} from 'react';
import {readDraft,writeDraft} from './draftStore.mjs';
const Context=createContext(null);
export function DraftProvider({owner,children}){
 const [warning,setWarning]=useState('');const memory=useRef(new Map());
 const store=useRef(null);if(!store.current)store.current={
  getItem(key){if(memory.current.has(key))return memory.current.get(key);try{return window.localStorage.getItem(key)}catch{ return null;}},
  setItem(key,value){memory.current.set(key,value);try{window.localStorage.setItem(key,value)}catch{setWarning('No se pudo conservar el borrador en este dispositivo. Mantén la app abierta hasta guardar en la nube.');}}
 };
 return <Context.Provider value={{owner,storage:store.current}}>{warning&&<p role="alert" className="warning">{warning}</p>}{children}</Context.Provider>;
}
export function useDraftState(scope,initial){
 const context=useContext(Context);const [value,setValue]=useState(()=>context?readDraft(context.storage,context.owner,scope,initial):typeof initial==='function'?initial():initial);
 const current=useRef(value);
 useEffect(()=>{if(context)writeDraft(context.storage,context.owner,scope,current.current);},[context?.owner,context?.storage,scope]);
 const set=useCallback(next=>{const resolved=typeof next==='function'?next(current.current):next;current.current=resolved;if(context)writeDraft(context.storage,context.owner,scope,resolved);setValue(resolved);},[context?.owner,context?.storage,scope]);
 const clear=useCallback(()=>{if(context)writeDraft(context.storage,context.owner,scope,null);},[context?.owner,context?.storage,scope]);
 return [value,set,clear];
}
// Explicit named business fields only. Authentication forms never use this component.
export function DraftForm({scope,fields,children,onSubmit,...props}){
 const [draft,setDraft]=useDraftState('form:'+scope,{});const ref=useRef(null);
 useEffect(()=>{for(const name of fields){const control=ref.current?.elements.namedItem(name);if(control&&Object.hasOwn(draft,name))control.value=draft[name];}},[]);
 function capture(){const next={};for(const name of fields){const control=ref.current?.elements.namedItem(name);if(control&&!['password','file','hidden'].includes(control.type))next[name]=control.value;}setDraft(next);}
 return <form {...props} ref={ref} onInput={capture} onChange={capture} onReset={()=>setDraft({})} onSubmit={onSubmit}>{children}</form>;
}
