-- Pebble Town: Allgemeinchat (für alle angemeldeten Spieler:innen sichtbar)
create table if not exists public.pebble_chat (id bigint generated always as identity primary key, user_id uuid not null default auth.uid() references auth.users(id) on delete cascade, name text not null default '', t text not null check (char_length(t) between 1 and 200), created_at timestamptz not null default now());
create index if not exists pebble_chat_time on public.pebble_chat (created_at desc);
-- Name und Absender setzt immer der Server (niemand kann unter fremdem Namen schreiben)
create or replace function public.pebble_chat_fill() returns trigger language plpgsql security definer set search_path = public as $$
begin new.user_id := auth.uid(); new.name := coalesce((select p.name from public.pebble_profiles p where p.user_id = auth.uid()), 'Jemand'); new.created_at := now(); return new; end $$;
drop trigger if exists pebble_chat_fill on public.pebble_chat;
create trigger pebble_chat_fill before insert on public.pebble_chat for each row execute function public.pebble_chat_fill();
alter table public.pebble_chat enable row level security;
drop policy if exists "chat lesen" on public.pebble_chat;
create policy "chat lesen" on public.pebble_chat for select to authenticated using (true);
drop policy if exists "chat schreiben" on public.pebble_chat;
create policy "chat schreiben" on public.pebble_chat for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "chat eigene loeschen" on public.pebble_chat;
create policy "chat eigene loeschen" on public.pebble_chat for delete to authenticated using (user_id = auth.uid());
do $$ begin alter publication supabase_realtime add table public.pebble_chat; exception when others then null; end $$;
