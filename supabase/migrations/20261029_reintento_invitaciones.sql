begin;
create function public.bum_request_approved_user(p_request_id uuid) returns uuid language sql stable security definer set search_path='' as $$
 select u.id from public.account_requests r join auth.users u on lower(u.email)=r.email join public.business_profiles p on p.id=u.id where r.id=p_request_id and p.status='approved';
$$;
revoke all on function public.bum_request_approved_user(uuid) from public,anon,authenticated;
grant execute on function public.bum_request_approved_user(uuid) to service_role;
commit;
