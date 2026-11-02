-- Append to the material/channel trial before its final ROLLBACK.
reset role;
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity,grams_per_base_unit) values
 ('12360000-0000-4000-8000-000000000013','12360000-0000-4000-8000-000000000001','EQUIV HUEVO','unit',10,12,50),
 ('12360000-0000-4000-8000-000000000014','12360000-0000-4000-8000-000000000001','EQUIV LECHE','ml',0.1,1000,1.03);
set local role authenticated;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000001';
do $$ declare r jsonb;lines jsonb;original jsonb;failed boolean;d date:=(now() at time zone 'America/Santo_Domingo')::date;backup jsonb;begin
 lines:='[{"ingredient_id":"12360000-0000-4000-8000-000000000013","quantity_base":999,"measurement_quantity":100,"measurement_unit":"g"},{"ingredient_id":"12360000-0000-4000-8000-000000000014","quantity_base":999,"measurement_quantity":103,"measurement_unit":"g"}]';
 r:=public.guardar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000033','GRAMOS EQUIV',12,'porción','scalable',lines,'Flan','12360000-0000-4000-8000-000000000021','','Postres');
 if not exists(select 1 from public.recipe_lines where recipe_id='12360000-0000-4000-8000-000000000033' and ingredient_id='12360000-0000-4000-8000-000000000013' and quantity_base=2 and measurement_quantity=100 and measurement_unit='g') then raise exception 'Grams did not convert to two eggs';end if;
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original from public.recipes rec where id='12360000-0000-4000-8000-000000000033';
 select jsonb_agg(jsonb_build_object('id',id,'ingredient_id',ingredient_id,'quantity_base',quantity_base,'measurement_unit','g','measurement_quantity',case when ingredient_id='12360000-0000-4000-8000-000000000013' then 150 else 103 end)) into lines from public.recipe_lines where recipe_id='12360000-0000-4000-8000-000000000033';
 perform public.actualizar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000033','GRAMOS EQUIV',12,'porción','scalable',lines,'Flan','12360000-0000-4000-8000-000000000021',original,'','Postres');
 if (select quantity_base from public.recipe_lines where recipe_id='12360000-0000-4000-8000-000000000033' and ingredient_id='12360000-0000-4000-8000-000000000013')<>3 then raise exception 'Edited grams not preserved';end if;
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original from public.recipes rec where id='12360000-0000-4000-8000-000000000033';
 update public.recipe_lines set measurement_quantity=0.15,measurement_unit='kg' where recipe_id='12360000-0000-4000-8000-000000000033' and ingredient_id='12360000-0000-4000-8000-000000000013';
 failed:=false;begin perform public.actualizar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000033','GRAMOS EQUIV',12,'porción','scalable',lines,'Flan','12360000-0000-4000-8000-000000000021',original,'','Postres');exception when others then failed:=true;end;if not failed then raise exception 'Stale display-unit edit accepted';end if;
 perform public.bum_fridge_priced_product('12360000-0000-4000-8000-000000000042','12360000-0000-4000-8000-000000000033','porción',3,50,null);
 r:=public.bum_fridge_production('12360000-0000-4000-8000-000000000052','12360000-0000-4000-8000-000000000042',12,0.5,d,d+2);
 if abs((r->>'unit_cost')::numeric-20.0/12)>0.000001 or jsonb_array_length(r->'production_details')<>2 then raise exception 'Converted production cost or consumption missing';end if;
 if (select stock_quantity from public.ingredients where id='12360000-0000-4000-8000-000000000013')<>10.5 or (select stock_quantity from public.ingredients where id='12360000-0000-4000-8000-000000000014')<>950 then raise exception 'Wrong stock deduction';end if;
 perform public.bum_fridge_production('12360000-0000-4000-8000-000000000052','12360000-0000-4000-8000-000000000042',12,0.5,d,d+2);
 if (select stock_quantity from public.ingredients where id='12360000-0000-4000-8000-000000000013')<>10.5 then raise exception 'Production retry deducted twice';end if;
 update public.ingredients set grams_per_base_unit=60 where id='12360000-0000-4000-8000-000000000013';
 r:=public.bum_fridge_production('12360000-0000-4000-8000-000000000054','12360000-0000-4000-8000-000000000042',12,0.5,d,d+2);
 if (select stock_quantity from public.ingredients where id='12360000-0000-4000-8000-000000000013')<>9.25 or abs((r->>'unit_cost')::numeric-17.5/12)>0.000001 then raise exception 'Production ignored the current weight equivalence';end if;
 update public.ingredients set grams_per_base_unit=50 where id='12360000-0000-4000-8000-000000000013';
 update public.ingredients set stock_quantity=100 where id='12360000-0000-4000-8000-000000000013';update public.ingredients set stock_quantity=1 where id='12360000-0000-4000-8000-000000000014';
 failed:=false;begin perform public.bum_fridge_production('12360000-0000-4000-8000-000000000053','12360000-0000-4000-8000-000000000042',12,1,d,d+2);exception when others then failed:=true;end;
 if not failed or (select stock_quantity from public.ingredients where id='12360000-0000-4000-8000-000000000013')<>100 or exists(select 1 from public.fridge_batches where id='12360000-0000-4000-8000-000000000053') then raise exception 'Insufficient stock did not roll back the whole operation';end if;
 failed:=false;begin perform public.bum_delete_recipe_book('12360000-0000-4000-8000-000000000021','{"name":"FRIDGE APPS","usage":"delivery"}');exception when others then failed:=true;end;if not failed then raise exception 'Nonempty book was deleted';end if;
 insert into public.recipe_books(id,owner_id,name,usage) values('12360000-0000-4000-8000-000000000022',auth.uid(),'VACIO','general');
 if public.bum_delete_recipe_book('12360000-0000-4000-8000-000000000022','{"name":"VACIO","usage":"general"}')<>'12360000-0000-4000-8000-000000000022'::uuid then raise exception 'Empty book delete failed';end if;
 lines:='[{"ingredient_id":"12360000-0000-4000-8000-000000000013","quantity_base":2,"measurement_quantity":100,"measurement_unit":"g"}]';
 perform public.guardar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000034','RESPALDO GRAMOS',1,'unidad','scalable',lines,'Flan','12360000-0000-4000-8000-000000000021','','Postres');backup:=public.bum_export_backup();
 if not exists(select 1 from jsonb_array_elements(backup->'data'->'ingredients') x where x->>'id'='12360000-0000-4000-8000-000000000013' and (x->>'grams_per_base_unit')::numeric=50) then raise exception 'Equivalence missing in backup';end if;
 delete from public.recipes where id='12360000-0000-4000-8000-000000000034';perform public.bum_restore_backup('12360000-0000-4000-8000-000000000072',backup);
 if not exists(select 1 from public.recipe_lines where recipe_id='12360000-0000-4000-8000-000000000034' and measurement_unit='g' and measurement_quantity=100 and quantity_base=2) then raise exception 'Gram recipe backup failed';end if;
end $$;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false;begin
 begin perform public.bum_recipe_base('12360000-0000-4000-8000-000000000013',100,'g','12360000-0000-4000-8000-000000000001');exception when others then failed:=true;end;if not failed then raise exception 'Foreign equivalence access allowed';end if;
end $$;
reset role;
rollback;
select 'OK: gramos, unidades, líquidos, edición, stock atómico, reintentos, recetarios privados y respaldo; todo revertido' as resultado;
