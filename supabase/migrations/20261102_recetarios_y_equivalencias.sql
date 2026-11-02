begin;
alter table public.ingredients add column grams_per_base_unit numeric check(grams_per_base_unit>0 and grams_per_base_unit<1000000 and grams_per_base_unit::text not in ('NaN','Infinity','-Infinity'));
alter table public.recipe_lines add column measurement_quantity numeric,add column measurement_unit text;
alter table public.recipe_lines add constraint recipe_measurement_pair check((measurement_quantity is null and measurement_unit is null) or (measurement_quantity>0 and measurement_quantity<1e12 and measurement_quantity::text not in ('NaN','Infinity','-Infinity') and measurement_unit in ('g','kg','mg','lb','oz','ml','L','gal US','fl oz','unidad','unit','docena')));
alter table public.fridge_batches add column production_details jsonb not null default '[]' check(jsonb_typeof(production_details)='array');

create function public.bum_recipe_base(p_ingredient uuid,p_quantity numeric,p_unit text,p_owner uuid) returns numeric
language plpgsql security invoker set search_path='' as $$
declare item public.ingredients;family text;factor numeric;result numeric;begin
 if p_owner is distinct from auth.uid() or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 select * into item from public.ingredients where id=p_ingredient and owner_id=p_owner;
 if not found then raise exception 'Ingrediente no disponible';end if;
 if p_quantity is null or p_quantity<=0 or p_quantity>=1e12 or p_quantity::text in ('NaN','Infinity','-Infinity') then raise exception 'Cantidad no válida';end if;
 select x.f,x.k into family,factor from (values ('g','g',1::numeric),('kg','g',1000),('mg','g',0.001),('lb','g',453.59237),('oz','g',28.349523125),('ml','ml',1),('L','ml',1000),('gal US','ml',3785.411784),('fl oz','ml',29.5735295625),('unidad','unit',1),('unit','unit',1),('docena','unit',12)) x(u,f,k) where x.u=p_unit;
 if factor is null then raise exception 'Unidad no válida';end if;
 result:=p_quantity*factor;
 if family<>item.base_unit then
  if family<>'g' or item.base_unit not in ('unit','ml') or item.grams_per_base_unit is null then raise exception 'Registra la equivalencia en gramos de %',item.name;end if;
  result:=result/item.grams_per_base_unit;
 end if;
 if result<0.001 then raise exception 'La cantidad equivalente de % debe ser al menos 0.001 en inventario',item.name;end if;
 return result;
end $$;
revoke all on function public.bum_recipe_base(uuid,numeric,text,uuid) from public,anon;
grant execute on function public.bum_recipe_base(uuid,numeric,text,uuid) to authenticated;

create function public.bum_validate_recipe_measurement() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if new.measurement_quantity is not null or new.measurement_unit is not null then
  new.quantity_base:=public.bum_recipe_base(new.ingredient_id,new.measurement_quantity,new.measurement_unit,new.owner_id);
 end if;
 return new;
end $$;
revoke all on function public.bum_validate_recipe_measurement() from public,anon,authenticated;
create trigger bum_recipe_measurement before insert or update on public.recipe_lines for each row execute function public.bum_validate_recipe_measurement();

-- Preserve existing validation, IDs and optimistic concurrency while adding display units.
do $$ declare oid_ oid;source text;before_ text;changed integer:=0;begin
 for oid_ in select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('guardar_receta_bum_bum','actualizar_receta_recetario_bum_bum') loop
  source:=pg_get_functiondef(oid_);before_:=source;
  source:=replace(source,'recipe_lines(owner_id,recipe_id,ingredient_id,quantity_base)','recipe_lines(owner_id,recipe_id,ingredient_id,quantity_base,measurement_quantity,measurement_unit)');
  source:=replace(source,'(linea->>''quantity_base'')::numeric);','(linea->>''quantity_base'')::numeric,(linea->>''measurement_quantity'')::numeric,linea->>''measurement_unit'');');
  source:=replace(source,'quantity_base=(linea->>''quantity_base'')::numeric','quantity_base=(linea->>''quantity_base'')::numeric,measurement_quantity=(linea->>''measurement_quantity'')::numeric,measurement_unit=linea->>''measurement_unit''');
  source:=replace(source,'(e.v->>''quantity_base'')::numeric=l.quantity_base','(e.v->>''quantity_base'')::numeric=l.quantity_base and (e.v->>''measurement_quantity'')::numeric is not distinct from l.measurement_quantity and (e.v->>''measurement_unit'') is not distinct from l.measurement_unit');
  if source=before_ then raise exception 'No se pudo adaptar la función de recetas';end if;execute source;changed:=changed+1;
 end loop;if changed<>2 then raise exception 'Faltan las funciones de recetas';end if;
