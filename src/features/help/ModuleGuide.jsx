import React from 'react';
import {MODULE_GUIDES} from './guides.mjs';
import './moduleGuide.css';
export default function ModuleGuide({module,isAdmin=false,displayName}){
 const guide=MODULE_GUIDES[module];if(!guide||guide.adminOnly&&!isAdmin)return null;
 return <details className="module-guide"><summary><span aria-hidden="true">📖</span> ¿Cómo se usa? <small>{displayName||module}</small></summary><div><h3>{guide.title}</h3><ol>{guide.steps.slice(0,4).map((step,index)=><li key={index}>{step}</li>)}</ol>{guide.steps.length>4&&<details><summary>Más detalles</summary><ol start={5}>{guide.steps.slice(4).map((step,index)=><li key={index}>{step}</li>)}</ol></details>}<p className="module-guide-example"><b>Ejemplo:</b> {guide.example}</p><p className="module-guide-tip">{guide.tip}</p></div></details>;
}
