import React,{useState} from 'react';import{createRoot}from'react-dom/client';import './style.css';
import { useEffect } from 'react';
import { supabase } from './supabase';
import Login from './Login';
import {
  obtenerIngredientes,
  guardarIngrediente,
  adaptarIngrediente
} from './ingredientsService';
const KEY='bum-bum-costos-v1',NEW='bum-bum-costos-v3';const blank=()=>({ingredients:[],recipes:[],quotes:[],sales:[],decorations:[],settings:{}});
const load=()=>{try{const existing=JSON.parse(localStorage.getItem(NEW)||localStorage.getItem(KEY)||'null');return {...blank(),...existing}}catch{return blank()}};
const fmt=n=>'RD$ '+Number(n||0).toLocaleString('es-DO',{minimumFractionDigits:2,maximumFractionDigits:2});const n=v=>Math.max(0,Number(v)||0);const uid=()=>crypto.randomUUID();
const units={g:['mass',1],kg:['mass',1000],lb:['mass',453.59237],oz:['mass',28.349523125],mg:['mass',.001],ml:['volume',1],L:['volume',1000],'fl oz':['volume',29.5735295625],unidad:['count',1],docena:['count',12]};
const conversion=(amount,from,to)=>units[from]?.[0]===units[to]?.[0]?amount*units[from][1]/units[to][1]:null;
function App(){const [db,setDb]=useState(load),[tab,setTab]=useState('Inicio'),[line,setLine]=useState([]),[selected,setSelected]=useState(''),[qty,setQty]=useState(1),[method,setMethod]=useState('margin'),[pct,setPct]=useState(35),[laborMode,setLaborMode]=useState('fixed'),[labor,setLabor]=useState(0),[hours,setHours]=useState(1),[extra,setExtra]=useState({fill:0,pack:0,delivery:0,other:0}),[decors,setDecors]=useState({}),[notice,setNotice]=useState('');
const update=fn=>setDb(old=>{const next=fn(structuredClone(old));localStorage.setItem(NEW,JSON.stringify(next));return next});

const [guardandoIngrediente, setGuardandoIngrediente] = useState(false);

async function guardarIngredienteFormulario(e) {
  e.preventDefault();

  if (guardandoIngrediente) return;

  const formulario = e.currentTarget;
  const datos = new FormData(formulario);

  setGuardandoIngrediente(true);

  try {
    const registro = await guardarIngrediente({
      name: String(datos.get('name')),
      price: Number(datos.get('price')),
      packageQty: Number(datos.get('packageQty')),
      unit: String(datos.get('unit'))
    });

    const ingrediente = adaptarIngrediente(registro);

    update(db => {
      if (!db.ingredients.some(i => i.id === ingrediente.id)) {
        db.ingredients.push(ingrediente);
      }
      return db;
    });

    formulario.reset();
    setNotice('Ingrediente guardado correctamente en Supabase.');
  } catch (error) {
    setNotice('Error al guardar: ' + error.message);
  } finally {
    setGuardandoIngrediente(false);
  }
}
               
const unitCost=i=>n(i.price)/Math.max(.000001,n(i.packageQty));const recipeCost=r=>(r.lines||[]).reduce((s,l)=>{const i=db.ingredients.find(x=>x.id===l.ingredientId);if(!i)return s;const q=conversion(n(l.qty),l.unit||i.unit,i.unit);return s+(q===null?0:q*unitCost(i))},0);
const recipe=db.recipes.find(x=>x.id===selected),base=recipe?recipeCost(recipe)*(recipe.scaling==='fixed'?Math.ceil(n(qty)):n(qty)):0,decorTotal=db.decorations.reduce((s,d)=>s+n(decors[d.id])*n(d.price),0),laborTotal=n(labor)*(laborMode==='hourly'?n(hours):1),total=base+decorTotal+laborTotal+Object.values(extra).reduce((a,b)=>a+n(b),0),price=method==='margin'?total/(1-Math.min(95,n(pct))/100):total*(1+n(pct)/100);
const fileImport=async e=>{const f=e.target.files?.[0];if(!f)return;try{const data=JSON.parse(await f.text());if(!Array.isArray(data.ingredients)||!Array.isArray(data.recipes)||!Array.isArray(data.quotes)||!Array.isArray(data.sales))throw Error('Estructura de respaldo no válida');if(!confirm('Esto reemplazará los datos de esta versión. ¿Continuar?'))return;update(()=>({...blank(),...data}));setNotice('Respaldo restaurado. Verifica los datos.')}catch(err){setNotice('No se pudo importar: '+err.message)}};
const exportData=()=>{const url=URL.createObjectURL(new Blob([JSON.stringify(db,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='bum-bum-costos-respaldo.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)};
const tabs=['Inicio','Ingredientes','Recetas','Decoraciones','Cotizador','Ventas','Respaldo'];return <><header><img src="/logo.jpg"/><div><h1>Bum Bum Costos</h1><span>Repostería artesanal · Gestión inteligente</span></div></header><nav>{tabs.map(t=><button className={tab===t?'active':''} key={t} onClick={()=>setTab(t)}>{t}</button>)}</nav><main>{notice&&<div className="notice" onClick={()=>setNotice('')}>{notice} ×</div>}{tab==='Inicio'&&<><h2>Tu negocio, bajo control</h2><div className="cards">{[['Ingredientes',db.ingredients.length],['Recetas',db.recipes.length],['Decoraciones',db.decorations.length],['Ventas',fmt(db.sales.reduce((s,x)=>s+n(x.gross),0))]].map(([a,b])=><div className="metric" key={a}><small>{a}</small><strong>{b}</strong></div>)}</div><section><h3>Empecemos</h3><p>Registra tus ingredientes, arma recetas y genera cotizaciones con decoraciones. Esta versión conserva tus datos en este navegador; todavía no está conectada a Supabase.</p></section></>}
{tab==='Ingredientes'&&<><h2>Ingredientes</h2><section>< <form onSubmit={guardarIngredienteFormulario}>(e.currentTarget);update(d=>{d.ingredients.push({id:uid(),name:f.get('name'),price:n(f.get('price')),packageQty:n(f.get('packageQty')),unit:f.get('unit')});return d});e.currentTarget.reset()}}><div className="grid"><label>Ingrediente<input name="name" required placeholder="Harina de trigo"/></label><label>Precio última compra RD$<input name="price" type="number" step=".01" min="0" required/></label><label>Cantidad comprada<input name="packageQty" type="number" step=".001" min=".001" required/></label><label>Unidad<select name="unit">{Object.keys(units).map(u=><option key={u}>{u}</option>)}</select></label></div><button>Guardar ingrediente</button></form></section><section><h3>Ingredientes registrados</h3>{db.ingredients.map(i=><div className="entry" key={i.id}><span><b>{i.name}</b><small>{fmt(i.price)} / {i.packageQty} {i.unit} · {fmt(unitCost(i))}/{i.unit}</small></span><button className="ghost" onClick={()=>{const v=prompt('Nuevo precio RD$',i.price);if(v!==null&&v.trim()!==''&&Number(v)>=0)update(d=>{d.ingredients.find(x=>x.id===i.id).price=n(v);return d})}}>Editar precio</button></div>)}</section></>}
{tab==='Recetas'&&<><h2>Recetas</h2><section><form onSubmit={e=>{e.preventDefault();if(!line.length){setNotice('Agrega ingredientes a la receta');return}const f=new FormData(e.currentTarget);update(d=>{d.recipes.push({id:uid(),name:f.get('name'),yield:n(f.get('yield')),yieldUnit:f.get('yieldUnit'),scaling:f.get('scaling'),lines:line});return d});setLine([]);e.currentTarget.reset()}}><div className="grid"><label>Nombre<input name="name" required/></label><label>Rendimiento<input name="yield" type="number" step=".001" min=".001" defaultValue="1" required/></label><label>Unidad de rendimiento<input name="yieldUnit" defaultValue="lb comercial" required/></label><label>Tipo<select name="scaling"><option value="scalable">Escalable</option><option value="fixed">Fija</option></select></label></div><h3>Ingredientes de la receta</h3>{line.map((l,j)=><div className="entry" key={j}><select value={l.ingredientId} onChange={e=>setLine(v=>v.map((x,k)=>k===j?{...x,ingredientId:e.target.value,unit:db.ingredients.find(i=>i.id===e.target.value)?.unit||'g'}:x))}>{db.ingredients.map(i=><option key={i.id} value={i.id}>{i.name}</option>)}</select><input aria-label="Cantidad" type="number" min=".001" step=".001" value={l.qty} onChange={e=>setLine(v=>v.map((x,k)=>k===j?{...x,qty:n(e.target.value)}:x))}/><select aria-label="Unidad" value={l.unit} onChange={e=>setLine(v=>v.map((x,k)=>k===j?{...x,unit:e.target.value}:x))}>{Object.keys(units).filter(u=>units[u][0]===units[db.ingredients.find(i=>i.id===l.ingredientId)?.unit]?.[0]).map(u=><option key={u}>{u}</option>)}</select><button type="button" className="ghost" onClick={()=>setLine(v=>v.filter((_,k)=>k!==j))}>Quitar</button></div>)}<div className="actions"><button type="button" className="secondary" onClick={()=>{const i=db.ingredients[0];if(i)setLine(v=>[...v,{ingredientId:i.id,qty:1,unit:i.unit}]);else setNotice('Primero registra un ingrediente')}}>+ Ingrediente</button><button>Guardar receta</button></div></form></section><section><h3>Recetario</h3>{db.recipes.map(r=><div className="entry" key={r.id}><span><b>{r.name}</b><small>{r.scaling==='fixed'?'Fija':'Escalable'} · {r.yield} {r.yieldUnit} · {fmt(recipeCost(r))}</small></span></div>)}</section></>}
{tab==='Decoraciones'&&<><h2>Catálogo de decoraciones</h2><section><form onSubmit={e=>{e.preventDefault();const f=new FormData(e.currentTarget);update(d=>{d.decorations.push({id:uid(),name:f.get('name'),type:f.get('type'),price:n(f.get('price'))});return d});e.currentTarget.reset()}}><div className="grid"><label>Decoración<input name="name" required placeholder="Perlas doradas"/></label><label>Tipo<select name="type">{['Perlas','Fondant','Flores','Lazos','Topper','Velas','Figuras','Mangueado','Otros'].map(x=><option key={x}>{x}</option>)}</select></label><label>Costo por unidad RD$<input name="price" type="number" step=".01" min="0" required/></label></div><button>Guardar decoración</button></form></section><section>{db.decorations.map(d=><div className="entry" key={d.id}><span><b>{d.name}</b><small>{d.type}</small></span><b>{fmt(d.price)}</b></div>)}</section></>}
{tab==='Cotizador'&&<><h2>Cotizar pastel</h2><section><div className="grid"><label>Receta<select value={selected} onChange={e=>setSelected(e.target.value)}><option value="">Seleccionar</option>{db.recipes.map(r=><option value={r.id} key={r.id}>{r.name}</option>)}</select></label><label>Cantidad de rendimientos<input type="number" step=".001" min=".001" value={qty} onChange={e=>setQty(e.target.value)}/></label>{[['fill','Rellenos y coberturas'],['pack','Empaque'],['delivery','Entrega'],['other','Otros gastos']].map(([k,label])=><label key={k}>{label} RD$<input type="number" min="0" step=".01" value={extra[k]} onChange={e=>setExtra(v=>({...v,[k]:e.target.value}))}/></label>)}<label>Mano de obra<select value={laborMode} onChange={e=>setLaborMode(e.target.value)}><option value="fixed">Monto fijo</option><option value="hourly">Horas × tarifa</option></select></label><label>{laborMode==='hourly'?'Tarifa por hora':'Monto fijo'} RD$<input type="number" min="0" value={labor} onChange={e=>setLabor(e.target.value)}/></label>{laborMode==='hourly'&&<label>Horas<input type="number" min="0" step=".25" value={hours} onChange={e=>setHours(e.target.value)}/></label>}<label>Método<select value={method} onChange={e=>setMethod(e.target.value)}><option value="margin">Margen sobre venta</option><option value="markup">Recargo sobre costo</option></select></label><label>Porcentaje %<input type="number" min="0" max="95" value={pct} onChange={e=>setPct(e.target.value)}/></label></div><h3>Decoraciones</h3>{db.decorations.map(d=><label className="entry" key={d.id}><span>{d.name} · {fmt(d.price)}/ud.</span><input aria-label={'Cantidad '+d.name} type="number" min="0" step="1" value={decors[d.id]||0} onChange={e=>setDecors(v=>({...v,[d.id]:e.target.value}))}/></label>)}<div className="result"><small>Bizcocho {fmt(base)} · Decoraciones {fmt(decorTotal)} · Mano de obra {fmt(laborTotal)}</small><p>Costo total <b>{fmt(total)}</b></p><h2>Precio sugerido {fmt(price)}</h2><p>Ganancia estimada {fmt(price-total)}</p></div><button disabled={!recipe||!n(qty)} onClick={()=>{update(d=>{d.quotes.push({id:uid(),date:new Date().toISOString().slice(0,10),recipeName:recipe.name,qty:n(qty),totalCost:total,price,method,pct});return d});setNotice('Cotización guardada')}}>Guardar cotización</button></section><section><h3>Cotizaciones guardadas</h3>{db.quotes.slice().reverse().map(q=><div className="entry" key={q.id}><span><b>{q.recipeName}</b><small>{q.date} · Costo {fmt(q.totalCost)}</small></span><b>{fmt(q.price)}</b></div>)}</section></>}
{tab==='Ventas'&&<><h2>Ventas</h2><section><form onSubmit={e=>{e.preventDefault();const f=new FormData(e.currentTarget);update(d=>{d.sales.push({id:uid(),date:f.get('date'),channel:f.get('channel'),description:f.get('description'),gross:n(f.get('gross')),commission:n(f.get('commission')),productionCost:n(f.get('productionCost')),extra:n(f.get('extra'))});return d});e.currentTarget.reset()}}><div className="grid"><label>Fecha<input name="date" type="date" defaultValue={new Date().toISOString().slice(0,10)} required/></label><label>Canal<select name="channel"><option>Uber Eats</option><option>PedidosYa</option><option>Directa</option></select></label><label>Descripción<input name="description" required/></label><label>Venta bruta RD$<input name="gross" type="number" min="0" step=".01" required/></label><label>Comisión %<input name="commission" type="number" min="0" max="100" step=".01" defaultValue="45" required/></label><label>Costo producción RD$<input name="productionCost" type="number" min="0" step=".01" required/></label><label>Otros gastos RD$<input name="extra" type="number" min="0" step=".01" defaultValue="0"/></label></div><button>Registrar venta</button></form></section><section>{db.sales.slice().reverse().map(s=><div className="entry" key={s.id}><span><b>{s.description}</b><small>{s.date} · {s.channel}</small></span><b>{fmt(n(s.gross)*(1-n(s.commission)/100)-n(s.productionCost)-n(s.extra))}</b></div>)}</section></>}
{tab==='Respaldo'&&<><h2>Respaldo y migración</h2><section><p>Exporta los datos antes de actualizar o cambiar de navegador. Puedes importar un respaldo JSON del prototipo anterior.</p><div className="actions"><button onClick={exportData}>Descargar respaldo JSON</button><label>Restaurar JSON<input type="file" accept=".json,application/json" onChange={fileImport}/></label></div><p className="warning">Restaurar reemplaza los datos actuales. Supabase, importación de PDF/Word y sincronización entre dispositivos todavía no están activados.</p></section></>}</main><footer>Versión 0.3 · Datos locales · Haz respaldos periódicos</footer></>}

function AppProtegida() {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;

    supabase.auth.getSession().then(({ data, error }) => {
      if (!active) return;
      if (error) console.error('Error de sesión:', error);
      setSession(data?.session ?? null);
      setLoading(false);
    });

    const { data: listener } =
      supabase.auth.onAuthStateChange((_event, newSession) => {
        if (active) {
          setSession(newSession);
          setLoading(false);
        }
      });

    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  if (loading) {
    return <p>Comprobando acceso a Bum Bum Costos...</p>;
  }

  if (!session) {
    return <Login onLogin={setSession} />;
  }

 
return (
  <>
    <PruebaSupabase />
    <App />
  </>
);

function PruebaSupabase() {
  const [mensaje, setMensaje] = useState(
    'Comprobando conexión con Supabase...'
  );
  const [guardando, setGuardando] = useState(false);

  useEffect(() => {
    obtenerIngredientes()
      .then(datos => {
        setMensaje(
          `Conexión exitosa. Ingredientes en la nube: ${datos.length}`
        );
      })
      .catch(error => {
        setMensaje(`Error de conexión: ${error.message}`);
      });
  }, []);

  async function probarGuardado() {
    if (guardando) return;

    setGuardando(true);
    setMensaje('Guardando ingrediente de prueba...');

    try {
      await guardarIngrediente({
        name: 'PRUEBA - Harina de trigo',
        price: 80,
        packageQty: 1000,
        unit: 'g'
      });

      const ingredientes = await obtenerIngredientes();

      setMensaje(
        `Guardado exitoso. Ingredientes en la nube: ${ingredientes.length}`
      );
    } catch (error) {
      setMensaje(`Error al guardar: ${error.message}`);
    } finally {
      setGuardando(false);
    }
  }

  return (
    <div style={{ textAlign: 'center', padding: 12 }}>
      <p>{mensaje}</p>
      <button
        type="button"
        disabled={guardando}
        onClick={probarGuardado}
      >
        {guardando
          ? 'Guardando...'
          : 'Guardar ingrediente de prueba'}
      </button>
    </div>
  );
}

}


createRoot(document.getElementById('root')).render(
  <AppProtegida />
);
