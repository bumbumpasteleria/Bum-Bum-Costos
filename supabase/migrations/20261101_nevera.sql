-- Apply only after review/authorization. New private stock; existing sales remain intact.
begin;
create table public.fridge_products (
 id uuid primary key, owner_id uuid not null default auth.uid() references auth.users(id),
 recipe_id uuid not null, name text not null check(length(name) between 1 and 160),
 unit text not null check(length(unit) between 1 and 30), minimum_quantity numeric not null default 0 check(minimum_quantity>=0 and minimum_quantity<1e9),
 created_at timestamptz not null default now(), unique(owner_id,recipe_id)
);
create table public.fridge_batches (
 id uuid primary key, owner_id uuid not null default auth.uid() references auth.users(id),
 product_id uuid not null references public.fridge_products(id),
 prepared_on date not null, expires_on date, initial_quantity numeric not null check(initial_quantity>0 and initial_quantity<1e9),
 remaining_quantity numeric not null check(remaining_quantity>=0 and remaining_quantity<=initial_quantity),
 unit_cost numeric not null check(unit_cost>=0), recipe_factor numeric not null check(recipe_factor>0 and recipe_factor<1e6),
 created_at timestamptz not null default now(), check(expires_on is null or expires_on>=prepared_on)
);
create table public.fridge_movements (
 id uuid primary key, owner_id uuid not null default auth.uid() references auth.users(id),
 product_id uuid not null references public.fridge_products(id), batch_id uuid references public.fridge_batches(id),
 kind text not null check(kind in ('production','adjustment','sale')),
 quantity numeric not null, reason text not null, sale_id uuid unique,
 created_at timestamptz not null default now()
);
create index fridge_batches_owner_product on public.fridge_batches(owner_id,product_id);
do $$ declare t text; begin
 foreach t in array array['fridge_products','fridge_batches','fridge_movements'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from anon,authenticated',t);
 -- Only reads from clients; mutations go through approved, owner-checked functions.
 execute format('grant select on public.%I to authenticated',t);
 execute format('create policy own_approved on public.%I for select to authenticated using (owner_id=(select auth.uid()) and (select public.bum_account_approved()))',t);
 end loop;
end $$;

-- Definers are necessary for atomic ledger mutations without direct client UPDATE grants.
-- Every entry checks approved membership and explicitly scopes every business query by uid.
create function public.bum_fridge_product(p_id uuid,p_recipe uuid,p_unit text,p_minimum numeric) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); r public.recipes; saved public.fridge_products;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada'; end if;
 if p_minimum is null or p_minimum<0 or p_minimum>=1e9 or p_minimum::text in ('NaN','Infinity','-Infinity') then raise exception 'Mínimo no válido'; end if;
 select * into r from public.recipes where id=p_recipe and owner_id=u;
 if not found then raise exception 'Selecciona una receta de tu cuenta'; end if;
 if p_unit is null or length(trim(p_unit)) not between 1 and 30 then raise exception 'Selecciona una unidad'; end if;
 select * into saved from public.fridge_products where id=p_id and owner_id=u for update;
 if found then
  if saved.recipe_id<>p_recipe or saved.unit<>p_unit then raise exception 'La receta y la unidad de un producto registrado se conservan'; end if;
  update public.fridge_products set minimum_quantity=p_minimum where id=p_id and owner_id=u returning * into saved;
 else
  insert into public.fridge_products(id,owner_id,recipe_id,name,unit,minimum_quantity) values(p_id,u,p_recipe,r.name,trim(p_unit),p_minimum) returning * into saved;
 end if;
 return to_jsonb(saved);
end $$;

