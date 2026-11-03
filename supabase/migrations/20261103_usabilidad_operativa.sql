begin;
-- Preserve the quotation as it was accepted; clients cannot forge material-consumption history.
alter function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean) rename to bum_validate_entry_before_ux;
create function public.bum_validate_entry(p_id uuid,p_kind text,p_details jsonb,p_owner uuid,p_require_recipe boolean) returns jsonb language plpgsql security invoker set search_path='' as $$
declare d jsonb;old_ public.business_entries;q public.quotes;reference_ uuid;begin
 if p_kind<>'order' then return public.bum_validate_entry_before_ux(p_id,p_kind,p_details,p_owner,p_require_recipe);end if;
 d:=public.bum_validate_entry_before_ux(p_id,p_kind,p_details-'quoteId'-'quoteSnapshot'-'materialUsage'-'materialCost',p_owner,p_require_recipe);
 select * into old_ from public.business_entries where id=p_id and owner_id=p_owner and kind='order';
 reference_:=case when p_details?'quoteId' then nullif(p_details->>'quoteId','')::uuid else nullif(old_.details->>'quoteId','')::uuid end;
 if reference_ is not null then
  if reference_::text=old_.details->>'quoteId' then d:=d||jsonb_build_object('quoteId',reference_,'quoteSnapshot',old_.details->'quoteSnapshot');
  else
   if old_.details?'materialUsage' or exists(select 1 from public.business_entries where owner_id=p_owner and kind='work_order' and details->>'orderId'=p_id::text and details->>'status'='done') or exists(select 1 from public.sales where owner_id=p_owner and details->>'orderId'=p_id::text) then raise exception 'El pedido ya tiene producción o venta; conserva su cotización de origen';end if;
   select * into q from public.quotes where id=reference_ and owner_id=p_owner;if not found then raise exception 'Selecciona una cotización de tu cuenta';end if;
   d:=d||jsonb_build_object('quoteId',reference_,'quoteSnapshot',q.details||jsonb_build_object('id',q.id,'price',q.quoted_price,'totalCost',q.total_cost));
  end if;
  if p_require_recipe and exists(select 1 from public.business_entries where owner_id=p_owner and kind='order' and id<>p_id and details->>'quoteId'=reference_::text and details->>'status'<>'cancelled') then raise exception 'Esta cotización ya tiene un pedido activo. Revisa ese pedido en lugar de duplicarlo';end if;
 elsif old_.details?'quoteId' and (old_.details?'materialUsage' or exists(select 1 from public.business_entries where owner_id=p_owner and kind='work_order' and details->>'orderId'=p_id::text and details->>'status'='done')) then raise exception 'Conserva la cotización del pedido que ya fue preparado';end if;
 if old_.details?'materialUsage' then d:=d||jsonb_build_object('materialUsage',old_.details->'materialUsage','materialCost',old_.details->'materialCost');end if;
 return d;
end $$;
revoke all on function public.bum_validate_entry(uuid,text,jsonb,uuid,boolean),public.bum_validate_entry_before_ux(uuid,text,jsonb,uuid,boolean) from public,anon,authenticated;

