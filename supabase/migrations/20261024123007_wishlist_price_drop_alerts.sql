-- Let a signed-in shopper follow a product's effective selling price. A
-- product update creates one PROMO notification for each watcher only when
-- the effective price (discount_price when present, otherwise price) falls.

create table public.price_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint price_alerts_user_product_key unique (user_id, product_id)
);

alter table public.price_alerts enable row level security;

revoke all on table public.price_alerts from public, anon;
grant select, insert, delete on table public.price_alerts to authenticated;

create policy price_alerts_read_own
  on public.price_alerts for select to authenticated
  using ((select auth.uid()) = user_id);

create policy price_alerts_create_own
  on public.price_alerts for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy price_alerts_delete_own
  on public.price_alerts for delete to authenticated
  using ((select auth.uid()) = user_id);

alter table public.notifications
  add column product_id uuid references public.products(id) on delete set null;

-- STOCK is not an allowed notifications.type value on this project. PROMO is
-- the existing product-notification category shared with the inbox UI.
create or replace function public.notify_restock()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if old.stock <= 0 and new.stock > 0 then
    insert into public.notifications (user_id, type, title, message, product_id)
    select sa.user_id,
           'PROMO',
           'Back in stock',
           new.name || ' is available again — order it before it sells out!',
           new.id
      from public.stock_alerts sa
     where sa.product_id = new.id;

    delete from public.stock_alerts where product_id = new.id;
  end if;

  return new;
end;
$$;

revoke all on function public.notify_restock() from public, anon, authenticated;

-- Account deletion pseudonymizes the auth user instead of removing it, so
-- subscriptions need explicit cleanup along with the existing alerts.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
begin
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  select role into v_role from public.profiles where id = v_uid;
  if coalesce(v_role, 'customer') <> 'customer' then
    raise exception 'not_customer' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.orders
     where customer_id = v_uid
       and status not in ('delivered', 'cancelled')
  ) then
    raise exception 'active_orders' using errcode = 'P0001';
  end if;

  delete from public.addresses where user_id = v_uid;
  delete from public.cart_items where customer_id = v_uid;
  delete from public.carts where user_id = v_uid;
  delete from public.wishlist_items where user_id = v_uid;
  delete from public.favorites where customer_id = v_uid;
  delete from public.device_tokens where user_id = v_uid;
  delete from public.payment_methods where user_id = v_uid;
  delete from public.stock_alerts where user_id = v_uid;
  delete from public.price_alerts where user_id = v_uid;
  delete from public.notifications where user_id = v_uid;

  update public.orders
     set delivery_address = 'Address removed (account deleted)',
         delivery_latitude = null,
         delivery_longitude = null,
         delivery_note = ''
   where customer_id = v_uid;

  update public.profiles
     set full_name = 'Deleted user',
         phone = '',
         avatar_url = null,
         is_active = false
   where id = v_uid;

  delete from auth.sessions where user_id = v_uid;
  delete from auth.identities where user_id = v_uid;
  update auth.users
     set email = 'deleted-' || v_uid || '@deleted.invalid',
         phone = null,
         encrypted_password = '',
         raw_user_meta_data = '{}'::jsonb,
         banned_until = 'infinity'
   where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

create or replace function public.notify_price_drop()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  old_effective_price numeric := coalesce(old.discount_price, old.price);
  new_effective_price numeric := coalesce(new.discount_price, new.price);
begin
  if new.is_active is true and new_effective_price < old_effective_price then
    insert into public.notifications (user_id, type, title, message, product_id)
    select pa.user_id,
           'PROMO',
           'Price dropped',
           new.name || ' is now ₹' || trim(to_char(new_effective_price, 'FM999999990.00')) || '.',
           new.id
      from public.price_alerts pa
     where pa.product_id = new.id;

    -- One alert per subscription. A shopper can opt in again from the
    -- product page if they want to follow its next price change too.
    delete from public.price_alerts where product_id = new.id;
  end if;

  return new;
end;
$$;

revoke all on function public.notify_price_drop() from public, anon, authenticated;

drop trigger if exists products_notify_price_drop on public.products;
create trigger products_notify_price_drop
  after update of price, discount_price on public.products
  for each row execute function public.notify_price_drop();
