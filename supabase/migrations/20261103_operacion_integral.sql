begin;
-- Preserve existing values and allow fractional consumption without rounding stock to three decimals.
alter table public.ingredients alter column stock_quantity type numeric,alter column minimum_stock type numeric,alter column last_unit_cost type numeric;
alter table public.recipe_lines alter column quantity_base type numeric;
-- Reuse the existing private, approved-account ledger and its version/backup infrastructure.
alter table public.business_entries drop constraint business_entries_kind_check;
alter table public.business_entries add constraint business_entries_kind_check check(kind in
 ('expense','order','recipe_info','quote_brand','product_cost','recipe_profile','subrecipe','customer','supplier','quality','business_settings','work_order','payment','cash','raw_lot','inventory_event'));
create unique index business_recipe_profile on public.business_entries(owner_id,(details->>'recipeId')) where kind='recipe_profile';
create unique index business_subrecipe on public.business_entries(owner_id,(details->>'recipeId')) where kind='subrecipe';
create unique index business_settings_owner on public.business_entries(owner_id) where kind='business_settings';
create index business_raw_lot on public.business_entries(owner_id,(details->>'ingredientId')) where kind='raw_lot';
create index business_payment_order on public.business_entries(owner_id,(details->>'orderId')) where kind='payment';

create function public.bum_ops_number(v jsonb,label_ text,maximum_ numeric default 1e9,positive_ boolean default false) returns numeric language plpgsql immutable set search_path='' as $$
declare n numeric;begin n:=(v#>>'{}')::numeric;if n is null or n<0 or n>=maximum_ or n::text in ('NaN','Infinity','-Infinity') or (positive_ and n=0) then raise exception 'Revisa %',label_;end if;return n;end $$;
revoke all on function public.bum_ops_number(jsonb,text,numeric,boolean) from public,anon,authenticated;

alter function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean) rename to bum_validate_entry_v25;
create function public.bum_validate_entry(p_id uuid,p_kind text,p_details jsonb,p_owner uuid,p_require_recipe boolean) returns jsonb language plpgsql security invoker set search_path='' as $$
declare d jsonb:='{}';k text;v text;rid uuid;child jsonb;n numeric;keys_ text[];seen uuid[]:='{}';cid uuid;begin
 if p_kind not in ('recipe_profile','subrecipe','customer','supplier','quality','business_settings','work_order','payment','cash','raw_lot','inventory_event') then return public.bum_validate_entry_v25(p_id,p_kind,p_details,p_owner,p_require_recipe);end if;
 if p_owner is distinct from auth.uid() or jsonb_typeof(p_details) is distinct from 'object' or length(p_details::text)>300000 then raise exception 'Registro no válido para esta cuenta';end if;
 keys_:=case p_kind
 when 'recipe_profile' then array['recipeId','shape','diameter','width','length','height','layers','prepMinutes','restMinutes','fermentMinutes','bakeMinutes','temperatureC','lossPct','notes']
 when 'subrecipe' then array['recipeId','children']
 when 'customer' then array['name','contact','email','address','notes','archived']
 when 'supplier' then array['name','contact','email','address','notes','archived']
 when 'quality' then array['name','date','recipeId','lotId','criterion','observed','result','responsible','action','notes']
 when 'business_settings' then array['profile','businessName','location','openingCash','openingDate','qualityCriteria','notes']
 when 'work_order' then array['name','date','orderId','recipeId','factor','quantity','status','notes','photo','productionId','productionCost','consumptions']
 when 'payment' then array['orderId','date','amount','direction','method','notes','openingDeposit']
 when 'cash' then array['name','date','amount','direction','category','sourceId','notes']
 when 'raw_lot' then array['ingredientId','date','expires','quantity','remaining','price','paid','code','supplier','purchaseId']
 else array['ingredientId','date','quantity','before','after','unit','reason','cost','sourceId','consumptions','unitCostBefore','unitCostAfter'] end;
 foreach k in array keys_ loop if p_details?k then d:=d||jsonb_build_object(k,p_details->k);end if;end loop;
 if p_kind in ('recipe_profile','subrecipe','work_order') or (p_kind='quality' and nullif(d->>'recipeId','') is not null) then
  rid:=(d->>'recipeId')::uuid;if rid is null or exists(select 1 from public.recipes where id=rid and owner_id<>p_owner) or (p_require_recipe and not exists(select 1 from public.recipes where id=rid and owner_id=p_owner)) then raise exception 'Selecciona una receta de tu cuenta';end if;
 end if;
 if p_kind in ('customer','supplier','quality','work_order','cash') and length(trim(coalesce(d->>'name',''))) not between 1 and 160 then raise exception 'Completa un nombre de hasta 160 caracteres';end if;
 if p_kind in ('customer','supplier') and d?'archived' and jsonb_typeof(d->'archived') is distinct from 'boolean' then raise exception 'Estado de archivo no válido';end if;
 foreach k in array array['contact','email','address','notes','location','businessName','criterion','observed','responsible','action','code','supplier','reason','method','qualityCriteria'] loop if d?k and (jsonb_typeof(d->k) is distinct from 'string' or length(d->>k)>5000) then raise exception 'Texto demasiado largo o no válido: %',k;end if;end loop;
 if p_kind in ('quality','work_order','payment','cash','raw_lot','inventory_event') then if nullif(d->>'date','') is null then raise exception 'Completa la fecha';end if;perform (d->>'date')::date;end if;
 if p_kind='recipe_profile' then
  if coalesce(d->>'shape','') not in ('round','square','rectangle','other') then raise exception 'Selecciona la forma del molde';end if;
  foreach k in array array['diameter','width','length','height','layers','prepMinutes','restMinutes','fermentMinutes','bakeMinutes','lossPct'] loop if d?k and d->k<>'null'::jsonb then n:=public.bum_ops_number(d->k,k,100000);if k='lossPct' and n>=100 then raise exception 'La merma debe ser menor de 100 %%';end if;if k='layers' and (n<>trunc(n) or n<1) then raise exception 'Indica un número entero de capas';end if;end if;end loop;
  if d?'temperatureC' and d->'temperatureC'<>'null'::jsonb then n:=(d->>'temperatureC')::numeric;if n<-273.15 or n>1000 or n::text in ('NaN','Infinity','-Infinity') then raise exception 'Temperatura fuera de rango';end if;end if;
 elsif p_kind='subrecipe' then
  if jsonb_typeof(d->'children') is distinct from 'array' or jsonb_array_length(d->'children')>30 then raise exception 'Revisa las subrecetas';end if;
  for child in select * from jsonb_array_elements(d->'children') loop
   cid:=(child->>'recipeId')::uuid;if cid=any(seen) then raise exception 'Ya añadiste esa subreceta. Ajusta su proporción en lugar de repetirla';end if;seen:=array_append(seen,cid);
   if not exists(select 1 from public.recipes where id=(child->>'recipeId')::uuid and owner_id=p_owner) or child->>'recipeId'=rid::text then raise exception 'Subreceta no disponible o referencia circular';end if;perform public.bum_ops_number(child->'factor','la proporción de subreceta',1e6,true);
  end loop;
  if exists(with recursive edges as(select (e.details->>'recipeId')::uuid a,(x->>'recipeId')::uuid b from public.business_entries e cross join lateral jsonb_array_elements(e.details->'children') x where e.owner_id=p_owner and e.kind='subrecipe' and e.id<>p_id union all select rid,(x->>'recipeId')::uuid from jsonb_array_elements(d->'children') x),walk as(select rid id,array[rid] path,false cycle union all select e.b,w.path||e.b,e.b=any(w.path) from walk w join edges e on e.a=w.id where not w.cycle and cardinality(w.path)<=30) select 1 from(select * from walk limit 2001) bounded having bool_or(cycle or cardinality(path)>30) or count(*)>2000) then raise exception 'Las subrecetas crean un ciclo o una composición demasiado grande';end if;
 elsif p_kind='business_settings' then
  if coalesce(d->>'profile','') not in ('pastry','bakery','mixed') then raise exception 'Selecciona el perfil del negocio';end if;n:=public.bum_ops_number(d->'openingCash','el saldo inicial',1e12);if n<>round(n,2) then raise exception 'El saldo inicial admite dos decimales';end if;perform (d->>'openingDate')::date;if nullif(d->>'openingDate','') is null then raise exception 'Completa la fecha de saldo inicial';end if;
 elsif p_kind='quality' then
  if coalesce(d->>'result','') not in ('passed','review','blocked') or length(trim(coalesce(d->>'criterion','')))=0 or length(trim(coalesce(d->>'responsible','')))=0 then raise exception 'Completa criterio, resultado y responsable';end if;
  if nullif(d->>'lotId','') is not null and not exists(select 1 from public.business_entries where id=(d->>'lotId')::uuid and owner_id=p_owner and kind='raw_lot') and not exists(select 1 from public.fridge_batches where id=(d->>'lotId')::uuid and owner_id=p_owner) then raise exception 'Selecciona un lote de tu cuenta';end if;
 elsif p_kind='work_order' then
  perform public.bum_ops_number(d->'factor','la proporción de la receta',1e6,true);perform public.bum_ops_number(d->'quantity','la cantidad producida',1e9,true);
  if coalesce(d->>'status','') not in ('planned','preparing','done','cancelled') then raise exception 'Estado no válido';end if;
  if nullif(d->>'orderId','') is not null and not exists(select 1 from public.business_entries where id=(d->>'orderId')::uuid and owner_id=p_owner and kind='order') then raise exception 'Pedido no disponible';end if;
  if length(coalesce(d->>'photo',''))>250000 or (nullif(d->>'photo','') is not null and d->>'photo'!~'^data:image/jpeg;base64,[A-Za-z0-9+/=]+$') then raise exception 'Fotografía no válida';end if;
 elsif p_kind in ('payment','cash') then
  n:=public.bum_ops_number(d->'amount','el importe',1e9,true);if n<>round(n,2) then raise exception 'Los pagos e importes de caja admiten dos decimales';end if;if coalesce(d->>'direction','') not in ('in','out') then raise exception 'Selecciona entrada o salida';end if;
  if p_kind='payment' and not exists(select 1 from public.business_entries where id=(d->>'orderId')::uuid and owner_id=p_owner and kind='order') then raise exception 'Pedido no disponible';end if;
 elsif p_kind='raw_lot' then
  if not exists(select 1 from public.ingredients where id=(d->>'ingredientId')::uuid and owner_id=p_owner) then raise exception 'Artículo no disponible';end if;
  n:=public.bum_ops_number(d->'quantity','la cantidad de compra',1e12,true);if public.bum_ops_number(d->'remaining','la existencia de lote',1e12)>n then raise exception 'Cantidad restante superior a la compra';end if;n:=public.bum_ops_number(d->'price','el precio',1e12);if n<>round(n,2) then raise exception 'El total de compra admite dos decimales';end if;n:=public.bum_ops_number(d->'paid','el pago',1e12);if n<>round(n,2) or n>(d->>'price')::numeric then raise exception 'Revisa el pago de la compra';end if;
  if nullif(d->>'expires','') is not null then perform (d->>'expires')::date;if (d->>'expires')::date<(d->>'date')::date then raise exception 'El vencimiento es anterior a la compra';end if;end if;
  if not p_require_recipe and (d->>'remaining')::numeric+coalesce((select sum((details->>'remaining')::numeric) from public.business_entries where owner_id=p_owner and kind='raw_lot' and id<>p_id and details->>'ingredientId'=d->>'ingredientId'),0)>(select stock_quantity from public.ingredients where owner_id=p_owner and id=(d->>'ingredientId')::uuid) then raise exception 'El lote del respaldo supera el inventario actual. No se restauró ningún registro';end if;
 end if;return d;
