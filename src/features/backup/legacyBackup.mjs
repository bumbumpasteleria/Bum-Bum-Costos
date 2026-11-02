import {TABLES} from './backup.mjs';
const units={g:['g',1],kg:['g',1000],lb:['g',453.59237],oz:['g',28.349523125],mg:['g',.001],ml:['ml',1],L:['ml',1000],'gal US':['ml',3785.411784],'fl oz':['ml',29.5735295625],unidad:['unit',1],unit:['unit',1],docena:['unit',12]};
export function upgradeBackup(input,owner){
 if(input?.format)return input;
 if(!input||!['ingredients','materials','recipes','books','quotes','sales','decorations'].every(k=>Array.isArray(input[k])))throw Error('Este archivo no tiene el formato de un respaldo de Bum Bum Costos.');
 const now=new Date().toISOString(),data=Object.fromEntries(TABLES.map(k=>[k,[]]));const base=row=>({id:row.id,owner_id:owner,created_at:now});
 data.ingredients=[...input.ingredients.map(r=>[r,'ingredient']),...input.materials.map(r=>[r,'material'])].map(([r,kind])=>{const unit=units[r.unit];if(!unit||unit[1]!==1)throw Error('Revisa las unidades del catálogo de esta copia antigua.');return {...base(r),name:r.name,supplier:r.supplier||'',item_kind:kind,base_unit:unit[0],last_unit_cost:r.lastUnitCost??r.price??null,stock_quantity:r.stockQuantity??0,minimum_stock:r.minimumStock??0,purchase_unit:r.purchaseUnit??null,purchase_quantity:r.purchaseQuantity??null,purchase_price:r.purchasePrice??null};});
 data.recipe_books=input.books.map(r=>({...base(r),name:r.name,usage:r.usage}));
 data.recipes=input.recipes.map(r=>({...base(r),name:r.name,recipe_book_id:r.bookId||null,yield_quantity:r.yield,yield_unit:r.yieldUnit,instructions:r.editSnapshot?.instructions||JSON.stringify({bumBum:1,productType:r.productType,scaling:r.scaling,category:r.category||'',preparation:r.preparation||''})}));
 for(const r of input.recipes)for(const line of r.lines||[]){const ingredient=data.ingredients.find(i=>i.id===line.ingredientId),unit=units[line.unit||ingredient?.base_unit];if(!ingredient||!unit||ingredient.base_unit!==unit[0])throw Error('Ingrediente o unidad no disponible en la copia.');data.recipe_lines.push({...base({id:line.id||crypto.randomUUID()}),recipe_id:r.id,ingredient_id:ingredient.id,quantity_base:Number(line.qty)*unit[1]});}
 data.decorations=input.decorations.map(r=>({...base(r),name:r.name,description:r.type,unit_cost:r.price}));
 data.quotes=input.quotes.map(r=>({...base(r),details:r,pricing_method:r.method,total_cost:r.totalCost,quoted_price:r.price}));
 data.sales=input.sales.map(r=>{const commission=Number(r.gross)*Number(r.commission)/100;return {...base(r),details:r,sold_at:r.date+'T12:00:00Z',channel:r.channel,gross_amount:r.gross,commission_amount:commission,net_amount:Number(r.gross)-commission,cost_amount:Number(r.productionCost)+Number(r.extra||0)};});
 for(const [source,target] of [['products','fridge_products'],['batches','fridge_batches'],['movements','fridge_movements']])data[target]=input.fridge?.[source]||[];
 return {format:'bum-bum-costos',version:2,owner,createdAt:now,data,legacy:true,legacyNotice:'Copia antigua: se recuperan los datos que contiene. Si no incluía existencias de ingredientes, se iniciarán en cero y deberás contarlas en Inventario. No incluye fotos, gastos ni pedidos nuevos.'};
}
