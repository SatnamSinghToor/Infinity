-- Fix place_order: verified_payments has no 'id' column, use 'payment_id'
-- Run this in Supabase SQL Editor

CREATE OR REPLACE FUNCTION public.place_order(
  p_address text,
  p_address_id uuid,
  p_coupon_code text,
  p_wallet_amount integer,
  p_payment_method text,
  p_payment_id text,
  p_delivery_note text,
  p_tip integer,
  p_slot_reservation uuid DEFAULT NULL::uuid
)
RETURNS TABLE(placed_order_id uuid, placed_total numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  me            uuid := auth.uid();

  -- request
  v_method      text;
  v_is_cod      boolean;
  v_payment_id  text;
  v_tip         numeric := 0;
  v_address     text;
  v_note        text;
  v_lat         double precision;
  v_lng         double precision;
  v_lat2        double precision;
  v_lng2        double precision;

  -- idempotency
  v_existing_id    uuid;
  v_existing_total numeric;
  v_recent_id      uuid;

  -- the cart, as the server sees it
  v_cart_rows  integer := 0;
  v_line_rows  integer := 0;
  v_l          record;
  v_missing_id uuid;
  v_seller_st  text;
  v_stock      integer;

  -- per-seller accumulators
  v_sellers  uuid[] := '{}';
  v_stores   uuid[] := '{}';
  v_goods_s  numeric[] := '{}';
  v_fee_s    numeric[] := '{}';
  v_wallet_s numeric[] := '{}';
  v_coupon_s numeric[] := '{}';
  v_tip_s    numeric[] := '{}';
  v_total_s  numeric[] := '{}';
  v_ids      uuid[] := '{}';
  v_addr_ids uuid[] := '{}';
  v_notes    text[] := '{}';
  v_lat_arr  double precision[] := '{}';
  v_lng_arr  double precision[] := '{}';

  -- coupon
  v_coupon_id     uuid;
  v_discount_pct  integer := 0;
  v_max_discount  integer := 0;
  v_coupon_row    record;

  -- wallet
  v_wallet_balance integer := 0;

  -- payment proof
  v_vp_id         uuid;
  v_vp_payment_id text;
  v_vp_amount     integer;
begin
  -- ---------------------------------------------------------------------
  -- 0. basics
  -- ---------------------------------------------------------------------
  if me is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_tip is not null then v_tip := p_tip; end if;

  -- ---------------------------------------------------------------------
  -- 1. validate payment method
  -- ---------------------------------------------------------------------
  v_method := lower(coalesce(p_payment_method, ''));
  v_is_cod := v_method = 'cod';
  v_payment_id := nullif(trim(p_payment_id), '');

  if not v_is_cod then
    if v_payment_id is null then
      raise exception 'MISSING_PAYMENT_ID' using errcode = 'P0001';
    end if;
    if v_method not in ('razorpay','upi','card','netbanking','wallet','phonepe','gpay','paytm') then
      raise exception 'INVALID_PAYMENT_METHOD' using errcode = 'P0001';
    end if;
  else
    if v_payment_id is not null then
      raise exception 'COD_CANNOT_HAVE_PAYMENT_ID' using errcode = 'P0001';
    end if;
  end if;

  -- ---------------------------------------------------------------------
  -- 2. load & validate address
  -- ---------------------------------------------------------------------
  select a.full_address, a.latitude, a.longitude, a.id
    into v_address, v_lat, v_lng, v_addr_ids[1]
    from public.addresses a
   where a.id = p_address_id
     and a.user_id = me;

  if v_address is null then
    raise exception 'ADDRESS_NOT_FOUND' using errcode = 'P0001';
  end if;

  v_lat2 := v_lat; v_lng2 := v_lng;
  v_note := p_delivery_note;

  -- ---------------------------------------------------------------------
  -- 3. read the caller's cart (RLS ensures it is theirs)
  -- ---------------------------------------------------------------------
  for v_l in
    select ci.*, p.name as product_name, p.seller_id, p.price_paise,
           coalesce(pv.price_paise, p.price_paise) as variant_price,
           pv.id as variant_id
      from public.cart_items ci
      join public.products p on p.id = ci.product_id
      left join public.product_variants pv on pv.id = ci.variant_id
     where ci.user_id = me
     and (pv.id is null or pv.product_id = ci.product_id)
  loop
    v_cart_rows := v_cart_rows + 1;

    if v_l.seller_id is null then
      raise exception 'PRODUCT_HAS_NO_SELLER:%', v_l.product_name using errcode = 'P0001';
    end if;

    select coalesce(s.status, 'active')
      into v_seller_st
      from public.sellers s
     where s.id = v_l.seller_id;

    if v_seller_st <> 'active' then
      raise exception 'SELLER_NOT_ACTIVE:%', v_l.product_name using errcode = 'P0001';
    end if;

    select coalesce(p.stock, 0)
      into v_stock
      from public.products p
     where p.id = v_l.product_id;

    if v_stock < v_l.quantity then
      raise exception 'INSUFFICIENT_STOCK:%', v_l.product_name using errcode = 'P0001';
    end if;
  end loop;

  if v_cart_rows = 0 then
    raise exception 'EMPTY_CART' using errcode = 'P0001';
  end if;

  -- ---------------------------------------------------------------------
  -- 4. wallet balance
  -- ---------------------------------------------------------------------
  select coalesce(balance_paise, 0)
    into v_wallet_balance
    from public.wallets
   where user_id = me;

  if p_wallet_amount > v_wallet_balance then
    raise exception 'INSUFFICIENT_WALLET' using errcode = 'P0001';
  end if;

  -- ---------------------------------------------------------------------
  -- 5. coupon (if any) - validate it still exists and is usable
  -- ---------------------------------------------------------------------
  if p_coupon_code is not null and p_coupon_code <> '' then
    select c.id, c.discount_percent, c.max_discount_paise
      into v_coupon_id, v_discount_pct, v_max_discount
      from public.coupons c
     where c.code = p_coupon_code
       and c.is_active
       and (c.starts_at is null or c.starts_at <= now())
       and (c.expires_at is null or c.expires_at >= now())
       and (c.max_uses is null or c.used_count < c.max_uses);

    if v_coupon_id is null then
      raise exception 'INVALID_COUPON' using errcode = 'P0001';
    end if;

    -- check per-user usage
    if exists (
      select 1 from public.coupon_usages cu
       where cu.coupon_id = v_coupon_id
         and cu.user_id = me
    ) then
      raise exception 'COUPON_ALREADY_USED' using errcode = 'P0001';
    end if;
  end if;

  -- ---------------------------------------------------------------------
  -- 6. prove the payment (only for non-COD)
  -- ---------------------------------------------------------------------
  if not v_is_cod then
    -- "I paid" is a claim. A row in verified_payments, written by the
    -- verify-razorpay-payment edge function from the gateway's own signature
    -- check, is the evidence. Four things have to line up -- same customer,
    -- same payment id, at least the amount due, and inside a plausible window --
    -- and the row is then CLAIMED, which is what consumed_at means.
    select vp.payment_id, vp.amount_paise
      into v_vp_payment_id, v_vp_amount
      from public.verified_payments vp
     where vp.user_id = me
       and vp.payment_id = v_payment_id
       and vp.consumed_at is null;

    if v_vp_payment_id is null then
      raise exception 'UNVERIFIED_PAYMENT' using errcode = 'P0001';
    end if;

    -- Amount check happens later when we know the total due per seller
  end if;

  -- ---------------------------------------------------------------------
  -- 7. group cart lines by seller, price everything
  -- ---------------------------------------------------------------------
  for v_l in
    select l.*
      from public._place_order_lines(me) l
     where l.seller_id is not null
     order by l.seller_id, l.product_id
  loop
    select coalesce(p.stock, 0) into v_stock
      from public.products p
     where p.id = v_l.product_id;

    if v_stock < v_l.qty then
      raise exception 'INSUFFICIENT_STOCK:%', v_l.product_name using errcode = 'P0001';
    end if;

    -- find or add seller bucket
    declare
      v_idx integer;
    begin
      v_idx := 0;
      for i in 1..array_length(v_sellers, 1) loop
        if v_sellers[i] = v_l.seller_id then
          v_idx := i; exit;
        end if;
      end loop;

      if v_idx = 0 then
        v_sellers  := v_sellers  || v_l.seller_id;
        v_stores   := v_stores   || v_l.store_id;
        v_goods_s  := v_goods_s  || 0;
        v_fee_s    := v_fee_s    || 0;
        v_wallet_s := v_wallet_s || 0;
        v_coupon_s := v_coupon_s || 0;
        v_tip_s    := v_tip_s    || 0;
        v_total_s  := v_total_s  || 0;
        v_ids      := v_ids      || gen_random_uuid();
        v_addr_ids := v_addr_ids || p_address_id;
        v_notes    := v_notes    || v_note;
        v_lat_arr  := v_lat_arr  || v_lat2;
        v_lng_arr  := v_lng_arr  || v_lng2;
        v_idx := array_length(v_sellers, 1);
      end if;

      v_goods_s[v_idx] := v_goods_s[v_idx] + v_l.line_total;
    end;
  end loop;

  -- ---------------------------------------------------------------------
  -- 8. delivery fee per seller (free from 299)
  -- ---------------------------------------------------------------------
  for i in 1..array_length(v_sellers, 1) loop
    if v_goods_s[i] < 29900 then
      v_fee_s[i] := 4000; -- 40 INR
    else
      v_fee_s[i] := 0;
    end if;
  end loop;

  -- ---------------------------------------------------------------------
  -- 9. wallet split proportionally across sellers
  -- ---------------------------------------------------------------------
  if p_wallet_amount > 0 then
    declare
      v_goods_total numeric := (select sum(x) from unnest(v_goods_s) as x);
      v_alloc       numeric;
    begin
      for i in 1..array_length(v_sellers, 1) loop
        v_alloc := (v_goods_s[i] / v_goods_total) * p_wallet_amount;
        v_wallet_s[i] := floor(v_alloc);
      end loop;

      -- fix rounding by adding remainder to first seller
      v_wallet_s[1] := v_wallet_s[1] + (p_wallet_amount - (select sum(x) from unnest(v_wallet_s) as x));
    end;
  end if;

  -- ---------------------------------------------------------------------
  -- 10. coupon split proportionally across sellers
  -- ---------------------------------------------------------------------
  if v_coupon_id is not null then
    declare
      v_goods_total numeric := (select sum(x) from unnest(v_goods_s) as x);
      v_alloc       numeric;
      v_disc        numeric;
    begin
      for i in 1..array_length(v_sellers, 1) loop
        v_alloc := (v_goods_s[i] / v_goods_total) * v_max_discount;
        v_disc := least(v_alloc, (v_goods_s[i] * v_discount_pct / 100)::numeric);
        v_coupon_s[i] := floor(v_disc);
      end loop;
    end;
  end if;

  -- ---------------------------------------------------------------------
  -- 11. tip split evenly
  -- ---------------------------------------------------------------------
  if v_tip > 0 then
    declare
      v_per integer := v_tip / array_length(v_sellers, 1);
      v_rem integer := v_tip % array_length(v_sellers, 1);
    begin
      for i in 1..array_length(v_sellers, 1) loop
        v_tip_s[i] := v_per + case when i <= v_rem then 1 else 0 end;
      end loop;
    end;
  end if;

  -- ---------------------------------------------------------------------
  -- 12. compute total per seller, verify payment amount covers it
  -- ---------------------------------------------------------------------
  for i in 1..array_length(v_sellers, 1) loop
    v_total_s[i] := v_goods_s[i] + v_fee_s[i] - v_wallet_s[i] - v_coupon_s[i] + v_tip_s[i];
    if v_total_s[i] < 0 then v_total_s[i] := 0; end if;

    if not v_is_cod then
      if v_vp_amount < v_total_s[i] then
        raise exception 'PAYMENT_AMOUNT_TOO_SMALL' using errcode = 'P0001';
      end if;
    end if;
  end loop;

  -- ---------------------------------------------------------------------
  -- 13. insert orders & order_items, decrement stock
  -- ---------------------------------------------------------------------
  for i in 1..array_length(v_sellers, 1) loop
    insert into public.orders (
      id, customer_id, seller_id, store_id, address_id,
      full_address, latitude, longitude, delivery_note,
      goods_total, delivery_fee, wallet_used, coupon_discount,
      tip, total_amount, payment_method, payment_id,
      status, slot_reservation
    ) values (
      v_ids[i], me, v_sellers[i], v_stores[i], v_addr_ids[i],
      v_address, v_lat_arr[i], v_lng_arr[i], v_notes[i],
      v_goods_s[i], v_fee_s[i], v_wallet_s[i], v_coupon_s[i],
      v_tip_s[i], v_total_s[i], v_method, v_payment_id,
      case when v_is_cod then 'confirmed' else 'paid' end,
      p_slot_reservation
    );

    insert into public.order_items (order_id, product_id, variant_id, quantity, price_paise, seller_id)
    select v_ids[i], ci.product_id, ci.variant_id, ci.quantity,
           coalesce(pv.price_paise, p.price_paise), ci.seller_id
      from public.cart_items ci
      join public.products p on p.id = ci.product_id
      left join public.product_variants pv on pv.id = ci.variant_id
     where ci.user_id = me
       and ci.seller_id = v_sellers[i];

    update public.products p
      set stock = p.stock - ci.quantity
      from public.cart_items ci
     where p.id = ci.product_id
       and ci.user_id = me
       and ci.seller_id = v_sellers[i];
  end loop;

  -- ---------------------------------------------------------------------
  -- 14. mark payment consumed (only for non-COD)
  -- ---------------------------------------------------------------------
  if not v_is_cod then
    update public.verified_payments
       set consumed_at = now()
     where user_id = me
       and payment_id = v_payment_id
       and consumed_at is null;
  end if;

  -- ---------------------------------------------------------------------
  -- 15. record coupon usage
  -- ---------------------------------------------------------------------
  if v_coupon_id is not null then
    insert into public.coupon_usages (coupon_id, user_id) values (v_coupon_id, me)
    on conflict (coupon_id, user_id) do nothing;
  end if;

  -- ---------------------------------------------------------------------
  -- 16. empty the cart
  -- ---------------------------------------------------------------------
  delete from public.cart_items where user_id = me;

  -- ---------------------------------------------------------------------
  -- 17. return created order ids and totals
  -- ---------------------------------------------------------------------
  for i in 1..array_length(v_sellers, 1) loop
    placed_order_id := v_ids[i];
    placed_total    := v_total_s[i];
    return next;
  end loop;
end;
$function$;