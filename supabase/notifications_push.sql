-- Push, the code half: when a notification lands in `notifications`, call
-- the send-push Edge Function so the phone gets a heads-up too, not just
-- the in-app inbox. Applied — this is the trigger actually running against
-- the live project, checked in here so a lost project can be rebuilt from
-- git instead of only from what happened to still be in the dashboard.
--
-- Needs the pg_net extension (already enabled) and a Vault secret named
-- push_webhook_secret holding the same value as the send-push function's
-- WEBHOOK_SHARED_SECRET. Set the secret once, from the SQL editor:
--
--   select vault.create_secret('<a long random string>', 'push_webhook_secret');
--
-- and the Edge Function's own secret (Dashboard -> Edge Functions ->
-- send-push -> Secrets, or `supabase secrets set`) to the same string, plus
-- FIREBASE_SERVICE_ACCOUNT_JSON (the whole service-account JSON Firebase
-- gives you, one line). Until both are set, this trigger's POST gets a 403
-- and the notification stays in-app only — inserts are never blocked by it.

create extension if not exists pg_net;

create or replace function public.notify_push_on_insert()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'vault', 'extensions'
as $$
declare
  v_secret text;
  -- The one alert either side of an order is actively waiting on: a seller
  -- expecting new orders, a rider waiting for a run. Everything else on
  -- this table (status updates, cancellations, restocks) stays the normal
  -- notification sound — this is the only pair of titles worth a phone
  -- reaching into someone's pocket for. See send-push and
  -- push_service.dart, which read this to pick the loud channel.
  v_loud boolean := new.title = 'New order received'
    or new.title = 'New delivery assigned';
begin
  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'push_webhook_secret';

  perform net.http_post(
    url := 'https://rtceqrzicxrxaajfrerl.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', v_secret
    ),
    body := jsonb_build_object(
      'user_id', new.user_id,
      'title', new.title,
      'body', new.message,
      'type', new.type,
      'order_id', new.order_id,
      'loud', v_loud
    )
  );

  return new;
end;
$$;

drop trigger if exists notifications_push_trigger on public.notifications;
create trigger notifications_push_trigger
  after insert on public.notifications
  for each row execute function public.notify_push_on_insert();

-- ---------------------------------------------------------------------------
-- Stock alerts: a customer asks to be told when a product is back
-- (`stock_alerts`, one row per product per customer). This writes the
-- ordinary in-app notification when it restocks, which the trigger above
-- then turns into a push on its own — no second HTTP call needed here.

create or replace function public.notify_restock()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if old.stock <= 0 and new.stock > 0 then
    insert into notifications (user_id, type, title, message)
    -- PROMO is an allowed notifications.type value; STOCK violates the
    -- notifications_type_check constraint and silently loses this alert.
    select sa.user_id, 'PROMO', 'Back in stock',
           new.name || ' is available again — order it before it sells out!'
    from stock_alerts sa
    where sa.product_id = new.id;
    -- One ping per restock; a customer who still cares re-subscribes from
    -- the product page (the button shows again once the row is gone).
    delete from stock_alerts where product_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_product_restock on public.products;
create trigger trg_product_restock
  after update of stock on public.products
  for each row execute function public.notify_restock();
