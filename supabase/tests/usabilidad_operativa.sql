set local role authenticated;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000001';
insert into public.recipe_books(id,owner_id,name,usage) values('12360000-0000-4000-8000-000000000981',auth.uid(),'ENCARGOS SINTETICOS','orders');
select public.guardar_receta_organizada_bum_bum('12360000-0000-4000-8000-000000000982','RECETA SINTETICA',1,'unidad','scalable','[{"ingredient_id":"12360000-0000-4000-8000-000000000011","quantity_base":1,"measurement_quantity":1,"measurement_unit":"g"}]','Otro artículo','12360000-0000-4000-8000-000000000981','','Prueba');
insert into public.quotes(id,owner_id,total_cost,quoted_price,pricing_method,details) values('12360000-0000-4000-8000-000000000983',auth.uid(),44.2,100,'margin','{"customer":"Cliente sintético","deliveryDate":"2026-12-01","recipeId":"12360000-0000-4000-8000-000000000982","recipeName":"RECETA SINTETICA","notes":"Conservar notas","breakdown":{"factor":1,"laborCost":25,"decorationCost":10,"expenses":[{"cost":5}],"materialLines":[{"id":"12360000-0000-4000-8000-000000000012","quantity":2,"unit":"unidad"}]}}');
do $$ declare r jsonb;d jsonb;before_ numeric;failed boolean:=false;v integer;begin
 select stock_quantity into before_ from public.ingredients where id='12360000-0000-4000-8000-000000000012';
 d:='{"customer":"Cliente sintético","contact":"Contacto de ejemplo","description":"Pedido sintético","deliveryDate":"2026-12-01","total":100,"deposit":0,"status":"pending","quoteId":"12360000-0000-4000-8000-000000000983","materialCost":999,"materialUsage":[{}],"recipes":[{"id":"12360000-0000-4000-8000-000000000985","recipeId":"12360000-0000-4000-8000-000000000982","factor":1,"quantity":1,"leadDays":2}],"photos":[]}';
 r:=public.bum_save_entry('12360000-0000-4000-8000-000000000984','order',d,0);
 if r->'details'?'materialUsage' or r->'details'?'materialCost' or r->'details'->'quoteSnapshot'->>'customer'<>'Cliente sintético' then raise exception 'Historial falsificable o cotización no conservada';end if;
 begin perform public.bum_save_entry('12360000-0000-4000-8000-000000000986','order',jsonb_set(d,'{recipes}','[]'),0);exception when others then failed:=true;end;if not failed then raise exception 'Pedido duplicado de cotización';end if;
 failed:=false;begin perform public.bum_save_entry('12360000-0000-4000-8000-000000000984','order',jsonb_set(d,'{status}','"ready"'),1);exception when others then failed:=true;end;if not failed then raise exception 'Pedido listo antes de preparar';end if;
 if (select stock_quantity from public.ingredients where id='12360000-0000-4000-8000-000000000012')<>before_ then raise exception 'Planificar consumió materiales';end if;
 select version into v from public.business_entries where id='12360000-0000-4000-8000-000000000985';perform public.bum_work_produce('12360000-0000-4000-8000-000000000987','12360000-0000-4000-8000-000000000985',v);
 update public.quotes set details=jsonb_set(details,'{breakdown,materialLines,0,quantity}','20') where id='12360000-0000-4000-8000-000000000983';
 r:=public.bum_save_entry('12360000-0000-4000-8000-000000000984','order',jsonb_set(d,'{status}','"ready"'),1);
 if (r->'details'->>'materialCost')::numeric<>4 or (r->'details'->'materialUsage'->0->>'quantity')::numeric<>2 then raise exception 'No se conservó la cotización aceptada o el costo histórico';end if;
 r:=public.bum_save_entry('12360000-0000-4000-8000-000000000984','order',r->'details',(r->>'version')::integer);
 r:=public.bum_order_sale('12360000-0000-4000-8000-000000000988','12360000-0000-4000-8000-000000000984',(now() at time zone 'America/Santo_Domingo')::date,'Directa',0,40);
 if (r->>'cost_amount')::numeric<>44.2 then raise exception 'Materiales duplicados o excluidos del resultado: %',r;end if;
 r:=public.bum_order_sale('12360000-0000-4000-8000-000000000988','12360000-0000-4000-8000-000000000984',(now() at time zone 'America/Santo_Domingo')::date,'Directa',0,40);
 if (r->>'cost_amount')::numeric<>44.2 or (select stock_quantity from public.ingredients where id='12360000-0000-4000-8000-000000000012')<>before_-2 then raise exception 'Reintento repitió consumo o costo';end if;
