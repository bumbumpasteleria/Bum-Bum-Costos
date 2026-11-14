begin;
-- Activation is set by the operator only after checking the scheduler and service.
alter table public.push_service_config add column ready boolean not null default false;
commit;
