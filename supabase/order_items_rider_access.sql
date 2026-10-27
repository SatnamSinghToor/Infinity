-- A rider sees the items of the orders they may see.
--
-- can_see_order() found a rider's orders through delivery_assignments, but
-- the app ties a run to its rider through orders.delivery_id (see
-- orders_rider_access.sql), so riders never saw what they were carrying —
-- not on their own runs, not on the open pool they choose runs from. This
-- adds the same two cases orders_rider_select allows: an unclaimed run
-- waiting for pickup, and a run that is theirs. Applied (migration
-- order_items_rider_access).
create or replace function public.can_see_order(o uuid)
returns boolean
language sql
security definer
set search_path to 'public'
as $function$
  select exists (
    select 1 from public.orders
    where id = o and (
      customer_id = auth.uid()
      or public.is_store_owner(store_id)
      or seller_id = auth.uid()
      or id in (select public.my_delivery_order_ids())
      or (
        public.is_delivery_partner()
        and (
          delivery_id = auth.uid()
          or (status = 'ready_for_pickup' and delivery_id is null)
        )
      )
    )
  ) or public.is_admin();
$function$;
