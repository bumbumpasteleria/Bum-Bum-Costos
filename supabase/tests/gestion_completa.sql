-- Replace the migration's COMMIT with this test. All fixtures and schema changes roll back.
insert into auth.users(id,email) values
 ('12380000-0000-4000-8000-000000000001','complete-a@example.invalid'),
 ('12380000-0000-4000-8000-000000000002','complete-b@example.invalid'),
 ('12380000-0000-4000-8000-000000000003','complete-pending@example.invalid');
update public.business_profiles set status='approved',password_required=false where id in ('12380000-0000-4000-8000-000000000001','12380000-0000-4000-8000-000000000002');
savepoint fixture;
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity,minimum_stock,item_kind,supplier) values
 ('12380000-0000-4000-8000-000000000011','12380000-0000-4000-8000-000000000001','COMPLETE HARINA','g',0.2,1000,100,'ingredient','Prueba');
insert into public.recipe_books(id,owner_id,name,usage) values('12380000-0000-4000-8000-000000000021','12380000-0000-4000-8000-000000000001','COMPLETE ENCARGOS','orders');
insert into public.recipes(id,owner_id,name,recipe_book_id,yield_quantity,yield_unit,instructions) values('12380000-0000-4000-8000-000000000031','12380000-0000-4000-8000-000000000001','COMPLETE ORIGINAL','12380000-0000-4000-8000-000000000021',12,'unidad','{"bumBum":1,"scaling":"scalable","productType":"Galleta","preparation":"Mezclar","category":"Postres"}');
insert into public.recipe_lines(id,owner_id,recipe_id,ingredient_id,quantity_base) values('12380000-0000-4000-8000-000000000041','12380000-0000-4000-8000-000000000001','12380000-0000-4000-8000-000000000031','12380000-0000-4000-8000-000000000011',250);
release savepoint fixture;
set local role authenticated;
set local request.jwt.claim.sub='12380000-0000-4000-8000-000000000001';
-- Unit choices round-trip without changing the base quantity or cost.
do $$ declare original jsonb;lines jsonb;begin
 insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity,item_kind,purchase_unit,purchase_quantity,purchase_price) values('12380000-0000-4000-8000-000000000012',auth.uid(),'COMPLETE LIQUIDO','ml',0.1,3785.411784,'ingredient','gal US',1,378.5411784);
 update public.ingredients set purchase_unit='kg',purchase_quantity=1,purchase_price=200 where id='12380000-0000-4000-8000-000000000011';
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original from public.recipes rec where id='12380000-0000-4000-8000-000000000031';
 lines:='[{"id":"12380000-0000-4000-8000-000000000041","ingredient_id":"12380000-0000-4000-8000-000000000011","quantity_base":250}]';
 perform public.actualizar_receta_organizada_bum_bum('12380000-0000-4000-8000-000000000031','COMPLETE ORIGINAL',1,'gal US','scalable',lines,'Galleta','12380000-0000-4000-8000-000000000021',original,'Mezclar','Postres');
 if (select yield_unit from public.recipes where id='12380000-0000-4000-8000-000000000031')<>'gal US' then raise exception 'Gallon yield rejected';end if;
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original from public.recipes rec where id='12380000-0000-4000-8000-000000000031';
 perform public.actualizar_receta_organizada_bum_bum('12380000-0000-4000-8000-000000000031','COMPLETE ORIGINAL',12,'unidad','scalable',lines,'Galleta','12380000-0000-4000-8000-000000000021',original,'Mezclar','Postres');
 if abs((select stock_quantity from public.ingredients where id='12380000-0000-4000-8000-000000000012')-3785.411784)>0.0005 then raise exception 'Gallon stock changed';end if;
