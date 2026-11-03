-- Append inside the migration transaction, without its final COMMIT. Synthetic data only.
insert into auth.users(id,email) values('12370000-0000-4000-8000-000000000001','weights-a@example.invalid'),('12370000-0000-4000-8000-000000000002','weights-b@example.invalid');
update public.business_profiles set status='approved',password_required=false where id in('12370000-0000-4000-8000-000000000001','12370000-0000-4000-8000-000000000002');
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity,grams_per_base_unit,grams_per_white,grams_per_yolk,conversion_reference) values
('12370000-0000-4000-8000-000000000011','12370000-0000-4000-8000-000000000001','HUEVO SINTETICO','unit',10,20,50,33,17,'{"kind":"reference","label":"Referencia sintética"}'),
('12370000-0000-4000-8000-000000000012','12370000-0000-4000-8000-000000000001','LECHE SINTETICA','ml',0.1,1000,1.03,null,null,'{"kind":"reference","label":"Referencia sintética"}');
insert into public.recipe_books(id,owner_id,name,usage) values('12370000-0000-4000-8000-000000000021','12370000-0000-4000-8000-000000000001','LIBRO SINTETICO','orders');
set local role authenticated;
set local request.jwt.claim.sub='12370000-0000-4000-8000-000000000001';
do $$ declare args jsonb;r jsonb;failed boolean:=false;begin
 if public.bum_recipe_base('12370000-0000-4000-8000-000000000011',66,'g clara',auth.uid())<>2 or public.bum_recipe_base('12370000-0000-4000-8000-000000000011',17,'g yema',auth.uid())<>1 or public.bum_recipe_base('12370000-0000-4000-8000-000000000011',2,'clara',auth.uid())<>2 or public.bum_recipe_base('12370000-0000-4000-8000-000000000012',103,'g',auth.uid())<>100 then raise exception 'Equivalencia incorrecta';end if;
 begin perform public.bum_recipe_base('12370000-0000-4000-8000-000000000012',33,'g clara',auth.uid());exception when others then failed:=true;end;if not failed then raise exception 'La leche permitió claras';end if;
 args:='{"p_id":"12370000-0000-4000-8000-000000000031","p_name":"RECETA DE PESOS SINTETICA","p_yield":1,"p_yield_unit":"unidad","p_scaling":"scalable","p_product_type":"Flan","p_book_id":"12370000-0000-4000-8000-000000000021","p_preparation":"Preparación sintética","p_category":"Prueba","p_lines":[{"ingredient_id":"12370000-0000-4000-8000-000000000011","quantity_base":2,"measurement_quantity":66,"measurement_unit":"g clara"},{"ingredient_id":"12370000-0000-4000-8000-000000000011","quantity_base":1,"measurement_quantity":17,"measurement_unit":"g yema"},{"ingredient_id":"12370000-0000-4000-8000-000000000011","quantity_base":1,"measurement_quantity":50,"measurement_unit":"g"},{"ingredient_id":"12370000-0000-4000-8000-000000000012","quantity_base":100,"measurement_quantity":103,"measurement_unit":"g"}]}';
 r:=public.bum_save_staged_recipe(args,'[]',null);
 if (select count(*) from public.recipe_lines where recipe_id='12370000-0000-4000-8000-000000000031' and measurement_unit='g clara')<>1 then raise exception 'No conservó gramos de clara';end if;
 perform public.bum_save_entry('12370000-0000-4000-8000-000000000041','order',jsonb_build_object('customer','Cliente sintético','contact','','description','Encargo sintético','deliveryDate',current_date,'total',100,'deposit',0,'status','pending','recipes',jsonb_build_array(jsonb_build_object('id','12370000-0000-4000-8000-000000000042','recipeId','12370000-0000-4000-8000-000000000031','factor',1,'quantity',1,'leadDays',0)),'photos','[]'::jsonb,'notes',''),0);
 r:=public.bum_work_produce('12370000-0000-4000-8000-000000000043','12370000-0000-4000-8000-000000000042',1);
 if (r->'details'->>'productionCost')::numeric<>40 or (select stock_quantity from public.ingredients where id='12370000-0000-4000-8000-000000000011')<>17 or (select stock_quantity from public.ingredients where id='12370000-0000-4000-8000-000000000012')<>900 then raise exception 'El consumo o costo de huevos y leche no coincide';end if;
 perform public.bum_work_produce('12370000-0000-4000-8000-000000000043','12370000-0000-4000-8000-000000000042',1);
 if (select stock_quantity from public.ingredients where id='12370000-0000-4000-8000-000000000011')<>17 then raise exception 'Reintento descontó dos veces';end if;
end $$;
set local request.jwt.claim.sub='12370000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false;begin
 begin perform public.bum_recipe_base('12370000-0000-4000-8000-000000000011',33,'g clara','12370000-0000-4000-8000-000000000001');exception when others then failed:=true;end;if not failed or exists(select 1 from public.ingredients where id='12370000-0000-4000-8000-000000000011') then raise exception 'Conversión o lectura entre cuentas';end if;
end $$;
reset role;
do $$ begin if has_function_privilege('anon','public.bum_recipe_base(uuid,numeric,text,uuid)','execute') or has_function_privilege('authenticated','public.bum_recipe_components(uuid,uuid)','execute') then raise exception 'Permisos ampliados';end if;end $$;
rollback;
select 'OK: gramos, claras, yemas, consumo compartido, costo, reintento y privacidad; todo revertido' as resultado;
