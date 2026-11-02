begin;
-- Preserve each existing function's ownership, validation and concurrency logic.
-- Materials already share the same private catalogue and recipe-line foreign key.
do $$ declare f record;source text;changed integer:=0;begin
 for f in select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('guardar_receta_bum_bum','guardar_receta_producto_bum_bum','guardar_receta_recetario_bum_bum','actualizar_receta_recetario_bum_bum','bum_restore_backup') loop
  source:=pg_get_functiondef(f.oid);
  if source ~ 'item_kind\s*=\s*''ingredient''' then
   source:=regexp_replace(source,'item_kind\s*=\s*''ingredient''','item_kind in (''ingredient'',''material'')','g');
   execute source;changed:=changed+1;
  end if;
 end loop;
 if changed<2 then raise exception 'No se encontraron las validaciones esperadas; no se aplicó la migración';end if;
end $$;
alter table public.fridge_products add column channel_prices jsonb not null default '{}'::jsonb check(jsonb_typeof(channel_prices)='object');
create function public.bum_fridge_channel_prices(p_id uuid,p_original jsonb,p_prices jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();old public.fridge_products;saved public.fridge_products;channel text;plan jsonb;field text;v numeric;clean jsonb:='{}';details jsonb;fee numeric;margin numeric;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 if p_id is null or jsonb_typeof(p_original) is distinct from 'object' or jsonb_typeof(p_prices) is distinct from 'object' or octet_length(p_prices::text)>10000 then raise exception 'Precios por canal no válidos';end if;
 for channel,plan in select * from jsonb_each(p_prices) loop
  if channel not in ('Directa','Uber Eats','PedidosYa') or jsonb_typeof(plan) is distinct from 'object' then raise exception 'Canal no disponible';end if;
  details:='{}';
  foreach field in array array['baseCost','packaging','labor','other','commission','margin','price'] loop
   v:=(plan->>field)::numeric;
   if v is null or v<0 or v>=1e9 or v::text in ('NaN','Infinity','-Infinity') then raise exception 'Revisa costos, precio y porcentajes del canal';end if;
   if field='price' and v<>round(v,2) then raise exception 'El precio admite dos decimales';end if;
   details:=details||jsonb_build_object(field,v);
  end loop;
  fee:=(details->>'commission')::numeric;margin:=(details->>'margin')::numeric;
  if fee+margin>=100 then raise exception 'Comisión y margen deben sumar menos de 100 por ciento';end if;
  clean:=clean||jsonb_build_object(channel,details);
 end loop;
 select * into old from public.fridge_products where id=p_id and owner_id=u for update;
 if not found then raise exception 'Producto no disponible para esta cuenta';end if;
 if old.channel_prices=clean then return to_jsonb(old);end if;
 if old.channel_prices is distinct from p_original then raise exception 'Los precios cambiaron. Actualiza y revisa antes de guardar';end if;
 update public.fridge_products set channel_prices=clean where id=p_id and owner_id=u returning * into saved;
 return to_jsonb(saved);
end $$;
revoke all on function public.bum_fridge_channel_prices(uuid,jsonb,jsonb) from public,anon;
grant execute on function public.bum_fridge_channel_prices(uuid,jsonb,jsonb) to authenticated;
-- Reuse private versioned business entries for the owner's quotation branding.
alter table public.business_entries drop constraint business_entries_kind_check;
alter table public.business_entries add constraint business_entries_kind_check check(kind in ('expense','order','recipe_info','quote_brand'));
alter function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean) rename to bum_validate_business_entry_v1;
create function public.bum_validate_entry(p_id uuid,p_kind text,p_details jsonb,p_owner uuid,p_require_recipe boolean) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare d jsonb;key text;value text;begin
 if p_kind is distinct from 'quote_brand' then return public.bum_validate_business_entry_v1(p_id,p_kind,p_details,p_owner,p_require_recipe);end if;
 if p_id is distinct from p_owner or jsonb_typeof(p_details) is distinct from 'object' or length(p_details::text)>300000 then raise exception 'Presentación no válida para esta cuenta';end if;
 d:='{}';
 foreach key in array array['businessName','phone','location','website','color','logo'] loop value:=coalesce(p_details->>key,'');d:=d||jsonb_build_object(key,value);end loop;
 if length(trim(d->>'businessName')) not between 1 and 160 or length(d->>'phone')>200 or length(d->>'location')>300 or length(d->>'website')>300 or (d->>'color')!~'^#[0-9A-Fa-f]{6}$' or length(d->>'logo')>250000 or (d->>'logo'<>'' and (d->>'logo')!~'^data:image/(jpeg|png);base64,[A-Za-z0-9+/=]+$') then raise exception 'Revisa el nombre, color o logo del negocio';end if;
 return d;
end $$;
revoke all on function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean),public.bum_validate_business_entry_v1(uuid,text,jsonb,uuid,boolean) from public,anon,authenticated;
do $$ declare source text;begin
 source:=pg_get_functiondef('public.bum_save_entry(uuid,text,jsonb,integer)'::regprocedure);
 if position('''expense'',''order'',''recipe_info''' in source)=0 then raise exception 'No se encontró la validación esperada de registros';end if;
 source:=replace(source,'''expense'',''order'',''recipe_info''','''expense'',''order'',''recipe_info'',''quote_brand''');execute source;
end $$;
commit;
