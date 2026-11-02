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
do $$ declare r jsonb;s jsonb;original jsonb;day date:=(now() at time zone 'America/Santo_Domingo')::date;failed boolean:=false;begin
 perform public.guardar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000031','PRICE RECETA',12,'unidad','scalable','[{"ingredient_id":"12360000-0000-4000-8000-000000000011","quantity_base":250}]','Tres leches','12360000-0000-4000-8000-000000000021','','Postres');
 r:=public.bum_fridge_priced_product('12360000-0000-4000-8000-000000000041','12360000-0000-4000-8000-000000000031','porción',3,50,null);
 if (r->>'sale_price')::numeric<>50 then raise exception 'Product price not saved';end if;
 original:=jsonb_build_object('sale_price',50,'minimum_quantity',3);
 r:=public.bum_fridge_priced_product('12360000-0000-4000-8000-000000000041','12360000-0000-4000-8000-000000000031','porción',3,50,null);
 perform public.bum_fridge_production('12360000-0000-4000-8000-000000000051','12360000-0000-4000-8000-000000000041',12,1,day,day+2);
 s:=jsonb_build_object('id','12360000-0000-4000-8000-000000000061','fridgeProductId','12360000-0000-4000-8000-000000000041','fridgeQuantity',3,'unitPrice',50,'date',day,'channel','Directa','gross',999,'commission',10,'extra',5);
 r:=public.bum_fridge_priced_sale(s);
 if (r->>'gross_amount')::numeric<>150 or (r->'details'->>'unitPrice')::numeric<>50 or (select remaining_quantity from public.fridge_batches where id='12360000-0000-4000-8000-000000000051')<>9 then raise exception 'Automatic total or stock incorrect';end if;
 perform public.bum_fridge_priced_sale(s);
 if (select remaining_quantity from public.fridge_batches where id='12360000-0000-4000-8000-000000000051')<>9 then raise exception 'Sale retry duplicated';end if;
 perform public.bum_fridge_priced_product('12360000-0000-4000-8000-000000000041','12360000-0000-4000-8000-000000000031','porción',3,60,original);
 if (select gross_amount from public.sales where id='12360000-0000-4000-8000-000000000061')<>150 then raise exception 'Historical sale changed';end if;
 begin perform public.bum_fridge_priced_product('12360000-0000-4000-8000-000000000041','12360000-0000-4000-8000-000000000031','porción',3,70,original);exception when others then failed:=true;end;
 if not failed then raise exception 'Stale price overwritten';end if;
 failed:=false;begin perform public.bum_fridge_priced_sale(s||'{"unitPrice":-1}');exception when others then failed:=true;end;if not failed then raise exception 'Negative accepted';end if;
 failed:=false;begin perform public.bum_fridge_priced_sale(s||'{"fridgeQuantity":1.1234}');exception when others then failed:=true;end;if not failed then raise exception 'Quantity precision accepted';end if;
 r:=public.bum_fridge_priced_sale(s||'{"id":"12360000-0000-4000-8000-000000000062","fridgeQuantity":0.5,"unitPrice":75.25}');
 if (r->>'gross_amount')::numeric<>37.63 or (select sale_price from public.fridge_products where id='12360000-0000-4000-8000-000000000041')<>60 then raise exception 'Sale override or rounding failed';end if;
 failed:=false;begin perform public.bum_fridge_priced_sale(s||'{"id":"12360000-0000-4000-8000-000000000063","fridgeQuantity":100}');exception when others then failed:=true;end;
 if not failed or exists(select 1 from public.sales where id='12360000-0000-4000-8000-000000000063') or (select remaining_quantity from public.fridge_batches where id='12360000-0000-4000-8000-000000000051')<>8.5 then raise exception 'Insufficient stock partially committed';end if;
end $$;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false;begin
 if exists(select 1 from public.fridge_products) then raise exception 'Foreign price leaked';end if;
 begin perform public.bum_fridge_priced_product('12360000-0000-4000-8000-000000000041','12360000-0000-4000-8000-000000000031','porción',3,1,null);exception when others then failed:=true;end;
 if not failed then raise exception 'Foreign price changed';end if;
end $$;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000003';
do $$ declare failed boolean:=false;begin
 begin perform public.bum_fridge_priced_sale('{}');exception when others then failed:=true;end;if not failed then raise exception 'Unapproved account accepted';end if;
end $$;
reset role;
do $$ begin if has_function_privilege('anon','public.bum_fridge_priced_sale(jsonb)','execute') then raise exception 'Anonymous access';end if;end $$;
rollback;
select 'OK: product prices, automatic totals, stock, retries, conflicts and account isolation; all reverted' as resultado;
