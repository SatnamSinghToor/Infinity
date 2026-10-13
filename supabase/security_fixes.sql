-- Security fixes for the HyperMart project, from the audit of 2026-09-20.
--
-- APPLIED on 2026-09-20 as three migrations: protect_profile_role,
-- protect_order_money and lock_down_stock_referral_coupon_functions.
-- Parts 4 and 5 (server-side pricing) are below.

-- ---------------------------------------------------------------------------
-- 1. Nobody can make themselves an admin.
--
-- `is_admin()` only looks at profiles.role, and the profiles policies let a
-- user update (or insert) their own row, so any signed-in user could set
-- role = 'admin' on themselves. This blocks that, while still letting people
-- switch between customer / seller / delivery as the app does. Calls with no
-- signed-in user (service role, SQL editor) are left alone.

create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.role = 'admin' and not public.is_admin() then
      raise exception 'Not allowed' using errcode = '42501';
    end if;
  elsif new.role is distinct from old.role and not public.is_admin() then
    if new.role = 'admin' or old.role = 'admin' then
      raise exception 'Not allowed' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_protect_profile_role on public.profiles;
create trigger trg_protect_profile_role
  before insert or update of role on public.profiles
  for each row execute function public.protect_profile_role();

-- ---------------------------------------------------------------------------
-- 2. Customers cannot rewrite the money on their own orders.
--
-- The orders policy lets a customer UPDATE their own order, and cancel_order
-- refunds orders.wallet_used, so a customer could raise wallet_used and then
-- cancel to be credited that much. Only admins (and server-side calls) may
-- change these columns once the order exists.

create or replace function public.protect_order_money()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin()
     and auth.uid() is not null
     and (new.total_amount is distinct from old.total_amount
          or new.delivery_fee is distinct from old.delivery_fee
          or new.wallet_used is distinct from old.wallet_used
          or new.payment_status is distinct from old.payment_status
          or new.payment_id is distinct from old.payment_id
          or new.customer_id is distinct from old.customer_id) then
    raise exception 'Order amounts cannot be changed' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_protect_order_money on public.orders;
create trigger trg_protect_order_money
  before update on public.orders
  for each row execute function public.protect_order_money();

-- ---------------------------------------------------------------------------
-- 3. Functions that anyone signed in could misuse.

-- Not called by the Flutter app; let nobody empty a product's stock through
-- the API.
revoke execute on function public.decrement_stock(jsonb) from public, anon, authenticated;

-- A referral may only be redeemed by the person themselves.
create or replace function public.apply_referral(p_new_user_id uuid, p_referral_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare referrer uuid;
declare already uuid;
begin
  if auth.uid() is distinct from p_new_user_id then
    raise exception 'Not allowed' using errcode = '42501';
  end if;

  select id into referrer from profiles
  where upper(referral_code) = upper(trim(coalesce(p_referral_code, '')));
  if referrer is null or referrer = p_new_user_id then return; end if;

  select referred_by into already from profiles where id = p_new_user_id;
  if already is not null then return; end if;

  update profiles set referred_by = referrer where id = p_new_user_id;

  insert into wallet_transactions (user_id, title, amount, type) values
    (referrer, 'Referral bonus', 50, 'CREDIT'),
    (p_new_user_id, 'Welcome referral bonus', 50, 'CREDIT');
end;
$$;

-- A coupon may only be used up by the person it is redeemed for.
create or replace function public.use_coupon(p_coupon_code text, p_user_id uuid, p_subtotal numeric)
returns table(coupon_id uuid, discount_percent integer, max_discount integer)
language plpgsql
security definer
set search_path = public
as $$
declare c record;
begin
  if auth.uid() is distinct from p_user_id then
    raise exception 'Not allowed' using errcode = '42501';
  end if;

  select * into c from coupons
  where upper(code) = upper(trim(coalesce(p_coupon_code, ''))) and is_active = true;

  if c.id is null then
    raise exception 'INVALID_COUPON' using errcode = 'P0001';
  end if;
  if coalesce(p_subtotal, 0) < c.min_order_value then
    raise exception 'MIN_ORDER:%', c.min_order_value using errcode = 'P0001';
  end if;
  if exists (select 1 from coupon_usages where coupon_id = c.id and user_id = p_user_id) then
    raise exception 'ALREADY_USED' using errcode = 'P0001';
  end if;

  insert into coupon_usages (coupon_id, user_id) values (c.id, p_user_id)
  on conflict (coupon_id, user_id) do nothing;

  coupon_id := c.id; discount_percent := c.discount_percent; max_discount := c.max_discount;
  return next;
end;
$$;


-- ---------------------------------------------------------------------------
-- 4. Orders are priced by the server.            APPLIED 2026-09-20
--
-- Before: the app inserted orders and order_items itself and sent every price,
-- the total and the payment status, and the old place_order function trusted
-- price_at_purchase from the caller. A customer could name their own price.
--
-- Now place_order(p_address, p_address_id, p_coupon_code, p_wallet_amount,
-- p_payment_method, p_payment_id, p_delivery_note) reads the caller's cart from
-- cart_items and works out everything itself: prices from products /
-- product_variants, delivery fee per seller (free from 299), the coupon (only if
-- coupons still backs it), the wallet (capped at the real balance), stock (locked
-- and taken), then writes one order per seller and empties the cart, all or
-- nothing. An online payment counts only if verify-razorpay-payment has recorded
-- it in verified_payments, for at least the amount due, and only once.
--
-- The migrations are: verified_payments_table, server_side_place_order and
-- server_side_place_order_fix_coupon (the current place_order is in the last).
-- verify-razorpay-payment (v4) writes verified_payments; create-razorpay-order
-- (v6) prices variants so its amount matches place_order.
--
-- Tested inside a rolled-back transaction: one seller and two sellers, variant
-- price, coupon, free delivery, too little stock, wallet cap, an online order
-- with no payment, a payment that is too small, a verified payment, the same
-- payment used twice, an empty cart and someone else's address.

-- ---------------------------------------------------------------------------
-- 5. Only place_order can create an order.   see the migration
--    lock_orders_to_place_order
--
-- The orders / order_items policies no longer allow a customer to INSERT; the
-- security-definer place_order function (which bypasses them) is the only way.

-- ---------------------------------------------------------------------------
-- 6. Still to do
--
-- * Turn on "Leaked password protection" in Auth settings (dashboard).
-- * Give public.can_see_order a fixed search_path.
-- * The old place_order(uuid, uuid, text, double precision, double precision,
--   numeric, numeric, jsonb) still exists but nobody may execute it; drop it
--   once nothing (e.g. the older Kotlin app) needs it.
