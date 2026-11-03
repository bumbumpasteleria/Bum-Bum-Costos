begin;
-- Unknown initial stock is distinct from a confirmed zero balance.
alter table public.ingredients alter column stock_quantity drop not null;
alter function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean) rename to bum_validate_entry_before_orders;
create function public.bum_validate_entry(p_id uuid,p_kind text,p_details jsonb,p_owner uuid,p_require_recipe boolean) returns jsonb language plpgsql security invoker set search_path='' as $$
declare d jsonb;parts jsonb;photos jsonb;part jsonb;image_ jsonb;rid uuid;line_id uuid;seen uuid[]:='{}';r public.recipes;book text;normalized jsonb:='[]';begin
 if p_kind='order' then
  if jsonb_typeof(p_details) is distinct from 'object' or length(p_details::text)>2000000 then raise exception 'El encargo supera el tamaño permitido';end if;
  d:=public.bum_validate_entry_before_orders(p_id,p_kind,p_details-'photos'-'recipes',p_owner,p_require_recipe);
  if p_details?'recipes' then
   parts:=p_details->'recipes';if jsonb_typeof(parts) is distinct from 'array' or jsonb_array_length(parts)>20 then raise exception 'Usa hasta 20 preparaciones por encargo';end if;
   for part in select * from jsonb_array_elements(parts) loop
    line_id:=(part->>'id')::uuid;rid:=(part->>'recipeId')::uuid;
    if line_id is null or rid is null or line_id=any(seen) or line_id=p_id then raise exception 'Revisa las preparaciones del encargo';end if;seen:=array_append(seen,line_id);
    select * into r from public.recipes where id=rid and owner_id=p_owner;
    if not found then
     if exists(select 1 from public.recipes where id=rid and owner_id<>p_owner) or p_require_recipe then raise exception 'Elige recetas de Encargos de tu cuenta';end if;
    else
     select usage into book from public.recipe_books where id=r.recipe_book_id and owner_id=p_owner;if book is distinct from 'orders' then raise exception 'Elige recetas de un recetario de Encargos';end if;
    end if;
    if coalesce((part->>'leadDays')::numeric,0)<>trunc(coalesce((part->>'leadDays')::numeric,0)) or coalesce((part->>'leadDays')::numeric,0) not between 0 and 365 then raise exception 'Indica entre 0 y 365 días de anticipación';end if;
    perform public.bum_ops_number(part->'factor','la proporción',1e6,true);perform public.bum_ops_number(part->'quantity','la cantidad prevista',1e9,true);
    normalized:=normalized||jsonb_build_array(jsonb_build_object('id',line_id,'recipeId',rid,'factor',(part->>'factor')::numeric,'quantity',(part->>'quantity')::numeric,'leadDays',coalesce((part->>'leadDays')::integer,0)));
   end loop;
   d:=d||jsonb_build_object('recipes',normalized,'recipeId',case when jsonb_array_length(normalized)>0 then normalized->0->>'recipeId' else null end);
  end if;
  photos:=coalesce(p_details->'photos','[]'::jsonb);if jsonb_typeof(photos) is distinct from 'array' or jsonb_array_length(photos)>6 then raise exception 'Usa hasta 6 fotografías';end if;
  for image_ in select * from jsonb_array_elements(photos) loop
   if jsonb_typeof(image_) is distinct from 'string' or length(image_#>>'{}')>250000 or (image_#>>'{}')!~'^data:image/jpeg;base64,[A-Za-z0-9+/=]+$' then raise exception 'Fotografía de referencia no válida';end if;
  end loop;
  return d||jsonb_build_object('photos',photos);
 elsif p_kind='work_order' then
  d:=public.bum_validate_entry_before_orders(p_id,p_kind,p_details-'managedOrderId'-'orderLineId',p_owner,p_require_recipe);
  if p_details?'managedOrderId' then
   if (p_details->>'managedOrderId') is distinct from (p_details->>'orderId') or (p_details->>'orderLineId') is distinct from p_id::text then raise exception 'Referencia de preparación no válida';end if;
   d:=d||jsonb_build_object('managedOrderId',p_details->>'managedOrderId','orderLineId',p_id);
  end if;return d;
 end if;return public.bum_validate_entry_before_orders(p_id,p_kind,p_details,p_owner,p_require_recipe);
end $$;
revoke all on function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean),public.bum_validate_entry_before_orders(uuid,text,jsonb,uuid,boolean) from public,anon,authenticated;

