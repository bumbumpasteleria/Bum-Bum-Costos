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
do $$ declare original jsonb; result jsonb; lineas jsonb; before_state text; begin
 select to_jsonb(r)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=r.id)) into original from public.recipes r where r.id='12348000-0000-4000-8000-000000000031';
 lineas:=original->'lines';
 result:=public.actualizar_receta_preparacion_bum_bum('12348000-0000-4000-8000-000000000031','EDIT ORIGINAL',12,'unidad','scalable',lineas,'Galleta','12348000-0000-4000-8000-000000000021',original,E'1. Mezclar.\n2. Hornear.');
 if (result->>'instructions')::jsonb->>'preparation' is distinct from E'1. Mezclar.\n2. Hornear.' or (result->>'instructions')::jsonb->>'custom'<>'conservar' then raise exception 'Texto o metadatos perdidos'; end if;
 if (select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id='12348000-0000-4000-8000-000000000031') is distinct from lineas then raise exception 'Líneas alteradas'; end if;
 before_state:=result->>'instructions';
 begin
  perform public.actualizar_receta_preparacion_bum_bum('12348000-0000-4000-8000-000000000031','EDIT ORIGINAL',12,'unidad','scalable',lineas,'Galleta','12348000-0000-4000-8000-000000000021',original,'Pisada');raise exception 'STALE_ACCEPTED';
 exception when others then if SQLERRM not like 'La receta cambió%' then raise; end if; end;
 select to_jsonb(r)||jsonb_build_object('lines',lineas) into original from public.recipes r where r.id='12348000-0000-4000-8000-000000000031';
 begin
  perform public.actualizar_receta_preparacion_bum_bum('12348000-0000-4000-8000-000000000031','EDIT ORIGINAL',12,'unidad','scalable',lineas,'Galleta','12348000-0000-4000-8000-000000000021',original,repeat('x',20001));raise exception 'LIMIT_ACCEPTED';
 exception when others then if SQLERRM not like 'La preparación debe%' then raise; end if; end;
 if (select instructions from public.recipes where id='12348000-0000-4000-8000-000000000031') is distinct from before_state then raise exception 'Error cambió receta'; end if;
 result:=public.actualizar_receta_preparacion_bum_bum('12348000-0000-4000-8000-000000000031','EDIT ORIGINAL',12,'unidad','scalable',lineas,'Galleta','12348000-0000-4000-8000-000000000021',original,'');
 if (result->>'instructions')::jsonb->>'preparation' is distinct from '' then raise exception 'Vacío no guardado'; end if;
 update public.recipes set instructions=E'Preparación antigua\nSin JSON' where id='12348000-0000-4000-8000-000000000031';
 select to_jsonb(r)||jsonb_build_object('lines',lineas) into original from public.recipes r where r.id='12348000-0000-4000-8000-000000000031';
 result:=public.actualizar_receta_preparacion_bum_bum('12348000-0000-4000-8000-000000000031','EDIT ORIGINAL',12,'unidad','scalable',lineas,'Galleta','12348000-0000-4000-8000-000000000021',original,'Nueva preparación');
 if (result->>'instructions')::jsonb->>'legacyInstructions' is distinct from E'Preparación antigua\nSin JSON' then raise exception 'Texto antiguo perdido'; end if;
 if not exists(select 1 from public.quotes where id='12348000-0000-4000-8000-000000000041' and total_cost=50 and quoted_price=100) then raise exception 'Histórico modificado'; end if;
 if not exists(select 1 from public.ingredients where id='12348000-0000-4000-8000-000000000011' and stock_quantity=1000 and last_unit_cost=0.2) then raise exception 'Stock o precio modificado'; end if;
end $$;
set local request.jwt.claim.sub='12348000-0000-4000-8000-000000000002';
do $$ begin
 begin
 perform public.actualizar_receta_preparacion_bum_bum('12348000-0000-4000-8000-000000000031','AJENA',12,'unidad','scalable','[]','Galleta','12348000-0000-4000-8000-000000000022','{}','AJENA'); raise exception 'FOREIGN_ACCEPTED';
 exception when others then if SQLERRM not like 'Receta no disponible%' then raise; end if; end;
end $$;
reset role;
do $$ begin
 if has_function_privilege('anon','public.actualizar_receta_preparacion_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,jsonb,text)','EXECUTE') then raise exception 'Anónimo habilitado'; end if;
end $$;
rollback;
select 'OK: preparación, concurrencia, aislamiento, histórico y texto antiguo; prueba deshecha' as resultado;
