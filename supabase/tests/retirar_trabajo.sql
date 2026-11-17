-- Run inside BEGIN / ROLLBACK. Synthetic rows only.
insert into auth.users(id,email) values('12371500-0000-4000-8000-000000000001','retire-a@example.invalid'),('12371500-0000-4000-8000-000000000002','retire-b@example.invalid');
update public.business_profiles set status='approved',password_required=false where id in('12371500-0000-4000-8000-000000000001','12371500-0000-4000-8000-000000000002');
insert into public.business_entries(id,owner_id,kind,details) values
('12371500-0000-4000-8000-000000000011','12371500-0000-4000-8000-000000000001','work_order','{"name":"SINTETICO","date":"2026-11-15","recipeId":"12371500-0000-4000-8000-000000000099","factor":0.5,"quantity":8,"status":"planned"}'),
('12371500-0000-4000-8000-000000000012','12371500-0000-4000-8000-000000000002','work_order','{"name":"AJENO","status":"planned"}'),
('12371500-0000-4000-8000-000000000013','12371500-0000-4000-8000-000000000001','work_order','{"name":"TERMINADO","status":"done","productionId":"12371500-0000-4000-8000-000000000090"}');
set local role authenticated;
set local request.jwt.claim.sub='12371500-0000-4000-8000-000000000001';
do $$ declare v integer;before_ jsonb;after_ jsonb;begin
 select version,details into v,before_ from public.business_entries where id='12371500-0000-4000-8000-000000000011';
 after_:=public.bum_retire_work('12371500-0000-4000-8000-000000000011',v,false);
 if after_->'details'->>'status'<>'cancelled' or ((after_->'details')-'status'::text) is distinct from (before_-'status'::text) or (after_->>'version')::integer<>v+1 then raise exception 'Se alteró el trabajo';end if;
 begin perform public.bum_retire_work('12371500-0000-4000-8000-000000000011',v,false);raise exception 'TEST_VERSION';exception when others then if sqlerrm='TEST_VERSION' then raise;end if;end;
 begin perform public.bum_retire_work('12371500-0000-4000-8000-000000000011',v+1,true);raise exception 'TEST_RECIPE';exception when others then if sqlerrm='TEST_RECIPE' then raise;end if;end;
 begin perform public.bum_retire_work('12371500-0000-4000-8000-000000000012',1,false);raise exception 'TEST_OWNER';exception when others then if sqlerrm='TEST_OWNER' then raise;end if;end;
 select version into v from public.business_entries where id='12371500-0000-4000-8000-000000000013';
 begin perform public.bum_retire_work('12371500-0000-4000-8000-000000000013',v,false);raise exception 'TEST_DONE';exception when others then if sqlerrm='TEST_DONE' then raise;end if;end;
end $$;
reset role;
do $$ begin if (select count(*) from public.business_entry_history where entry_id='12371500-0000-4000-8000-000000000011')<>1 then raise exception 'Historial no conservado';end if;end $$;
select 'Retiro de trabajo huérfano, versión, historial y aislamiento correctos' as resultado;
