-- Where the app files what it could not survive.
--
-- RUN THIS ONCE in the Supabase SQL editor, like account_exists.sql.
--
-- Why: the app had no crash reporting at all (no Crashlytics, no Sentry), so
-- an error on a customer's phone reached nobody. lib/services/error_reporter.dart
-- writes here instead — first-party, no new dependency, no third party holding
-- user data.
--
-- What is deliberately NOT here: e-mail, phone, names, addresses, cart
-- contents. Only the message, the stack, which platform, and the account it
-- happened to (so an admin can follow up) — see the columns.

create table if not exists public.app_errors (
  id uuid primary key default gen_random_uuid(),
  -- The signed-in account the error happened to. Guests are not reported at
  -- all (the app logs those locally), so this is never null in practice; the
  -- cascade means deleting an account takes its error rows with it.
  user_id uuid not null references auth.users (id) on delete cascade,
  -- 'flutter' (a widget failed), 'async' (a future nobody awaited) or a name
  -- a caller passes for a caught-but-worth-knowing error.
  source text not null default 'unknown',
  message text not null,
  stack text,
  platform text,
  -- The message with ids and numbers stripped, so "the same bug" groups.
  fingerprint text,
  created_at timestamptz not null default now()
);

create index if not exists app_errors_created_idx
  on public.app_errors (created_at desc);
create index if not exists app_errors_fingerprint_idx
  on public.app_errors (fingerprint, created_at desc);

alter table public.app_errors enable row level security;

-- An app may file an error for the account that hit it, and only that one.
drop policy if exists app_errors_own_insert on public.app_errors;
create policy app_errors_own_insert on public.app_errors
  for insert to authenticated
  with check (user_id = auth.uid());

-- Reading is for admins alone: an error carries a stack trace, which is
-- debugging material, not something to hand back to every user.
drop policy if exists app_errors_admin_read on public.app_errors;
create policy app_errors_admin_read on public.app_errors
  for select to authenticated
  using (public.is_admin());

-- No update and no delete policies: a report is a record. Clearing old rows
-- is an admin/SQL job, e.g.
--   delete from public.app_errors where created_at < now() - interval '90 days';

-- Handy while triaging, from the SQL editor:
--   select fingerprint, count(*), max(created_at) as last_seen
--   from public.app_errors
--   group by fingerprint
--   order by count(*) desc;