create function public.bum_fridge_production(p_id uuid,p_product uuid,p_quantity numeric,p_factor numeric,p_prepared date,p_expires date) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); product public.fridge_products; batch public.fridge_batches; cost numeric; total_lines integer; valid_lines integer;
 today date:=(now() at time zone 'America/Santo_Domingo')::date;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada'; end if;
 select * into product from public.fridge_products where id=p_product and owner_id=u for update;
 if not found then raise exception 'Producto no disponible'; end if;
 select * into batch from public.fridge_batches where id=p_id and owner_id=u;
 if found then
  if batch.product_id<>p_product or batch.initial_quantity<>p_quantity or batch.recipe_factor<>p_factor or batch.prepared_on<>p_prepared or batch.expires_on is distinct from p_expires then raise exception 'El registro ya existe con otros datos'; end if;
  return to_jsonb(batch);
 end if;
 if p_quantity is null or p_factor is null or p_quantity<=0 or p_quantity>=1e9 or p_factor<=0 or p_factor>=1e6 or p_quantity::text in ('NaN','Infinity','-Infinity') or p_factor::text in ('NaN','Infinity','-Infinity') then raise exception 'Introduce cantidades mayores que cero'; end if;
 if p_prepared is null or p_prepared>today or (p_expires is not null and (p_expires<p_prepared or p_expires<today)) then raise exception 'Revisa las fechas de preparación y vencimiento'; end if;
 perform 1 from public.recipes where id=product.recipe_id and owner_id=u;
 if not found then raise exception 'La receta de origen ya no está disponible'; end if;
 select count(*),count(i.id) filter(where i.last_unit_cost is not null),sum(l.quantity_base*i.last_unit_cost)
 into total_lines,valid_lines,cost from public.recipe_lines l left join public.ingredients i on i.id=l.ingredient_id and i.owner_id=u
 where l.recipe_id=product.recipe_id and l.owner_id=u;
 if total_lines=0 or total_lines<>valid_lines or cost is null or cost<0 then raise exception 'Completa los ingredientes y precios de la receta'; end if;
 insert into public.fridge_batches(id,owner_id,product_id,prepared_on,expires_on,initial_quantity,remaining_quantity,unit_cost,recipe_factor)
 values(p_id,u,p_product,p_prepared,p_expires,p_quantity,p_quantity,cost*p_factor/p_quantity,p_factor) returning * into batch;
 insert into public.fridge_movements(id,owner_id,product_id,batch_id,kind,quantity,reason) values(p_id,u,p_product,p_id,'production',p_quantity,'Preparación registrada');
 return to_jsonb(batch);
end $$;

create function public.bum_fridge_adjust(p_id uuid,p_batch uuid,p_expected numeric,p_quantity numeric,p_reason text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); b public.fridge_batches; m public.fridge_movements;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada'; end if;
 -- Same lock order as production/sales to prevent lost updates/deadlocks.
 perform 1 from public.fridge_products where id=(select product_id from public.fridge_batches where id=p_batch and owner_id=u) and owner_id=u for update;
 select * into b from public.fridge_batches where id=p_batch and owner_id=u for update;
 if not found then raise exception 'Lote no disponible'; end if;
 select * into m from public.fridge_movements where id=p_id and owner_id=u;
 if found then
  if m.batch_id is distinct from p_batch or m.reason is distinct from trim(p_reason) or m.quantity is distinct from p_quantity-p_expected then raise exception 'El ajuste ya existe con otros datos'; end if;
  return to_jsonb(b);
 end if;
 if p_quantity is null or p_quantity<0 or p_quantity>b.initial_quantity or p_quantity::text in ('NaN','Infinity','-Infinity') or length(trim(coalesce(p_reason,''))) not between 1 and 500 then raise exception 'Revisa la cantidad y el motivo. Registra nuevas preparaciones para añadir otro lote'; end if;
 if b.remaining_quantity is distinct from p_expected then raise exception 'Las existencias cambiaron. Actualiza antes de ajustar'; end if;
 update public.fridge_batches set remaining_quantity=p_quantity where id=p_batch and owner_id=u returning * into b;
 insert into public.fridge_movements(id,owner_id,product_id,batch_id,kind,quantity,reason) values(p_id,u,b.product_id,p_batch,'adjustment',p_quantity-p_expected,trim(p_reason));
 return to_jsonb(b);
end $$;

