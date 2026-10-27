-- Chat with Support: one conversation per account, between that account
-- and the admins. Applied (migration support_messages).
--
-- thread_id is the account the conversation belongs to; sender_id is who
-- wrote the message (the account itself, or an admin answering it). An
-- account reads and writes only its own thread; an admin reads every
-- thread and writes into any of them. Nobody edits or deletes a message.
create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references auth.users (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  -- Set when the other side has seen it (the account's messages by an
  -- admin, an admin's by the account).
  read_at timestamptz
);

create index if not exists support_messages_thread_idx
  on public.support_messages (thread_id, created_at);

alter table public.support_messages enable row level security;

create policy support_messages_read on public.support_messages
  for select to authenticated
  using (thread_id = (select auth.uid()) or public.is_admin());

-- Writing only as oneself, and only into one's own thread unless an admin.
create policy support_messages_write on public.support_messages
  for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and (thread_id = (select auth.uid()) or public.is_admin())
  );

-- Marking the other side's messages as read, and nothing else: the
-- columns a reader may touch are limited below.
create policy support_messages_mark_read on public.support_messages
  for update to authenticated
  using (
    (thread_id = (select auth.uid()) and sender_id <> (select auth.uid()))
    or public.is_admin()
  )
  with check (
    (thread_id = (select auth.uid()) and sender_id <> (select auth.uid()))
    or public.is_admin()
  );

revoke update on public.support_messages from authenticated;
grant update (read_at) on public.support_messages to authenticated;

alter publication supabase_realtime add table public.support_messages;
