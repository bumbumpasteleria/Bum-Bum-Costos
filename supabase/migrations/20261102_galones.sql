begin;
-- Expand only the purchase-unit constraint. Existing quantities and prices remain intact.
do $$ declare c record;begin for c in select conname from pg_constraint where conrelid='public.ingredients'::regclass and contype='c' and pg_get_constraintdef(oid) like '%purchase_unit%' loop execute format('alter table public.ingredients drop constraint %I',c.conname);end loop;end $$;
alter table public.ingredients add constraint ingredients_purchase_unit_check check(purchase_unit in ('g','kg','lb','oz','mg','ml','L','fl oz','gal US','unidad','docena'));
create or replace function public.actualizar_receta_recetario_bum_bum(
 p_id uuid,p_name text,p_yield numeric,p_yield_unit text,p_scaling text,
 p_lines jsonb,p_product_type text,p_book_id uuid,p_original jsonb
) returns jsonb language plpgsql security invoker set search_path='' as $$
declare actual public.recipes%rowtype; linea jsonb; meta jsonb; respuesta jsonb;
begin
 if auth.uid() is null then raise exception 'Inicia sesión.'; end if;
 select * into actual from public.recipes where id=p_id and owner_id=auth.uid() for update;
 if not found then raise exception 'Receta no disponible para esta cuenta.'; end if;
 perform 1 from public.recipe_lines where recipe_id=p_id and owner_id=auth.uid() for update;
 if p_original is null or jsonb_typeof(p_original) is distinct from 'object'
    or jsonb_typeof(p_original->'lines') is distinct from 'array' then
  raise exception 'Recarga la receta antes de editarla.';
 end if;
 if actual.name is distinct from p_original->>'name'
    or actual.yield_quantity is distinct from (p_original->>'yield_quantity')::numeric
    or actual.yield_unit is distinct from p_original->>'yield_unit'
    or actual.recipe_book_id is distinct from (p_original->>'recipe_book_id')::uuid
    or actual.instructions is distinct from p_original->>'instructions'
    or (select count(*) from public.recipe_lines where recipe_id=p_id and owner_id=auth.uid())<>jsonb_array_length(p_original->'lines')
    or exists(select 1 from public.recipe_lines l where l.recipe_id=p_id and l.owner_id=auth.uid()
      and not exists(select 1 from jsonb_array_elements(p_original->'lines') e(v)
       where (e.v->>'id')::uuid=l.id and (e.v->>'ingredient_id')::uuid=l.ingredient_id
       and (e.v->>'quantity_base')::numeric=l.quantity_base)) then
  raise exception 'La receta cambió mientras la editabas. Cancela la edición y vuelve a abrirla para revisar los cambios.';
 end if;
 if nullif(trim(p_name),'') is null or length(trim(p_name))>160 or p_yield is null
    or p_yield<=0 or p_yield::text in ('NaN','Infinity','-Infinity')
    or p_yield_unit is null or p_yield_unit not in ('unidad','porción','docena','g','kg','lb','lb comercial','oz','ml','L','gal US','bandeja','caja')
    or p_scaling is null or p_scaling not in ('fixed','scalable') then raise exception 'Revisa el nombre y el rendimiento de la receta.'; end if;
 if p_product_type is null or p_product_type not in ('Bizcocho','Cupcake','Galleta','Brownie','Cheesecake','Flan','Tres leches','Postre en vaso','Pan','Otro artículo') then raise exception 'Selecciona un tipo de producto válido.'; end if;
 if p_book_id is null or not exists(select 1 from public.recipe_books where id=p_book_id and owner_id=auth.uid()) then raise exception 'Selecciona un recetario de tu cuenta.'; end if;
 if p_lines is null or jsonb_typeof(p_lines) is distinct from 'array' then raise exception 'Agrega ingredientes a la receta.'; end if;
 if jsonb_array_length(p_lines)=0 then raise exception 'Agrega ingredientes a la receta.'; end if;
 if (select count(*) from jsonb_array_elements(p_lines) e(v) where e.v->>'id' is not null)
    <>(select count(distinct e.v->>'id') from jsonb_array_elements(p_lines) e(v) where e.v->>'id' is not null) then raise exception 'Hay líneas repetidas. Recarga la receta.'; end if;
 for linea in select * from jsonb_array_elements(p_lines) loop
  if not exists(select 1 from public.ingredients where id=(linea->>'ingredient_id')::uuid and owner_id=auth.uid() and item_kind='ingredient') then raise exception 'Selecciona un ingrediente de esta cuenta.'; end if;
  if linea->>'quantity_base' is null or linea->>'quantity_base' in ('NaN','Infinity','-Infinity')
     or (linea->>'quantity_base')::numeric<0.001 then raise exception 'Revisa las cantidades de los ingredientes.'; end if;
  if linea->>'id' is not null and not exists(select 1 from public.recipe_lines where id=(linea->>'id')::uuid and recipe_id=p_id and owner_id=auth.uid()) then raise exception 'Una línea no pertenece a esta receta.'; end if;
 end loop;
 begin meta:=actual.instructions::jsonb; exception when invalid_text_representation then meta:=null; end;
 if jsonb_typeof(meta) is distinct from 'object' then
  meta:=case when actual.instructions is null then '{}'::jsonb else jsonb_build_object('legacyInstructions',actual.instructions) end;
 end if;
 update public.recipes set name=trim(p_name),yield_quantity=p_yield,yield_unit=p_yield_unit,recipe_book_id=p_book_id,
  instructions=(meta||jsonb_build_object('bumBum',1,'scaling',p_scaling,'productType',p_product_type))::text
 where id=p_id and owner_id=auth.uid();
 delete from public.recipe_lines l where l.recipe_id=p_id and l.owner_id=auth.uid()
  and not exists(select 1 from jsonb_array_elements(p_lines) e(v) where (e.v->>'id')::uuid=l.id);
 for linea in select * from jsonb_array_elements(p_lines) loop
  if linea->>'id' is null then
   insert into public.recipe_lines(owner_id,recipe_id,ingredient_id,quantity_base)
   values(auth.uid(),p_id,(linea->>'ingredient_id')::uuid,(linea->>'quantity_base')::numeric);
  else
   update public.recipe_lines set ingredient_id=(linea->>'ingredient_id')::uuid,quantity_base=(linea->>'quantity_base')::numeric
   where id=(linea->>'id')::uuid and recipe_id=p_id and owner_id=auth.uid();
  end if;
 end loop;
 select to_jsonb(r) into respuesta from public.recipes r where r.id=p_id and r.owner_id=auth.uid();
 return respuesta||jsonb_build_object('recipe_lines',coalesce((select jsonb_agg(to_jsonb(l)||jsonb_build_object('ingredients',jsonb_build_object('base_unit',i.base_unit)) order by l.id)
   from public.recipe_lines l join public.ingredients i on i.id=l.ingredient_id
   where l.recipe_id=p_id and l.owner_id=auth.uid()),'[]'::jsonb));
end; $$;
revoke all on function public.actualizar_receta_recetario_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.actualizar_receta_recetario_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,jsonb) to authenticated;

commit;

