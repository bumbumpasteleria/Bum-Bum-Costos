-- Run after the migration in a transaction and ROLLBACK all synthetic records.
insert into auth.users(id,email) values('12371400-0000-4000-8000-000000000001','notices-a@example.invalid'),('12371400-0000-4000-8000-000000000002','notices-b@example.invalid');
update public.business_profiles set status='approved',password_required=false where id in('12371400-0000-4000-8000-000000000001','12371400-0000-4000-8000-000000000002');
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost,stock_quantity,minimum_stock) values('12371400-0000-4000-8000-000000000011','12371400-0000-4000-8000-000000000001','SINTETICO','g',1,3,3),('12371400-0000-4000-8000-000000000012','12371400-0000-4000-8000-000000000002','OTRA CUENTA','g',1,0,3);
insert into public.business_entries(id,owner_id,kind,details) values('12371400-0000-4000-8000-000000000021','12371400-0000-4000-8000-000000000001','work_order',jsonb_build_object('name','SINTETICO','date',(now() at time zone 'America/Santo_Domingo')::date,'status','planned'));
insert into public.business_entries(id,owner_id,kind,details) values
('12371400-0000-4000-8000-000000000022','12371400-0000-4000-8000-000000000001','order',jsonb_build_object('status','pending','deliveryDate',(now() at time zone 'America/Santo_Domingo')::date,'total',100,'deposit',20)),
('12371400-0000-4000-8000-000000000023','12371400-0000-4000-8000-000000000001','order',jsonb_build_object('status','cancelled','deliveryDate',(now() at time zone 'America/Santo_Domingo')::date,'total',100,'deposit',0)),
('12371400-0000-4000-8000-000000000024','12371400-0000-4000-8000-000000000001','raw_lot',jsonb_build_object('ingredientId','12371400-0000-4000-8000-000000000011','remaining',1,'expires',((now() at time zone 'America/Santo_Domingo')::date+2)));
insert into public.fridge_products(id,owner_id,recipe_id,name,unit,minimum_quantity) values('12371400-0000-4000-8000-000000000031','12371400-0000-4000-8000-000000000001','12371400-0000-4000-8000-000000000099','SINTETICO','unidad',2);
insert into public.fridge_batches(id,owner_id,product_id,prepared_on,expires_on,initial_quantity,remaining_quantity,unit_cost,recipe_factor) values('12371400-0000-4000-8000-000000000032','12371400-0000-4000-8000-000000000001','12371400-0000-4000-8000-000000000031',(now() at time zone 'America/Santo_Domingo')::date,(now() at time zone 'America/Santo_Domingo')::date+2,1,1,1,1);
insert into public.push_subscriptions(id,owner_id,subscription,hour) values('synthetic-notices-device','12371400-0000-4000-8000-000000000001','{}',0);
insert into public.push_preferences(owner_id,preferences) values('12371400-0000-4000-8000-000000000001','{"preparations":false}');
do $$ declare e jsonb;begin
 e:=public.bum_notice_events('12371400-0000-4000-8000-000000000001',(now() at time zone 'America/Santo_Domingo')::date);
 if (select (value->>'count')::integer from jsonb_array_elements(e) where value->>'kind'='shopping')<>1 then raise exception 'Mínimo o aislamiento incorrecto';end if;
 if exists(select 1 from jsonb_array_elements(e) where value->>'kind' in('deliveries','production','fridgeExpiry','rawExpiry','balances') and (value->>'count')::integer<>1) then raise exception 'Conteo por módulo incorrecto';end if;
 if exists(select 1 from jsonb_array_elements(e) where value->>'kind'='requests') then raise exception 'Solicitudes visibles a cuenta normal';end if;
end $$;
set local role authenticated;
set local request.jwt.claim.sub='12371400-0000-4000-8000-000000000001';
do $$ begin
 begin perform public.bum_notice_events('12371400-0000-4000-8000-000000000002',current_date);raise exception 'Lectura privilegiada permitida';exception when insufficient_privilege then null;end;
 begin perform public.bum_notice_claim(1);raise exception 'Despacho permitido a cliente';exception when insufficient_privilege then null;end;
end $$;
reset role;
-- Isolate claims without changing real subscription state permanently: this transaction rolls back.
update public.push_subscriptions set claimed_until=now()+interval '1 hour' where id<>'synthetic-notices-device';
set local role service_role;
do $$ declare r jsonb;e jsonb;day_ date:=(now() at time zone 'America/Santo_Domingo')::date;begin
 r:=public.bum_notice_claim(100);
 if jsonb_array_length(r)<>1 then raise exception 'No se reservó el dispositivo sintético';end if;
 if exists(select 1 from jsonb_array_elements(r->0->'events') where value->>'kind'='preparations') then raise exception 'Preferencia desactivada ignorada';end if;
 for e in select value from jsonb_array_elements(r->0->'events') loop perform public.bum_notice_ack('synthetic-notices-device','12371400-0000-4000-8000-000000000001',e->>'kind',day_);end loop;
 if public.bum_notice_claim(100)<>'[]'::jsonb then raise exception 'Reserva duplicada';end if;
 update public.push_subscriptions set claimed_until=null,last_checked_at=now()-interval '16 minutes' where id='synthetic-notices-device';
 if public.bum_notice_claim(100)<>'[]'::jsonb then raise exception 'Se repitió un aviso confirmado el mismo día';end if;
end $$;
reset role;
select 'Privacidad, mínimos, preferencias y confirmación diaria correctos' as resultado;
rollback;
