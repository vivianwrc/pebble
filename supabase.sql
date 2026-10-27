-- Pebble – Spielstände online speichern
-- Einmal im Supabase SQL Editor ausführen (New query → einfügen → Run).
create table if not exists public.pebble_saves (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  name       text,
  data       jsonb,
  updated_at timestamptz not null default now()
);
alter table public.pebble_saves enable row level security;
drop policy if exists "pebble lesen" on public.pebble_saves;
create policy "pebble lesen" on public.pebble_saves for select using (user_id = auth.uid());
drop policy if exists "pebble anlegen" on public.pebble_saves;
create policy "pebble anlegen" on public.pebble_saves for insert with check (user_id = auth.uid());
drop policy if exists "pebble ändern" on public.pebble_saves;
create policy "pebble ändern" on public.pebble_saves for update using (user_id = auth.uid()) with check (user_id = auth.uid());
