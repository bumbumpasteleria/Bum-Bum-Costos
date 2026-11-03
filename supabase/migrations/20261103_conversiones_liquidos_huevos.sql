begin;
alter table public.ingredients
 add column grams_per_white numeric check(grams_per_white>0 and grams_per_white<1000 and grams_per_white::text not in ('NaN','Infinity','-Infinity')),
 add column grams_per_yolk numeric check(grams_per_yolk>0 and grams_per_yolk<1000 and grams_per_yolk::text not in ('NaN','Infinity','-Infinity')),
 add column conversion_reference jsonb check(jsonb_typeof(conversion_reference)='object' and octet_length(conversion_reference::text)<10000);
alter table public.recipe_lines drop constraint recipe_measurement_pair;
alter table public.recipe_lines add constraint recipe_measurement_pair check((measurement_quantity is null and measurement_unit is null) or (measurement_quantity>0 and measurement_quantity<1e12 and measurement_quantity::text not in ('NaN','Infinity','-Infinity') and measurement_unit in ('g','kg','mg','lb','oz','ml','L','gal US','fl oz','unidad','unit','docena','g clara','g yema','clara','yema')));

alter function public.bum_recipe_base(uuid,numeric,text,uuid) rename to bum_recipe_base_before_egg;
create function public.bum_recipe_base(p_ingredient uuid,p_quantity numeric,p_unit text,p_owner uuid) returns numeric language plpgsql security invoker set search_path='' as $$
declare i public.ingredients;weight_ numeric;result_ numeric;begin
 if p_unit not in ('g clara','g yema','clara','yema') then return public.bum_recipe_base_before_egg(p_ingredient,p_quantity,p_unit,p_owner);end if;
 if p_owner is distinct from auth.uid() or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 select * into i from public.ingredients where id=p_ingredient and owner_id=p_owner;
 if not found or i.base_unit<>'unit' then raise exception 'Selecciona el huevo comprado por unidades de tu catálogo';end if;
 weight_:=case when p_unit in ('g clara','clara') then i.grams_per_white else i.grams_per_yolk end;
 if weight_ is null or p_quantity is null or p_quantity<=0 or p_quantity>=1e12 or p_quantity::text in('NaN','Infinity','-Infinity') then raise exception 'Completa el peso de claras y yemas y su cantidad';end if;
 result_:=case when p_unit in('clara','yema') then p_quantity else p_quantity/weight_ end;
 if result_<.001 or result_::text in('NaN','Infinity','-Infinity') then raise exception 'Revisa la cantidad equivalente de huevo';end if;
 return result_;
end $$;
revoke all on function public.bum_recipe_base(uuid,numeric,text,uuid),public.bum_recipe_base_before_egg(uuid,numeric,text,uuid) from public,anon;
grant execute on function public.bum_recipe_base(uuid,numeric,text,uuid),public.bum_recipe_base_before_egg(uuid,numeric,text,uuid) to authenticated;

-- Pair the white and yolk requirements within one recipe, including its linked components.
create or replace function public.bum_recipe_components(p_recipe uuid,p_owner uuid) returns table(ingredient_id uuid,quantity numeric) language plpgsql security invoker set search_path='' as $$
declare nodes jsonb;begin
 if p_owner is distinct from auth.uid() then raise exception 'Cuenta no disponible';end if;
 with recursive tree as(
 select p_recipe id,1::numeric factor,array[p_recipe] path
 union all select (x->>'recipeId')::uuid,t.factor*(x->>'factor')::numeric,t.path||(x->>'recipeId')::uuid from tree t join public.business_entries b on b.owner_id=p_owner and b.kind='subrecipe' and b.details->>'recipeId'=t.id::text cross join lateral jsonb_array_elements(b.details->'children') x where cardinality(t.path)<31 and not (x->>'recipeId')::uuid=any(t.path)
 ) select coalesce(jsonb_agg(to_jsonb(bounded)),'[]'::jsonb) into nodes from(select * from tree limit 2001) bounded;
 if jsonb_array_length(nodes)>2000 or exists(select 1 from jsonb_array_elements(nodes) n where jsonb_array_length(n->'path')>30) then raise exception 'La composición tiene demasiados niveles o componentes';end if;
 return query with amounts as(select l.ingredient_id item,l.measurement_unit unit_,(case when l.measurement_quantity is null then l.quantity_base else public.bum_recipe_base(l.ingredient_id,l.measurement_quantity,l.measurement_unit,p_owner) end)*t.factor amount from jsonb_to_recordset(nodes) t(id uuid,factor numeric) join public.recipes r on r.id=t.id and r.owner_id=p_owner join public.recipe_lines l on l.recipe_id=r.id and l.owner_id=p_owner)
 select a.item,coalesce(sum(a.amount) filter(where a.unit_ is null or a.unit_ not in('g clara','g yema','clara','yema')),0)+greatest(coalesce(sum(a.amount) filter(where a.unit_ in('g clara','clara')),0),coalesce(sum(a.amount) filter(where a.unit_ in('g yema','yema')),0)) from amounts a group by a.item;
end $$;
revoke all on function public.bum_recipe_components(uuid,uuid) from public,anon,authenticated;
commit;
