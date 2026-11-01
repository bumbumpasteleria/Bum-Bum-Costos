begin;
-- Additive wrappers. Existing clients and account policies remain unchanged.
create function public.guardar_receta_organizada_bum_bum(
 p_id uuid,p_name text,p_yield numeric,p_yield_unit text,p_scaling text,p_lines jsonb,
 p_product_type text,p_book_id uuid,p_preparation text,p_category text
) returns jsonb language plpgsql security invoker set search_path='' as $$
declare result jsonb; saved_instructions text;
begin
 if auth.uid() is null then raise exception 'Inicia sesión.'; end if;
 if p_category is null or length(trim(p_category))>80 then raise exception 'La categoría admite hasta 80 caracteres.'; end if;
 result:=public.guardar_receta_importada_bum_bum(p_id,p_name,p_yield,p_yield_unit,p_scaling,p_lines,p_product_type,p_book_id,p_preparation);
 update public.recipes set instructions=((instructions::jsonb)||jsonb_build_object('category',trim(p_category)))::text
 where id=p_id and owner_id=auth.uid() returning instructions into saved_instructions;
 if not found then raise exception 'No se pudo confirmar la receta de tu cuenta.'; end if;
 return result||jsonb_build_object('instructions',saved_instructions);
end; $$;
create function public.actualizar_receta_organizada_bum_bum(
 p_id uuid,p_name text,p_yield numeric,p_yield_unit text,p_scaling text,p_lines jsonb,
 p_product_type text,p_book_id uuid,p_original jsonb,p_preparation text,p_category text
) returns jsonb language plpgsql security invoker set search_path='' as $$
declare result jsonb; saved_instructions text;
begin
 if auth.uid() is null then raise exception 'Inicia sesión.'; end if;
 if p_category is null or length(trim(p_category))>80 then raise exception 'La categoría admite hasta 80 caracteres.'; end if;
 result:=public.actualizar_receta_preparacion_bum_bum(p_id,p_name,p_yield,p_yield_unit,p_scaling,p_lines,p_product_type,p_book_id,p_original,p_preparation);
 update public.recipes set instructions=((instructions::jsonb)||jsonb_build_object('category',trim(p_category)))::text
 where id=p_id and owner_id=auth.uid() returning instructions into saved_instructions;
 if not found then raise exception 'No se pudo confirmar la receta de tu cuenta.'; end if;
 return result||jsonb_build_object('instructions',saved_instructions);
end; $$;
revoke all on function public.guardar_receta_organizada_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,text,text) from public,anon,authenticated;
revoke all on function public.actualizar_receta_organizada_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,jsonb,text,text) from public,anon,authenticated;
grant execute on function public.guardar_receta_organizada_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,text,text) to authenticated;
grant execute on function public.actualizar_receta_organizada_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,jsonb,text,text) to authenticated;
commit;