alter function public.bum_save_entry(uuid,text,jsonb,integer) rename to bum_save_entry_before_orders;
create function public.bum_save_entry(p_id uuid,p_kind text,p_details jsonb,p_expected integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();d jsonb:=p_details;o public.business_entries;saved public.business_entries;w public.business_entries;part jsonb;recipe public.recipes;target jsonb;line_id uuid;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));
 if p_kind='work_order' then
  select * into w from public.business_entries where id=p_id and owner_id=u and kind='work_order';
  if w.details?'managedOrderId' then
   if (d->>'recipeId') is distinct from (w.details->>'recipeId') or (d->>'factor')::numeric is distinct from (w.details->>'factor')::numeric or (d->>'quantity')::numeric is distinct from (w.details->>'quantity')::numeric or (d->>'orderId') is distinct from (w.details->>'orderId') then raise exception 'Edita las recetas y cantidades desde el encargo';end if;
   d:=d||jsonb_build_object('managedOrderId',w.details->>'managedOrderId','orderLineId',p_id);
  elsif d?'managedOrderId' or d?'orderLineId' then raise exception 'Las preparaciones del encargo se crean al guardar el pedido';end if;
  return public.bum_save_entry_before_orders(p_id,p_kind,d,p_expected);
 elsif p_kind is distinct from 'order' then return public.bum_save_entry_before_orders(p_id,p_kind,d,p_expected);end if;
 select * into o from public.business_entries where id=p_id and owner_id=u and kind='order' for update;
 if found then
  if not d?'recipes' and o.details?'recipes' then d:=d||jsonb_build_object('recipes',o.details->'recipes');end if;
  if not d?'photos' and o.details?'photos' then d:=d||jsonb_build_object('photos',o.details->'photos');end if;
  if exists(select 1 from public.business_entries where owner_id=u and kind='payment' and details->>'orderId'=p_id::text) and (d->>'deposit')::numeric is distinct from (o.details->>'deposit')::numeric then raise exception 'Registra cobros o devoluciones en Agenda y cobros';end if;
  if exists(select 1 from public.sales where owner_id=u and details->>'orderId'=p_id::text) and ((d->>'total')::numeric is distinct from (o.details->>'total')::numeric or coalesce(d->'recipes','[]'::jsonb) is distinct from coalesce(o.details->'recipes','[]'::jsonb)) then raise exception 'Este encargo ya se vendió; conserva su total y preparaciones';end if;
 end if;
 saved:=jsonb_populate_record(null::public.business_entries,public.bum_ops_put(p_id,'order',d,p_expected));
 if not saved.details?'recipes' then return to_jsonb(saved);end if;
 if jsonb_array_length(saved.details->'recipes')>0 and exists(select 1 from public.business_entries where owner_id=u and kind='work_order' and details->>'orderId'=p_id::text and not details?'managedOrderId' and details->>'status'<>'cancelled') then raise exception 'El encargo tiene preparaciones manuales. Revisa su producción antes de añadir nuevas tareas para no duplicarlas';end if;
 for w in select * from public.business_entries where owner_id=u and kind='work_order' and details->>'managedOrderId'=p_id::text for update loop
  if not exists(select 1 from jsonb_array_elements(saved.details->'recipes') p where p->>'id'=w.id::text) then
   if w.details->>'status'='done' then raise exception 'Una preparación terminada no puede retirarse del encargo';end if;
   perform public.bum_ops_put(w.id,'work_order',jsonb_set(w.details,'{status}','"cancelled"'::jsonb),w.version);
  end if;
 end loop;
 for part in select * from jsonb_array_elements(saved.details->'recipes') loop
  line_id:=(part->>'id')::uuid;
  select * into w from public.business_entries where id=line_id for update;
  if found and (w.owner_id<>u or w.kind<>'work_order' or w.details->>'managedOrderId' is distinct from p_id::text) then raise exception 'Una preparación pertenece a otro registro';end if;
  if w.details->>'status'='done' then
   if w.details->>'recipeId' is distinct from part->>'recipeId' or (w.details->>'factor')::numeric<>(part->>'factor')::numeric or (w.details->>'quantity')::numeric<>(part->>'quantity')::numeric then raise exception 'La preparación ya terminó; conserva su receta y cantidades';end if;continue;
  end if;
  select * into recipe from public.recipes where id=(part->>'recipeId')::uuid and owner_id=u;
  target:=jsonb_build_object('name',left(recipe.name,160),'date',((saved.details->>'deliveryDate')::date-coalesce((part->>'leadDays')::integer,0))::text,'orderId',p_id,'managedOrderId',p_id,'orderLineId',line_id,'recipeId',part->>'recipeId','factor',(part->>'factor')::numeric,'quantity',(part->>'quantity')::numeric,'status',case when saved.details->>'status'='cancelled' then 'cancelled' else coalesce(w.details->>'status','planned') end,'notes',coalesce(w.details->>'notes',''),'photo',coalesce(w.details->>'photo',''));
  perform public.bum_ops_put(line_id,'work_order',target,coalesce(w.version,0));
 end loop;
 return to_jsonb(saved);
end $$;
revoke all on function public.bum_save_entry(uuid,text,jsonb,integer),public.bum_save_entry_before_orders(uuid,text,jsonb,integer) from public,anon,authenticated;
grant execute on function public.bum_save_entry(uuid,text,jsonb,integer) to authenticated;

-- A new catalog item has no confirmed stock. Its first purchase starts the tracked balance.
do $$ declare s text;old_ text:='if not found or i.stock_quantity is null then raise exception ''Registra primero el conteo inicial del artículo en Inventario'';end if;';begin
 s:=pg_get_functiondef('public.bum_inventory_purchase(uuid,uuid,numeric,numeric,date,date,text,text,numeric)'::regprocedure);
 if position(old_ in s)=0 then raise exception 'No se pudo actualizar el inicio por compras';end if;
 s:=replace(s,old_,'if not found then raise exception ''Artículo no disponible'';end if;if i.stock_quantity is null then if exists(select 1 from public.business_entries where owner_id=u and kind=''raw_lot'' and details->>''ingredientId''=p_item::text and (details->>''remaining'')::numeric>0) then raise exception ''Revisa los lotes del artículo antes de iniciar su saldo'';end if;i.stock_quantity:=0;end if;');
 s:=replace(s,'set stock_quantity=stock_quantity+p_quantity','set stock_quantity=coalesce(stock_quantity,0)+p_quantity');execute s;
end $$;
commit;
