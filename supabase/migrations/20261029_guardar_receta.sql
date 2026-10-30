-- Atomic recipe creation. Existing table policies continue to enforce ownership.
begin;
create function public.guardar_receta_bum_bum(p_id uuid, p_name text, p_yield numeric, p_yield_unit text, p_scaling text, p_lines jsonb)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare linea jsonb;
begin
  if auth.uid() is null then raise exception 'Inicia sesión.'; end if;
  if nullif(trim(p_name),'') is null or p_yield <= 0 or p_yield is null or p_scaling is null or p_scaling not in ('fixed','scalable') or p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines)=0 then
    raise exception 'Receta no válida.';
  end if;
  insert into public.recipes(id,owner_id,name,yield_quantity,yield_unit,instructions)
  values(p_id,auth.uid(),trim(p_name),p_yield,p_yield_unit,jsonb_build_object('bumBum',1,'scaling',p_scaling)::text);
  for linea in select * from jsonb_array_elements(p_lines) loop
    if not exists(select 1 from public.ingredients where id=(linea->>'ingredient_id')::uuid and owner_id=auth.uid()) then raise exception 'Ingrediente no disponible para esta cuenta.'; end if;
    insert into public.recipe_lines(owner_id,recipe_id,ingredient_id,quantity_base)
    values(auth.uid(),p_id,(linea->>'ingredient_id')::uuid,(linea->>'quantity_base')::numeric);
  end loop;
  return p_id;
end;
$$;
revoke all on function public.guardar_receta_bum_bum(uuid,text,numeric,text,text,jsonb) from public, anon;
grant execute on function public.guardar_receta_bum_bum(uuid,text,numeric,text,text,jsonb) to authenticated;
commit;
