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
do $$ declare original jsonb; result jsonb; line_id uuid; before_state jsonb; after_state jsonb; snapshot jsonb; begin
 select to_jsonb(r)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=r.id)) into original
 from public.recipes r where r.id='12348000-0000-4000-8000-000000000031';
 line_id:=(original->'lines'->0->>'id')::uuid;
 result:=public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT ACTUALIZADA',24,'unidad','scalable',
  jsonb_build_array(jsonb_build_object('id',line_id,'ingredient_id','12348000-0000-4000-8000-000000000011','quantity_base',500),
  jsonb_build_object('ingredient_id','12348000-0000-4000-8000-000000000012','quantity_base',100)),
  'Galleta','12348000-0000-4000-8000-000000000021',original);
 if result->>'id'<>'12348000-0000-4000-8000-000000000031' or jsonb_array_length(result->'recipe_lines')<>2 then raise exception 'Se perdió identidad o líneas'; end if;
 if not exists(select 1 from public.recipe_lines where id=line_id and quantity_base=500) then raise exception 'Se reemplazó la línea existente'; end if;
 if (result->>'instructions')::jsonb->>'custom'<>'conservar' then raise exception 'Se perdió metadata'; end if;
 if not exists(select 1 from public.quotes where id='12348000-0000-4000-8000-000000000041' and total_cost=50 and quoted_price=100 and details->>'recipeName'='EDIT ORIGINAL') then raise exception 'Cotización histórica alterada'; end if;
 if not exists(select 1 from public.ingredients where id='12348000-0000-4000-8000-000000000011' and stock_quantity=1000 and last_unit_cost=0.2) then raise exception 'Stock o precio alterado'; end if;
 before_state:=result;
 begin
  perform public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT PISADA',24,'unidad','scalable','[]','Galleta','12348000-0000-4000-8000-000000000021',original);
  raise exception 'STALE_ACCEPTED';
 exception when others then if SQLERRM not like 'La receta cambió%' then raise; end if; end;
 select to_jsonb(r)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=r.id)) into snapshot
 from public.recipes r where r.id='12348000-0000-4000-8000-000000000031';
 begin
  perform public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT AJENA',24,'unidad','scalable',
   '[{"ingredient_id":"12348000-0000-4000-8000-000000000013","quantity_base":100}]','Galleta','12348000-0000-4000-8000-000000000021',snapshot);
  raise exception 'FOREIGN_ACCEPTED';
 exception when others then if SQLERRM not like 'Selecciona un ingrediente%' then raise; end if; end;
 begin
  perform public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT SIN LINEAS',24,'unidad','scalable','[]','Galleta','12348000-0000-4000-8000-000000000021',snapshot);
  raise exception 'EMPTY_ACCEPTED';
 exception when others then if SQLERRM not like 'Agrega ingredientes%' then raise; end if; end;
 begin
  perform public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT RECETARIO AJENO',24,'unidad','scalable',
   jsonb_build_array(jsonb_build_object('id',line_id,'ingredient_id','12348000-0000-4000-8000-000000000011','quantity_base',500)),
   'Galleta','12348000-0000-4000-8000-000000000022',snapshot);
  raise exception 'FOREIGN_BOOK_ACCEPTED';
 exception when others then if SQLERRM not like 'Selecciona un recetario%' then raise; end if; end;
 begin
  perform public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT CANTIDAD INVALIDA',24,'unidad','scalable',
   jsonb_build_array(jsonb_build_object('id',line_id,'ingredient_id','12348000-0000-4000-8000-000000000011','quantity_base',-1)),
   'Galleta','12348000-0000-4000-8000-000000000021',snapshot);
  raise exception 'NEGATIVE_ACCEPTED';
 exception when others then if SQLERRM not like 'Revisa las cantidades%' then raise; end if; end;
 result:=public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT UNA LINEA',24,'unidad','fixed',
  jsonb_build_array(jsonb_build_object('id',line_id,'ingredient_id','12348000-0000-4000-8000-000000000011','quantity_base',600)),
  'Galleta','12348000-0000-4000-8000-000000000021',snapshot);
 if jsonb_array_length(result->'recipe_lines')<>1 or not exists(select 1 from public.recipe_lines where id=line_id and quantity_base=600) then raise exception 'Quitar una línea afectó otra'; end if;
 update public.recipes set instructions='Preparación antigua: mezclar sin perder este texto.' where id='12348000-0000-4000-8000-000000000031';
 select to_jsonb(r)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=r.id)) into snapshot
 from public.recipes r where r.id='12348000-0000-4000-8000-000000000031';
 result:=public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT TEXTO CONSERVADO',24,'unidad','fixed',
  jsonb_build_array(jsonb_build_object('id',line_id,'ingredient_id','12348000-0000-4000-8000-000000000011','quantity_base',600)),
  'Galleta','12348000-0000-4000-8000-000000000021',snapshot);
 if (result->>'instructions')::jsonb->>'legacyInstructions'<>'Preparación antigua: mezclar sin perder este texto.' then raise exception 'Se perdió la preparación antigua'; end if;

end $$;
set local request.jwt.claim.sub='12348000-0000-4000-8000-000000000002';
do $$ begin
 begin
  perform public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','EDIT AJENA',1,'unidad','fixed','[]','Galleta','12348000-0000-4000-8000-000000000022','{}');
  raise exception 'CROSS_ACCOUNT_ACCEPTED';
 exception when others then if SQLERRM not like 'Receta no disponible%' then raise; end if; end;
end $$;
reset role;
set local role anon;
do $$ begin
 begin
  perform public.actualizar_receta_recetario_bum_bum('12348000-0000-4000-8000-000000000031','ANON',1,'unidad','fixed','[]','Galleta','12348000-0000-4000-8000-000000000021','{}');
  raise exception 'ANON_ACCEPTED';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'OK: edición atómica, IDs conservados, agregar/quitar líneas, metadata e histórico intactos, conflicto detectado y acceso ajeno rechazado; pruebas y función deshechas.' as resultado;