end $$;
revoke all on function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean),public.bum_validate_entry_v25(uuid,text,jsonb,uuid,boolean) from public,anon,authenticated;

create function public.bum_ops_put(p_id uuid,p_kind text,p_data jsonb,p_expected integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();r public.business_entries;d jsonb;begin
 if u is null or not public.bum_account_approved() or p_id is null or p_expected is null or p_expected<0 then raise exception 'Cuenta o registro no disponible';end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text,931));
 d:=public.bum_validate_entry(p_id,p_kind,p_data,u,true);
 select * into r from public.business_entries where id=p_id for update;
 if found then
  if r.owner_id<>u or r.kind<>p_kind then raise exception 'Registro no disponible';end if;if r.details=d then return to_jsonb(r);end if;if r.version<>p_expected then raise exception 'El registro cambió. Actualiza antes de guardar';end if;
  insert into public.business_entry_history(owner_id,entry_id,kind,details,version) values(u,r.id,r.kind,r.details,r.version);
  update public.business_entries set details=d,version=version+1,updated_at=now() where id=p_id returning * into r;
 else if p_expected<>0 then raise exception 'El registro anterior ya no está disponible';end if;insert into public.business_entries(id,owner_id,kind,details) values(p_id,u,p_kind,d) returning * into r;end if;return to_jsonb(r);
