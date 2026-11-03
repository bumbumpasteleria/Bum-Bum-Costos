begin;
alter table public.business_entries drop constraint business_entries_kind_check;
alter table public.business_entries add constraint business_entries_kind_check check(kind in ('expense','order','recipe_info','quote_brand','product_cost','recipe_profile','subrecipe','customer','supplier','quality','business_settings','work_order','payment','cash','raw_lot','inventory_event','recipe_draft'));
alter function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean) rename to bum_validate_entry_before_drafts;
create function public.bum_validate_entry(p_id uuid,p_kind text,p_details jsonb,p_owner uuid,p_require_recipe boolean) returns jsonb language plpgsql security invoker set search_path='' as $$
declare f jsonb:=p_details->'form';begin
 if p_kind<>'recipe_draft' then return public.bum_validate_entry_before_drafts(p_id,p_kind,p_details,p_owner,p_require_recipe);end if;
 if p_owner is distinct from auth.uid() or jsonb_typeof(p_details) is distinct from 'object' or length(p_details::text)>250000 or jsonb_typeof(f) is distinct from 'object' then raise exception 'Borrador no válido para esta cuenta';end if;
 if jsonb_typeof(f->'name') is distinct from 'string' or length(trim(f->>'name')) not between 1 and 160 or jsonb_typeof(f->'lines') is distinct from 'array' or jsonb_array_length(f->'lines')>500 or jsonb_typeof(f->'stages') is distinct from 'array' or jsonb_array_length(f->'stages')>20 then raise exception 'Revisa el nombre, ingredientes y etapas del borrador';end if;
 if nullif(f->>'bookId','') is not null and not exists(select 1 from public.recipe_books where id=(f->>'bookId')::uuid and owner_id=p_owner) then raise exception 'Selecciona un recetario de tu cuenta';end if;
 if p_details?'archived' and jsonb_typeof(p_details->'archived') is distinct from 'boolean' then raise exception 'Estado de borrador no válido';end if;
 return jsonb_build_object('form',f,'archived',coalesce((p_details->>'archived')::boolean,false));
end $$;
revoke all on function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean),public.bum_validate_entry_before_drafts(uuid,text,jsonb,uuid,boolean) from public,anon,authenticated;
alter function public.bum_save_entry(uuid,text,jsonb,integer) rename to bum_save_entry_before_drafts;
create function public.bum_save_entry(p_id uuid,p_kind text,p_details jsonb,p_expected integer) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if p_kind='recipe_draft' then return public.bum_ops_put(p_id,p_kind,p_details,p_expected);end if;
 return public.bum_save_entry_before_drafts(p_id,p_kind,p_details,p_expected);
end $$;
revoke all on function public.bum_save_entry(uuid,text,jsonb,integer),public.bum_save_entry_before_drafts(uuid,text,jsonb,integer) from public,anon,authenticated;
grant execute on function public.bum_save_entry(uuid,text,jsonb,integer) to authenticated;
commit;
