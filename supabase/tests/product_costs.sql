reset role;
set local role authenticated;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000001';
do $$ declare d jsonb;r jsonb;failed boolean:=false;begin
 d:='{"recipeId":"12360000-0000-4000-8000-000000000033","recipeName":"GRAMOS EQUIV","quantity":1,"laborMode":"fixed","labor":100,"hours":1,"extra":{"pack":10,"fill":0,"delivery":0,"other":5},"totalCost":155,"produced":12,"unitCost":12.91666667,"yieldUnit":"porción"}';
 r:=public.bum_save_entry('12360000-0000-4000-8000-000000000083','product_cost',d,0);
 if r->>'kind'<>'product_cost' or (r->'details'->>'totalCost')::numeric<>155 then raise exception 'Final product cost was not saved';end if;
 r:=public.bum_save_entry('12360000-0000-4000-8000-000000000083','product_cost',d||'{"labor":120,"totalCost":175}',1);
 if not exists(select 1 from public.business_entry_history where entry_id='12360000-0000-4000-8000-000000000083' and kind='product_cost' and (details->>'totalCost')::numeric=155) then raise exception 'Product cost history missing';end if;
 begin perform public.bum_save_entry('12360000-0000-4000-8000-000000000084','product_cost',d,0);exception when others then failed:=true;end;if not failed then raise exception 'Duplicate final-cost sheets accepted';end if;
 perform public.bum_save_entry('12360000-0000-4000-8000-000000000033','recipe_info','{"notes":"Ficha de receta conservada","allergens":"","storage":"","photo":""}',0);
 perform set_config('bum.test_cost_backup',public.bum_export_backup()::text,true);
end $$;
reset role;
delete from public.business_entries where id='12360000-0000-4000-8000-000000000083';
set local role authenticated;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000001';
do $$ begin
 perform public.bum_restore_backup('12360000-0000-4000-8000-000000000073',current_setting('bum.test_cost_backup')::jsonb);
 if not exists(select 1 from public.business_entries where id='12360000-0000-4000-8000-000000000083' and kind='product_cost' and (details->>'totalCost')::numeric=175) then raise exception 'Product cost backup failed';end if;
end $$;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false;begin
 begin perform public.bum_save_entry('12360000-0000-4000-8000-000000000085','product_cost','{"recipeId":"12360000-0000-4000-8000-000000000033","recipeName":"Ajena","quantity":1,"laborMode":"fixed","labor":0,"hours":1,"extra":{},"totalCost":0,"produced":1,"unitCost":0,"yieldUnit":"unidad"}',0);exception when others then failed:=true;end;if not failed then raise exception 'Foreign recipe cost sheet accepted';end if;
end $$;
reset role;
rollback;
select 'OK: recetarios, gramos, inventario, costos finales privados, historial y respaldo; todo revertido' as resultado;
