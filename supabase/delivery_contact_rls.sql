-- A delivery partner could never actually read the customer's phone number
-- on a run they had claimed: `profiles` had no SELECT policy covering it
-- (see "Users delivery and admins can view profiles" below, which only
-- covers seller rows), so the app's own lookup came back with nothing for
-- every real order. It went unnoticed because the one order tested against
-- had been placed by the same account that was now testing the delivery
-- side — the Call button dialled a real, reachable number: the tester's
-- own. Applied.
--
-- Scoped narrowly: only the customer on an order currently assigned to this
-- partner, and only while it isn't delivered yet — not every customer this
-- partner has ever met, and not indefinitely once the run is done.

drop policy if exists profiles_delivery_view_assigned_customer on public.profiles;
create policy profiles_delivery_view_assigned_customer on public.profiles
for select
using (
  exists (
    select 1 from public.orders o
    where o.customer_id = profiles.id
      and o.delivery_id = auth.uid()
      and o.status <> 'delivered'
  )
);
