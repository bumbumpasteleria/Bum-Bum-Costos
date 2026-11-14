begin;
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;
-- The scheduler's random credential stays in a table with no client privileges.
create function public.bum_push_tick() returns bigint language plpgsql security definer set search_path='' as $$
declare request_ bigint;begin
 if not exists(select 1 from public.push_subscriptions where enabled) then return null;end if;
 select net.http_post(url:='https://exanisbqasrzoerdghmz.supabase.co/functions/v1/task-notifications',headers:=jsonb_build_object('Content-Type','application/json','x-bum-cron',(select cron_token from public.push_service_config where id=1)),body:='{"action":"dispatch"}'::jsonb,timeout_milliseconds:=60000) into request_;
 return request_;
end $$;
revoke all on function public.bum_push_tick() from public,anon,authenticated,service_role;
select cron.schedule('bum-bum-recordatorios','*/15 * * * *','select public.bum_push_tick();');
commit;
