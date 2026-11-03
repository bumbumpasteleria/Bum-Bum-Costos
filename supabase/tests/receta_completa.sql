-- Append to the migration without COMMIT; synthetic account, always ROLLBACK.
insert into auth.users(id,email) values('12371000-0000-4000-8000-000000000001','batch@example.invalid');
update public.business_profiles set status='approved',password_required=false where id='12371000-0000-4000-8000-000000000001';
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost) values('12371000-0000-4000-8000-000000000011','12371000-0000-4000-8000-000000000001','ARTICULO SINTETICO','g',1);
insert into public.recipe_books(id,owner_id,name,usage) values('12371000-0000-4000-8000-000000000021','12371000-0000-4000-8000-000000000001','LIBRO SINTETICO','orders');
set local role authenticated;
set local request.jwt.claim.sub='12371000-0000-4000-8000-000000000001';
do $$ declare args_ jsonb;r_ jsonb;begin
 args_:='{"p_id":"12371000-0000-4000-8000-000000000031","p_name":"RECETA COMPLETA SINTETICA","p_yield":1,"p_yield_unit":"receta completa","p_scaling":"scalable","p_product_type":"Otro artículo","p_book_id":"12371000-0000-4000-8000-000000000021","p_preparation":"Preparación sintética","p_category":"Prueba","p_lines":[{"ingredient_id":"12371000-0000-4000-8000-000000000011","quantity_base":100,"measurement_quantity":100,"measurement_unit":"g"}]}';
 r_:=public.bum_save_staged_recipe(args_,'[]',null);
 if (select yield_unit from public.recipes where id='12371000-0000-4000-8000-000000000031')<>'receta completa' then raise exception 'No conservó el rendimiento completo';end if;
 r_:=r_||jsonb_build_object('lines',r_->'recipe_lines');
 perform public.bum_save_staged_recipe(jsonb_set(args_,'{p_name}','"RECETA COMPLETA EDITADA"'),'[]',r_);
end $$;
select true as receta_completa_creada_y_editada;
rollback;