end $$;
revoke all on function public.bum_ops_put(uuid,text,jsonb,integer) from public,anon,authenticated;

alter function public.bum_save_entry(uuid,text,jsonb,integer) rename to bum_save_entry_v25;
create function public.bum_save_entry(p_id uuid,p_kind text,p_details jsonb,p_expected integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare old public.business_entries;d jsonb:=p_details;begin
 if auth.uid() is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,931));
 if p_kind in ('recipe_profile','subrecipe','customer','supplier','quality','business_settings','work_order') then
  if p_kind='work_order' then
   select * into old from public.business_entries where id=p_id and owner_id=auth.uid() and kind='work_order';
   if old.details?'productionId' then raise exception 'Una preparación terminada conserva su historial. Crea otra orden';end if;
   if d?'productionId' or d?'consumptions' or d?'productionCost' or d->>'status'='done' then raise exception 'Usa Registrar producción terminada para descontar inventario';end if;
  end if;
  return public.bum_ops_put(p_id,p_kind,d,p_expected);
 end if;
 if p_kind='order' and exists(select 1 from public.business_entries where owner_id=auth.uid() and kind='payment' and details->>'orderId'=p_id::text) then
  select * into old from public.business_entries where owner_id=auth.uid() and id=p_id and kind='order' for update;
  if (d->>'deposit')::numeric is distinct from (old.details->>'deposit')::numeric then raise exception 'Registra cobros o devoluciones desde Agenda y cobros; no cambies el anticipo manualmente';end if;
 end if;
 if p_kind in ('payment','cash','raw_lot','inventory_event') then raise exception 'Usa la operación correspondiente para conservar el historial';end if;
 return public.bum_save_entry_v25(p_id,p_kind,d,p_expected);
end $$;
revoke all on function public.bum_save_entry(uuid,text,jsonb,integer),public.bum_save_entry_v25(uuid,text,jsonb,integer) from public,anon,authenticated;
grant execute on function public.bum_save_entry(uuid,text,jsonb,integer) to authenticated;

create function public.bum_recipe_components(p_recipe uuid,p_owner uuid) returns table(ingredient_id uuid,quantity numeric) language plpgsql security invoker set search_path='' as $$
declare nodes jsonb;
begin
 if p_owner is distinct from auth.uid() then raise exception 'Cuenta no disponible';end if;
 with recursive tree as(
 select p_recipe id,1::numeric factor,array[p_recipe] path
 union all select (x->>'recipeId')::uuid,t.factor*(x->>'factor')::numeric,t.path||(x->>'recipeId')::uuid from tree t join public.business_entries b on b.owner_id=p_owner and b.kind='subrecipe' and b.details->>'recipeId'=t.id::text cross join lateral jsonb_array_elements(b.details->'children') x where cardinality(t.path)<31 and not (x->>'recipeId')::uuid=any(t.path)
 ) select coalesce(jsonb_agg(to_jsonb(bounded)),'[]'::jsonb) into nodes from(select * from tree limit 2001) bounded;
 if jsonb_array_length(nodes)>2000 or exists(select 1 from jsonb_array_elements(nodes) n where jsonb_array_length(n->'path')>30) then raise exception 'La composición tiene demasiados niveles o componentes';end if;
 return query select l.ingredient_id,sum((case when l.measurement_quantity is null then l.quantity_base else public.bum_recipe_base(l.ingredient_id,l.measurement_quantity,l.measurement_unit,p_owner) end)*t.factor) from jsonb_to_recordset(nodes) t(id uuid,factor numeric) join public.recipes r on r.id=t.id and r.owner_id=p_owner join public.recipe_lines l on l.recipe_id=r.id and l.owner_id=p_owner group by l.ingredient_id;
end $$;
revoke all on function public.bum_recipe_components(uuid,uuid) from public,anon,authenticated;

