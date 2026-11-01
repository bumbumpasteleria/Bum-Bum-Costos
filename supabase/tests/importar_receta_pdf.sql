-- Execute after the migration in a test transaction. Always ROLLBACK.
begin;
insert into auth.users(id,email) values
 ('12349000-0000-4000-8000-000000000001','pdf-a@example.invalid'),
 ('12349000-0000-4000-8000-000000000002','pdf-b@example.invalid');
update public.business_profiles set status='approved',password_required=false where id in ('12349000-0000-4000-8000-000000000001','12349000-0000-4000-8000-000000000002');
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity) values
 ('12349000-0000-4000-8000-000000000011','12349000-0000-4000-8000-000000000001','PDF HARINA','g',0.2,1000),
 ('12349000-0000-4000-8000-000000000012','12349000-0000-4000-8000-000000000002','PDF AJENO','g',1,100);
insert into public.recipe_books(id,owner_id,name,usage) values ('12349000-0000-4000-8000-000000000021','12349000-0000-4000-8000-000000000001','PDF ENCARGOS','orders');
set local role authenticated;
set local request.jwt.claim.sub='12349000-0000-4000-8000-000000000001';
do $$ declare r jsonb; failed boolean:=false; begin
 r:=public.guardar_receta_importada_bum_bum('12349000-0000-4000-8000-000000000031','PDF GALLETAS',12,'unidad','scalable','[{"ingredient_id":"12349000-0000-4000-8000-000000000011","quantity_base":250}]','Galleta','12349000-0000-4000-8000-000000000021',E'Mezclar.\nHornear.');
 if r->>'owner_id'<>'12349000-0000-4000-8000-000000000001' or (r->>'instructions')::jsonb->>'preparation' is distinct from E'Mezclar.\nHornear.' or jsonb_array_length(r->'recipe_lines')<>1 then raise exception 'Incomplete import'; end if;
 begin
 perform public.guardar_receta_importada_bum_bum('12349000-0000-4000-8000-000000000031','REPLACEMENT',12,'unidad','scalable','[]','Galleta','12349000-0000-4000-8000-000000000021','');
 exception when others then failed:=true; end;
 if not failed then raise exception 'Duplicate accepted'; end if;
 failed:=false;
 begin
 perform public.guardar_receta_importada_bum_bum('12349000-0000-4000-8000-000000000032','FOREIGN INGREDIENT',12,'unidad','scalable','[{"ingredient_id":"12349000-0000-4000-8000-000000000012","quantity_base":20}]','Galleta','12349000-0000-4000-8000-000000000021','');
 exception when others then failed:=true; end;
 if not failed or exists(select 1 from public.recipes where id='12349000-0000-4000-8000-000000000032') then raise exception 'Foreign accepted or partial import'; end if;
 if not exists(select 1 from public.ingredients where id='12349000-0000-4000-8000-000000000011' and stock_quantity=1000 and last_unit_cost=0.2) then raise exception 'Catalog changed'; end if;
end $$;
set local request.jwt.claim.sub='12349000-0000-4000-8000-000000000002';
do $$ begin
 if exists(select 1 from public.recipes where id='12349000-0000-4000-8000-000000000031') then raise exception 'Other account sees recipe'; end if;
end $$;
reset role;
do $$ begin
 if has_function_privilege('anon','public.guardar_receta_importada_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,text)','EXECUTE') then raise exception 'Anonymous execution enabled'; end if;
end $$;
rollback;
