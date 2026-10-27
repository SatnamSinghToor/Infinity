-- Fix mutable search_path warnings: set search_path = '' on public functions
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT p.proname, n.nspname FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.prosecdef = false LOOP
    EXECUTE format('ALTER FUNCTION public.%I() SET search_path = ''', r.proname);
  END LOOP;
END $$;