-- Allocate tracked raw lots first (FEFO); existing untracked stock stays usable.
create function public.bum_consume_raw_lots(p_ingredient uuid,p_quantity numeric,p_date date,p_reason text,p_source uuid) returns void language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();r public.business_entries;left_ numeric:=p_quantity;take_ numeric;tracked numeric;stock_ numeric;begin
 if u is null or not public.bum_account_approved() or p_quantity<0 then raise exception 'Consumo no válido';end if;
 select stock_quantity into stock_ from public.ingredients where id=p_ingredient and owner_id=u for update;if not found or stock_ is null or stock_<p_quantity then raise exception 'Existencias insuficientes o sin registrar';end if;
 select coalesce(sum((details->>'remaining')::numeric),0) into tracked from public.business_entries where owner_id=u and kind='raw_lot' and details->>'ingredientId'=p_ingredient::text;
 if tracked>stock_ then raise exception 'Los lotes superan las existencias. Revisa y concilia el inventario';end if;
 for r in select * from public.business_entries where owner_id=u and kind='raw_lot' and details->>'ingredientId'=p_ingredient::text and (details->>'remaining')::numeric>0 order by nullif(details->>'expires','')::date nulls last,created_at,id for update loop
  if left_<=0 then exit;end if;
  if p_reason='production' and ((r.details->>'date')::date>p_date or (nullif(r.details->>'expires','') is not null and (r.details->>'expires')::date<p_date)) then continue;end if;
  take_:=least(left_,(r.details->>'remaining')::numeric);perform public.bum_ops_put(r.id,'raw_lot',jsonb_set(r.details,'{remaining}',to_jsonb((r.details->>'remaining')::numeric-take_)),r.version);left_:=left_-take_;
 end loop;
 if left_>greatest(0,stock_-tracked) then raise exception 'No hay suficientes lotes vigentes. Registra la merma de lo vencido';end if;
end $$;
revoke all on function public.bum_consume_raw_lots(uuid,numeric,date,text,uuid) from public,anon,authenticated;

create function public.bum_inventory_purchase(p_id uuid,p_item uuid,p_quantity numeric,p_price numeric,p_date date,p_expires date,p_code text,p_supplier text,p_paid numeric) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();i public.ingredients;r public.business_entries;d jsonb;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));
 perform public.bum_ops_number(to_jsonb(p_quantity),'la cantidad',1e12,true);perform public.bum_ops_number(to_jsonb(p_price),'el precio',1e12);perform public.bum_ops_number(to_jsonb(p_paid),'el pago',1e12);
 if p_price/p_quantity>=1e10 then raise exception 'Costo unitario fuera de rango';end if;
 if p_date is null or p_date>(now() at time zone 'America/Santo_Domingo')::date or p_paid>p_price then raise exception 'Revisa fecha y pago de compra';end if;
 select * into r from public.business_entries where id=p_id;if found then if r.owner_id<>u or r.kind<>'raw_lot' or r.details->>'ingredientId'<>p_item::text or (r.details->>'quantity')::numeric<>p_quantity or (r.details->>'price')::numeric<>p_price or (r.details->>'paid')::numeric<>p_paid or r.details->>'date'<>p_date::text or coalesce(r.details->>'expires','')<>coalesce(p_expires::text,'') or coalesce(r.details->>'code','')<>coalesce(p_code,'') or coalesce(r.details->>'supplier','')<>coalesce(p_supplier,'') then raise exception 'Este intento ya existe con otros datos';end if;select * into i from public.ingredients where id=p_item and owner_id=u;return to_jsonb(i);end if;
 select * into i from public.ingredients where id=p_item and owner_id=u for update;if not found or i.stock_quantity is null then raise exception 'Registra primero el conteo inicial del artículo en Inventario';end if;
 if lower(trim(coalesce(p_supplier,'')))<>lower(trim(coalesce(i.supplier,''))) then raise exception 'Este artículo pertenece a otro proveedor. Registra una variante para conservar precios separados';end if;
 d:=jsonb_build_object('ingredientId',p_item,'date',p_date,'expires',p_expires,'quantity',p_quantity,'remaining',p_quantity,'price',p_price,'paid',p_paid,'code',coalesce(p_code,''),'supplier',coalesce(p_supplier,''),'purchaseId',p_id);
 perform public.bum_ops_put(p_id,'raw_lot',d,0);
 perform public.bum_ops_put(gen_random_uuid(),'inventory_event',jsonb_build_object('ingredientId',p_item,'date',p_date,'quantity',p_quantity,'before',i.stock_quantity,'after',i.stock_quantity+p_quantity,'unit',i.base_unit,'reason','purchase','cost',p_price,'sourceId',p_id),0);
 update public.ingredients set stock_quantity=stock_quantity+p_quantity,last_unit_cost=p_price/p_quantity where id=p_item and owner_id=u returning * into i;
 if p_paid>0 then perform public.bum_ops_put(gen_random_uuid(),'cash',jsonb_build_object('name','Pago de compra: '||i.name,'date',p_date,'amount',p_paid,'direction','out','category','purchase','sourceId',p_id,'notes','Pago registrado al comprar'),0);end if;
 return to_jsonb(i);
end $$;
revoke all on function public.bum_inventory_purchase(uuid,uuid,numeric,numeric,date,date,text,text,numeric) from public,anon;grant execute on function public.bum_inventory_purchase(uuid,uuid,numeric,numeric,date,date,text,text,numeric) to authenticated;

