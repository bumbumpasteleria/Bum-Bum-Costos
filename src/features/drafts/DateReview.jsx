import React from 'react';
const today=()=>new Intl.DateTimeFormat('en-CA',{timeZone:'America/Santo_Domingo',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
export default function DateReview({date,onToday}){return date&&date<today()?<p className="date-review" role="status">Este formulario conserva la fecha {date}. Revísala antes de guardar. <button type="button" className="ghost" onClick={()=>onToday(today())}>Usar fecha de hoy</button></p>:null;}
