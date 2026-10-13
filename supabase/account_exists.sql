-- Lets the login screen tell "new user" from "existing user" so a fresh
-- email/phone goes straight to sign-up. Run once in the SQL editor.
-- These are existence checks only (no data leaves the server).

create or replace function public.account_exists_phone(p text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where phone = p or phone = '+91' || p or phone = replace(p, ' ', '')
  );
$$;

create or replace function public.account_exists_email(p text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from auth.users where lower(email) = lower(p)
  );
$$;

revoke execute on function public.account_exists_phone(text) from public;
grant execute on function public.account_exists_phone(text)
  to anon, authenticated;

revoke execute on function public.account_exists_email(text) from public;
grant execute on function public.account_exists_email(text)
  to anon, authenticated;
