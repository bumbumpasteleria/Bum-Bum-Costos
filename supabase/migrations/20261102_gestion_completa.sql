begin;
create table public.business_entries(
 id uuid primary key,owner_id uuid not null default auth.uid() references auth.users(id),
 kind text not null check(kind in ('expense','order','recipe_info')),details jsonb not null,
 version integer not null default 1 check(version>0),created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table public.business_entry_history(
 id uuid primary key default gen_random_uuid(),owner_id uuid not null references auth.users(id),entry_id uuid not null,
 kind text not null,details jsonb not null,version integer not null,created_at timestamptz not null default now()
);
create table public.recipe_versions(
 id uuid primary key default gen_random_uuid(),owner_id uuid not null references auth.users(id),recipe_id uuid not null,
 snapshot jsonb not null,transaction_id bigint not null default txid_current(),created_at timestamptz not null default now(),unique(recipe_id,transaction_id)
);
create table public.backup_restores(id uuid primary key,owner_id uuid not null references auth.users(id),fingerprint text not null,summary jsonb not null,created_at timestamptz not null default now());
do $$ declare t text;begin foreach t in array array['business_entries','business_entry_history','recipe_versions','backup_restores'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from anon,authenticated',t);
 execute format('grant select on public.%I to authenticated',t);
 execute format('create policy private_approved on public.%I for select to authenticated using(owner_id=(select auth.uid()) and (select public.bum_account_approved()))',t);
end loop;end $$;
create index business_entries_owner_kind on public.business_entries(owner_id,kind,created_at);
create index recipe_versions_owner_recipe on public.recipe_versions(owner_id,recipe_id,created_at);

create function public.bum_validate_entry(p_id uuid,p_kind text,p_details jsonb,p_owner uuid,p_require_recipe boolean) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare u uuid:=p_owner;d jsonb;amount numeric;deposit numeric;day date;
begin
 if coalesce(p_kind,'') not in ('expense','order','recipe_info') or jsonb_typeof(p_details) is distinct from 'object' or length(p_details::text)>300000 then raise exception 'Registro de respaldo no válido';end if;
 if p_kind='expense' then
  amount:=(p_details->>'amount')::numeric;day:=(p_details->>'date')::date;
  if amount is null or amount<=0 or amount>=1e9 or amount::text in ('NaN','Infinity','-Infinity') or day is null or length(trim(coalesce(p_details->>'description',''))) not between 1 and 300 or coalesce(p_details->>'category','') not in ('Servicios','Alquiler','Transporte','Personal','Mantenimiento','Otros') or coalesce(p_details->>'channel','') not in ('General','Directa','Uber Eats','PedidosYa') then raise exception 'Revisa el gasto y su importe';end if;
  d:=jsonb_build_object('date',day,'amount',amount,'description',trim(p_details->>'description'),'category',p_details->>'category','channel',p_details->>'channel','voided',coalesce((p_details->>'voided')::boolean,false));
 elsif p_kind='order' then
  amount:=(p_details->>'total')::numeric;deposit:=(p_details->>'deposit')::numeric;day:=(p_details->>'deliveryDate')::date;
  if day is null or amount is null or deposit is null or amount<0 or deposit<0 or deposit>amount or amount>=1e9 or amount::text in ('NaN','Infinity','-Infinity') or deposit::text in ('NaN','Infinity','-Infinity') or length(trim(coalesce(p_details->>'customer',''))) not between 1 and 160 or length(trim(coalesce(p_details->>'description',''))) not between 1 and 1000 or length(coalesce(p_details->>'contact',''))>200 or length(coalesce(p_details->>'notes',''))>5000 or coalesce(p_details->>'status','') not in ('pending','preparing','ready','delivered','cancelled') then raise exception 'Revisa el cliente, fecha, estado y montos del pedido';end if;
  if nullif(p_details->>'recipeId','') is not null and ((p_require_recipe and not exists(select 1 from public.recipes r join public.recipe_books b on b.id=r.recipe_book_id and b.owner_id=u where r.id=(p_details->>'recipeId')::uuid and r.owner_id=u and b.usage='orders')) or exists(select 1 from public.recipes where id=(p_details->>'recipeId')::uuid and owner_id<>u)) then raise exception 'Elige una receta de Encargos de tu cuenta';end if;
  d:=jsonb_build_object('customer',trim(p_details->>'customer'),'contact',p_details->>'contact','description',trim(p_details->>'description'),'deliveryDate',day,'total',amount,'deposit',deposit,'status',p_details->>'status','recipeId',nullif(p_details->>'recipeId',''),'notes',p_details->>'notes');
 else
  if (p_require_recipe and not exists(select 1 from public.recipes where id=p_id and owner_id=u)) or exists(select 1 from public.recipes where id=p_id and owner_id<>u) then raise exception 'Receta no disponible';end if;
  if length(coalesce(p_details->>'notes',''))>20000 or length(coalesce(p_details->>'allergens',''))>1000 or length(coalesce(p_details->>'storage',''))>1000 or length(coalesce(p_details->>'photo',''))>250000 or (nullif(p_details->>'photo','') is not null and (p_details->>'photo')!~'^data:image/jpeg;base64,[A-Za-z0-9+/=]+$') then raise exception 'Revisa las notas o la fotografía';end if;
  d:=jsonb_build_object('notes',coalesce(p_details->>'notes',''),'allergens',coalesce(p_details->>'allergens',''),'storage',coalesce(p_details->>'storage',''),'photo',coalesce(p_details->>'photo',''));
 end if;
 return d;
end $$;
revoke all on function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean) from public,anon,authenticated;

create function public.bum_save_entry(p_id uuid,p_kind text,p_details jsonb,p_expected integer) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();old public.business_entries;saved public.business_entries;d jsonb;amount numeric;deposit numeric;day date;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 if p_id is null or coalesce(p_kind,'') not in ('expense','order','recipe_info') or jsonb_typeof(p_details) is distinct from 'object' or length(p_details::text)>300000 or p_expected is null or p_expected<0 then raise exception 'Registro no válido';end if;
 d:=public.bum_validate_entry(p_id,p_kind,p_details,u,true);
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,19));
 select * into old from public.business_entries where id=p_id and owner_id=u for update;
 if found then
  if old.kind<>p_kind then raise exception 'El registro tiene otro tipo';end if;
  if old.details=d then return to_jsonb(old);end if;
  if old.version<>p_expected then raise exception 'Este registro cambió. Actualiza y revisa antes de guardar';end if;
  if p_kind='expense' and coalesce((old.details->>'voided')::boolean,false) then raise exception 'El gasto ya fue anulado';end if;
  insert into public.business_entry_history(owner_id,entry_id,kind,details,version) values(u,old.id,old.kind,old.details,old.version);
  update public.business_entries set details=d,version=version+1,updated_at=now() where id=p_id and owner_id=u returning * into saved;
 else
  if p_expected<>0 then raise exception 'El registro ya no está disponible';end if;
  insert into public.business_entries(id,owner_id,kind,details) values(p_id,u,p_kind,d) returning * into saved;
 end if;
 return to_jsonb(saved);