create function public.bum_fridge_sale(p_sale jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); product public.fridge_products; b public.fridge_batches; saved public.sales;
 sid uuid:=(p_sale->>'id')::uuid; pid uuid:=(p_sale->>'fridgeProductId')::uuid;
 q numeric:=(p_sale->>'fridgeQuantity')::numeric; needed numeric; taken numeric; cost numeric:=0;
 gross numeric:=(p_sale->>'gross')::numeric; pct numeric:=(p_sale->>'commission')::numeric; extra numeric:=(p_sale->>'extra')::numeric;
 day date:=(p_sale->>'date')::date; today date:=(now() at time zone 'America/Santo_Domingo')::date;
 allocations jsonb:='[]'::jsonb;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada'; end if;
 select * into product from public.fridge_products where id=pid and owner_id=u for update;
 if not found then raise exception 'Producto no disponible'; end if;
 select * into saved from public.sales where id=sid and owner_id=u;
 if found then
  if saved.details->>'fridgeProductId' is distinct from pid::text or (saved.details->>'fridgeQuantity')::numeric is distinct from q or saved.gross_amount is distinct from gross or (saved.details->>'commission')::numeric is distinct from pct or (saved.details->>'extra')::numeric is distinct from extra or saved.sold_at::date is distinct from day or saved.channel is distinct from coalesce(nullif(p_sale->>'channel',''),'Directa') then raise exception 'La venta ya existe con otros datos. Actualiza Ventas antes de crear otro registro'; end if;
  return to_jsonb(saved);
 end if;
 if q is null or q<=0 or q>=1e9 or gross is null or gross<0 or pct is null or pct<0 or pct>100 or extra is null or extra<0 or day is null or day>today
 or q::text in ('NaN','Infinity','-Infinity') or gross::text in ('NaN','Infinity','-Infinity') or pct::text in ('NaN','Infinity','-Infinity') or extra::text in ('NaN','Infinity','-Infinity') then raise exception 'Revisa los importes, la fecha y la cantidad vendida'; end if;
 needed:=q;
 for b in select * from public.fridge_batches where product_id=pid and owner_id=u and prepared_on<=day and (expires_on is null or expires_on>=greatest(day,today)) and remaining_quantity>0 order by expires_on nulls last,prepared_on,id for update loop
  taken:=least(needed,b.remaining_quantity);
  update public.fridge_batches set remaining_quantity=remaining_quantity-taken where id=b.id and owner_id=u;
  cost:=cost+taken*b.unit_cost;
  allocations:=allocations||jsonb_build_array(jsonb_build_object('batchId',b.id,'quantity',taken));
  needed:=needed-taken;exit when needed=0;
 end loop;
 if needed>0 then raise exception 'No hay suficientes existencias vigentes en la nevera. Actualiza la lista'; end if;
 insert into public.sales(id,owner_id,sold_at,channel,details,gross_amount,commission_amount,net_amount,cost_amount)
 values(sid,u,day+time '12:00',coalesce(nullif(p_sale->>'channel',''),'Directa'),p_sale||jsonb_build_object('description',product.name,'productionCost',cost,'fridgeUnit',product.unit,'batches',allocations),gross,gross*pct/100,gross-gross*pct/100,cost+extra) returning * into saved;
 insert into public.fridge_movements(id,owner_id,product_id,kind,quantity,reason,sale_id) values(sid,u,pid,'sale',-q,'Venta registrada',sid);
 return to_jsonb(saved);
end $$;
revoke all on function public.bum_fridge_product(uuid,uuid,text,numeric),public.bum_fridge_production(uuid,uuid,numeric,numeric,date,date),public.bum_fridge_adjust(uuid,uuid,numeric,numeric,text),public.bum_fridge_sale(jsonb) from public,anon;
grant execute on function public.bum_fridge_product(uuid,uuid,text,numeric),public.bum_fridge_production(uuid,uuid,numeric,numeric,date,date),public.bum_fridge_adjust(uuid,uuid,numeric,numeric,text),public.bum_fridge_sale(jsonb) to authenticated;
commit;
