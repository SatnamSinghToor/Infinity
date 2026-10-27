-- Riders could only see orders listed for them in delivery_assignments, but
-- the app finds work as "ready_for_pickup with no rider yet" and claims it by
-- setting orders.delivery_id — so the Available list was always empty and
-- Accept could never write. Applied (migration orders_rider_access).
--
-- A delivery partner may see the open pool and their own runs, take an
-- unclaimed run, and move their own run along. Money columns stay locked by
-- protect_order_money; customers and sellers are unaffected.
create policy orders_rider_select on public.orders
  for select to authenticated
  using (
    public.is_delivery_partner()
    and ((status = 'ready_for_pickup' and delivery_id is null)
         or delivery_id = (select auth.uid()))
  );

create policy orders_rider_update on public.orders
  for update to authenticated
  using (
    public.is_delivery_partner()
    and ((status = 'ready_for_pickup' and delivery_id is null)
         or delivery_id = (select auth.uid()))
  )
  with check (delivery_id = (select auth.uid()));
