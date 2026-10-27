-- Pebble Town: echter Freundes-Chat, Ende-zu-Ende-verschlüsselt
-- Öffentliche Schlüssel (alle Angemeldeten dürfen lesen)
create table if not exists public.pebble_pubkeys (user_id uuid primary key references auth.users(id) on delete cascade, pub jsonb not null, updated_at timestamptz not null default now());
alter table public.pebble_pubkeys enable row level security;
drop policy if exists "pubkeys lesen" on public.pebble_pubkeys;
create policy "pubkeys lesen" on public.pebble_pubkeys for select to authenticated using (true);
drop policy if exists "pubkeys eigene" on public.pebble_pubkeys;
create policy "pubkeys eigene" on public.pebble_pubkeys for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "pubkeys eigene aendern" on public.pebble_pubkeys;
create policy "pubkeys eigene aendern" on public.pebble_pubkeys for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
-- Privater Schlüssel, nur mit dem eigenen Passwort verschlüsselt, nur für sich selbst lesbar
create table if not exists public.pebble_privkeys (user_id uuid primary key references auth.users(id) on delete cascade, wrapped text not null, salt text not null, iv text not null, updated_at timestamptz not null default now());
alter table public.pebble_privkeys enable row level security;
drop policy if exists "privkeys nur selbst" on public.pebble_privkeys;
create policy "privkeys nur selbst" on public.pebble_privkeys for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
-- Nachrichten: nur verschlüsselt, nur Absender und Empfänger lesen, schreiben nur an echte Freunde
create table if not exists public.pebble_msgs (id bigint generated always as identity primary key, sender uuid not null references auth.users(id) on delete cascade, receiver uuid not null references auth.users(id) on delete cascade, iv text not null, ct text not null, created_at timestamptz not null default now());
create index if not exists pebble_msgs_recv on public.pebble_msgs (receiver, created_at);
create index if not exists pebble_msgs_send on public.pebble_msgs (sender, created_at);
alter table public.pebble_msgs enable row level security;
drop policy if exists "msgs lesen" on public.pebble_msgs;
create policy "msgs lesen" on public.pebble_msgs for select to authenticated using (auth.uid() = sender or auth.uid() = receiver);
drop policy if exists "msgs senden" on public.pebble_msgs;
create policy "msgs senden" on public.pebble_msgs for insert to authenticated with check (sender = auth.uid() and exists (select 1 from public.pebble_friends f where f.status = 'accepted' and ((f.a = sender and f.b = receiver) or (f.a = receiver and f.b = sender))));
-- Live-Zustellung
do $$ begin alter publication supabase_realtime add table public.pebble_msgs; exception when others then null; end $$;
