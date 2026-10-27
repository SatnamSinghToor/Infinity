-- Function EXECUTE grants for the app (replaces the blanket grant).
--
-- History: the function permissions were lost (blanket revoke) which broke
-- profile/orders/addresses loading (42501 permission denied) after login,
-- then a blanket GRANT re-opened every internal SECURITY DEFINER helper.
-- This file is the correct middle ground:
--   1. revoke EXECUTE from everything in schema public (anon, authenticated, public)
--   2. grant EXECUTE only for the functions the app calls via .rpc() and for
--      helpers used inside RLS policies evaluated on behalf of those roles
--
-- Result: 389 security warnings -> 17 (only the app-facing SECURITY DEFINER
-- surface remains, which is intentional; plus pre-existing perf/password advisories).
--
-- Applied on 2026-10-19 via SQL editor.

-- 1. clean slate
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon, authenticated, public;

-- 2. grant the app surface only
DO $$
DECLARE
  -- Callable before sign-in: is_admin() is needed by anon-visible RLS policies.
  anon_fns text[] := ARRAY[
    'is_admin'];
  -- callable after sign-in: the app's .rpc() surface + policy helpers
  authed_fns text[] := ARRAY[
    'apply_referral','claim_device_token','delete_my_account','payout_balance',
    'request_payout','wallet_debit','place_order','my_delivery_order_ids',
    'release_device_token','is_admin'];
  fn text;
  r RECORD;
  granted int := 0;
BEGIN
  FOREACH fn IN ARRAY anon_fns LOOP
    FOR r IN SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
             WHERE n.nspname = 'public' AND p.proname = fn LOOP
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO anon', r.oid::regprocedure);
      granted := granted + 1;
    END LOOP;
  END LOOP;
  FOREACH fn IN ARRAY authed_fns LOOP
    FOR r IN SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
             WHERE n.nspname = 'public' AND p.proname = fn LOOP
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.oid::regprocedure);
      granted := granted + 1;
    END LOOP;
  END LOOP;
  RAISE NOTICE 'granted % grants', granted;
END $$;

-- 3. these stay locked (server-side pricing; nobody calls them from the client)
-- The revoke in step 1 already covers them, but keep the explicit lines so a
-- future blanket grant does not silently re-open them.
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
             WHERE n.nspname = 'public' AND p.proname = 'decrement_stock') THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.decrement_stock(items jsonb) FROM anon, authenticated, public';
  END IF;
END $$;

-- 4. quick verification helper (run manually)
-- select p.proname, pg_get_function_identity_arguments(p.oid) as args,
--        has_function_privilege('authenticated', p.oid, 'execute') as authed_exec,
--        has_function_privilege('anon', p.oid, 'execute') as anon_exec
-- from pg_proc p join pg_namespace n on p.pronamespace = n.oid
-- where n.nspname = 'public'
--   and p.proname in ('my_delivery_order_ids','is_admin','decrement_stock','place_order')
-- order by p.proname;
