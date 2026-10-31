export const SOURCES={
 nist:{name:'NIST Handbook 44 (2026), Appendix C',url:'https://www.nist.gov/document/2026-nist-handbook-44-appendix-c'},
 temperature:{name:'NIST Guide to SI, Appendix B.9',url:'https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9'},
 imperial:{name:'UK Units of Measurement Regulations 1994',url:'https://www.legislation.gov.uk/uksi/1994/2867/made'},
 kitchen:{name:'NIST Metric Kitchen',url:'https://www.nist.gov/pml/owm/metric-si/metric-kitchen/metric-kitchen-cooking-measurement-equivalencies'},
 fda:{name:'FDA: metric equivalents of household measures',url:'https://www.fda.gov/regulatory-information/search-fda-guidance-documents/guidance-industry-guidelines-determining-metric-equivalents-household-measures'},
 baking:{name:'King Arthur Baking: Ingredient Weight Chart',url:'https://www.kingarthurbaking.com/learn/ingredient-weight-chart'},
 metricCup:{name:'Healthdirect Australia: taza de 250 mL',url:'https://www.healthdirect.gov.au/healthy-living/food-and-nutrition/drinking-water-and-your-health'},
 water:{name:'NIST GLP 10, abril de 2013, página 5',url:'https://www.nist.gov/system/files/documents/2017/05/09/GLP_10_20130424.pdf'}
};
const date='2026-10-31';
// Keep the published measure. These cup measures do NOT establish a physical density.
const baking=(id,name,massG,referenceQty,refUnit,conditions)=>({id,name,kind:'culinary',massG,referenceQty,refUnit,source:SOURCES.baking.url,sourceName:SOURCES.baking.name,date,conditions:conditions+' Marca, llenado y temperatura pueden variar; no hay una temperatura especificada en la tabla.'});
export const INGREDIENT_REFERENCES=[
 baking('flour','Harina de trigo de uso general','120','1','ref-cup','Harina de uso general; referencia culinaria.'),
 baking('bread-flour','Harina de pan','120','1','ref-cup','Harina para pan; referencia culinaria.'),
 baking('white-sugar','Azúcar blanca granulada','198','1','ref-cup','Azúcar granulada.'),
 baking('brown-sugar','Azúcar morena compactada','213','1','ref-cup','La fuente especifica compactada.'),
 baking('icing-sugar','Azúcar glas sin tamizar','113','1','ref-cup','La fuente especifica sin tamizar.'),
 baking('butter','Mantequilla','113','0.5','ref-cup','La fuente indica 8 cucharadas (media taza).'),
 baking('oil','Aceite vegetal','198','1','ref-cup','Equivalencia culinaria; no es densidad física.'),
 baking('milk','Leche fresca','227','1','ref-cup','Equivalencia culinaria; no es densidad física.'),
 baking('honey','Miel','21','1','ref-tbsp','Una cucharada de referencia de la fuente.'),
 baking('cocoa','Cocoa sin azúcar','42','0.5','ref-cup','Media taza de cocoa sin azúcar.'),
 baking('cream','Crema de leche','227','1','ref-cup','Tabla heavy/light/half & half; confirmar el producto.'),
 baking('chocolate','Chocolate picado','170','1','ref-cup','Chocolate picado; no equivale a chocolate fundido o chips.'),
 baking('cornstarch','Maicena','28','0.25','ref-cup','Un cuarto de taza de almidón de maíz.'),
 {id:'water',name:'Agua pura a 20 °C',kind:'density',massG:'0.99820675',volumeMl:'1',source:SOURCES.water.url,sourceName:SOURCES.water.name,date,conditions:'Agua pura libre de aire a 20 °C; densidad de referencia, no exacta. No representa necesariamente agua mineral o del grifo. Fuente publicada en abril de 2013.'}
];

