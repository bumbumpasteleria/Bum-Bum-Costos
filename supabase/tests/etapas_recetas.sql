-- Synthetic fixtures from materiales_y_canales.sql; never real recipe content.
set local role authenticated;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000001';
do $$ declare args jsonb;r jsonb;s jsonb;failed boolean:=false;original jsonb;begin
 args:='{"p_id":"12360000-0000-4000-8000-000000000951","p_name":"RECETA ETAPAS SINTETICA","p_yield":8,"p_yield_unit":"unidad","p_scaling":"scalable","p_product_type":"Otro artículo","p_book_id":"12360000-0000-4000-8000-000000000021","p_preparation":"Montaje","p_category":"Prueba","p_lines":[{"ingredient_id":"12360000-0000-4000-8000-000000000011","quantity_base":20,"measurement_quantity":20,"measurement_unit":"g"},{"ingredient_id":"12360000-0000-4000-8000-000000000011","quantity_base":30,"measurement_quantity":30,"measurement_unit":"g"}]}';
 s:='[{"id":"12360000-0000-4000-8000-000000000961","name":"Base","preparation":"Mezclar","lineIndexes":[0]},{"id":"12360000-0000-4000-8000-000000000962","name":"Crema","preparation":"Enfriar","lineIndexes":[1]}]';
 r:=public.bum_save_staged_recipe(args,s,null);
 if jsonb_array_length((r->>'instructions')::jsonb->'stages')<>2 or (select sum(quantity_base) from public.recipe_lines where recipe_id=(args->>'p_id')::uuid)<>50 then raise exception 'Etapas duplicadas o cantidades alteradas';end if;
 if ((r->>'instructions')::jsonb->'stages'->0->'lineIds'->>0)::uuid=((r->>'instructions')::jsonb->'stages'->1->'lineIds'->>0)::uuid then raise exception 'Misma línea en dos etapas';end if;
 select to_jsonb(rec)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=rec.id)) into original from public.recipes rec where id=(args->>'p_id')::uuid;
 args:=jsonb_set(args,'{p_lines}',(select jsonb_agg(jsonb_build_object('id',l.id,'ingredient_id',l.ingredient_id,'quantity_base',l.quantity_base,'measurement_quantity',l.measurement_quantity,'measurement_unit',l.measurement_unit) order by l.quantity_base) from public.recipe_lines l where l.recipe_id=(args->>'p_id')::uuid));
 r:=public.bum_save_staged_recipe(args,s,original);
 begin perform public.bum_save_staged_recipe(args,jsonb_set(s,'{1,lineIndexes}','[0]'),r||jsonb_build_object('lines',r->'recipe_lines'));exception when others then failed:=true;end;
 if not failed then raise exception 'Ingrediente en dos etapas aceptado';end if;
end $$;
set local request.jwt.claim.sub='12360000-0000-4000-8000-000000000002';
do $$ begin if exists(select 1 from public.recipes where id='12360000-0000-4000-8000-000000000951') then raise exception 'Etapas visibles a otra cuenta';end if;end $$;
reset role;
rollback;
select 'OK etapas: guardar, editar, ingredientes repetidos, total único y privacidad; pruebas revertidas' as resultado;
