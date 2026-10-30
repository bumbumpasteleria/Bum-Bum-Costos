begin;
create table public.recipe_books (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id),
  name text not null check (length(trim(name))>0),
  usage text not null check (usage in ('orders','delivery','general')),
  created_at timestamptz not null default now()
);
create unique index recipe_books_owner_name on public.recipe_books(owner_id,lower(trim(name)));
alter table public.recipe_books enable row level security;
create policy recipe_books_owner on public.recipe_books for all to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
revoke all on public.recipe_books from anon,authenticated;
grant select,insert,update on public.recipe_books to authenticated;
alter table public.recipes add column recipe_book_id uuid references public.recipe_books(id) on delete restrict;

create function public.check_recipe_book_owner() returns trigger language plpgsql security invoker set search_path='' as $$
begin
  if new.recipe_book_id is not null and not exists(select 1 from public.recipe_books where id=new.recipe_book_id and owner_id=new.owner_id) then raise exception 'El recetario debe pertenecer a esta cuenta.'; end if;
  return new;
end; $$;
create trigger recipes_check_book_owner before insert or update of recipe_book_id,owner_id on public.recipes for each row execute function public.check_recipe_book_owner();

create function public.guardar_receta_recetario_bum_bum(p_id uuid,p_name text,p_yield numeric,p_yield_unit text,p_scaling text,p_lines jsonb,p_product_type text,p_book_id uuid)
returns uuid language plpgsql security invoker set search_path='' as $$
begin
  if auth.uid() is null or not exists(select 1 from public.recipe_books where id=p_book_id and owner_id=auth.uid()) then raise exception 'Selecciona un recetario de tu cuenta.'; end if;
  perform public.guardar_receta_producto_bum_bum(p_id,p_name,p_yield,p_yield_unit,p_scaling,p_lines,p_product_type);
  update public.recipes set recipe_book_id=p_book_id where id=p_id and owner_id=auth.uid();
  return p_id;
end; $$;
revoke all on function public.guardar_receta_recetario_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid) from public,anon;
grant execute on function public.guardar_receta_recetario_bum_bum(uuid,text,numeric,text,text,jsonb,text,uuid) to authenticated;
commit;
