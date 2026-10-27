-- Payouts: the missing half of "earnings".
--
-- The seller's Earnings screen already totals `orders.seller_payout` (written
-- by the set_order_commission trigger when an order is delivered) and the
-- delivery partner's screen totals `delivery_earnings`. Both showed money that
-- could never actually leave the app: there was no request, no queue, no
-- decision, no record.
--
-- RUN THIS ONCE in the Supabase SQL editor (like account_exists.sql).
--
-- Shape of it:
--   * a seller or delivery partner asks for an amount (only for themselves),
--   * the *server* checks the amount against what they have really earned and
--     what they have already asked for — the app is never trusted with money,
--     the same rule place_order follows,
--   * the admin sees it in Moderation -> Payouts and approves or rejects it,
--   * approving does not move money by itself: `paid` (and the reference) is
--     set by whoever actually sends the transfer. Nobody should believe an
--     app that says "paid" without a bank saying so too.

create table if not exists public.payout_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- Which side of the business is being paid. Copied from profiles.role when
  -- the request is made, so a later role change cannot rewrite history.
  role text not null check (role in ('seller', 'delivery')),
  amount numeric not null check (amount > 0),
  -- Where the money should go, as the partner told us in Payout Details
  -- (UPI id or bank account), so the admin sees it without leaving the queue.
  method text,
  note text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'paid')),
  decided_by uuid references auth.users (id),
  decided_at timestamptz,
  decision_note text,
  -- Set when the transfer is actually made.
  paid_at timestamptz,
  payment_reference text,
  created_at timestamptz not null default now()
);

create index if not exists payout_requests_user_idx
  on public.payout_requests (user_id, created_at desc);
create index if not exists payout_requests_status_idx
  on public.payout_requests (status, created_at desc);

alter table public.payout_requests enable row level security;

-- A partner may ask, and only for themselves, and only for a role they hold.
drop policy if exists payout_requests_own_insert on public.payout_requests;
create policy payout_requests_own_insert on public.payout_requests
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and role = (select role from public.profiles where id = auth.uid())
    and status = 'pending'
    and decided_by is null
    and paid_at is null
  );

-- A partner sees their own requests; an admin sees all of them.
drop policy if exists payout_requests_read on public.payout_requests;
create policy payout_requests_read on public.payout_requests
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- Only an admin may decide. Nobody may approve their own request: the update
-- policy below is the only path that can change `status`, and it is admin-only.
drop policy if exists payout_requests_admin_update on public.payout_requests;
create policy payout_requests_admin_update on public.payout_requests
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- No deletes, by anyone: this is a money record.

-- ---------------------------------------------------------------------------
-- Asking for a payout.
--
-- The app calls this with an amount, not a balance: `earned - already asked
-- for` is worked out here, from the same tables the two Earnings screens
-- total, so a hand-crafted request cannot ask for more than is owed.

create or replace function public.request_payout(
  p_amount numeric,
  p_method text default null,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  my_role text;
  earned numeric := 0;
  outstanding numeric := 0;
  available numeric;
  new_id uuid;
begin
  if me is null then
    raise exception 'NOT_SIGNED_IN' using errcode = '42501';
  end if;

  select role into my_role from public.profiles where id = me;
  if my_role is null or my_role not in ('seller', 'delivery') then
    raise exception 'NOT_A_PAYOUT_ROLE' using errcode = '42501';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'BAD_AMOUNT' using errcode = 'P0001';
  end if;

  if my_role = 'seller' then
    select coalesce(sum(seller_payout), 0) into earned
    from public.orders
    where seller_id = me and status = 'delivered';
  else
    select coalesce(sum(amount), 0) into earned
    from public.delivery_earnings
    where partner_id = me;
  end if;

  -- Everything already asked for and not yet rejected, so the same money
  -- cannot be requested twice while a decision is pending.
  select coalesce(sum(amount), 0) into outstanding
  from public.payout_requests
  where user_id = me and status in ('pending', 'approved', 'paid');

  earned := round(earned, 2);
  outstanding := round(outstanding, 2);
  available := round(earned - outstanding, 2);

  if round(p_amount, 2) > available then
    raise exception 'OVER_BALANCE:%', available using errcode = 'P0001';
  end if;

  insert into public.payout_requests (user_id, role, amount, method, note)
  values (me, my_role, round(p_amount, 2), nullif(trim(p_method), ''),
          nullif(trim(p_note), ''))
  returning id into new_id;

  return new_id;
end;
$$;

revoke execute on function public.request_payout(numeric, text, text)
  from public, anon;
grant execute on function public.request_payout(numeric, text, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- What a partner may ask for right now, so the app can show it without
-- trusting its own arithmetic. Returns one row: earned, outstanding, available.

create or replace function public.payout_balance()
returns table(earned numeric, outstanding numeric, available numeric, role text)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  my_role text;
  e numeric := 0;
  o numeric := 0;
begin
  if me is null then
    return;
  end if;

  select p.role into my_role from public.profiles p where p.id = me;
  if my_role is null then
    return;
  end if;

  if my_role = 'seller' then
    select coalesce(sum(seller_payout), 0) into e
    from public.orders
    where seller_id = me and status = 'delivered';
  elsif my_role = 'delivery' then
    select coalesce(sum(amount), 0) into e
    from public.delivery_earnings
    where partner_id = me;
  else
    return;
  end if;

  select coalesce(sum(amount), 0) into o
  from public.payout_requests
  where user_id = me and status in ('pending', 'approved', 'paid');

  e := round(e, 2);
  o := round(o, 2);
  return query select e, o, round(e - o, 2), my_role;
end;
$$;

revoke execute on function public.payout_balance() from public, anon;
grant execute on function public.payout_balance() to authenticated;
