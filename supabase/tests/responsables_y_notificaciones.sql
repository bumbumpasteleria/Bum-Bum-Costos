-- Append to the migration without COMMIT. All synthetic rows are rolled back.
insert into auth.users(id,email) values('12371100-0000-4000-8000-000000000001','reminders-a@example.invalid'),('12371100-0000-4000-8000-000000000002','reminders-b@example.invalid');
update public.business_profiles set status='approved',password_required=false where id in('12371100-0000-4000-8000-000000000001','12371100-0000-4000-8000-000000000002');
insert into public.ingredients(id,owner_id,name,base_unit,last_unit_cost) values('12371100-0000-4000-8000-000000000011','12371100-0000-4000-8000-000000000001','ARTICULO SINTETICO','g',1);
insert into public.business_entries(id,owner_id,kind,details) values('12371100-0000-4000-8000-000000000021','12371100-0000-4000-8000-000000000001','work_order',jsonb_build_object('name','PREPARACION SINTETICA','date',(now() at time zone 'America/Santo_Domingo')::date,'status','planned'));
set local role authenticated;
set local request.jwt.claim.sub='12371100-0000-4000-8000-000000000001';
do $$ declare r_ jsonb;failed_ boolean;backup_ jsonb;begin
 r_:=public.bum_assign_task('shopping','12371100-0000-4000-8000-000000000011','Ana Pérez',0);
 if r_->>'responsible'<>'Ana Pérez' or (r_->>'version')::integer<>1 then raise exception 'Asignación perdida';end if;
 perform public.bum_assign_task('shopping','12371100-0000-4000-8000-000000000011','Ana Pérez',0);
 perform public.bum_assign_task('shopping','12371100-0000-4000-8000-000000000011','María López',1);
 failed_:=false;begin perform public.bum_assign_task('shopping','12371100-0000-4000-8000-000000000011','Ana Pérez',1);exception when others then failed_:=true;end;if not failed_ then raise exception 'Sobrescritura concurrente';end if;
 perform public.bum_assign_task('work','12371100-0000-4000-8000-000000000021','Ana Pérez',0);
 backup_:=public.bum_export_backup();if not exists(select 1 from jsonb_array_elements(backup_->'data'->'business_entries') e where e->>'kind'='task_assignment') then raise exception 'El respaldo omitió responsables';end if;
 failed_:=false;begin perform public.bum_push_claim();exception when insufficient_privilege then failed_:=true;end;if not failed_ then raise exception 'El cliente ejecutó el despachador';end if;
end $$;
set local request.jwt.claim.sub='12371100-0000-4000-8000-000000000002';
do $$ declare failed_ boolean:=false;begin
 begin perform public.bum_assign_task('shopping','12371100-0000-4000-8000-000000000011','Intruso',0);exception when others then failed_:=true;end;if not failed_ or exists(select 1 from public.business_entries where kind='task_assignment') then raise exception 'Acceso entre cuentas';end if;
end $$;
reset role;
insert into public.push_subscriptions(id,owner_id,subscription,hour) values('synthetic-reminder','12371100-0000-4000-8000-000000000001','{}',0);
set local role service_role;
do $$ declare rows_ jsonb;begin
 rows_:=public.bum_push_claim();if jsonb_array_length(rows_)<>1 or (rows_->0->>'preparations')::integer<>1 then raise exception 'Pendientes incorrectos';end if;
 if jsonb_array_length(public.bum_push_claim())<>0 then raise exception 'Aviso duplicado en paralelo';end if;
 update public.push_subscriptions set last_sent_day=(now() at time zone 'America/Santo_Domingo')::date,claimed_until=null where id='synthetic-reminder';
 if jsonb_array_length(public.bum_push_claim())<>0 then raise exception 'Aviso diario duplicado';end if;
end $$;
select true as responsables_privacidad_respaldo_y_avisos_verificados;
rollback;
