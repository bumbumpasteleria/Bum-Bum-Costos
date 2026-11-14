begin;
create table public.push_preferences(owner_id uuid primary key references auth.users(id) on delete cascade,preferences jsonb not null default '{}');
alter table public.push_preferences enable row level security;
revoke all on public.push_preferences from public,anon,authenticated;
grant all on public.push_preferences to service_role;
alter table public.push_subscriptions add column sent_events jsonb not null default '{}',add column last_checked_at timestamptz;

create function public.bum_notice_events(p_owner uuid,p_day date) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result_ jsonb:='[]';n_ integer;begin
 select count(*) into n_ from public.business_entries w where owner_id=p_owner and kind='work_order' and details->>'status' in('planned','preparing') and details->>'date'<=p_day::text and not exists(select 1 from public.business_entries o where o.owner_id=p_owner and o.kind='order' and o.id::text=w.details->>'orderId' and o.details->>'status'='cancelled');
 result_:=result_||jsonb_build_array(jsonb_build_object('kind','preparations','count',n_,'target','Agenda y cobros'));
 select count(*) into n_ from public.business_entries where owner_id=p_owner and kind='order' and details->>'status' not in('delivered','cancelled') and details->>'deliveryDate'<=p_day::text;
 result_:=result_||jsonb_build_array(jsonb_build_object('kind','deliveries','count',n_,'target','Pedidos'));
 select count(*) into n_ from public.ingredients i where owner_id=p_owner and stock_quantity is not null and minimum_stock is not null and greatest(0,i.stock_quantity-coalesce((select sum((r.details->>'remaining')::numeric) from public.business_entries r where r.owner_id=p_owner and r.kind='raw_lot' and r.details->>'ingredientId'=i.id::text and ((nullif(r.details->>'expires','') is not null and r.details->>'expires'<p_day::text) or (select q.details->>'result' from public.business_entries q where q.owner_id=p_owner and q.kind='quality' and q.details->>'lotId'=r.id::text order by q.updated_at desc,q.id desc limit 1)='blocked')),0))<=minimum_stock;
 result_:=result_||jsonb_build_array(jsonb_build_object('kind','shopping','count',n_,'target','Compras'));
 select count(*) into n_ from public.fridge_products p where p.owner_id=p_owner and coalesce((select sum(b.remaining_quantity) from public.fridge_batches b where b.owner_id=p_owner and b.product_id=p.id and b.remaining_quantity>0 and b.prepared_on<=p_day and (b.expires_on is null or b.expires_on>=p_day) and (select q.details->>'result' from public.business_entries q where q.owner_id=p_owner and q.kind='quality' and q.details->>'lotId'=b.id::text order by q.updated_at desc,q.id desc limit 1) is distinct from 'blocked'),0)<=p.minimum_quantity;
 result_:=result_||jsonb_build_array(jsonb_build_object('kind','production','count',n_,'target','Producción'));
 select count(*) into n_ from public.fridge_batches where owner_id=p_owner and remaining_quantity>0 and prepared_on<=p_day and expires_on<=p_day+3;
 result_:=result_||jsonb_build_array(jsonb_build_object('kind','fridgeExpiry','count',n_,'target','Mi nevera'));
 select count(*) into n_ from public.business_entries where owner_id=p_owner and kind='raw_lot' and (details->>'remaining')::numeric>0 and nullif(details->>'expires','') is not null and details->>'expires'<=(p_day+3)::text;
 result_:=result_||jsonb_build_array(jsonb_build_object('kind','rawExpiry','count',n_,'target','Movimientos de inventario'));
 select count(*) into n_ from public.business_entries where owner_id=p_owner and kind='order' and details->>'status'<>'cancelled' and details->>'deliveryDate'<=p_day::text and (details->>'total')::numeric>(details->>'deposit')::numeric;
 result_:=result_||jsonb_build_array(jsonb_build_object('kind','balances','count',n_,'target','Caja y rentabilidad'));
 if exists(select 1 from public.business_admins where user_id=p_owner) then
  select count(*) into n_ from public.account_requests where status='pending';
  result_:=result_||jsonb_build_array(jsonb_build_object('kind','requests','count',n_,'target','Solicitudes'));
 end if;
 return result_;
end $$;
revoke all on function public.bum_notice_events(uuid,date) from public,anon,authenticated;
grant execute on function public.bum_notice_events(uuid,date) to service_role;

create function public.bum_notice_claim(p_limit integer default 20) returns jsonb language plpgsql security definer set search_path='' as $$
declare r_ public.push_subscriptions;e_ jsonb;prefs_ jsonb;events_ jsonb;day_ date:=(now() at time zone 'America/Santo_Domingo')::date;hour_ integer:=extract(hour from now() at time zone 'America/Santo_Domingo');result_ jsonb:='[]';begin
 for r_ in select s.* from public.push_subscriptions s join public.business_profiles p on p.id=s.owner_id where s.enabled and p.status='approved' and not p.password_required and s.hour<=hour_ and (s.claimed_until is null or s.claimed_until<now()) and (s.last_checked_at is null or s.last_checked_at<now()-interval '14 minutes') order by s.last_checked_at nulls first,s.id limit least(greatest(p_limit,1),100) for update of s skip locked loop
  select preferences into prefs_ from public.push_preferences where owner_id=r_.owner_id;
  events_:='[]';
  for e_ in select value from jsonb_array_elements(public.bum_notice_events(r_.owner_id,day_)) loop
   if (e_->>'count')::integer>0 and coalesce((prefs_->>(case when e_->>'kind' in('fridgeExpiry','rawExpiry') then 'expiry' else e_->>'kind' end))::boolean,true) and r_.sent_events->>(e_->>'kind') is distinct from day_::text then events_:=events_||jsonb_build_array(e_);end if;
  end loop;
  update public.push_subscriptions set last_checked_at=now(),claimed_until=case when jsonb_array_length(events_)>0 then now()+interval '5 minutes' else null end where id=r_.id;
  if jsonb_array_length(events_)>0 then result_:=result_||jsonb_build_array(jsonb_build_object('id',r_.id,'ownerId',r_.owner_id,'subscription',r_.subscription,'day',day_,'events',events_));end if;
 end loop;return result_;
end $$;
create function public.bum_notice_ack(p_id text,p_owner uuid,p_kind text,p_day date) returns void language plpgsql security definer set search_path='' as $$begin
 if p_kind not in('preparations','deliveries','shopping','production','fridgeExpiry','rawExpiry','balances','requests') then raise exception 'Aviso no válido';end if;
 update public.push_subscriptions set sent_events=jsonb_set(sent_events,array[p_kind],to_jsonb(p_day::text)),last_sent_day=p_day where id=p_id and owner_id=p_owner;
end $$;
revoke all on function public.bum_notice_claim(integer),public.bum_notice_ack(text,uuid,text,date) from public,anon,authenticated;
grant execute on function public.bum_notice_claim(integer),public.bum_notice_ack(text,uuid,text,date) to service_role;
commit;