end $$;

create function public.bum_delete_recipe_book(p_id uuid,p_original jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();book public.recipe_books;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 select * into book from public.recipe_books where id=p_id and owner_id=u for update;
 if not found then raise exception 'Recetario no disponible';end if;
 if p_original is null or book.name is distinct from p_original->>'name' or book.usage is distinct from p_original->>'usage' then raise exception 'El recetario cambió. Actualiza la lista antes de eliminar.';end if;
 if exists(select 1 from public.recipes where recipe_book_id=p_id) then raise exception 'Este recetario tiene recetas. Reasígnalas a otro recetario antes de eliminarlo.';end if;
 delete from public.recipe_books where id=p_id and owner_id=u;return p_id;
end $$;
revoke all on function public.bum_delete_recipe_book(uuid,jsonb) from public,anon;
grant execute on function public.bum_delete_recipe_book(uuid,jsonb) to authenticated;

create or replace function public.bum_fridge_production(p_id uuid,p_product uuid,p_quantity numeric,p_factor numeric,p_prepared date,p_expires date) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();product public.fridge_products;batch public.fridge_batches;cost numeric:=0;used record;details_ jsonb:='[]';
 today date:=(now() at time zone 'America/Santo_Domingo')::date;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 select * into product from public.fridge_products where id=p_product and owner_id=u for update;
 if not found then raise exception 'Producto no disponible';end if;
 select * into batch from public.fridge_batches where id=p_id and owner_id=u;
 if found then
  if batch.product_id<>p_product or batch.initial_quantity<>p_quantity or batch.recipe_factor<>p_factor or batch.prepared_on<>p_prepared or batch.expires_on is distinct from p_expires then raise exception 'El registro ya existe con otros datos';end if;return to_jsonb(batch);
 end if;
 if p_id is null or p_quantity is null or p_factor is null or p_quantity<=0 or p_quantity>=1e9 or p_factor<=0 or p_factor>=1e6 or p_quantity::text in ('NaN','Infinity','-Infinity') or p_factor::text in ('NaN','Infinity','-Infinity') then raise exception 'Introduce cantidades mayores que cero';end if;
 if p_prepared is null or p_prepared>today or (p_expires is not null and (p_expires<p_prepared or p_expires<today)) then raise exception 'Revisa las fechas de preparación y vencimiento';end if;
 -- Recipe edits and production use the same recipe-before-lines lock order.
 perform 1 from public.recipes where id=product.recipe_id and owner_id=u for update;
 if not found then raise exception 'La receta de origen ya no está disponible';end if;
 perform 1 from public.recipe_lines where recipe_id=product.recipe_id and owner_id=u for update;
 if not exists(select 1 from public.recipe_lines where recipe_id=product.recipe_id and owner_id=u) then raise exception 'La receta no tiene ingredientes';end if;
 perform 1 from public.ingredients i where i.owner_id=u and i.id in(select ingredient_id from public.recipe_lines where recipe_id=product.recipe_id and owner_id=u) order by i.id for update;
 if exists(select 1 from public.recipe_lines l where l.recipe_id=product.recipe_id and l.owner_id=u and not exists(select 1 from public.ingredients i where i.id=l.ingredient_id and i.owner_id=u)) then raise exception 'Hay ingredientes no disponibles';end if;
 for used in select i.id,i.name,i.base_unit,i.stock_quantity,i.last_unit_cost,
 sum(case when l.measurement_quantity is null then l.quantity_base else public.bum_recipe_base(i.id,l.measurement_quantity,l.measurement_unit,u) end)*p_factor as quantity
 from public.recipe_lines l join public.ingredients i on i.id=l.ingredient_id and i.owner_id=u where l.recipe_id=product.recipe_id and l.owner_id=u group by i.id order by i.id loop
  if used.last_unit_cost is null or used.last_unit_cost<0 then raise exception 'Completa el precio de %',used.name;end if;
  if used.stock_quantity is null then raise exception 'Registra las existencias de % en Inventario',used.name;end if;
  if used.stock_quantity<used.quantity then raise exception 'Existencias insuficientes de %: necesitas % %, tienes %',used.name,used.quantity,used.base_unit,used.stock_quantity;end if;
  cost:=cost+used.quantity*used.last_unit_cost;
  update public.ingredients set stock_quantity=stock_quantity-used.quantity where id=used.id and owner_id=u;
  details_:=details_||jsonb_build_array(jsonb_build_object('ingredientId',used.id,'name',used.name,'quantity',used.quantity,'unit',used.base_unit,'unitCost',used.last_unit_cost));
 end loop;
 insert into public.fridge_batches(id,owner_id,product_id,prepared_on,expires_on,initial_quantity,remaining_quantity,unit_cost,recipe_factor,production_details)
 values(p_id,u,p_product,p_prepared,p_expires,p_quantity,p_quantity,cost/p_quantity,p_factor,details_) returning * into batch;
 insert into public.fridge_movements(id,owner_id,product_id,batch_id,kind,quantity,reason) values(p_id,u,p_product,p_id,'production',p_quantity,'Preparación registrada');return to_jsonb(batch);
end $$;

-- A separate private final-cost sheet for each recipe; IDs do not collide with recipe_info.
alter table public.business_entries drop constraint business_entries_kind_check;
alter table public.business_entries add constraint business_entries_kind_check check(kind in ('expense','order','recipe_info','quote_brand','product_cost'));
create unique index business_product_cost_recipe on public.business_entries(owner_id,(details->>'recipeId')) where kind='product_cost';
alter function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean) rename to bum_validate_entry_brands_v1;
create function public.bum_validate_entry(p_id uuid,p_kind text,p_details jsonb,p_owner uuid,p_require_recipe boolean) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare rid uuid;d jsonb;extras jsonb:='{}';key text;value numeric;begin
 if p_kind is distinct from 'product_cost' then return public.bum_validate_entry_brands_v1(p_id,p_kind,p_details,p_owner,p_require_recipe);end if;
 if p_owner is distinct from auth.uid() or jsonb_typeof(p_details) is distinct from 'object' or length(p_details::text)>20000 then raise exception 'Ficha de costos no válida';end if;
 rid:=(p_details->>'recipeId')::uuid;
 if rid is null or exists(select 1 from public.recipes where id=rid and owner_id<>p_owner) or (coalesce(p_require_recipe,true) and not exists(select 1 from public.recipes where id=rid and owner_id=p_owner)) then raise exception 'Selecciona una receta de tu cuenta';end if;
 if length(trim(coalesce(p_details->>'recipeName',''))) not between 1 and 160 or length(coalesce(p_details->>'yieldUnit','')) not between 1 and 40 or p_details->>'laborMode' not in ('fixed','hourly') or p_details->>'laborMode' is null then raise exception 'Completa el nombre, rendimiento y mano de obra del producto';end if;
 d:=jsonb_build_object('recipeId',rid,'recipeName',p_details->>'recipeName','yieldUnit',p_details->>'yieldUnit','laborMode',p_details->>'laborMode');
 foreach key in array array['quantity','labor','hours','totalCost','produced','unitCost'] loop
  value:=(p_details->>key)::numeric;
  if value is null or value<0 or value>=1e12 or value::text in ('NaN','Infinity','-Infinity') or (key in ('quantity','produced') and value<=0) then raise exception 'Revisa los importes de la ficha de costos';end if;
  d:=d||jsonb_build_object(key,value);
 end loop;
 if jsonb_typeof(p_details->'extra') is distinct from 'object' then raise exception 'Completa los gastos adicionales';end if;
 foreach key in array array['fill','pack','delivery','other'] loop
  value:=coalesce((p_details->'extra'->>key)::numeric,0);
  if value<0 or value>=1e10 or value::text in ('NaN','Infinity','-Infinity') then raise exception 'Revisa los gastos adicionales';end if;
  extras:=extras||jsonb_build_object(key,value);
 end loop;
 return d||jsonb_build_object('extra',extras);
end $$;
revoke all on function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean),public.bum_validate_entry_brands_v1(uuid,text,jsonb,uuid,boolean) from public,anon,authenticated;
do $$ declare source text;prior text;begin
 source:=pg_get_functiondef('public.bum_save_entry(uuid,text,jsonb,integer)'::regprocedure);prior:=source;
 source:=replace(source,'''expense'',''order'',''recipe_info'',''quote_brand''','''expense'',''order'',''recipe_info'',''quote_brand'',''product_cost''');
 if source=prior then raise exception 'No se pudo habilitar la ficha privada de costos';end if;execute source;
end $$;

commit;
