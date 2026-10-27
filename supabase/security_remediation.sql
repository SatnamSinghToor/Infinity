-- Security hardening applied to Supabase project rtceqrzicxrxaajfrerl on 2026-10-24.
-- Account existence endpoints are no longer exposed to app roles; login attempts
-- now determine whether the credentials are valid without disclosing account membership.
revoke all on function public.account_exists_phone(text) from public, anon, authenticated;
revoke all on function public.account_exists_email(text) from public, anon, authenticated;

-- A signed-in user may release only a device token that belongs to that user.
create or replace function public.release_device_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or coalesce(trim(p_token), '') = '' then
    return;
  end if;
  delete from public.device_tokens
  where token = trim(p_token) and user_id = auth.uid();
end;
$$;
revoke all on function public.release_device_token(text) from public, anon;
grant execute on function public.release_device_token(text) to authenticated;

-- Pin the deployed bigint overload to trusted schemas.
alter function public.place_order(text, uuid, text, bigint, text, text, text, bigint, uuid)
  set search_path = public, pg_temp;
revoke all on function public.place_order(text, uuid, text, bigint, text, text, text, bigint, uuid) from public, anon;
revoke all on function public.place_order(text, uuid, text, integer, text, text, text, integer, uuid) from public, anon;
grant execute on function public.place_order(text, uuid, text, bigint, text, text, text, bigint, uuid) to authenticated;
grant execute on function public.place_order(text, uuid, text, integer, text, text, text, integer, uuid) to authenticated;

-- These helpers do not need to be callable by anonymous clients. Keep their
-- authenticated EXECUTE grants for existing RLS/app call sites.
revoke all on function public.can_see_order(uuid) from public, anon;
revoke all on function public.is_delivery_partner() from public, anon;
revoke all on function public.is_store_owner(uuid) from public, anon;
revoke all on function public.my_delivery_order_ids() from public, anon;
revoke all on function public.order_store(uuid) from public, anon;

-- Keep the dated recovery copies inaccessible through the Data API.
revoke all on table public.deleted_cart_items_backup_20261020 from public, anon, authenticated;
revoke all on table public.deleted_order_items_backup_20261020 from public, anon, authenticated;
revoke all on table public.deleted_products_backup_20261020 from public, anon, authenticated;
revoke all on table public.product_image_urls_backup_20261020 from public, anon, authenticated;
