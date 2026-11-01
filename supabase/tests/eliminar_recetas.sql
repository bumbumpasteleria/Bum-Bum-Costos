begin;
-- Run with the migration inside BEGIN and replace its COMMIT with these tests.
-- Synthetic fixtures only. No real recipes are edited.
insert into auth.users(id,email) values
 ('12348000-0000-4000-8000-000000000001','edit-a@example.invalid'),
 ('12348000-0000-4000-8000-000000000002','edit-b@example.invalid');
update public.business_profiles set status='approved',password_required=false
 where id in ('12348000-0000-4000-8000-000000000001','12348000-0000-4000-8000-000000000002');
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity) values
 ('12348000-0000-4000-8000-000000000011','12348000-0000-4000-8000-000000000001','EDIT HARINA','g',0.2,1000),
 ('12348000-0000-4000-8000-000000000012','12348000-0000-4000-8000-000000000001','EDIT AZUCAR','g',0.3,500),
 ('12348000-0000-4000-8000-000000000013','12348000-0000-4000-8000-000000000002','EDIT AJENO','g',1,100);
insert into public.recipe_books(id,owner_id,name,usage) values
 ('12348000-0000-4000-8000-000000000021','12348000-0000-4000-8000-000000000001','EDIT ENCARGOS','orders'),
 ('12348000-0000-4000-8000-000000000022','12348000-0000-4000-8000-000000000002','EDIT AJENO','orders');
set local role authenticated;
set local request.jwt.claim.sub='12348000-0000-4000-8000-000000000001';
select public.guardar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT ORIGINAL',12,'unidad','scalable',
 '[{"ingredient_id":"12348000-0000-4000-8000-000000000011","quantity_base":250}]'::jsonb,'Galleta','12348000-0000-4000-8000-000000000021');
update public.recipes set instructions='{"bumBum":1,"scaling":"scalable","productType":"Galleta","custom":"conservar"}' where id='12348000-0000-4000-8000-000000000031';
insert into public.quotes(id,owner_id,details,total_cost,quoted_price,pricing_method) values
 ('12348000-0000-4000-8000-000000000041',auth.uid(),'{"recipeName":"EDIT ORIGINAL"}',50,100,'markup');
set local request.jwt.claim.sub='12348000-0000-4000-8000-000000000002';
do $$ declare removed uuid; begin
 delete from public.recipes where id='12348000-0000-4000-8000-000000000031' returning id into removed;
 if removed is not null then raise exception 'Borrado de receta ajena permitido'; end if;
end $$;
set local request.jwt.claim.sub='12348000-0000-4000-8000-000000000001';
do $$ declare removed uuid; begin
 if not exists(select 1 from public.recipes where id='12348000-0000-4000-8000-000000000031') then raise exception 'Receta ajena no se conservó'; end if;
 delete from public.recipes where id='12348000-0000-4000-8000-000000000031' and owner_id=auth.uid() returning id into removed;
 if removed is distinct from '12348000-0000-4000-8000-000000000031'::uuid then raise exception 'No eliminó receta propia'; end if;
 if exists(select 1 from public.recipe_lines where recipe_id=removed) then raise exception 'Líneas huérfanas'; end if;
 if not exists(select 1 from public.quotes where id='12348000-0000-4000-8000-000000000041' and quoted_price=100 and total_cost=50) then raise exception 'Histórico borrado'; end if;
 if not exists(select 1 from public.ingredients where id='12348000-0000-4000-8000-000000000011' and stock_quantity=1000 and last_unit_cost=0.2) then raise exception 'Ingrediente modificado'; end if;
 if not exists(select 1 from public.recipe_books where id='12348000-0000-4000-8000-000000000021') then raise exception 'Recetario borrado'; end if;
end $$;
reset role;
rollback;
select 'OK: receta propia y líneas eliminadas; catálogo, recetario e histórico conservados; cuenta ajena bloqueada; prueba deshecha' as resultado;
