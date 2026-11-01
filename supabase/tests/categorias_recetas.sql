-- Execute in the migration's BEGIN transaction, replacing its COMMIT.
insert into auth.users(id,email) values
 ('12350000-0000-4000-8000-000000000001','category-a@example.invalid'),
 ('12350000-0000-4000-8000-000000000002','category-b@example.invalid');
update public.business_profiles set status='approved',password_required=false where id in ('12350000-0000-4000-8000-000000000001','12350000-0000-4000-8000-000000000002');
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity) values ('12350000-0000-4000-8000-000000000011','12350000-0000-4000-8000-000000000001','CATEGORY HARINA','g',0.2,1000);
insert into public.recipe_books(id,owner_id,name,usage) values ('12350000-0000-4000-8000-000000000021','12350000-0000-4000-8000-000000000001','CATEGORY APPS','delivery');
set local role authenticated;
set local request.jwt.claim.sub='12350000-0000-4000-8000-000000000001';
do $$ declare r jsonb; original jsonb; lines jsonb; failed boolean:=false; begin
 r:=public.guardar_receta_organizada_bum_bum('12350000-0000-4000-8000-000000000031','CATEGORY MASA',6,'bandeja','scalable','[{"ingredient_id":"12350000-0000-4000-8000-000000000011","quantity_base":250}]','Galleta','12350000-0000-4000-8000-000000000021',E'Mezclar.\nHornear.','Masas');
 if (r->>'instructions')::jsonb->>'category' is distinct from 'Masas' or (r->>'instructions')::jsonb->>'preparation' is distinct from E'Mezclar.\nHornear.' then raise exception 'Category/preparation missing'; end if;
 select to_jsonb(recipe)||jsonb_build_object('lines',(select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id=recipe.id)) into original from public.recipes recipe where id='12350000-0000-4000-8000-000000000031';
 lines:=original->'lines';
 r:=public.actualizar_receta_organizada_bum_bum('12350000-0000-4000-8000-000000000031','CATEGORY MASA',6,'bandeja','scalable',lines,'Galleta','12350000-0000-4000-8000-000000000021',original,E'Mezclar.\nHornear.','Rellenos propios');
 if (r->>'instructions')::jsonb->>'category' is distinct from 'Rellenos propios' or (r->>'instructions')::jsonb->>'preparation' is distinct from E'Mezclar.\nHornear.' then raise exception 'Category update lost metadata'; end if;
 if (select jsonb_agg(to_jsonb(l)) from public.recipe_lines l where l.recipe_id='12350000-0000-4000-8000-000000000031') is distinct from lines then raise exception 'Line IDs changed'; end if;
 begin
 perform public.actualizar_receta_organizada_bum_bum('12350000-0000-4000-8000-000000000031','STALE',6,'bandeja','scalable',lines,'Galleta','12350000-0000-4000-8000-000000000021',original,'','Pisada');
 exception when others then failed:=true; end;
 if not failed then raise exception 'Stale update accepted'; end if;
 failed:=false;
 begin
 perform public.guardar_receta_organizada_bum_bum('12350000-0000-4000-8000-000000000032','INVALID',6,'bandeja','scalable','[{"ingredient_id":"12350000-0000-4000-8000-000000000011","quantity_base":250}]','Galleta','12350000-0000-4000-8000-000000000021','',repeat('x',81));
 exception when others then failed:=true; end;
 if not failed or exists(select 1 from public.recipes where id='12350000-0000-4000-8000-000000000032') then raise exception 'Invalid category accepted'; end if;
 if not exists(select 1 from public.ingredients where id='12350000-0000-4000-8000-000000000011' and stock_quantity=1000 and last_unit_cost=0.2) then raise exception 'Catalog changed'; end if;
end $$;
set local request.jwt.claim.sub='12350000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false; begin
 if exists(select 1 from public.recipes where id='12350000-0000-4000-8000-000000000031') then raise exception 'Other account sees recipe'; end if;
 begin
 perform public.actualizar_receta_organizada_bum_bum('12350000-0000-4000-8000-000000000031','FOREIGN',6,'bandeja','scalable','[]','Galleta','12350000-0000-4000-8000-000000000021','{}','','Foreign');
 exception when others then failed:=true; end;
 if not failed then raise exception 'Other account changed recipe'; end if;
end $$;
reset role;
do $$ begin
 if has_function_privilege('anon','public.guardar_receta_organizada_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,text,text)','EXECUTE') or has_function_privilege('anon','public.actualizar_receta_organizada_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid,jsonb,text,text)','EXECUTE') then raise exception 'Anonymous enabled'; end if;
end $$;
rollback;
select 'OK: categorías, preparación, IDs, concurrencia y aislamiento; prueba revertida' as resultado;
