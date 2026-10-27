-- Push notifications: where the app records device tokens. Applied — this
-- matches the live table. The send-push Edge Function reads it to target a
-- user's devices.
--
-- The app registers with an upsert on_conflict=token (push_service.dart), so
-- `token` must be unique on its own. The live table once had only
-- unique (user_id, token): Postgres rejected every upsert, the app swallowed
-- the error, and no phone ever registered — push looked dead end to end.

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform text not null default 'android',
  updated_at timestamptz not null default now(),
  constraint device_tokens_user_id_token_key unique (user_id, token)
);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'device_tokens_token_key') then
    alter table public.device_tokens
      add constraint device_tokens_token_key unique (token);
  end if;
end $$;

create index if not exists idx_device_tokens_user on public.device_tokens (user_id);

-- The upsert doesn't send updated_at, so stamp it here: it is the only way to
-- tell from the table whether a phone has checked in recently.
create or replace function public.device_tokens_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_device_tokens_touch on public.device_tokens;
create trigger trg_device_tokens_touch
  before update on public.device_tokens
  for each row execute function public.device_tokens_touch();

alter table public.device_tokens enable row level security;

-- Each signed-in user manages only their own rows (admins all of them);
-- guests can't touch any, so their tokens are never stored.
drop policy if exists device_tokens_own on public.device_tokens;
drop policy if exists "Users manage own device tokens" on public.device_tokens;
create policy "Users manage own device tokens" on public.device_tokens
  for all
  using ((user_id = (select auth.uid())) or is_admin())
  with check ((user_id = (select auth.uid())) or is_admin());

-- A phone's token belongs to whoever is signed in on it right now. The
-- policy above only lets an account touch its own rows, so the next account
-- on the same phone could never take a token over — the phone kept getting
-- the previous account's pushes (a seller's "New order received" read out
-- on a customer's phone). The app goes through these instead. Applied
-- (migration device_token_claim_release).
create or replace function public.claim_device_token(p_token text, p_platform text default null)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or coalesce(trim(p_token), '') = '' then
    return;
  end if;
  insert into device_tokens (token, user_id, platform)
  values (trim(p_token), auth.uid(), p_platform)
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = coalesce(excluded.platform, device_tokens.platform);
end;
$$;

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
  delete from device_tokens
  where token = trim(p_token) and user_id = auth.uid();
end;
$$;

revoke all on function public.claim_device_token(text, text) from public, anon;
grant execute on function public.claim_device_token(text, text) to authenticated;
revoke all on function public.release_device_token(text) from public, anon;
grant execute on function public.release_device_token(text) to authenticated;