create function public.bum_inventory_adjust(p_id uuid,p_item uuid,p_quantity numeric,p_minimum numeric,p_expected numeric,p_expected_minimum numeric,p_reason text) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();i public.ingredients;r public.business_entries;day date:=(now() at time zone 'America/Santo_Domingo')::date;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));perform public.bum_ops_number(to_jsonb(p_quantity),'la existencia',1e12);perform public.bum_ops_number(to_jsonb(p_minimum),'el mínimo',1e12);if length(trim(coalesce(p_reason,''))) not between 1 and 500 then raise exception 'Describe el motivo del ajuste';end if;
 select * into r from public.business_entries where id=p_id;if found then if r.owner_id<>u or r.kind<>'inventory_event' or r.details->>'ingredientId'<>p_item::text or (r.details->>'after')::numeric<>p_quantity then raise exception 'Este intento pertenece a otro ajuste';end if;select * into i from public.ingredients where id=p_item and owner_id=u;return to_jsonb(i);end if;
 select * into i from public.ingredients where id=p_item and owner_id=u for update;if not found or i.stock_quantity is distinct from p_expected or i.minimum_stock is distinct from p_expected_minimum then raise exception 'Las existencias cambiaron. Actualiza antes de guardar';end if;
 if p_quantity<coalesce(i.stock_quantity,0) then perform public.bum_consume_raw_lots(p_item,i.stock_quantity-p_quantity,day,'adjustment',p_id);end if;
 perform public.bum_ops_put(p_id,'inventory_event',jsonb_build_object('ingredientId',p_item,'date',day,'quantity',abs(p_quantity-coalesce(i.stock_quantity,0)),'before',i.stock_quantity,'after',p_quantity,'unit',i.base_unit,'reason',p_reason,'cost',0),0);
 update public.ingredients set stock_quantity=p_quantity,minimum_stock=p_minimum where id=p_item and owner_id=u returning * into i;return to_jsonb(i);
end $$;
revoke all on function public.bum_inventory_adjust(uuid,uuid,numeric,numeric,numeric,numeric,text) from public,anon;grant execute on function public.bum_inventory_adjust(uuid,uuid,numeric,numeric,numeric,numeric,text) to authenticated;

create function public.bum_order_payment(p_id uuid,p_order uuid,p_date date,p_amount numeric,p_direction text,p_method text,p_notes text) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();o public.business_entries;r public.business_entries;received numeric;next_ numeric;d jsonb;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));perform public.bum_ops_number(to_jsonb(p_amount),'el importe',1e9,true);if p_direction not in ('in','out') or p_date is null or p_date>(now() at time zone 'America/Santo_Domingo')::date then raise exception 'Revisa tipo y fecha del cobro';end if;
 select * into o from public.business_entries where id=p_order and owner_id=u and kind='order' for update;if not found then raise exception 'Pedido no disponible';end if;
 select * into r from public.business_entries where id=p_id;if found then if r.owner_id<>u or r.kind<>'payment' or r.details->>'orderId'<>p_order::text or (r.details->>'amount')::numeric<>p_amount or r.details->>'direction'<>p_direction or r.details->>'date'<>p_date::text then raise exception 'Este intento pertenece a otro pago';end if;return to_jsonb(o);end if;
 received:=(o.details->>'deposit')::numeric;next_:=received+case when p_direction='in' then p_amount else -p_amount end;if next_<0 or next_>(o.details->>'total')::numeric then raise exception 'El cobro supera el saldo o la devolución supera lo recibido';end if;
 d:=jsonb_build_object('orderId',p_order,'date',p_date,'amount',p_amount,'direction',p_direction,'method',coalesce(p_method,''),'notes',coalesce(p_notes,''),'openingDeposit',received);
 perform public.bum_ops_put(p_id,'payment',d,0);return public.bum_ops_put(o.id,'order',jsonb_set(o.details,'{deposit}',to_jsonb(next_)),o.version);
end $$;
revoke all on function public.bum_order_payment(uuid,uuid,date,numeric,text,text,text) from public,anon;grant execute on function public.bum_order_payment(uuid,uuid,date,numeric,text,text,text) to authenticated;

create function public.bum_cash_record(p_id uuid,p_data jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();r public.business_entries;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));select * into r from public.business_entries where id=p_id;
 if found then if r.owner_id<>u or r.kind<>'cash' or r.details<>public.bum_validate_entry(p_id,'cash',p_data,u,true) then raise exception 'Este intento pertenece a otro movimiento';end if;return to_jsonb(r);end if;
 if (p_data->>'date')::date>(now() at time zone 'America/Santo_Domingo')::date then raise exception 'La fecha no puede ser futura';end if;return public.bum_ops_put(p_id,'cash',p_data,0);
end $$;
revoke all on function public.bum_cash_record(uuid,jsonb) from public,anon;grant execute on function public.bum_cash_record(uuid,jsonb) to authenticated;

-- Guard stable references from deletions and simultaneous graph changes.
create function public.bum_ops_recipe_delete_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare r public.business_entries;begin perform pg_advisory_xact_lock(hashtextextended(old.owner_id::text,931));if exists(select 1 from public.business_entries b cross join lateral jsonb_array_elements(b.details->'children') x where b.owner_id=old.owner_id and b.kind='subrecipe' and x->>'recipeId'=old.id::text) then raise exception 'Esta receta se utiliza como subreceta. Retira primero sus vínculos';end if;for r in select * from public.business_entries where owner_id=old.owner_id and kind='subrecipe' and details->>'recipeId'=old.id::text loop perform public.bum_ops_put(r.id,'subrecipe',jsonb_set(r.details,'{children}','[]'::jsonb),r.version);end loop;return old;end $$;
revoke all on function public.bum_ops_recipe_delete_guard() from public,anon,authenticated;
create trigger bum_ops_recipe_delete before delete on public.recipes for each row execute function public.bum_ops_recipe_delete_guard();

