begin;
-- Extend only the yield-unit allowlist in existing private recipe functions.
-- No new privileges, public endpoints, or changes to ingredient measurements.
do $$ declare f record;source_ text;changed_ integer:=0;
 old_ text:='''gal US'',''bandeja'',''caja''';
 new_ text:='''gal US'',''bandeja'',''caja'',''receta completa''';
begin
 for f in select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname in('guardar_receta_bum_bum','guardar_receta_producto_bum_bum','guardar_receta_recetario_bum_bum','actualizar_receta_recetario_bum_bum') loop
  source_:=pg_get_functiondef(f.oid);
  if position(old_ in source_)>0 then execute replace(source_,old_,new_);changed_:=changed_+1;end if;
 end loop;
 if changed_<1 then raise exception 'No se encontró la validación de rendimiento esperada';end if;
end $$;
commit;
