begin;
-- Backward-compatible wrapper: existing edit validation and locking stay in place.
create function public.actualizar_receta_preparacion_bum_bum(
 p_id uuid,p_name text,p_yield numeric,p_yield_unit text,p_scaling text,
 p_lines jsonb,p_product_type text,p_book_id uuid,p_original jsonb,p_preparation text
) returns jsonb language plpgsql security invoker set search_path='' as $$
declare respuesta jsonb; instrucciones text;
begin
 if auth.uid() is null then raise exception 'Inicia sesión.'; end if;
 if p_preparation is null or length(p_preparation)>20000 then raise exception 'La preparación debe ser texto de hasta 20,000 caracteres.'; end if;
 respuesta:=public.actualizar_receta_recetario_bum_bum(p_id,p_name,p_yield,p_yield_unit,p_scaling,p_lines,p_product_type,p_book_id,p_original);
 update public.recipes set instructions=((instructions::jsonb)||jsonb_build_object('preparation',p_preparation))::text
 where id=p_id and owner_id=auth.uid() returning instructions into instrucciones;
 return respuesta||jsonb_build_object('instructions',instrucciones);
end; $$;
revoke all on function public.actualizar_receta_preparacion_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,jsonb,text) from public,anon,authenticated;
grant execute on function public.actualizar_receta_preparacion_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,jsonb,text) to authenticated;
commit;
