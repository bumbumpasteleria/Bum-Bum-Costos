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
reset role;
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity,item_kind) values ('12360000-0000-4000-8000-000000000012','12360000-0000-4000-8000-000000000001','MATERIAL CAJA','unit',2,100,'material');
set local role authenticated;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000001';
do $$ declare r jsonb;failed boolean:=false;begin
 r:=public.bum_save_entry(auth.uid(),'quote_brand','{"businessName":"Negocio de ejemplo","phone":"Contacto ficticio","location":"Ubicación ficticia","website":"","color":"#225577","logo":""}',0);
 if r->'details'->>'color'<>'#225577' then raise exception 'Brand color not saved';end if;
 begin perform public.bum_save_entry('12360000-0000-4000-8000-000000000002','quote_brand',r->'details',0);exception when others then failed:=true;end;
 if not failed then raise exception 'Brand owner not enforced';end if;
 failed:=false;begin perform public.bum_save_entry(auth.uid(),'quote_brand',(r->'details')||'{"color":"not-a-color"}',1);exception when others then failed:=true;end;
 if not failed then raise exception 'Invalid color accepted';end if;
 perform public.bum_save_entry('12360000-0000-4000-8000-000000000081','expense','{"date":"2026-11-02","amount":5,"description":"Gasto de prueba","category":"Otros","channel":"General"}',0);
end $$;
do $$ declare r jsonb;original jsonb;lines jsonb;prices jsonb;backup jsonb;day date:=(now() at time zone 'America/Santo_Domingo')::date;failed boolean:=false;begin
 lines:='[{"ingredient_id":"12360000-0000-4000-8000-000000000011","quantity_base":250},{"ingredient_id":"12360000-0000-4000-8000-000000000012","quantity_base":12}]';
 perform public.guardar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000031','MATERIAL RECETA',12,'unidad','scalable',lines,'Tres leches','12360000-0000-4000-8000-000000000021','','Postres');
 if (select count(*) from public.recipe_lines where recipe_id='12360000-0000-4000-8000-000000000031')<>2 then raise exception 'Material not saved in recipe';end if;
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original from public.recipes rec where id='12360000-0000-4000-8000-000000000031';
 select jsonb_agg(jsonb_build_object('id',id,'ingredient_id',ingredient_id,'quantity_base',quantity_base)) into lines from public.recipe_lines where recipe_id='12360000-0000-4000-8000-000000000031';
 perform public.actualizar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000031','MATERIAL EDITADA',12,'unidad','scalable',lines,'Tres leches','12360000-0000-4000-8000-000000000021',original,'Mezclar','Postres');
 perform public.bum_fridge_priced_product('12360000-0000-4000-8000-000000000041','12360000-0000-4000-8000-000000000031','porción',3,50,null);
 r:=public.bum_fridge_production('12360000-0000-4000-8000-000000000051','12360000-0000-4000-8000-000000000041',12,1,day,day+2);
 if abs((r->>'unit_cost')::numeric-74.0/12)>0.000001 then raise exception 'Lot excludes material cost';end if;
 prices:='{"PedidosYa":{"baseCost":6.166667,"packaging":1,"labor":2,"other":0.5,"commission":30,"margin":20,"price":19.34}}';
 r:=public.bum_fridge_channel_prices('12360000-0000-4000-8000-000000000041','{}',prices);
 perform public.bum_fridge_channel_prices('12360000-0000-4000-8000-000000000041','{}',prices);
 if (r->'channel_prices'->'PedidosYa'->>'commission')::numeric<>30 then raise exception 'Channel fees not saved';end if;
 failed:=false;begin perform public.bum_fridge_channel_prices('12360000-0000-4000-8000-000000000041','{}',jsonb_set(prices,'{PedidosYa,price}','20'));exception when others then failed:=true;end;if not failed then raise exception 'Stale channel overwrite';end if;
 failed:=false;begin perform public.bum_fridge_channel_prices('12360000-0000-4000-8000-000000000041',prices,jsonb_set(prices,'{PedidosYa,commission}','80'));exception when others then failed:=true;end;if not failed then raise exception 'Impossible commission and margin';end if;
 r:=public.bum_fridge_priced_sale(jsonb_build_object('id','12360000-0000-4000-8000-000000000061','fridgeProductId','12360000-0000-4000-8000-000000000041','fridgeQuantity',3,'unitPrice',19.34,'date',day,'channel','PedidosYa','commission',30,'extra',10.5));
 if (r->>'gross_amount')::numeric<>58.02 or abs((r->>'cost_amount')::numeric-29)>0.000001 then raise exception 'Sale omitted recipe materials or channel extras';end if;
 -- A recipe without fridge references can be recovered with its material lines.
 lines:='[{"ingredient_id":"12360000-0000-4000-8000-000000000012","quantity_base":1}]';
 perform public.guardar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000032','MATERIAL RESPALDO',1,'unidad','scalable',lines,'Otro artículo','12360000-0000-4000-8000-000000000021','','Postres');
 backup:=public.bum_export_backup();delete from public.recipes where id='12360000-0000-4000-8000-000000000032';
 perform public.bum_restore_backup('12360000-0000-4000-8000-000000000071',backup);
 if not exists(select 1 from public.recipe_lines where recipe_id='12360000-0000-4000-8000-000000000032' and ingredient_id='12360000-0000-4000-8000-000000000012') then raise exception 'Material backup rejected';end if;
end $$;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false;begin
 if exists(select 1 from public.recipe_lines) or exists(select 1 from public.fridge_products) then raise exception 'Account isolation failed';end if;
 begin perform public.bum_fridge_channel_prices('12360000-0000-4000-8000-000000000041','{}','{}');exception when others then failed:=true;end;if not failed then raise exception 'Foreign prices changed';end if;
end $$;
reset role;
do $$ begin if has_function_privilege('anon','public.bum_fridge_channel_prices(uuid,jsonb,jsonb)','execute') then raise exception 'Anonymous access';end if;end $$;
rollback;
select 'OK: recipe materials, editing, production costs, channel prices, commissions, backups and account isolation; all reverted' as resultado;
