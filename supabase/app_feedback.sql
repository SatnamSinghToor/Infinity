-- APPLIED 2026-09-20 as the migration app_feedback_table.
-- Contact Us, Product Requests and Rate Us (Profile) all save a row here.

create table if not exists public.app_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind text not null check (kind in ('contact', 'product_request', 'rating')),
  title text,
  message text,
  rating integer check (rating between 1 and 5),
  status text not null default 'open' check (status in ('open', 'done')),
  created_at timestamptz not null default now()
);

alter table public.app_feedback enable row level security;

create policy "own feedback: insert" on public.app_feedback
  for insert to authenticated
  with check (user_id = auth.uid() and status = 'open');

create policy "own feedback: read" on public.app_feedback
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "admin feedback: update" on public.app_feedback
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create index if not exists app_feedback_user_idx on public.app_feedback (user_id, created_at desc);
