begin;
-- Stage membership annotates actual recipe lines. It never creates a second ingredient ledger.
create function public.bum_save_staged_recipe(p_recipe jsonb,p_stages jsonb,p_original jsonb default null)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare u uuid:=auth.uid();result jsonb;stage jsonb;entry jsonb;idx integer;line_ jsonb;lid uuid;used uuid[]:='{}';indices integer[]:='{}';stage_ids uuid[]:='{}';sid uuid;members jsonb;stages jsonb:='[]';saved text;rid uuid:=(p_recipe->>'p_id')::uuid;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Inicia sesión con una cuenta aprobada';end if;
 if jsonb_typeof(p_stages) is distinct from 'array' or jsonb_array_length(p_stages)>20 or length(p_stages::text)>250000 then raise exception 'Revisa las etapas de la receta';end if;
 -- Existing transactional save performs ownership, ingredient, measurement, yield and optimistic-version checks.
 if p_original is null then
 result:=public.guardar_receta_organizada_bum_bum(rid,p_recipe->>'p_name',(p_recipe->>'p_yield')::numeric,p_recipe->>'p_yield_unit',p_recipe->>'p_scaling',p_recipe->'p_lines',p_recipe->>'p_product_type',(p_recipe->>'p_book_id')::uuid,p_recipe->>'p_preparation',p_recipe->>'p_category');
 else
 result:=public.actualizar_receta_organizada_bum_bum(rid,p_recipe->>'p_name',(p_recipe->>'p_yield')::numeric,p_recipe->>'p_yield_unit',p_recipe->>'p_scaling',p_recipe->'p_lines',p_recipe->>'p_product_type',(p_recipe->>'p_book_id')::uuid,p_original,p_recipe->>'p_preparation',p_recipe->>'p_category');
 end if;
 for stage in select * from jsonb_array_elements(p_stages) loop
  sid:=(stage->>'id')::uuid;
  if sid is null or sid=any(stage_ids) or jsonb_typeof(stage->'name') is distinct from 'string' or length(trim(stage->>'name')) not between 1 and 100 or jsonb_typeof(stage->'preparation') is distinct from 'string' or length(stage->>'preparation')>10000 or jsonb_typeof(stage->'lineIndexes') is distinct from 'array' then raise exception 'Completa el nombre y las instrucciones de cada etapa';end if;
  stage_ids:=array_append(stage_ids,sid);members:='[]';
  for entry in select * from jsonb_array_elements(stage->'lineIndexes') loop
   if jsonb_typeof(entry) is distinct from 'number' or (entry#>>'{}')::numeric<>trunc((entry#>>'{}')::numeric) then raise exception 'Ingrediente de etapa no válido';end if;
   idx:=(entry#>>'{}')::integer;
   if idx<0 or idx>=jsonb_array_length(p_recipe->'p_lines') or idx=any(indices) then raise exception 'Cada línea solo puede pertenecer a una etapa';end if;
   indices:=array_append(indices,idx);line_:=p_recipe->'p_lines'->idx;
   select l.id into lid from public.recipe_lines l where l.owner_id=u and l.recipe_id=rid and not(l.id=any(used)) and l.ingredient_id=(line_->>'ingredient_id')::uuid and l.quantity_base=(line_->>'quantity_base')::numeric and (nullif(line_->>'id','') is null or l.id=(line_->>'id')::uuid) and l.measurement_quantity is not distinct from (line_->>'measurement_quantity')::numeric and l.measurement_unit is not distinct from (line_->>'measurement_unit') order by l.id limit 1;
   if lid is null then raise exception 'No se pudo vincular el ingrediente a su etapa. No se guardó ningún cambio';end if;
   used:=array_append(used,lid);members:=members||jsonb_build_array(lid);
  end loop;
  stages:=stages||jsonb_build_array(jsonb_build_object('id',sid,'name',trim(stage->>'name'),'preparation',stage->>'preparation','lineIds',members));
 end loop;
 update public.recipes set instructions=((instructions::jsonb)||jsonb_build_object('stages',stages))::text where id=rid and owner_id=u returning instructions into saved;
 if not found then raise exception 'No se pudo confirmar la receta de tu cuenta';end if;
 return result||jsonb_build_object('instructions',saved);
end $$;
revoke all on function public.bum_save_staged_recipe(jsonb,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.bum_save_staged_recipe(jsonb,jsonb,jsonb) to authenticated;
commit;
