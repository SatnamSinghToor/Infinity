-- What the app saw happen.
--
-- RUN THIS ONCE in the Supabase SQL editor, like app_errors.sql.
--
-- Why: the shop had no product analytics at all. Which products get opened,
-- what people search for, where a checkout is abandoned, whether a coupon
-- ever applies — none of it was recorded anywhere, so every decision about
-- what to stock and what to fix was a guess. lib/services/analytics.dart
-- writes here instead: first-party, no new dependency, no third party holding
-- the shop's data.
--
-- What is deliberately NOT here: names, phone numbers, addresses, e-mail,
-- cart contents, payment ids. The app can only send the events and the fields
-- listed in `Analytics.catalog`, and it drops anything else — including a
-- guest's activity, which is not recorded at all.
--
-- The one piece of text stored is a search term, clipped to 60 characters:
-- a shop that does not know what people looked for and did not find cannot
-- fix that. Everything else is a name, a number or a yes/no.

create table if not exists public.app_events (
  id uuid primary key default gen_random_uuid(),
  -- The account the event happened to. The app skips guests, so this is
  -- never null in practice; the cascade means deleting an account takes its
  -- events with it.
  user_id uuid not null references auth.users (id) on delete cascade,
  -- One of the names in Analytics.catalog: 'app_open', 'product_view',
  -- 'add_to_cart', 'search', 'checkout_started', 'order_placed',
  -- 'coupon_failed'.
  name text not null,
  -- The event's fields, already filtered by the app: ids, counts, amounts.
  props jsonb not null default '{}'::jsonb,
  platform text,
  created_at timestamptz not null default now()
);

create index if not exists app_events_created_idx
  on public.app_events (created_at desc);
create index if not exists app_events_name_idx
  on public.app_events (name, created_at desc);

alter table public.app_events enable row level security;

-- An app may record an event for the account that caused it, and only that.
drop policy if exists app_events_own_insert on public.app_events;
create policy app_events_own_insert on public.app_events
  for insert to authenticated
  with check (user_id = auth.uid());

-- Reading is for admins alone: this is the shop's own bookkeeping.
drop policy if exists app_events_admin_read on public.app_events;
create policy app_events_admin_read on public.app_events
  for select to authenticated
  using (public.is_admin());

-- No update and no delete policies: an event is a record. Clearing old rows is
-- an admin/SQL job, e.g.
--   delete from public.app_events where created_at < now() - interval '180 days';

-- Handy from the SQL editor:
--   -- what happened this week, most common first:
--   select name, count(*) from public.app_events
--   where created_at > now() - interval '7 days'
--   group by name order by count(*) desc;
--
--   -- searched for, found nothing: the stocking list, written by customers
--   select props->>'term' as term, count(*) from public.app_events
--   where name = 'search' and (props->>'results')::int = 0
--   group by 1 order by 2 desc limit 50;
--
--   -- checkouts that did not become orders, per day
--   select date_trunc('day', created_at) as day,
--          count(*) filter (where name = 'checkout_started') as started,
--          count(*) filter (where name = 'order_placed') as placed
--   from public.app_events group by 1 order by 1 desc;
