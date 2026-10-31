begin;
insert into auth.users(id,email) values('12347000-0000-4000-8000-000000000011','pending-test@example.invalid');
set local role authenticated;
set local request.jwt.claim.sub='12347000-0000-4000-8000-000000000011';
do $$ begin
 if public.bum_account_approved() then raise exception 'Cuenta pendiente aprobada'; end if;
 begin insert into public.ingredients(name,base_unit) values('NO DEBE GUARDARSE','g'); exception when insufficient_privilege then null; end;
 if exists(select 1 from public.ingredients where name='NO DEBE GUARDARSE') then raise exception 'Acceso sin aprobación'; end if;
 begin update public.business_profiles set status='approved' where id=auth.uid(); exception when insufficient_privilege then null; end;
 if public.bum_account_approved() then raise exception 'Autopromoción permitida'; end if;
end $$;
reset role;
insert into public.account_requests(email,owner_name,business_name,location,ip_hash,status) values('approved-test@example.invalid','Dueña temporal','Negocio temporal','Santo Domingo','test','approving');
insert into auth.users(id,email) values('12347000-0000-4000-8000-000000000012','approved-test@example.invalid');
set local role authenticated;
set local request.jwt.claim.sub='12347000-0000-4000-8000-000000000012';
do $$ begin
 if not public.bum_account_approved() then raise exception 'Invitación aprobada no reconocida'; end if;
 if not exists(select 1 from public.business_profiles where id=auth.uid() and business_name='Negocio temporal' and password_required) then raise exception 'Perfil de negocio perdido'; end if;
 if exists(select 1 from public.business_profiles where id='12347000-0000-4000-8000-000000000011') then raise exception 'Perfil ajeno visible'; end if;
end $$;
insert into public.ingredients(name,base_unit) values('TEMP APROBADA','g');
reset role;
rollback;
select 'OK: pendientes bloqueados, sin autopromoción, perfiles privados y aprobación reconocida; pruebas deshechas' as resultado;
