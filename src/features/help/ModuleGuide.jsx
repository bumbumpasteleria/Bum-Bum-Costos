import React from 'react';
import {MODULE_GUIDES} from './guides.mjs';
import './moduleGuide.css';
export default function ModuleGuide({module,isAdmin=false}){
 const guide=MODULE_GUIDES[module];if(!guide||guide.adminOnly&&!isAdmin)return null;
 return <details className="module-guide"><summary><span aria-hidden="true">📖</span> ¿Cómo se usa? <small>{module}</small></summary><div><h3>{guide.title}</h3><ol>{guide.steps.map((step,index)=><li key={index}>{step}</li>)}</ol><p className="module-guide-example"><b>Ejemplo:</b> {guide.example}</p><p className="module-guide-tip">{guide.tip}</p></div></details>;
}