end $$;

-- Restore a complete staged version, both while the recipe exists and after deleting it.
reset role;
do $$ declare args jsonb;stages jsonb;r jsonb;original_ jsonb;version_ uuid;begin
 args:='{"p_id":"12360000-0000-4000-8000-000000000991","p_name":"ETAPAS SINTETICAS","p_yield":8,"p_yield_unit":"unidad","p_scaling":"scalable","p_product_type":"Otro artículo","p_book_id":"12360000-0000-4000-8000-000000000981","p_preparation":"Montar","p_category":"Prueba","p_lines":[{"ingredient_id":"12360000-0000-4000-8000-000000000011","quantity_base":20,"measurement_quantity":20,"measurement_unit":"g"},{"ingredient_id":"12360000-0000-4000-8000-000000000011","quantity_base":30,"measurement_quantity":30,"measurement_unit":"g"}]}';
 stages:='[{"id":"12360000-0000-4000-8000-000000000992","name":"Base original","preparation":"Hornear base","lineIndexes":[0]},{"id":"12360000-0000-4000-8000-000000000993","name":"Crema original","preparation":"Enfriar crema","lineIndexes":[1]}]';
 r:=public.bum_save_staged_recipe(args,stages,null);
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original_ from public.recipes rec where id=(args->>'p_id')::uuid;
 -- A real version is captured in a later transaction. This rollback-only fixture represents it,
 -- because production deliberately skips versions of recipes created within this transaction.
 insert into public.recipe_versions(owner_id,recipe_id,snapshot) values(auth.uid(),(args->>'p_id')::uuid,original_);
 args:=jsonb_set(args,'{p_lines}',(select jsonb_agg(jsonb_build_object('id',l.id,'ingredient_id',l.ingredient_id,'quantity_base',l.quantity_base,'measurement_quantity',l.measurement_quantity,'measurement_unit',l.measurement_unit) order by l.quantity_base) from public.recipe_lines l where l.recipe_id=(args->>'p_id')::uuid));
 r:=public.bum_save_staged_recipe(jsonb_set(args,'{p_name}','"ETAPAS MODIFICADAS"'),jsonb_set(stages,'{0,name}','"Base nueva"'),original_);
 select id into version_ from public.recipe_versions where recipe_id=(args->>'p_id')::uuid and (snapshot->>'instructions')::jsonb->'stages'->0->>'name'='Base original' order by created_at limit 1;
 if version_ is null then raise exception 'No se capturó la versión de etapas';end if;
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original_ from public.recipes rec where id=(args->>'p_id')::uuid;
 r:=public.bum_restore_recipe_version(version_,original_);
 if (r->>'instructions')::jsonb->'stages'->0->>'name'<>'Base original' or (r->>'instructions')::jsonb->'stages'->1->>'preparation'<>'Enfriar crema' then raise exception 'No se restauraron las etapas';end if;
 delete from public.recipes where id=(args->>'p_id')::uuid;
 r:=public.bum_restore_recipe_version(version_,null);
 if (r->>'instructions')::jsonb->'stages'->0->>'name'<>'Base original' or (select sum(quantity_base) from public.recipe_lines where recipe_id=(args->>'p_id')::uuid)<>50 then raise exception 'Recuperación tras eliminar incompleta';end if;
 if exists(select 1 from jsonb_array_elements((r->>'instructions')::jsonb->'stages') s cross join lateral jsonb_array_elements_text(s->'lineIds') lid where not exists(select 1 from public.recipe_lines where id=lid::uuid and recipe_id=(args->>'p_id')::uuid)) then raise exception 'Etapas apuntan a líneas anteriores';end if;
end $$;
set local role authenticated;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false;begin
 if exists(select 1 from public.business_entries where details->>'quoteId'='12360000-0000-4000-8000-000000000983') then raise exception 'Cotización de otra cuenta visible';end if;
 begin perform public.bum_order_sale('12360000-0000-4000-8000-000000000989','12360000-0000-4000-8000-000000000984',(now() at time zone 'America/Santo_Domingo')::date,'Directa',0,0);exception when others then failed:=true;end;if not failed then raise exception 'Venta de otra cuenta';end if;
end $$;
reset role;
do $$ begin if has_function_privilege('authenticated','public.bum_pack_order(uuid)','execute') or has_function_privilege('anon','public.bum_order_sale(uuid,uuid,date,text,numeric,numeric)','execute') then raise exception 'Permisos de ayudantes ampliados';end if;end $$;
rollback;
select 'OK: cotización, materiales únicos, venta, reintentos, restauración de etapas y privacidad; todo revertido' as resultado;
