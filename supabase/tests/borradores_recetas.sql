-- Synthetic fixtures; run in a transaction after the migration and roll back.
insert into auth.users(id,email) values('12370000-0000-4000-8000-000000000001','draft-a@example.invalid'),('12370000-0000-4000-8000-000000000002','draft-b@example.invalid');
update public.business_profiles set status='approved',password_required=false where id in('12370000-0000-4000-8000-000000000001','12370000-0000-4000-8000-000000000002');
set local role authenticated;
set local request.jwt.claim.sub='12370000-0000-4000-8000-000000000001';
do $$ declare d jsonb;r jsonb;failed boolean:=false;begin
 d:='{"form":{"name":"Borrador sintético","bookId":"","yield":"","lines":[{"name":"Ingrediente pendiente","ingredientId":"","qty":"20","unit":"g","stageId":"base"}],"stages":[{"id":"base","name":"Base","preparation":"Mezclar"}]},"archived":false}';
 r:=public.bum_save_entry('12370000-0000-4000-8000-000000000011','recipe_draft',d,0);
 if r->'details'->'form'->'lines'->0->>'qty'<>'20' then raise exception 'Borrador pierde cantidades';end if;
 if exists(select 1 from public.recipes where id='12370000-0000-4000-8000-000000000011') then raise exception 'Borrador activó una receta incompleta';end if;
 r:=public.bum_save_entry('12370000-0000-4000-8000-000000000011','recipe_draft',jsonb_set(d,'{form,name}','"Borrador actualizado"'),1);
 begin perform public.bum_save_entry('12370000-0000-4000-8000-000000000011','recipe_draft',d,1);exception when others then failed:=true;end;
 if not failed then raise exception 'Sobrescritura de borrador con versión antigua';end if;
end $$;
set local request.jwt.claim.sub='12370000-0000-4000-8000-000000000002';
do $$ declare failed boolean:=false;begin
 if exists(select 1 from public.business_entries where kind='recipe_draft') then raise exception 'Borrador de otra cuenta visible';end if;
 begin perform public.bum_save_entry('12370000-0000-4000-8000-000000000011','recipe_draft','{"form":{"name":"Ajeno","lines":[],"stages":[]}}',2);exception when others then failed:=true;end;
 if not failed then raise exception 'Borrador de otra cuenta modificable';end if;
end $$;
reset role;
rollback;
select 'OK: borradores privados, parciales, versiones y sin activar costos; prueba revertida' as resultado;