end $$;

create function public.bum_capture_recipe_version() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op='UPDATE' and old is not distinct from new then return new;end if;
 if tg_op='UPDATE' and exists(select 1 from public.recipes where id=old.id and owner_id=old.owner_id and xmin::text=(txid_current()%4294967296)::text) then return new;end if;
 insert into public.recipe_versions(owner_id,recipe_id,snapshot)
 values(old.owner_id,old.id,to_jsonb(old)||jsonb_build_object('lines',coalesce((select jsonb_agg(to_jsonb(l) order by l.id) from public.recipe_lines l where l.recipe_id=old.id and l.owner_id=old.owner_id),'[]'::jsonb))) on conflict(recipe_id,transaction_id) do nothing;
 if tg_op='DELETE' then return old;else return new;end if;
end $$;
create trigger bum_recipe_versions before update or delete on public.recipes for each row execute function public.bum_capture_recipe_version();
revoke all on function public.bum_capture_recipe_version() from public,anon,authenticated;

create function public.bum_restore_recipe_version(p_version uuid,p_original jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();v public.recipe_versions;current_recipe public.recipes;m jsonb;lines jsonb;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 select * into v from public.recipe_versions where id=p_version and owner_id=u;
 if not found then raise exception 'Versión no disponible';end if;
 if exists(select 1 from public.recipes where id=v.recipe_id and owner_id<>u) then raise exception 'No se puede recuperar este identificador';end if;
 begin m:=(v.snapshot->>'instructions')::jsonb;exception when others then m:='{}'::jsonb;end;
 select * into current_recipe from public.recipes where id=v.recipe_id and owner_id=u for update;
 if found then
  select jsonb_agg(jsonb_build_object('ingredient_id',l->>'ingredient_id','quantity_base',l->>'quantity_base')||case when exists(select 1 from public.recipe_lines where id=(l->>'id')::uuid and recipe_id=v.recipe_id and owner_id=u) then jsonb_build_object('id',l->>'id') else '{}'::jsonb end) into lines from jsonb_array_elements(v.snapshot->'lines') l;
  return public.actualizar_receta_organizada_bum_bum(v.recipe_id,v.snapshot->>'name',(v.snapshot->>'yield_quantity')::numeric,v.snapshot->>'yield_unit',coalesce(m->>'scaling','scalable'),lines,coalesce(m->>'productType','Otro artículo'),(v.snapshot->>'recipe_book_id')::uuid,p_original,coalesce(m->>'preparation',m->>'legacyInstructions',''),coalesce(m->>'category',''));
 end if;
 if p_original is not null then raise exception 'La receta ya no está. Actualiza el historial';end if;
 select jsonb_agg(jsonb_build_object('ingredient_id',l->>'ingredient_id','quantity_base',l->>'quantity_base')) into lines from jsonb_array_elements(v.snapshot->'lines') l;
 return public.guardar_receta_organizada_bum_bum(v.recipe_id,v.snapshot->>'name',(v.snapshot->>'yield_quantity')::numeric,v.snapshot->>'yield_unit',coalesce(m->>'scaling','scalable'),lines,coalesce(m->>'productType','Otro artículo'),(v.snapshot->>'recipe_book_id')::uuid,coalesce(m->>'preparation',m->>'legacyInstructions',''),coalesce(m->>'category',''));
end $$;

create function public.bum_export_backup() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();t text;items jsonb;d jsonb:='{}'::jsonb;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 foreach t in array array['ingredients','recipe_books','recipes','recipe_lines','decorations','quotes','fridge_products','fridge_batches','sales','fridge_movements','business_entries','business_entry_history','recipe_versions'] loop
  execute format('select coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) from public.%I r where owner_id=$1',t) into items using u;d:=d||jsonb_build_object(t,items);
 end loop;
 return jsonb_build_object('format','bum-bum-costos','version',2,'owner',u,'createdAt',now(),'data',d);
end $$;

create function public.bum_restore_backup(p_id uuid,p_backup jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();t text;item jsonb;rid uuid;existing_owner uuid;cols text;inserted integer;total integer:=0;skipped integer:=0;summary jsonb;prior public.backup_restores;new_recipes uuid[]:='{}';fingerprint text:=md5(p_backup::text);
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 if p_id is null or p_backup->>'format' is distinct from 'bum-bum-costos' or p_backup->>'version' is distinct from '2' or p_backup->>'owner' is distinct from u::text or jsonb_typeof(p_backup->'data') is distinct from 'object' or octet_length(p_backup::text)>26214400 then raise exception 'El respaldo no es válido para esta cuenta o supera 25 MB';end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text,889));
 select * into prior from public.backup_restores where id=p_id and owner_id=u;
 if found then if prior.fingerprint<>fingerprint then raise exception 'Este intento pertenece a otro archivo';end if;return prior.summary;end if;
 foreach t in array array['ingredients','recipe_books','recipes','recipe_lines','decorations','quotes','fridge_products','fridge_batches','sales','fridge_movements','business_entries','business_entry_history','recipe_versions'] loop
  if jsonb_typeof(p_backup->'data'->t) is distinct from 'array' or jsonb_array_length(p_backup->'data'->t)>20000 then raise exception 'Colección incompleta o demasiado grande: %',t;end if;
  for item in select * from jsonb_array_elements(p_backup->'data'->t) loop
   rid:=(item->>'id')::uuid;
   if rid is null or item->>'owner_id' is distinct from u::text then raise exception 'Registro de otra cuenta o sin identificador';end if;
   execute format('select owner_id from public.%I where id=$1',t) into existing_owner using rid;
   if existing_owner is not null then if existing_owner<>u then raise exception 'Identificador no disponible';end if;skipped:=skipped+1;continue;end if;
   if t='recipe_lines' then
    if not ((item->>'recipe_id')::uuid=any(new_recipes)) then skipped:=skipped+1;continue;end if;
    if not exists(select 1 from public.ingredients where id=(item->>'ingredient_id')::uuid and owner_id=u and item_kind='ingredient') then raise exception 'Ingrediente de receta no disponible';end if;
   elsif t='recipes' then
    if nullif(item->>'recipe_book_id','') is not null and not exists(select 1 from public.recipe_books where id=(item->>'recipe_book_id')::uuid and owner_id=u) then raise exception 'Recetario no disponible';end if;
   elsif t='fridge_products' then
    if not exists(select 1 from public.recipes where id=(item->>'recipe_id')::uuid and owner_id=u) then raise exception 'Receta de nevera no disponible';end if;
   elsif t='fridge_batches' or t='fridge_movements' then
    if not exists(select 1 from public.fridge_products where id=(item->>'product_id')::uuid and owner_id=u) then raise exception 'Producto de nevera no disponible';end if;
    if t='fridge_movements' and nullif(item->>'batch_id','') is not null and not exists(select 1 from public.fridge_batches where id=(item->>'batch_id')::uuid and owner_id=u) then raise exception 'Lote no disponible';end if;
    if t='fridge_movements' and nullif(item->>'sale_id','') is not null and not exists(select 1 from public.sales where id=(item->>'sale_id')::uuid and owner_id=u) then raise exception 'Venta no disponible';end if;
   elsif t='business_entries' then
    item:=jsonb_set(item,'{details}',public.bum_validate_entry(rid,item->>'kind',item->'details',u,false));
    if item->>'kind'='recipe_info' and exists(select 1 from public.recipes where id=rid and owner_id<>u) then raise exception 'Receta de otra cuenta';end if;
    if item->>'kind'='order' and nullif(item->'details'->>'recipeId','') is not null and exists(select 1 from public.recipes where id=(item->'details'->>'recipeId')::uuid and owner_id<>u) then raise exception 'Receta del encargo no disponible';end if;
   elsif t='business_entry_history' then
    if not exists(select 1 from public.business_entries where id=(item->>'entry_id')::uuid and owner_id=u) then raise exception 'Historial sin registro de esta cuenta';end if;
   elsif t='recipe_versions' then
    if exists(select 1 from public.recipes where id=(item->>'recipe_id')::uuid and owner_id<>u) then raise exception 'Versión de otra cuenta';end if;
   end if;
   select string_agg(format('%I',a.attname),',' order by a.attnum) into cols from pg_attribute a where a.attrelid=format('public.%I',t)::regclass and a.attnum>0 and not a.attisdropped and item ? a.attname;
   execute format('insert into public.%1$I (%2$s) select %2$s from jsonb_populate_record(null::public.%1$I,$1) on conflict(id) do nothing',t,cols) using item;
   get diagnostics inserted=row_count;total:=total+inserted;
   if t='recipes' and inserted=1 then new_recipes:=array_append(new_recipes,rid);end if;
  end loop;
 end loop;
 summary:=jsonb_build_object('inserted',total,'skipped',skipped);
 insert into public.backup_restores(id,owner_id,fingerprint,summary) values(p_id,u,fingerprint,summary);
 return summary;
end $$;
revoke all on function public.bum_save_entry(uuid,text,jsonb,integer),public.bum_restore_recipe_version(uuid,jsonb),public.bum_export_backup(),public.bum_restore_backup(uuid,jsonb) from public,anon;
grant execute on function public.bum_save_entry(uuid,text,jsonb,integer),public.bum_restore_recipe_version(uuid,jsonb),public.bum_export_backup(),public.bum_restore_backup(uuid,jsonb) to authenticated;
commit;
