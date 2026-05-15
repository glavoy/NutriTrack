-- NutriTrack notes table migration.
--
-- Run this once in the Supabase SQL Editor to support the in-app Notes screen.
-- This does not modify existing foods, entries, or user_targets data.

begin;

create table if not exists public.user_notes (
  user_id uuid primary key references auth.users(id) on delete cascade,
  note text not null default '',
  updated_at timestamptz not null default now()
);

grant select, insert, update, delete on public.user_notes to authenticated;
revoke select, insert, update, delete, truncate on public.user_notes from anon;

alter table public.user_notes enable row level security;

drop policy if exists "Manage own note" on public.user_notes;

create policy "Manage own note"
on public.user_notes
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

commit;