-- Existing production remains the single source for finished lots and historical unit cost.
-- Add graph serialization, resolve live subrecipes and consume raw lots in that same transaction.
do $$ declare s text;prior text;begin
 s:=pg_get_functiondef('public.bum_fridge_production(uuid,uuid,numeric,numeric,date,date)'::regprocedure);prior:=s;
 s:=replace(s,'select * into product from public.fridge_products','perform pg_advisory_xact_lock(hashtextextended(u::text,931)); select * into product from public.fridge_products');
 s:=replace(s,'if not exists(select 1 from public.recipe_lines where recipe_id=product.recipe_id and owner_id=u)','if not exists(select 1 from public.bum_recipe_components(product.recipe_id,u))');
 s:=replace(s,'i.id in(select ingredient_id from public.recipe_lines where recipe_id=product.recipe_id and owner_id=u)','i.id in(select ingredient_id from public.bum_recipe_components(product.recipe_id,u))');
 s:=replace(s,'sum(case when l.measurement_quantity is null then l.quantity_base else public.bum_recipe_base(i.id,l.measurement_quantity,l.measurement_unit,u) end)*p_factor as quantity','sum(l.quantity)*p_factor as quantity');
 s:=replace(s,'from public.recipe_lines l join public.ingredients i on i.id=l.ingredient_id and i.owner_id=u where l.recipe_id=product.recipe_id and l.owner_id=u group by i.id order by i.id loop','from public.bum_recipe_components(product.recipe_id,u) l join public.ingredients i on i.id=l.ingredient_id and i.owner_id=u group by i.id order by i.id loop');
 s:=replace(s,'cost:=cost+used.quantity*used.last_unit_cost;','perform public.bum_consume_raw_lots(used.id,used.quantity,p_prepared,''production'',p_id); cost:=cost+used.quantity*used.last_unit_cost;');
 s:=replace(s,'update public.ingredients set stock_quantity=stock_quantity-used.quantity where id=used.id and owner_id=u;','perform public.bum_ops_put(gen_random_uuid(),''inventory_event'',jsonb_build_object(''ingredientId'',used.id,''date'',p_prepared,''quantity'',used.quantity,''before'',used.stock_quantity,''after'',used.stock_quantity-used.quantity,''unit'',used.base_unit,''reason'',''production'',''sourceId'',p_id,''cost'',used.quantity*used.last_unit_cost),0); update public.ingredients set stock_quantity=stock_quantity-used.quantity where id=used.id and owner_id=u;');
 if s=prior or position('sum(l.quantity)' in s)=0 or position('bum_consume_raw_lots(used.id' in s)=0 then raise exception 'No se pudo conectar la producción existente';end if;execute s;
end $$;
create function public.bum_work_produce(p_id uuid,p_work uuid,p_expected integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();w public.business_entries;used record;cost numeric:=0;details_ jsonb:='[]';day date:=(now() at time zone 'America/Santo_Domingo')::date;begin
 if u is null or not public.bum_account_approved() or p_id is null then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));
 select * into w from public.business_entries where id=p_work and owner_id=u and kind='work_order' for update;if not found then raise exception 'Orden de trabajo no disponible';end if;
 if w.details?'productionId' then if w.details->>'productionId'<>p_id::text then raise exception 'Esta orden ya fue producida';end if;return to_jsonb(w);end if;
 if w.version<>p_expected or w.details->>'status'='cancelled' then raise exception 'La orden cambió o fue cancelada';end if;
 perform 1 from public.recipes where owner_id=u order by id for update;
 perform 1 from public.ingredients where owner_id=u and id in(select ingredient_id from public.bum_recipe_components((w.details->>'recipeId')::uuid,u)) order by id for update;
 if not exists(select 1 from public.bum_recipe_components((w.details->>'recipeId')::uuid,u)) then raise exception 'La receta no tiene ingredientes';end if;
 for used in select i.id,i.name,i.base_unit,i.stock_quantity,i.last_unit_cost,c.quantity*(w.details->>'factor')::numeric quantity from public.bum_recipe_components((w.details->>'recipeId')::uuid,u) c join public.ingredients i on i.id=c.ingredient_id and i.owner_id=u order by i.id loop
  if used.last_unit_cost is null or used.stock_quantity is null or used.stock_quantity<used.quantity then raise exception 'Completa precios y existencias suficientes de %',used.name;end if;
  perform public.bum_consume_raw_lots(used.id,used.quantity,day,'production',p_id);cost:=cost+used.quantity*used.last_unit_cost;
  perform public.bum_ops_put(gen_random_uuid(),'inventory_event',jsonb_build_object('ingredientId',used.id,'date',day,'quantity',used.quantity,'before',used.stock_quantity,'after',used.stock_quantity-used.quantity,'unit',used.base_unit,'reason','work_order','sourceId',p_id,'cost',used.quantity*used.last_unit_cost),0);
  update public.ingredients set stock_quantity=stock_quantity-used.quantity where id=used.id and owner_id=u;
  details_:=details_||jsonb_build_array(jsonb_build_object('ingredientId',used.id,'name',used.name,'quantity',used.quantity,'unit',used.base_unit,'unitCost',used.last_unit_cost));
 end loop;
 return public.bum_ops_put(w.id,'work_order',w.details||jsonb_build_object('status','done','productionId',p_id,'productionCost',cost,'consumptions',details_),w.version);
end $$;
revoke all on function public.bum_work_produce(uuid,uuid,integer) from public,anon;grant execute on function public.bum_work_produce(uuid,uuid,integer) to authenticated;

-- Serialize recipe graph reads with every existing recipe-save entry point, before row locks.
do $$ declare r record;s text;begin for r in select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace join pg_language l on l.oid=p.prolang where n.nspname='public' and l.lanname='plpgsql' and (p.proname like 'guardar_receta_%' or p.proname like 'actualizar_receta_%') loop
 s:=pg_get_functiondef(r.oid);s:=regexp_replace(s,'\mBEGIN\M','BEGIN perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,931));','i');execute s;
 end loop;end $$;
do $$ declare s text;begin
 s:=pg_get_functiondef('public.actualizar_receta_recetario_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,jsonb)'::regprocedure);
 s:=replace(s,'if jsonb_array_length(p_lines)=0 then','if jsonb_array_length(p_lines)=0 and not exists(select 1 from public.business_entries where owner_id=auth.uid() and kind=''subrecipe'' and details->>''recipeId''=p_id::text and jsonb_array_length(details->''children'')>0) then');execute s;