create function public.bum_pack_order(p_order uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();o public.business_entries;raw_ jsonb;materials_ jsonb;item_ jsonb;i public.ingredients;qty numeric;total_ numeric:=0;used_ jsonb:='[]';day_ date:=(now() at time zone 'America/Santo_Domingo')::date;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));
 select * into o from public.business_entries where id=p_order and owner_id=u and kind='order' for update;if not found or o.details->>'status'='cancelled' then raise exception 'Pedido no disponible';end if;
 if o.details?'materialUsage' or not o.details?'quoteSnapshot' then return to_jsonb(o);end if;
 if exists(select 1 from public.business_entries where owner_id=u and kind='work_order' and details->>'orderId'=p_order::text and details->>'status' in('planned','preparing')) then raise exception 'Termina las preparaciones en Agenda antes de marcar el pedido Listo o registrar su venta';end if;
 raw_:=coalesce(o.details->'quoteSnapshot'->'breakdown'->'materialLines',o.details->'quoteSnapshot'->'materials','[]');
 if jsonb_typeof(raw_) is distinct from 'array' or jsonb_array_length(raw_)>500 then raise exception 'Revisa los materiales adicionales de la cotización';end if;
 materials_:='[]';
 for item_ in select * from jsonb_array_elements(raw_) loop
  select * into i from public.ingredients where id=(item_->>'id')::uuid and owner_id=u and item_kind='material';if not found then raise exception 'Un material adicional ya no está en tu catálogo';end if;
  qty:=public.bum_recipe_base(i.id,coalesce(item_->>'quantity',item_->>'qty')::numeric,coalesce(item_->>'unit',i.base_unit),u);perform public.bum_ops_number(to_jsonb(qty),'la cantidad del material',1e12,true);
  materials_:=materials_||jsonb_build_array(jsonb_build_object('id',i.id,'quantity',qty));
 end loop;
 perform 1 from public.ingredients where owner_id=u and id in(select (x->>'id')::uuid from jsonb_array_elements(materials_) x) order by id for update;
 for item_ in select jsonb_build_object('id',x->>'id','quantity',sum((x->>'quantity')::numeric)) from jsonb_array_elements(materials_) x group by x->>'id' order by x->>'id' loop
  select * into i from public.ingredients where id=(item_->>'id')::uuid and owner_id=u;qty:=(item_->>'quantity')::numeric;
  if i.stock_quantity is null or i.stock_quantity<qty or i.last_unit_cost is null then raise exception 'Completa existencias y precio de % antes de terminar el pedido',i.name;end if;
  perform public.bum_consume_raw_lots(i.id,qty,day_,'production',p_order);
  perform public.bum_ops_put(gen_random_uuid(),'inventory_event',jsonb_build_object('ingredientId',i.id,'date',day_,'quantity',qty,'before',i.stock_quantity,'after',i.stock_quantity-qty,'unit',i.base_unit,'reason','order_materials','sourceId',p_order,'cost',qty*i.last_unit_cost),0);
  update public.ingredients set stock_quantity=stock_quantity-qty where id=i.id and owner_id=u;
  total_:=total_+qty*i.last_unit_cost;used_:=used_||jsonb_build_array(jsonb_build_object('ingredientId',i.id,'name',i.name,'quantity',qty,'unit',i.base_unit,'unitCost',i.last_unit_cost));
 end loop;
 insert into public.business_entry_history(owner_id,entry_id,kind,details,version) values(u,o.id,o.kind,o.details,o.version);
 update public.business_entries set details=details||jsonb_build_object('materialUsage',used_,'materialCost',total_),version=version+1,updated_at=now() where id=o.id and owner_id=u returning * into o;
 return to_jsonb(o);
end $$;
revoke all on function public.bum_pack_order(uuid) from public,anon,authenticated;

alter function public.bum_save_entry(uuid,text,jsonb,integer) rename to bum_save_entry_before_ux;
create function public.bum_save_entry(p_id uuid,p_kind text,p_details jsonb,p_expected integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare result_ jsonb;begin
 result_:=public.bum_save_entry_before_ux(p_id,p_kind,p_details,p_expected);
 if p_kind='order' and result_->'details'->>'status' in('ready','delivered') then return public.bum_pack_order(p_id);end if;
 return result_;
end $$;
revoke all on function public.bum_save_entry(uuid,text,jsonb,integer),public.bum_save_entry_before_ux(uuid,text,jsonb,integer) from public,anon,authenticated;
grant execute on function public.bum_save_entry(uuid,text,jsonb,integer) to authenticated;

alter function public.bum_order_sale(uuid,uuid,date,text,numeric,numeric) rename to bum_order_sale_before_ux;
create function public.bum_order_sale(p_id uuid,p_order uuid,p_date date,p_channel text,p_commission numeric,p_extra numeric) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();o jsonb;r jsonb;exists_ boolean;cost_ numeric;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));
 select exists(select 1 from public.sales where id=p_id) into exists_;
 if exists_ then return public.bum_order_sale_before_ux(p_id,p_order,p_date,p_channel,p_commission,p_extra);end if;
 o:=public.bum_pack_order(p_order);r:=public.bum_order_sale_before_ux(p_id,p_order,p_date,p_channel,p_commission,p_extra);
 cost_:=round(coalesce((o->'details'->>'materialCost')::numeric,0),2);
 update public.sales set cost_amount=cost_amount+cost_,details=details||jsonb_build_object('productionCost',coalesce((details->>'productionCost')::numeric,0)+cost_,'additionalMaterialsCost',cost_) where id=p_id and owner_id=u returning to_jsonb(sales.*) into r;
 return r;
