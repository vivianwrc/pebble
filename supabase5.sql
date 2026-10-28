-- Pebble Town: Konto und alle Pebble-Daten selbst löschen (DSGVO Art. 17)
-- Löscht alle Pebble-Daten der angemeldeten Person. Das Login selbst wird nur gelöscht,
-- wenn es in keiner anderen App dieses Projekts (z. B. Pingpaar) noch benutzt wird.
create or replace function public.pebble_delete_me() returns text language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); r record; used boolean := false; n int;
begin
  if uid is null then raise exception 'nicht angemeldet'; end if;
  delete from public.pebble_msgs where sender = uid or receiver = uid;
  delete from public.pebble_chat where user_id = uid;
  delete from public.pebble_friends where a = uid or b = uid;
  delete from public.pebble_pubkeys where user_id = uid;
  delete from public.pebble_privkeys where user_id = uid;
  delete from public.pebble_saves where user_id = uid;
  delete from public.pebble_logins where user_id = uid;
  delete from public.pebble_profiles where user_id = uid;
  -- nutzt eine andere App dieses Projekts das Login noch?
  for r in select kcu.table_schema, kcu.table_name, kcu.column_name
           from information_schema.table_constraints tc
           join information_schema.key_column_usage kcu on kcu.constraint_name = tc.constraint_name and kcu.table_schema = tc.table_schema
           join information_schema.constraint_column_usage ccu on ccu.constraint_name = tc.constraint_name
           where tc.constraint_type = 'FOREIGN KEY' and ccu.table_schema = 'auth' and ccu.table_name = 'users'
             and kcu.table_schema = 'public' and kcu.table_name not like 'pebble\_%'
  loop
    execute format('select count(*) from %I.%I where %I = $1', r.table_schema, r.table_name, r.column_name) into n using uid;
    if n > 0 then used := true; exit; end if;
  end loop;
  if not used then delete from auth.users where id = uid; return 'konto'; end if;
  return 'pebble';
end $$;
revoke all on function public.pebble_delete_me() from public, anon;
grant execute on function public.pebble_delete_me() to authenticated;
