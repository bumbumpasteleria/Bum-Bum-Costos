import {money} from './finance.mjs';
const clean=value=>String(value??'').normalize('NFKC').replace(/[\u0000-\u001f]/g,' ').replace(/[^\x20-\x7e\u00a0-\u00ff]/g,'?');
export async function createReportPdf(report,business='Mi negocio',salesOnly=false){
 const {jsPDF}=await import('jspdf');const doc=new jsPDF({unit:'mm',format:'a4'});let y=0;
 const line=(text,size=10,bold=false)=>{doc.setFont('helvetica',bold?'bold':'normal');doc.setFontSize(size);const lines=doc.splitTextToSize(clean(text),174);for(const textLine of lines){if(y>267){doc.addPage();header();}doc.setFont('helvetica',bold?'bold':'normal');doc.setFontSize(size);doc.text(textLine,18,y);y+=size*.46+1.5;}};
 const keepTogether=(title,details)=>{doc.setFont('helvetica','bold');doc.setFontSize(10);const h=doc.splitTextToSize(clean(title),174).length*6.1;doc.setFont('helvetica','normal');doc.setFontSize(9);const needed=h+doc.splitTextToSize(clean(details),174).length*5.65+2;if(needed<220&&y+needed>267){doc.addPage();header();}};
 function header(){doc.setFillColor(138,52,80);doc.rect(0,0,210,32,'F');doc.setTextColor(255,255,255);doc.setFont('helvetica','bold');doc.setFontSize(16);doc.text('Bum Bum Costos',18,15);doc.setFontSize(10);doc.text(salesOnly?'Reporte de ventas':'Reporte financiero',18,23);doc.setTextColor(50,40,44);y=43;}
 header();line(business,14,true);line(`${report.from} al ${report.to} | Canal: ${report.channel}`);y+=3;
 for(const [title,amount] of [['Ventas brutas',report.gross],['Comisiones',report.commission],['Ingresos después de comisiones',report.net],['Costo de producción registrado',report.production],['Otros gastos de ventas',report.extra],...(!salesOnly?[['Gastos del negocio',report.expensesTotal],['Resultado registrado',report.result]]:[])])line(`${title}: ${money(amount)}`,11,title==='Resultado registrado');
 line('Resultado según los datos registrados. No incluye gastos que no hayas añadido ni equivale al efectivo disponible.',9);if(report.channel!=='Todos')line('Los gastos generales sin canal se incluyen únicamente en la vista Todos.',9);y+=3;line(`Ventas (${report.count})`,13,true);
 if(!report.rows.length)line('No hay ventas en este período.');
 for(const r of report.rows){const title=`${r.date} | ${r.channel} | ${r.description||'Venta'}`,details=`Bruta ${money(r.gross)} | Comisión ${money(r.commission)} | Producción ${money(r.production)} | Otros ${money(r.extra)} | Resultado ${money(r.result)}`;keepTogether(title,details);line(title,10,true);line(details,9);y+=2;}
 if(!salesOnly){line('Gastos del negocio',13,true);if(!report.expenses.length)line('No hay gastos registrados en este período.');for(const e of report.expenses)line(`${e.date} | ${e.category} | ${e.description} | ${money(e.amount)}`,9);}
 if(report.warnings.length){line('Datos que requieren revisión',12,true);for(const warning of report.warnings)line(warning,9);}
 const pages=doc.getNumberOfPages();for(let i=1;i<=pages;i++){doc.setPage(i);doc.setDrawColor(225,212,212);doc.line(18,278,192,278);doc.setFontSize(8);doc.setFont('helvetica','normal');doc.text(`Bum Bum Costos | ${i} / ${pages}`,18,284);}
 return doc;
}
export async function downloadReport(report,business,salesOnly=false){const doc=await createReportPdf(report,business,salesOnly);doc.save(`bum-bum-${salesOnly?'ventas':'finanzas'}-${report.from}-${report.to}.pdf`);}
