begin;
create table public.business_admins(user_id uuid primary key references auth.users(id));
alter table public.business_admins enable row level security;
revoke all on public.business_admins from anon,authenticated;
grant select on public.business_admins to authenticated;
create policy business_admin_self on public.business_admins for select to authenticated using(user_id=auth.uid());
insert into public.business_admins(user_id) select id from auth.users where lower(email)='bumbumpasteleria@gmail.com';
do $$ begin if not exists(select 1 from public.business_admins) then raise exception 'No se encontró la cuenta administradora. No se aplicaron cambios.'; end if; end $$;

create table public.account_requests(
 id uuid primary key default gen_random_uuid(),email text not null unique,
 owner_name text not null,business_name text not null,location text not null,
 description text not null default '',business_type text not null default '',phone text not null default '',website text not null default '',
 status text not null default 'pending' check(status in ('pending','approving','approved','rejected')),
 ip_hash text not null,admin_notified boolean not null default false,invitation_sent boolean not null default false,
 auth_user_id uuid references auth.users(id),reviewed_by uuid references auth.users(id),reviewed_at timestamptz,
 created_at timestamptz not null default now()
);
alter table public.account_requests enable row level security;
revoke all on public.account_requests from anon,authenticated;

create table public.business_profiles(
 id uuid primary key references auth.users(id),owner_name text not null default '',business_name text not null default '',
 location text not null default '',description text not null default '',business_type text not null default '',phone text not null default '',website text not null default '',
 status text not null default 'pending' check(status in ('pending','approved')),
 password_required boolean not null default true,created_at timestamptz not null default now()
);
alter table public.business_profiles enable row level security;
revoke all on public.business_profiles from anon,authenticated;
grant select on public.business_profiles to authenticated;
grant update(password_required) on public.business_profiles to authenticated;
create policy business_profile_self_read on public.business_profiles for select to authenticated using(id=auth.uid());
create policy business_profile_password on public.business_profiles for update to authenticated using(id=auth.uid() and status='approved') with check(id=auth.uid() and status='approved');
-- Preserve access for existing users. No credentials or business records change.
insert into public.business_profiles(id,status,password_required) select id,'approved',false from auth.users;

create function public.bum_account_approved() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.business_profiles where id=auth.uid() and status='approved');
$$;
revoke all on function public.bum_account_approved() from public,anon;
grant execute on function public.bum_account_approved() to authenticated;
do $$ declare tabla text; begin
 foreach tabla in array array['ingredients','recipes','recipe_lines','decorations','quotes','sales','purchases','inventory_movements','recipe_books'] loop
  execute format('create policy account_approval_gate on public.%I as restrictive for all to authenticated using ((select public.bum_account_approved())) with check ((select public.bum_account_approved()))',tabla);
 end loop;
end $$;

create function public.bum_new_business_profile() returns trigger language plpgsql security definer set search_path='' as $$
declare solicitud public.account_requests;
begin
 select * into solicitud from public.account_requests where email=lower(new.email) and status in ('approving','approved');
 insert into public.business_profiles(id,owner_name,business_name,location,description,business_type,phone,website,status,password_required)
 values(new.id,coalesce(solicitud.owner_name,''),coalesce(solicitud.business_name,''),coalesce(solicitud.location,''),coalesce(solicitud.description,''),coalesce(solicitud.business_type,''),coalesce(solicitud.phone,''),coalesce(solicitud.website,''),case when solicitud.id is null then 'pending' else 'approved' end,true);
 return new;
end $$;
create trigger bum_create_business_profile after insert on auth.users for each row execute function public.bum_new_business_profile();

create function public.bum_submit_account_request(p_data jsonb,p_ip_hash text) returns uuid language plpgsql security definer set search_path='' as $$
declare created_id uuid; normalized_email text=lower(trim(p_data->>'email'));
begin
 perform pg_advisory_xact_lock(hashtext('bum_account_requests'));
 if exists(select 1 from public.account_requests where email=normalized_email) then return null; end if;
 if (select count(*) from public.account_requests where created_at>now()-interval '1 hour')>=50 or (select count(*) from public.account_requests where ip_hash=p_ip_hash and created_at>now()-interval '1 hour')>=5 then raise exception 'RATE_LIMIT'; end if;
 insert into public.account_requests(email,owner_name,business_name,location,description,business_type,phone,website,ip_hash)
 values(normalized_email,p_data->>'ownerName',p_data->>'businessName',p_data->>'location',coalesce(p_data->>'description',''),coalesce(p_data->>'businessType',''),coalesce(p_data->>'phone',''),coalesce(p_data->>'website',''),p_ip_hash) returning id into created_id;
 return created_id;
end $$;
revoke all on function public.bum_submit_account_request(jsonb,text) from public,anon,authenticated;
grant execute on function public.bum_submit_account_request(jsonb,text) to service_role;
grant all on public.business_admins,public.business_profiles,public.account_requests to service_role;
commit;
