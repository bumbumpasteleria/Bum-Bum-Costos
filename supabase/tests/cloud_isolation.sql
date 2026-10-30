-- Synthetic fixtures only; all fixture writes are rolled back.
begin;
insert into auth.users(id,email) values
('12340000-0000-4000-8000-000000000001','bum-test-a@example.invalid'),
('12340000-0000-4000-8000-000000000002','bum-test-b@example.invalid');
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost) values
('12340000-0000-4000-8000-000000000011','12340000-0000-4000-8000-000000000001','TEMP A','g',0.12),
('12340000-0000-4000-8000-000000000012','12340000-0000-4000-8000-000000000002','TEMP B','g',0.20);
set local role authenticated;
set local request.jwt.claim.sub='12340000-0000-4000-8000-000000000001';
select public.guardar_receta_bum_bum('12340000-0000-4000-8000-000000000021','TEMP RECETA',1,'lb','fixed','[{"ingredient_id":"12340000-0000-4000-8000-000000000011","quantity_base":500}]'::jsonb);
do $$ begin
  if (select count(*) from public.recipe_lines where recipe_id='12340000-0000-4000-8000-000000000021') <> 1 then raise exception 'No se guardaron las líneas'; end if;
  if exists(select 1 from public.ingredients where id='12340000-0000-4000-8000-000000000012') then raise exception 'Acceso cruzado'; end if;
  begin
    perform public.guardar_receta_bum_bum('12340000-0000-4000-8000-000000000022','TEMP INVALIDA',1,'lb','fixed','[{"ingredient_id":"12340000-0000-4000-8000-000000000012","quantity_base":500}]'::jsonb);
  exception when others then null;
  end;
  if exists(select 1 from public.recipes where id='12340000-0000-4000-8000-000000000022') then raise exception 'Receta parcial'; end if;
end $$;
set local request.jwt.claim.sub='12340000-0000-4000-8000-000000000002';
do $$ declare modified integer; begin
  if exists(select 1 from public.recipes where id='12340000-0000-4000-8000-000000000021') then raise exception 'Receta de otra cuenta visible'; end if;
  update public.ingredients set last_unit_cost=999 where id='12340000-0000-4000-8000-000000000011';
  get diagnostics modified = row_count;
  if modified <> 0 then raise exception 'Actualización cruzada permitida'; end if;
end $$;
reset role;
rollback;
select 'OK: receta atómica y aislamiento entre cuentas; fixtures deshechos' as resultado;
