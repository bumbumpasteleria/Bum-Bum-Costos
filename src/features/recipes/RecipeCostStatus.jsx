import React from 'react';
export default function RecipeCostStatus({assessment,format}){
 return assessment.complete?<strong>Costo: {format(assessment.total)}</strong>:<span className="warning" style={{display:'block'}}><strong style={{display:'block'}}>Costo incompleto</strong><small style={{display:'block',marginTop:4}}>Revisa estos datos antes de cotizar:</small>{assessment.issues.map((issue,index)=><small key={index} style={{display:'block',marginTop:4}}>• {issue}</small>)}</span>;
}
