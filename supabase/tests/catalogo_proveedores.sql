-- Synthetic data only; all fixture writes are rolled back.
begin;
insert into auth.users(id,email) values ('12345000-0000-4000-8000-000000000001','catalogo-test@example.invalid');
set local role authenticated;
set local request.jwt.claim.sub='12345000-0000-4000-8000-000000000001';
insert into public.ingredients(id,name,supplier,item_kind,base_unit,last_unit_cost,purchase_unit,purchase_quantity,purchase_price) values
('12345000-0000-4000-8000-000000000011','Harina temporal','Proveedor A','ingredient','g',0.12,'kg',1,120),
('12345000-0000-4000-8000-000000000012','Harina temporal','Proveedor B','ingredient','g',0.20,'kg',1,200),
('12345000-0000-4000-8000-000000000013','Caja temporal','Empaques','material','unit',20,'unidad',10,200);
select public.guardar_receta_producto_bum_bum('12345000-0000-4000-8000-000000000021','Galletas temporales',12,'unidad','fixed','[{"ingredient_id":"12345000-0000-4000-8000-000000000012","quantity_base":500}]'::jsonb,'Galleta');
do $$ declare costo numeric; begin
  select sum(l.quantity_base*i.last_unit_cost) into costo from public.recipe_lines l join public.ingredients i on i.id=l.ingredient_id where l.recipe_id='12345000-0000-4000-8000-000000000021';
  if costo<>100 then raise exception 'Costo del proveedor incorrecto'; end if;
  if not exists(select 1 from public.recipes where id='12345000-0000-4000-8000-000000000021' and instructions::jsonb->>'productType'='Galleta') then raise exception 'Tipo de producto perdido'; end if;
  begin
    perform public.guardar_receta_producto_bum_bum('12345000-0000-4000-8000-000000000022','Inválida',1,'unidad','fixed','[{"ingredient_id":"12345000-0000-4000-8000-000000000013","quantity_base":1}]'::jsonb,'Galleta');
  exception when others then null;
  end;
  if exists(select 1 from public.recipes where id='12345000-0000-4000-8000-000000000022') then raise exception 'Material aceptado como ingrediente'; end if;
end $$;
insert into public.quotes(id,details,pricing_method,total_cost,quoted_price) values ('12345000-0000-4000-8000-000000000031','{"productType":"Galleta","recipeName":"Galletas temporales","materialCost":40,"materials":[{"id":"12345000-0000-4000-8000-000000000013","qty":2,"unitCost":20}]}'::jsonb,'margin',140,200);
do $$ begin
  if not exists(select 1 from public.quotes where id='12345000-0000-4000-8000-000000000031' and details->>'materialCost'='40' and details->>'productType'='Galleta') then raise exception 'Detalle de cotización perdido'; end if;
end $$;
reset role;
rollback;
select 'OK: proveedores, materiales y tipo de postre; datos de prueba deshechos' as resultado;
