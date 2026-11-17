begin;
create function public.bum_retire_work(p_work uuid,p_expected integer,p_restore boolean default false) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();w public.business_entries;o public.business_entries;next_ jsonb;begin
 if u is null or not public.bum_account_approved() or p_work is null or p_expected is null or p_expected<0 or p_restore is null then raise exception 'Cuenta o trabajo no disponible';end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text,931));
 select * into w from public.business_entries where id=p_work and owner_id=u and kind='work_order' for update;
 if not found then raise exception 'Trabajo no disponible';end if;
 if w.version<>p_expected then raise exception 'El trabajo cambió. Actualiza la lista antes de continuar';end if;
 if w.details?'productionId' or w.details?'consumptions' or w.details?'productionCost' or w.details->>'status'='done' then raise exception 'Una preparación terminada conserva su historial';end if;
 if p_restore then
  if w.details->>'status' is distinct from 'cancelled' then raise exception 'El trabajo ya no está retirado';end if;
  select * into o from public.business_entries where owner_id=u and kind='order' and id::text=w.details->>'orderId';
  if found and o.details->>'status' in('cancelled','ready','delivered') then raise exception 'Revisa primero el estado del pedido';end if;
  next_:=jsonb_set(w.details,'{status}','"planned"');
  return public.bum_save_entry(w.id,'work_order',next_,w.version);
 end if;
 if coalesce(w.details->>'status','') not in('planned','preparing') then raise exception 'El trabajo no está pendiente';end if;
 -- A deleted recipe must not prevent retiring an obsolete pending task.
 insert into public.business_entry_history(owner_id,entry_id,kind,details,version) values(u,w.id,w.kind,w.details,w.version);
 update public.business_entries set details=jsonb_set(details,'{status}','"cancelled"'),version=version+1,updated_at=now() where id=w.id and owner_id=u returning * into w;
 return to_jsonb(w);
end $$;
revoke all on function public.bum_retire_work(uuid,integer,boolean) from public,anon,authenticated;
grant execute on function public.bum_retire_work(uuid,integer,boolean) to authenticated;
commit;
