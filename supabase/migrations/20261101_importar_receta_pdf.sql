begin;
-- A new recipe, its ingredient lines and preparation commit together.
-- Existing functions and all account policies are preserved.
create function public.guardar_receta_importada_bum_bum(
 p_id uuid,p_name text,p_yield numeric,p_yield_unit text,p_scaling text,
 p_lines jsonb,p_product_type text,p_book_id uuid,p_preparation text
) returns jsonb language plpgsql security invoker set search_path='' as $$
declare saved public.recipes; result jsonb;
begin
 if auth.uid() is null then raise exception 'Inicia sesión.'; end if;
 if p_preparation is null or length(p_preparation)>20000 then raise exception 'La preparación debe tener hasta 20,000 caracteres.'; end if;
 -- Repeating a save cannot modify or replace an existing recipe.
 if exists(select 1 from public.recipes where id=p_id) then raise exception 'Esta receta ya está guardada. Revisa tu lista antes de volver a importar.'; end if;
 perform public.guardar_receta_recetario_bum_bum(p_id,p_name,p_yield,p_yield_unit,p_scaling,p_lines,p_product_type,p_book_id);
 update public.recipes set instructions=((instructions::jsonb)||jsonb_build_object('preparation',p_preparation))::text
 where id=p_id and owner_id=auth.uid() returning * into saved;
 if not found then raise exception 'No se pudo guardar la receta de tu cuenta.'; end if;
 select to_jsonb(saved)||jsonb_build_object('recipe_lines',coalesce(jsonb_agg(to_jsonb(l)||jsonb_build_object('ingredients',jsonb_build_object('base_unit',i.base_unit))) filter(where l.id is not null),'[]'::jsonb))
 into result from public.recipe_lines l join public.ingredients i on i.id=l.ingredient_id and i.owner_id=auth.uid()
 where l.recipe_id=p_id and l.owner_id=auth.uid();
 return result;
end; $$;
revoke all on function public.guardar_receta_importada_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,text) from public,anon,authenticated;
grant execute on function public.guardar_receta_importada_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,text) to authenticated;
commit;
