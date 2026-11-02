begin;
alter table public.fridge_products add column sale_price numeric(12,2) check(sale_price>=0 and sale_price<1e9);
create function public.bum_fridge_priced_product(p_id uuid,p_recipe uuid,p_unit text,p_minimum numeric,p_price numeric,p_original jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();old public.fridge_products;saved public.fridge_products;
begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 if p_id is null or p_price is null or p_price<0 or p_price>=1e9 or p_price::text in ('NaN','Infinity','-Infinity') or p_price<>round(p_price,2) then raise exception 'Precio no válido: usa hasta dos decimales';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,27));
 select * into old from public.fridge_products where id=p_id and owner_id=u for update;
 if found then
  if old.recipe_id is distinct from p_recipe or old.unit is distinct from p_unit then raise exception 'La receta y unidad del producto se conservan';end if;
  if old.sale_price is not distinct from p_price and old.minimum_quantity is not distinct from p_minimum then return to_jsonb(old);end if;
  if p_original is null or jsonb_typeof(p_original) is distinct from 'object' or not (p_original ? 'sale_price' and p_original ? 'minimum_quantity') or old.sale_price is distinct from (p_original->>'sale_price')::numeric or old.minimum_quantity is distinct from (p_original->>'minimum_quantity')::numeric then raise exception 'El producto cambió. Actualiza Mi nevera y revisa antes de guardar';end if;
 elsif p_original is not null then raise exception 'Producto no disponible';end if;
 perform public.bum_fridge_product(p_id,p_recipe,p_unit,p_minimum);
 update public.fridge_products set sale_price=p_price where id=p_id and owner_id=u returning * into saved;
 return to_jsonb(saved);
end $$;
create function public.bum_fridge_priced_sale(p_sale jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare price numeric:=(p_sale->>'unitPrice')::numeric;q numeric:=(p_sale->>'fridgeQuantity')::numeric;total numeric;result jsonb;
begin
 if auth.uid() is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;
 if price is null or price<0 or price>=1e9 or price::text in ('NaN','Infinity','-Infinity') or price<>round(price,2) or q is null or q<0.001 or q>=1e9 or q::text in ('NaN','Infinity','-Infinity') or q<>round(q,3) then raise exception 'Revisa precio (dos decimales) y cantidad (tres decimales)';end if;
 total:=round(price*q,2);if total>=1e12 then raise exception 'Total demasiado grande';end if;
 result:=public.bum_fridge_sale(p_sale||jsonb_build_object('gross',total,'unitPrice',price));
 if (result->'details'->>'unitPrice')::numeric is distinct from price then raise exception 'La venta ya existe con otro precio. Actualiza Ventas';end if;
 return result;
end $$;
revoke all on function public.bum_fridge_priced_product(uuid,uuid,text,numeric,numeric,jsonb),public.bum_fridge_priced_sale(jsonb) from public,anon;
grant execute on function public.bum_fridge_priced_product(uuid,uuid,text,numeric,numeric,jsonb),public.bum_fridge_priced_sale(jsonb) to authenticated;
commit;