end $$;
revoke all on function public.bum_order_sale(uuid,uuid,date,text,numeric,numeric),public.bum_order_sale_before_ux(uuid,uuid,date,text,numeric,numeric) from public,anon,authenticated;
grant execute on function public.bum_order_sale(uuid,uuid,date,text,numeric,numeric) to authenticated;

-- Restore historical stages together with the formula, mapping old line IDs to the restored lines.
create or replace function public.bum_restore_recipe_version(p_version uuid,p_original jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();v public.recipe_versions;m jsonb;line_ jsonb;stage_ jsonb;lines_ jsonb:='[]';stages_ jsonb:='[]';indices_ jsonb;args_ jsonb;current_ boolean;begin
 if u is null or not public.bum_account_approved() then raise exception 'Cuenta no autorizada';end if;perform pg_advisory_xact_lock(hashtextextended(u::text,931));
 select * into v from public.recipe_versions where id=p_version and owner_id=u;if not found then raise exception 'Versión no disponible';end if;
 if exists(select 1 from public.recipes where id=v.recipe_id and owner_id<>u) then raise exception 'No se puede recuperar este identificador';end if;
 perform 1 from public.recipes where id=v.recipe_id and owner_id=u for update;current_:=found;
 if not current_ and p_original is not null then raise exception 'La receta ya no está. Actualiza el historial';end if;
 if current_ and p_original is null then raise exception 'Actualiza la receta antes de recuperar esta versión';end if;
 begin m:=(v.snapshot->>'instructions')::jsonb;exception when others then m:='{}';end;
 if jsonb_typeof(m) is distinct from 'object' then m:='{}';end if;
 for line_ in select * from jsonb_array_elements(v.snapshot->'lines') loop
  lines_:=lines_||jsonb_build_array(jsonb_build_object('ingredient_id',line_->>'ingredient_id','quantity_base',(line_->>'quantity_base')::numeric,'measurement_quantity',(line_->>'measurement_quantity')::numeric,'measurement_unit',line_->>'measurement_unit')||case when current_ and exists(select 1 from public.recipe_lines where id=(line_->>'id')::uuid and recipe_id=v.recipe_id and owner_id=u) then jsonb_build_object('id',line_->>'id') else '{}'::jsonb end);
 end loop;
 for stage_ in select * from jsonb_array_elements(coalesce(m->'stages','[]')) loop
  if exists(select 1 from jsonb_array_elements_text(stage_->'lineIds') id_ where not exists(select 1 from jsonb_array_elements(v.snapshot->'lines') l where l->>'id'=id_)) then raise exception 'Esta versión tiene una asignación de etapas incompleta. Elige otra versión; no se cambió la receta';end if;
  select coalesce(jsonb_agg(n-1 order by n),'[]') into indices_ from jsonb_array_elements(v.snapshot->'lines') with ordinality l(value,n) where stage_->'lineIds' ? (l.value->>'id');
  stages_:=stages_||jsonb_build_array(jsonb_build_object('id',stage_->>'id','name',stage_->>'name','preparation',coalesce(stage_->>'preparation',''),'lineIndexes',indices_));
 end loop;
 args_:=jsonb_build_object('p_id',v.recipe_id,'p_name',v.snapshot->>'name','p_yield',(v.snapshot->>'yield_quantity')::numeric,'p_yield_unit',v.snapshot->>'yield_unit','p_scaling',coalesce(m->>'scaling','scalable'),'p_product_type',coalesce(m->>'productType','Otro artículo'),'p_book_id',v.snapshot->>'recipe_book_id','p_preparation',coalesce(m->>'preparation',m->>'legacyInstructions',case when m='{}'::jsonb then v.snapshot->>'instructions' else '' end,''),'p_category',coalesce(m->>'category',''),'p_lines',lines_);
 return public.bum_save_staged_recipe(args_,stages_,case when current_ then p_original else null end);
end $$;
revoke all on function public.bum_restore_recipe_version(uuid,jsonb) from public,anon,authenticated;
grant execute on function public.bum_restore_recipe_version(uuid,jsonb) to authenticated;
commit;
