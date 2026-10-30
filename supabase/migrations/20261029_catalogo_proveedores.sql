-- Add purchase metadata without modifying existing stock or recipe references.
begin;
alter table public.ingredients
  add column supplier text not null default '',
  add column item_kind text not null default 'ingredient' check (item_kind in ('ingredient','material')),
  add column purchase_unit text check (purchase_unit in ('g','kg','lb','oz','mg','ml','L','fl oz','unidad','docena')),
  add column purchase_quantity numeric check (purchase_quantity > 0),
  add column purchase_price numeric check (purchase_price >= 0);

create function public.guardar_receta_producto_bum_bum(p_id uuid,p_name text,p_yield numeric,p_yield_unit text,p_scaling text,p_lines jsonb,p_product_type text)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare linea jsonb;
begin
  if auth.uid() is null then raise exception 'Inicia sesión.'; end if;
  if p_product_type is null or p_product_type not in ('Bizcocho','Cupcake','Galleta','Brownie','Cheesecake','Flan','Tres leches','Postre en vaso','Pan','Otro artículo') then raise exception 'Selecciona un tipo de producto válido.'; end if;
  if p_lines is null or jsonb_typeof(p_lines)<>'array' then raise exception 'Agrega ingredientes.'; end if;
  for linea in select * from jsonb_array_elements(p_lines) loop
    if not exists(select 1 from public.ingredients where id=(linea->>'ingredient_id')::uuid and owner_id=auth.uid() and item_kind='ingredient') then raise exception 'Selecciona un ingrediente de esta cuenta.'; end if;
  end loop;
  perform public.guardar_receta_bum_bum(p_id,p_name,p_yield,p_yield_unit,p_scaling,p_lines);
  update public.recipes set instructions=jsonb_build_object('bumBum',1,'scaling',p_scaling,'productType',p_product_type)::text where id=p_id and owner_id=auth.uid();
  return p_id;
end;
$$;
revoke all on function public.guardar_receta_producto_bum_bum(uuid,text,numeric,text,text,jsonb,text) from public,anon;
grant execute on function public.guardar_receta_producto_bum_bum(uuid,text,numeric,text,text,jsonb,text) to authenticated;
commit;
