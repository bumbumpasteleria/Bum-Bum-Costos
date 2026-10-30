begin;
insert into auth.users(id,email) values ('12346000-0000-4000-8000-000000000001','books-a@example.invalid'),('12346000-0000-4000-8000-000000000002','books-b@example.invalid');
insert into public.recipe_books(id,owner_id,name,usage) values
('12346000-0000-4000-8000-000000000011','12346000-0000-4000-8000-000000000001','Apps','delivery'),
('12346000-0000-4000-8000-000000000012','12346000-0000-4000-8000-000000000001','Encargos','orders'),
('12346000-0000-4000-8000-000000000013','12346000-0000-4000-8000-000000000002','Privado','orders');
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost) values ('12346000-0000-4000-8000-000000000021','12346000-0000-4000-8000-000000000001','Harina temporal','g',0.12);
set local role authenticated;
set local request.jwt.claim.sub='12346000-0000-4000-8000-000000000001';
select public.guardar_receta_recetario_bum_bum('12346000-0000-4000-8000-000000000031','Vainilla',1,'unidad','fixed','[{"ingredient_id":"12346000-0000-4000-8000-000000000021","quantity_base":500}]'::jsonb,'Bizcocho','12346000-0000-4000-8000-000000000011');
do $$ begin
  if (select count(*) from public.recipe_books)<>2 then raise exception 'Recetario ajeno visible'; end if;
  begin
    update public.recipes set recipe_book_id='12346000-0000-4000-8000-000000000013' where id='12346000-0000-4000-8000-000000000031';
  exception when others then null;
  end;
  if not exists(select 1 from public.recipes where id='12346000-0000-4000-8000-000000000031' and recipe_book_id='12346000-0000-4000-8000-000000000011') then raise exception 'Se permitió asignación cruzada'; end if;
end $$;
update public.recipes set recipe_book_id='12346000-0000-4000-8000-000000000012' where id='12346000-0000-4000-8000-000000000031';
do $$ declare costo numeric; begin
  select sum(l.quantity_base*i.last_unit_cost) into costo from public.recipe_lines l join public.ingredients i on i.id=l.ingredient_id where l.recipe_id='12346000-0000-4000-8000-000000000031';
  if costo<>60 then raise exception 'Costo alterado al mover receta'; end if;
  if not exists(select 1 from public.recipes r join public.recipe_books b on b.id=r.recipe_book_id where r.id='12346000-0000-4000-8000-000000000031' and b.usage='orders') then raise exception 'Receta de encargo no asignada'; end if;
end $$;
reset role;
rollback;
select 'OK: recetarios privados, asignación y costos conservados; pruebas deshechas' as resultado;