end $$;
create function public.bum_compose_recipe(p_id uuid,p_name text,p_book uuid,p_yield numeric,p_unit text,p_children jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();r public.recipes;b public.business_entries;begin
 if u is null or not public.bum_account_approved() or length(trim(coalesce(p_name,''))) not between 1 and 160 or length(trim(coalesce(p_unit,''))) not between 1 and 40 then raise exception 'Completa nombre, rendimiento y recetario';end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text,931));perform public.bum_ops_number(to_jsonb(p_yield),'el rendimiento',1e9,true);
 if not exists(select 1 from public.recipe_books where id=p_book and owner_id=u) or jsonb_typeof(p_children) is distinct from 'array' or jsonb_array_length(p_children)=0 then raise exception 'Selecciona un recetario y al menos una subreceta';end if;
 select * into r from public.recipes where id=p_id;if found then
  select * into b from public.business_entries where owner_id=u and kind='subrecipe' and details->>'recipeId'=p_id::text;
  if r.owner_id<>u or r.name<>trim(p_name) or r.recipe_book_id<>p_book or r.yield_quantity<>p_yield or r.yield_unit<>p_unit or b.details->'children' is distinct from p_children then raise exception 'Este intento pertenece a otra receta';end if;
 else
  insert into public.recipes(id,owner_id,name,recipe_book_id,yield_quantity,yield_unit,instructions) values(p_id,u,trim(p_name),p_book,p_yield,p_unit,'{"bumBum":1,"scaling":"scalable","productType":"Otro artículo","preparation":"","category":""}') returning * into r;
  perform public.bum_ops_put(gen_random_uuid(),'subrecipe',jsonb_build_object('recipeId',p_id,'children',p_children),0);
 end if;return to_jsonb(r)||jsonb_build_object('recipe_lines','[]'::jsonb);
end $$;
revoke all on function public.bum_compose_recipe(uuid,text,uuid,numeric,text,jsonb) from public,anon;grant execute on function public.bum_compose_recipe(uuid,text,uuid,numeric,text,jsonb) to authenticated;
create function public.bum_ops_ingredient_lock() returns trigger language plpgsql security definer set search_path='' as $$
begin if auth.uid() is not null then perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,931));end if;return null;end $$;
create trigger bum_ops_ingredient_lock before update or delete on public.ingredients for each statement execute function public.bum_ops_ingredient_lock();
create function public.bum_ops_ingredient_history() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op='DELETE' then if exists(select 1 from public.business_entries where owner_id=old.owner_id and kind in ('raw_lot','inventory_event') and details->>'ingredientId'=old.id::text) then raise exception 'Este artículo tiene compras o movimientos. Conserva su historial y ajusta sus existencias';end if;return old;end if;
 if auth.uid()=new.owner_id and old.last_unit_cost is distinct from new.last_unit_cost then
  perform public.bum_ops_put(gen_random_uuid(),'inventory_event',jsonb_build_object('ingredientId',new.id,'date',(now() at time zone 'America/Santo_Domingo')::date,'quantity',0,'before',old.stock_quantity,'after',new.stock_quantity,'unit',new.base_unit,'reason','price_change','cost',0,'unitCostBefore',old.last_unit_cost,'unitCostAfter',new.last_unit_cost),0);
 end if;return new;
end $$;
create trigger bum_ops_ingredient_history before update or delete on public.ingredients for each row execute function public.bum_ops_ingredient_history();
revoke all on function public.bum_ops_ingredient_lock(),public.bum_ops_ingredient_history() from public,anon,authenticated;
create function public.bum_lot_usable(p_lot uuid,p_owner uuid) returns boolean language sql stable security invoker set search_path='' as $$
 select p_owner=auth.uid() and (select details->>'result' from public.business_entries where owner_id=p_owner and kind='quality' and details->>'lotId'=p_lot::text order by updated_at desc,id desc limit 1) is distinct from 'blocked';
$$;
revoke all on function public.bum_lot_usable(uuid,uuid) from public,anon,authenticated;
do $$ declare s text;begin
 s:=pg_get_functiondef('public.bum_consume_raw_lots(uuid,numeric,date,text,uuid)'::regprocedure);s:=replace(s,'if left_<=0 then exit;end if;','if left_<=0 then exit;end if; if p_reason=''production'' and not public.bum_lot_usable(r.id,u) then continue;end if;');execute s;
 s:=pg_get_functiondef('public.bum_fridge_sale(jsonb)'::regprocedure);if position('and remaining_quantity>0 order by' in s)=0 then raise exception 'No se pudo conectar el control de calidad de lotes';end if;
 s:=replace(s,'and remaining_quantity>0 order by','and remaining_quantity>0 and public.bum_lot_usable(id,u) order by');execute s;
end $$;
create function public.bum_raw_lot_waste(p_id uuid,p_lot uuid,p_quantity numeric,p_expected numeric,p_reason text) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();r public.business_entries;e public.business_entries;i public.ingredients;day date:=(now() at time zone 'America/Santo_Domingo')::date;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));perform public.bum_ops_number(to_jsonb(p_quantity),'la merma del lote',1e12,true);
 if length(trim(coalesce(p_reason,''))) not between 1 and 500 then raise exception 'Describe el motivo de la merma';end if;
 select * into e from public.business_entries where id=p_id;if found then if e.owner_id<>u or e.kind<>'inventory_event' or e.details->>'sourceId'<>p_lot::text or (e.details->>'quantity')::numeric<>p_quantity then raise exception 'Este intento pertenece a otra merma';end if;return to_jsonb(e);end if;
 select * into r from public.business_entries where id=p_lot and owner_id=u and kind='raw_lot';if not found then raise exception 'Lote no disponible';end if;
 select * into i from public.ingredients where id=(r.details->>'ingredientId')::uuid and owner_id=u for update;
 if i.stock_quantity is null or i.stock_quantity<p_quantity or (r.details->>'remaining')::numeric is distinct from p_expected or p_quantity>p_expected then raise exception 'Las existencias del lote cambiaron o son insuficientes';end if;
 perform public.bum_ops_put(r.id,'raw_lot',jsonb_set(r.details,'{remaining}',to_jsonb(p_expected-p_quantity)),r.version);
 update public.ingredients set stock_quantity=stock_quantity-p_quantity where id=i.id and owner_id=u;
 return public.bum_ops_put(p_id,'inventory_event',jsonb_build_object('ingredientId',i.id,'date',day,'quantity',p_quantity,'before',i.stock_quantity,'after',i.stock_quantity-p_quantity,'unit',i.base_unit,'reason',p_reason,'sourceId',p_lot,'cost',p_quantity*(r.details->>'price')::numeric/(r.details->>'quantity')::numeric),0);
