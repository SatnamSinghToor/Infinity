-- A customer deleting their own account from the app (Play Store requires
-- the option in-app). Applied (migrations delete_my_account*).
--
-- Orders are kept — they are the seller's and rider's records too — but
-- stripped of the delivery address and note. Everything else personal goes,
-- and the login is closed for good (identities and sessions removed, email
-- replaced, banned forever). Sellers and riders are refused: their store and
-- runs go through support. Refused too while an order is still active.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
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
  if exists (select 1 from public.orders
             where customer_id = v_uid
               and status not in ('delivered', 'cancelled')) then
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

-- The customer may see the name and phone of the rider bringing an order
-- that is still on its way (the tracking screen's Call button) — the mirror
-- of profiles_delivery_view_assigned_customer. Applied (migration
-- profiles_customer_view_assigned_rider).
create policy profiles_customer_view_assigned_rider on public.profiles
  for select to authenticated
  using (exists (
    select 1 from public.orders o
    where o.delivery_id = profiles.id
      and o.customer_id = (select auth.uid())
      and o.status <> 'delivered'
      and o.status <> 'cancelled'
  ));
