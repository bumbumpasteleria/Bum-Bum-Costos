begin;
-- Versioned business entries preserve assignments in the existing backup and history flow.
alter table public.business_entries drop constraint business_entries_kind_check;
alter table public.business_entries add constraint business_entries_kind_check check(kind in ('expense','order','recipe_info','quote_brand','product_cost','recipe_profile','subrecipe','customer','supplier','quality','business_settings','work_order','payment','cash','raw_lot','inventory_event','recipe_draft','task_assignment'));
alter function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean) rename to bum_validate_entry_before_assignments;
create function public.bum_validate_entry(p_id uuid,p_kind text,p_details jsonb,p_owner uuid,p_require_recipe boolean) returns jsonb language plpgsql security invoker set search_path='' as $$
declare scope_ text:=p_details->>'scope';target_ uuid:=(case when p_kind='task_assignment' then p_details->>'target_id' else null end)::uuid;name_ text:=trim(p_details->>'responsible');begin
 if p_kind<>'task_assignment' then return public.bum_validate_entry_before_assignments(p_id,p_kind,p_details,p_owner,p_require_recipe);end if;
 if p_owner is distinct from auth.uid() or jsonb_typeof(p_details->'responsible') is distinct from 'string' or name_ is null or length(name_)>120 or name_~'[[:cntrl:]]' or p_id is distinct from md5(p_owner::text||':'||scope_||':'||target_::text)::uuid then raise exception 'Asignación no válida para esta cuenta';end if;
 if not(case scope_
 when 'work' then exists(select 1 from public.business_entries where owner_id=p_owner and id=target_ and kind='work_order')
 when 'delivery' then exists(select 1 from public.business_entries where owner_id=p_owner and id=target_ and kind='order')
 when 'production' then exists(select 1 from public.fridge_products where owner_id=p_owner and id=target_)
 when 'shopping' then exists(select 1 from public.ingredients where owner_id=p_owner and id=target_)
 else false end) then raise exception 'Selecciona una tarea de tu negocio';end if;
 return jsonb_build_object('scope',scope_,'target_id',target_,'responsible',name_);
end $$;
revoke all on function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean),public.bum_validate_entry_before_assignments(uuid,text,jsonb,uuid,boolean) from public,anon,authenticated;
create function public.bum_assign_task(p_kind text,p_target uuid,p_name text,p_expected integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();saved_ jsonb;begin
 if u is null or not public.bum_account_approved() then raise exception 'Inicia sesión con una cuenta aprobada';end if;
 if p_kind not in('work','delivery','production','shopping') or p_kind is null or p_target is null then raise exception 'Selecciona una tarea de tu negocio';end if;
 saved_:=public.bum_ops_put(md5(u::text||':'||p_kind||':'||p_target::text)::uuid,'task_assignment',jsonb_build_object('scope',p_kind,'target_id',p_target,'responsible',p_name),p_expected);
 return saved_||jsonb_build_object('kind',p_kind,'target_id',p_target,'responsible',saved_->'details'->>'responsible');
end $$;
revoke all on function public.bum_assign_task(text,uuid,text,integer) from public,anon;
grant execute on function public.bum_assign_task(text,uuid,text,integer) to authenticated;

-- Push endpoints and server signing keys are accessible only to the sending service.
create table public.push_service_config(id integer primary key check(id=1),vapid jsonb,cron_token text not null default(gen_random_uuid()::text||gen_random_uuid()::text));
insert into public.push_service_config(id) values(1);
create table public.push_subscriptions(
 id text primary key,owner_id uuid not null references auth.users(id) on delete cascade,subscription jsonb not null,
 enabled boolean not null default true,hour integer not null default 9 check(hour between 0 and 23),
 last_sent_day date,claimed_until timestamptz,last_test_at timestamptz,updated_at timestamptz not null default now()
);
alter table public.push_service_config enable row level security;
alter table public.push_subscriptions enable row level security;
revoke all on public.push_service_config,public.push_subscriptions from public,anon,authenticated;
grant all on public.push_service_config,public.push_subscriptions to service_role;
create function public.bum_push_claim(p_limit integer default 50) returns jsonb language plpgsql security definer set search_path='' as $$
declare row_ public.push_subscriptions;day_ date:=(now() at time zone 'America/Santo_Domingo')::date;hour_ integer:=extract(hour from now() at time zone 'America/Santo_Domingo');preps_ integer;deliveries_ integer;result_ jsonb:='[]';begin
 for row_ in select s.* from public.push_subscriptions s join public.business_profiles p on p.id=s.owner_id where s.enabled and p.status='approved' and not p.password_required and s.hour<=hour_ and (s.last_sent_day is null or s.last_sent_day<day_) and (s.claimed_until is null or s.claimed_until<now()) and exists(select 1 from public.business_entries b where b.owner_id=s.owner_id and ((b.kind='work_order' and b.details->>'status' in('planned','preparing') and b.details->>'date'<=day_::text and not exists(select 1 from public.business_entries o where o.owner_id=b.owner_id and o.kind='order' and o.id::text=b.details->>'orderId' and o.details->>'status'='cancelled')) or (b.kind='order' and b.details->>'status' not in('delivered','cancelled') and b.details->>'deliveryDate'<=day_::text))) order by s.updated_at limit least(greatest(p_limit,1),100) for update of s skip locked loop
  select count(*) into preps_ from public.business_entries w where w.owner_id=row_.owner_id and w.kind='work_order' and w.details->>'status' in('planned','preparing') and w.details->>'date'<=day_::text and not exists(select 1 from public.business_entries o where o.owner_id=w.owner_id and o.kind='order' and o.id::text=w.details->>'orderId' and o.details->>'status'='cancelled');
  select count(*) into deliveries_ from public.business_entries o where o.owner_id=row_.owner_id and o.kind='order' and o.details->>'status' not in('delivered','cancelled') and o.details->>'deliveryDate'<=day_::text;
  if preps_+deliveries_>0 then
   update public.push_subscriptions set claimed_until=now()+interval '5 minutes' where id=row_.id;
   result_:=result_||jsonb_build_array(jsonb_build_object('id',row_.id,'ownerId',row_.owner_id,'subscription',row_.subscription,'day',day_,'preparations',preps_,'deliveries',deliveries_));
  end if;
 end loop;return result_;
end $$;
revoke all on function public.bum_push_claim(integer) from public,anon,authenticated;
grant execute on function public.bum_push_claim(integer) to service_role;
commit;