end $$;
revoke all on function public.bum_raw_lot_waste(uuid,uuid,numeric,numeric,text) from public,anon;grant execute on function public.bum_raw_lot_waste(uuid,uuid,numeric,numeric,text) to authenticated;
create function public.bum_purchase_payment(p_id uuid,p_lot uuid,p_date date,p_amount numeric,p_notes text) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();r public.business_entries;e public.business_entries;paid numeric;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));perform public.bum_ops_number(to_jsonb(p_amount),'el pago',1e12,true);
 if p_date is null or p_date>(now() at time zone 'America/Santo_Domingo')::date then raise exception 'Revisa la fecha de pago';end if;
 select * into r from public.business_entries where id=p_lot and owner_id=u and kind='raw_lot' for update;if not found then raise exception 'Compra no disponible';end if;
 select * into e from public.business_entries where id=p_id;if found then if e.owner_id<>u or e.kind<>'cash' or e.details->>'sourceId'<>p_lot::text or (e.details->>'amount')::numeric<>p_amount or e.details->>'date'<>p_date::text then raise exception 'Este intento pertenece a otro pago';end if;return to_jsonb(r);end if;
 paid:=(r.details->>'paid')::numeric+p_amount;if paid>(r.details->>'price')::numeric then raise exception 'El pago supera el saldo de la compra';end if;
 perform public.bum_ops_put(p_id,'cash',jsonb_build_object('name','Pago de compra: '||coalesce(r.details->>'supplier','Proveedor'),'date',p_date,'amount',p_amount,'direction','out','category','purchase','sourceId',p_lot,'notes',coalesce(p_notes,'')),0);
 return public.bum_ops_put(r.id,'raw_lot',jsonb_set(r.details,'{paid}',to_jsonb(paid)),r.version);
end $$;
revoke all on function public.bum_purchase_payment(uuid,uuid,date,numeric,text) from public,anon;grant execute on function public.bum_purchase_payment(uuid,uuid,date,numeric,text) to authenticated;

create unique index sales_order_once on public.sales(owner_id,(details->>'orderId')) where nullif(details->>'orderId','') is not null;
create function public.bum_order_sale(p_id uuid,p_order uuid,p_date date,p_channel text,p_commission numeric,p_extra numeric) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();o public.business_entries;s public.sales;cost numeric;gross numeric;fee numeric;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));
 if p_date is null or p_date>(now() at time zone 'America/Santo_Domingo')::date or p_channel not in ('Directa','Uber Eats','PedidosYa') or p_commission>100 then raise exception 'Revisa fecha y canal de venta';end if;
 perform public.bum_ops_number(to_jsonb(p_commission),'la comisión',100.00001);perform public.bum_ops_number(to_jsonb(p_extra),'los gastos adicionales',1e9);
 select * into o from public.business_entries where id=p_order and owner_id=u and kind='order' for update;if not found or o.details->>'status'='cancelled' then raise exception 'Pedido no disponible o cancelado';end if;
 select * into s from public.sales where id=p_id;if found then if s.owner_id<>u or s.details->>'orderId'<>p_order::text or s.sold_at::date<>p_date or s.channel<>p_channel or (s.details->>'commission')::numeric<>p_commission or (s.details->>'extra')::numeric<>p_extra then raise exception 'Este intento pertenece a otra venta';end if;return to_jsonb(s);end if;
 if exists(select 1 from public.sales where owner_id=u and details->>'orderId'=p_order::text) then raise exception 'Este encargo ya tiene una venta registrada';end if;
 if exists(select 1 from public.business_entries where owner_id=u and kind='work_order' and details->>'orderId'=p_order::text and details->>'status' in ('planned','preparing')) then raise exception 'Termina o cancela las preparaciones pendientes antes de registrar la venta';end if;
 select sum((details->>'productionCost')::numeric) into cost from public.business_entries where owner_id=u and kind='work_order' and details->>'orderId'=p_order::text and details->>'status'='done';
 if cost is null then raise exception 'Registra la producción del encargo para conservar su costo real';end if;
 if p_extra<>round(p_extra,2) then raise exception 'Los gastos de venta admiten dos decimales';end if;
 gross:=round((o.details->>'total')::numeric,2);cost:=round(cost,2);fee:=round(gross*p_commission/100,2);
 insert into public.sales(id,owner_id,sold_at,channel,gross_amount,commission_amount,net_amount,cost_amount,details)
 values(p_id,u,(p_date::text||'T12:00:00Z')::timestamptz,p_channel,gross,fee,gross-fee,cost+p_extra,jsonb_build_object('orderId',p_order,'date',p_date,'channel',p_channel,'description',o.details->>'description','gross',gross,'commission',p_commission,'productionCost',cost,'extra',p_extra)) returning * into s;return to_jsonb(s);
end $$;
revoke all on function public.bum_order_sale(uuid,uuid,date,text,numeric,numeric) from public,anon;grant execute on function public.bum_order_sale(uuid,uuid,date,text,numeric,numeric) to authenticated;
commit;
