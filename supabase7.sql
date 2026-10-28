-- Pebble Town: echtes Gästebuch – Freund:innen schreiben einander Einträge
create table if not exists public.pebble_guestbook (id bigint generated always as identity primary key, owner uuid not null references auth.users(id) on delete cascade, author uuid not null default auth.uid() references auth.users(id) on delete cascade, author_name text not null default '', t text not null check (char_length(t) between 1 and 200), created_at timestamptz not null default now());
create index if not exists pebble_guestbook_owner on public.pebble_guestbook (owner, created_at desc);
create or replace function public.pebble_gb_fill() returns trigger language plpgsql security definer set search_path = public as $$
begin new.author := auth.uid(); new.author_name := coalesce((select p.name from public.pebble_profiles p where p.user_id = auth.uid()), 'Jemand'); new.created_at := now(); return new; end $$;
drop trigger if exists pebble_gb_fill on public.pebble_guestbook;
create trigger pebble_gb_fill before insert on public.pebble_guestbook for each row execute function public.pebble_gb_fill();
alter table public.pebble_guestbook enable row level security;
drop policy if exists "gb lesen" on public.pebble_guestbook;
create policy "gb lesen" on public.pebble_guestbook for select to authenticated using (
  owner = auth.uid() or author = auth.uid() or public.pebble_is_admin()
  or exists (select 1 from public.pebble_friends f where f.status = 'accepted' and ((f.a = auth.uid() and f.b = owner) or (f.b = auth.uid() and f.a = owner))));
drop policy if exists "gb schreiben" on public.pebble_guestbook;
create policy "gb schreiben" on public.pebble_guestbook for insert to authenticated with check (
  author = auth.uid() and owner <> auth.uid()
  and not exists (select 1 from public.pebble_bans b where b.user_id = auth.uid())
  and exists (select 1 from public.pebble_friends f where f.status = 'accepted' and ((f.a = auth.uid() and f.b = owner) or (f.b = auth.uid() and f.a = owner))));
drop policy if exists "gb loeschen" on public.pebble_guestbook;
create policy "gb loeschen" on public.pebble_guestbook for delete to authenticated using (owner = auth.uid() or author = auth.uid() or public.pebble_is_admin());

-- Konto löschen: auch Gästebuch-Einträge entfernen
create or replace function public.pebble_delete_me() returns text language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); r record; used boolean := false; n int;
begin
  if uid is null then raise exception 'nicht angemeldet'; end if;
  delete from public.pebble_msgs where sender = uid or receiver = uid;
  delete from public.pebble_chat where user_id = uid;
  delete from public.pebble_guestbook where owner = uid or author = uid;
  delete from public.pebble_friends where a = uid or b = uid;
  delete from public.pebble_pubkeys where user_id = uid;
  delete from public.pebble_privkeys where user_id = uid;
  delete from public.pebble_saves where user_id = uid;
  delete from public.pebble_backup where user_id = uid;
  delete from public.pebble_reports where reporter = uid;
  delete from public.pebble_logins where user_id = uid;
  delete from public.pebble_profiles where user_id = uid;
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
