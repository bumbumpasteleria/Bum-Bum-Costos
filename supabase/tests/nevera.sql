-- Run after the migration inside its transaction, replacing COMMIT. Everything rolls back.
insert into auth.users(id,email) values
 ('12360000-0000-4000-8000-000000000001','fridge-a@example.invalid'),
 ('12360000-0000-4000-8000-000000000002','fridge-b@example.invalid'),
 ('12360000-0000-4000-8000-000000000003','fridge-pending@example.invalid');
update public.business_profiles set status='approved',password_required=false where id in ('12360000-0000-4000-8000-000000000001','12360000-0000-4000-8000-000000000002');
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity) values ('12360000-0000-4000-8000-000000000011','12360000-0000-4000-8000-000000000001','FRIDGE HARINA','g',0.2,1000);
insert into public.recipe_books(id,owner_id,name,usage) values ('12360000-0000-4000-8000-000000000021','12360000-0000-4000-8000-000000000001','FRIDGE APPS','delivery');
set local role authenticated;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000001';
do $$ declare result jsonb; sale jsonb; before_qty numeric; failed boolean:=false; day date:=(now() at time zone 'America/Santo_Domingo')::date; begin
 perform public.guardar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000031','FRIDGE RECETA',12,'unidad','scalable','[{"ingredient_id":"12360000-0000-4000-8000-000000000011","quantity_base":250}]','Tres leches','12360000-0000-4000-8000-000000000021','','Postres');
 perform public.bum_fridge_product('12360000-0000-4000-8000-000000000041','12360000-0000-4000-8000-000000000031','porción',3);
 perform public.bum_fridge_production('12360000-0000-4000-8000-000000000051','12360000-0000-4000-8000-000000000041',12,1,day,day+2);
 -- Retry must not duplicate stock.
 perform public.bum_fridge_production('12360000-0000-4000-8000-000000000051','12360000-0000-4000-8000-000000000041',12,1,day,day+2);
 if (select sum(remaining_quantity) from public.fridge_batches)<>12 then raise exception 'Production duplicated'; end if;
 -- A second lot expires first and must be consumed first.
 perform public.bum_fridge_production('12360000-0000-4000-8000-000000000052','12360000-0000-4000-8000-000000000041',2,0.5,day,day+1);
 sale:=jsonb_build_object('id','12360000-0000-4000-8000-000000000061','fridgeProductId','12360000-0000-4000-8000-000000000041','fridgeQuantity',3,'date',day,'channel','Directa','gross',100,'commission',0,'extra',0);
 result:=public.bum_fridge_sale(sale);
 if (result->'details'->>'productionCost')::numeric not between 29.1666 and 29.1667 then raise exception 'Lot cost incorrect'; end if;
 if (select remaining_quantity from public.fridge_batches where id='12360000-0000-4000-8000-000000000052')<>0 or (select remaining_quantity from public.fridge_batches where id='12360000-0000-4000-8000-000000000051')<>11 then raise exception 'FEFO incorrect'; end if;
 perform public.bum_fridge_sale(sale);
 if (select sum(remaining_quantity) from public.fridge_batches)<>11 then raise exception 'Sale retry double-decremented'; end if;
 begin perform public.bum_fridge_sale(sale||jsonb_build_object('id','12360000-0000-4000-8000-000000000062','fridgeQuantity',99));exception when others then failed:=true;end;
 if not failed or exists(select 1 from public.sales where id='12360000-0000-4000-8000-000000000062') or (select sum(remaining_quantity) from public.fridge_batches)<>11 then raise exception 'Oversell was not atomic'; end if;
 perform public.bum_fridge_adjust('12360000-0000-4000-8000-000000000071','12360000-0000-4000-8000-000000000051',11,3,'Consumo propio');
 perform public.bum_fridge_adjust('12360000-0000-4000-8000-000000000071','12360000-0000-4000-8000-000000000051',11,3,'Consumo propio');
 failed:=false;begin perform public.bum_fridge_adjust('12360000-0000-4000-8000-000000000072','12360000-0000-4000-8000-000000000051',11,1,'Stale');exception when others then failed:=true;end;
 if not failed then raise exception 'Stale adjustment accepted';end if;
 if not exists(select 1 from public.ingredients where id='12360000-0000-4000-8000-000000000011' and stock_quantity=1000 and last_unit_cost=0.2) then raise exception 'Catalog changed';end if;
end $$;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false;begin
 if exists(select 1 from public.fridge_products) or exists(select 1 from public.fridge_batches) or exists(select 1 from public.fridge_movements) then raise exception 'Cross-account read';end if;
 begin perform public.bum_fridge_adjust('12360000-0000-4000-8000-000000000073','12360000-0000-4000-8000-000000000051',3,1,'Foreign');exception when others then failed:=true;end;
 if not failed then raise exception 'Cross-account update';end if;
 failed:=false;begin perform public.bum_fridge_product('12360000-0000-4000-8000-000000000042','12360000-0000-4000-8000-000000000031','porción',0);exception when others then failed:=true;end;
 if not failed then raise exception 'Foreign recipe allowed';end if;
end $$;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000003';
do $$ declare failed boolean:=false;begin
 begin perform public.bum_fridge_sale('{}');exception when others then failed:=true;end;
 if not failed then raise exception 'Pending account mutation';end if;
end $$;
reset role;
do $$ begin
 if has_function_privilege('anon','public.bum_fridge_sale(jsonb)','execute') or has_table_privilege('authenticated','public.fridge_batches','update') then raise exception 'Excess grants';end if;
end $$;
rollback;
select 'OK: production, sale costs, retries, oversell rollback, adjustments and private accounts; all reverted' as resultado;
