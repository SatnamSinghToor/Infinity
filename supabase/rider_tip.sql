-- A tip for the delivery partner. Applied (migration rider_tip).
--
-- place_order(... , p_tip integer default 0) — the live function — checks
-- the tip is 0..500, adds it on top of the bill, never lets the wallet pay
-- it (wallet is capped at the bill without the tip, so each seller's share
-- stays exact), and puts the whole tip on the checkout's first order
-- (orders.tip, included in that order's total_amount). create-razorpay-order
-- works the payable out the same way: (bill - wallet) + tip.
alter table public.orders
  add column if not exists tip numeric not null default 0
  check (tip >= 0 and tip <= 500);

-- The seller's commission is on the goods only: not delivery, not the tip.
create or replace function public.set_order_commission()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  pct numeric;
  product_total numeric;
begin
  if new.status = 'delivered' and (old.status is distinct from 'delivered') then
    select commission_percent into pct from sellers where id = new.seller_id;
    pct := coalesce(pct, 10);
    product_total := coalesce(new.total_amount, 0) - coalesce(new.delivery_fee, 0)
                     - coalesce(new.tip, 0);
    new.commission_amount := round(product_total * pct / 100.0, 2);
    new.seller_payout := round(product_total - new.commission_amount, 2);
  end if;
  return new;
end;
$function$;

-- The tip is money like the rest of the order: nobody but an admin moves it.
create or replace function public.protect_order_money()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin()
     and auth.uid() is not null
     and (new.total_amount is distinct from old.total_amount
          or new.delivery_fee is distinct from old.delivery_fee
          or new.wallet_used is distinct from old.wallet_used
          or new.tip is distinct from old.tip
          or new.payment_status is distinct from old.payment_status
          or new.payment_id is distinct from old.payment_id
          or new.customer_id is distinct from old.customer_id) then
    raise exception 'Order amounts cannot be changed' using errcode = '42501';
  end if;
  return new;
end;
$function$;

-- The rider gets the tip the moment the order is delivered — written by the
-- server, not the app, so it can't be skipped or inflated.
create or replace function public.credit_rider_tip()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.status = 'delivered' and old.status is distinct from 'delivered'
     and coalesce(new.tip, 0) > 0 and new.delivery_id is not null
     and not exists (select 1 from delivery_earnings
                     where order_id = new.id and note = 'Tip') then
    insert into delivery_earnings (partner_id, order_id, amount, note)
    values (new.delivery_id, new.id, new.tip::int, 'Tip');
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_credit_rider_tip on public.orders;
create trigger trg_credit_rider_tip
  after update of status on public.orders
  for each row execute function public.credit_rider_tip();
