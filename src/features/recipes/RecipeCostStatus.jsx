import React from 'react';
export default function RecipeCostStatus({assessment,format}){
 return assessment.complete?<strong>Costo: {format(assessment.total)}</strong>:<span className="warning" style={{display:'block'}}><strong>Costo incompleto</strong><small>Revisa estos datos antes de cotizar:</small>{assessment.issues.map((issue,index)=><small key={index}>• {issue}</small>)}</span>;
}
