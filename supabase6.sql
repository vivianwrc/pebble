-- Pebble Town: Moderation im Allgemeinchat und tägliche Sicherung der Spielstände

-- Wer ist Betreiberin (Moderation)?
create or replace function public.pebble_is_admin() returns boolean language sql stable as $$
  select coalesce(lower(auth.jwt() ->> 'email') in ('vivianweirauch30@gmail.com'), false) $$;

-- Gesperrte Spieler:innen dürfen nicht mehr im Allgemeinchat schreiben
create table if not exists public.pebble_bans (user_id uuid primary key references auth.users(id) on delete cascade, reason text default '', created_at timestamptz not null default now());
alter table public.pebble_bans enable row level security;
drop policy if exists "bans lesen" on public.pebble_bans;
create policy "bans lesen" on public.pebble_bans for select to authenticated using (user_id = auth.uid() or public.pebble_is_admin());
drop policy if exists "bans verwalten" on public.pebble_bans;
create policy "bans verwalten" on public.pebble_bans for all to authenticated using (public.pebble_is_admin()) with check (public.pebble_is_admin());

drop policy if exists "chat schreiben" on public.pebble_chat;
create policy "chat schreiben" on public.pebble_chat for insert to authenticated with check (user_id = auth.uid() and not exists (select 1 from public.pebble_bans b where b.user_id = auth.uid()));
drop policy if exists "chat eigene loeschen" on public.pebble_chat;
create policy "chat eigene loeschen" on public.pebble_chat for delete to authenticated using (user_id = auth.uid() or public.pebble_is_admin());

-- Meldungen
create table if not exists public.pebble_reports (id bigint generated always as identity primary key, reporter uuid not null default auth.uid() references auth.users(id) on delete cascade, chat_id bigint, reported_user uuid, reported_name text, t text, reason text default '', created_at timestamptz not null default now(), done boolean not null default false);
alter table public.pebble_reports enable row level security;
drop policy if exists "melden" on public.pebble_reports;
create policy "melden" on public.pebble_reports for insert to authenticated with check (reporter = auth.uid());
drop policy if exists "meldungen lesen" on public.pebble_reports;
create policy "meldungen lesen" on public.pebble_reports for select to authenticated using (public.pebble_is_admin());
drop policy if exists "meldungen bearbeiten" on public.pebble_reports;
create policy "meldungen bearbeiten" on public.pebble_reports for update to authenticated using (public.pebble_is_admin()) with check (public.pebble_is_admin());
drop policy if exists "meldungen loeschen" on public.pebble_reports;
create policy "meldungen loeschen" on public.pebble_reports for delete to authenticated using (public.pebble_is_admin());

-- Tägliche Sicherung der Spielstände (14 Tage aufbewahrt)
create table if not exists public.pebble_backup (day date not null, user_id uuid not null references auth.users(id) on delete cascade, data jsonb, primary key (day, user_id));
alter table public.pebble_backup enable row level security; -- keine Policy: nur die Datenbank selbst kommt dran
create extension if not exists pg_cron;
create or replace function public.pebble_backup_run() returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.pebble_backup(day, user_id, data) select current_date, user_id, data from public.pebble_saves on conflict (day, user_id) do update set data = excluded.data;
  delete from public.pebble_backup where day < current_date - 14;
end $$;
revoke all on function public.pebble_backup_run() from public, anon, authenticated;
select cron.unschedule(jobid) from cron.job where jobname = 'pebble-backup';
select cron.schedule('pebble-backup', '0 3 * * *', 'select public.pebble_backup_run()');
select public.pebble_backup_run();

-- Konto löschen: auch Sicherungen und Meldungen der Person entfernen
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