end $$;
do $$ declare r jsonb;d jsonb;backup jsonb;broken jsonb;original jsonb;lines jsonb;v uuid;failed boolean:=false;date_text text:=(now() at time zone 'America/Santo_Domingo')::date::text;t text;begin
 d:=jsonb_build_object('date',date_text,'amount',100,'description','Servicios','category','Servicios','channel','General');
 r:=public.bum_save_entry('12380000-0000-4000-8000-000000000051','expense',d,0);
 r:=public.bum_save_entry('12380000-0000-4000-8000-000000000051','expense',d,0);
 if (r->>'version')::integer<>1 then raise exception 'Retry duplicated expense';end if;
 perform public.bum_save_entry('12380000-0000-4000-8000-000000000051','expense',d||'{"amount":120}',1);
 begin perform public.bum_save_entry('12380000-0000-4000-8000-000000000051','expense',d||'{"amount":150}',1);exception when others then failed:=true;end;
 if not failed or (select count(*) from public.business_entry_history)<>1 then raise exception 'Expense conflict/history failed';end if;
 failed:=false;begin perform public.bum_save_entry('12380000-0000-4000-8000-000000000052','expense',d||'{"amount":-1}',0);exception when others then failed:=true;end;
 if not failed then raise exception 'Negative expense accepted';end if;
 d:=jsonb_build_object('customer','Cliente de prueba','contact','','description','Encargo de prueba','deliveryDate',date_text,'total',200,'deposit',50,'status','pending','recipeId','12380000-0000-4000-8000-000000000031','notes','');
 perform public.bum_save_entry('12380000-0000-4000-8000-000000000061','order',d,0);
 failed:=false;begin perform public.bum_save_entry('12380000-0000-4000-8000-000000000062','order',d||'{"deposit":201}',0);exception when others then failed:=true;end;
 if not failed then raise exception 'Invalid deposit accepted';end if;
 perform public.bum_save_entry('12380000-0000-4000-8000-000000000031','recipe_info','{"notes":"Ficha privada","allergens":"Declarados por usuario","storage":"Indicación propia","photo":""}',0);
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original from public.recipes rec where id='12380000-0000-4000-8000-000000000031';
 lines:='[{"id":"12380000-0000-4000-8000-000000000041","ingredient_id":"12380000-0000-4000-8000-000000000011","quantity_base":100}]';
 perform public.actualizar_receta_organizada_bum_bum('12380000-0000-4000-8000-000000000031','COMPLETE EDITADA',12,'unidad','scalable',lines,'Galleta','12380000-0000-4000-8000-000000000021',original,'Nuevos pasos','Masas');
 select id into v from public.recipe_versions where recipe_id='12380000-0000-4000-8000-000000000031';
 if v is null or (select snapshot->>'name' from public.recipe_versions where id=v)<>'COMPLETE ORIGINAL' then raise exception 'Original version not captured';end if;
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original from public.recipes rec where id='12380000-0000-4000-8000-000000000031';
 perform public.bum_restore_recipe_version(v,original);
 if (select name from public.recipes where id='12380000-0000-4000-8000-000000000031')<>'COMPLETE ORIGINAL' or (select quantity_base from public.recipe_lines where id='12380000-0000-4000-8000-000000000041')<>250 then raise exception 'Version restore failed';end if;
 backup:=public.bum_export_backup();
 if backup->>'owner'<>'12380000-0000-4000-8000-000000000001' or backup->>'version'<>'2' then raise exception 'Wrong backup envelope';end if;
 for t in select jsonb_object_keys(backup->'data') loop
  if exists(select 1 from jsonb_array_elements(backup->'data'->t) item where item->>'owner_id'<>'12380000-0000-4000-8000-000000000001') then raise exception 'Backup leaked another account';end if;
 end loop;
 r:=public.bum_restore_backup('12380000-0000-4000-8000-000000000071',backup);
 if (r->>'inserted')::integer<>0 then raise exception 'Existing rows overwritten';end if;
 delete from public.recipes where id='12380000-0000-4000-8000-000000000031';
 r:=public.bum_restore_backup('12380000-0000-4000-8000-000000000072',backup);
 if (r->>'inserted')::integer<>2 or (select count(*) from public.recipe_lines where recipe_id='12380000-0000-4000-8000-000000000031')<>1 then raise exception 'Missing recipe/lines not restored';end if;
 r:=public.bum_restore_backup('12380000-0000-4000-8000-000000000072',backup);
 if (r->>'inserted')::integer<>2 then raise exception 'Restore retry not idempotent';end if;
 delete from public.recipes where id='12380000-0000-4000-8000-000000000031';
 broken:=jsonb_set(backup,'{data,recipe_lines,0,ingredient_id}','"12380000-0000-4000-8000-000000009999"');
 failed:=false;begin perform public.bum_restore_backup('12380000-0000-4000-8000-000000000073',broken);exception when others then failed:=true;end;
 if not failed or exists(select 1 from public.recipes where id='12380000-0000-4000-8000-000000000031') then raise exception 'Restore partially committed';end if;
 if not exists(select 1 from public.ingredients where id='12380000-0000-4000-8000-000000000011' and stock_quantity=1000 and last_unit_cost=0.2) then raise exception 'Inventory overwritten';end if;
end $$;
set local request.jwt.claim.sub='12380000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false;r jsonb;begin
 if exists(select 1 from public.business_entries) or exists(select 1 from public.recipe_versions) or exists(select 1 from public.business_entry_history) then raise exception 'Cross-account read';end if;
 begin perform public.bum_save_entry('12380000-0000-4000-8000-000000000051','expense','{"date":"2026-11-01","amount":1,"description":"Foreign","category":"Otros","channel":"General"}',0);exception when others then failed:=true;end;
 if not failed then raise exception 'Cross-account overwrite';end if;
 r:=public.bum_save_entry('12380000-0000-4000-8000-000000000081','expense','{"date":"2026-11-01","amount":1,"description":"Own","category":"Otros","channel":"General"}',0);
 if r->>'owner_id'<>'12380000-0000-4000-8000-000000000002' then raise exception 'Second account cannot save';end if;
end $$;
set local request.jwt.claim.sub='12380000-0000-4000-8000-000000000003';
do $$ declare failed boolean:=false;begin begin perform public.bum_export_backup();exception when others then failed:=true;end;if not failed then raise exception 'Pending account exported';end if;end $$;
reset role;
do $$ begin if has_function_privilege('anon','public.bum_export_backup()','execute') or has_table_privilege('authenticated','public.business_entries','update') then raise exception 'Excess permissions';end if;end $$;
rollback;
select 'OK: expenses, orders, versions, backup recovery, retries, rollback and private accounts; all reverted' as resultado;
