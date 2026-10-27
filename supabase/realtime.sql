-- Realtime: the tables the app watches live with `.stream()` must be in
-- the supabase_realtime publication, or the stream only ever returns its
-- first snapshot and nothing after. Applied (migration
-- realtime_publication_tables). Row-level security still decides which
-- rows each signed-in user receives.
--
--   orders            customer's order list, seller orders, rider runs,
--                     order tracking status
--   notifications     the inbox and its unread badge
--   delivery_tracking the rider's live position on the customer's map
--   banners           home carousel edits by the admin
alter publication supabase_realtime
  add table public.orders, public.notifications, public.delivery_tracking,
    public.banners;
