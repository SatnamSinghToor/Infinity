# The backend, and where it lives

Duggu runs on one Supabase project: Postgres (with Row Level Security),
Auth, Storage, Realtime and Edge Functions. The app is only half of it — and
until now, the other half existed **only inside that project**. This folder
is where it belongs, so it can be reviewed, backed up and rebuilt.

## In this repo

| File | What it is |
|---|---|
| `account_exists.sql` | `account_exists_phone` / `account_exists_email`, so the login screen can tell a new number from a known one. Applied. |
| `app_feedback.sql` | `app_feedback` table for Contact Us, Product Requests and Rate Us. Applied. |
| `device_tokens.sql` | Where each signed-in device's FCM token is kept. Applied. |
| `security_fixes.sql` | The 2026-09-20 audit's fixes, plus the section at the end listing what is still outstanding. Applied (parts 1–5). |
| `delivery_contact_rls.sql` | Lets a delivery partner read the phone of the customer on a run assigned to them — `profiles` had no policy for it, so the in-app Call button could never actually reach a real customer. Applied. |
| `notifications_push.sql` | A database trigger that calls `send-push` whenever a row lands in `notifications`, plus the restock trigger that feeds it. Applied. |
| `functions/send-push/` | The sender that reads `device_tokens` and pushes through FCM HTTP v1. Deployed (v15) and wired to the trigger above. |
| `functions/generate-product-description/` | The seller's AI writer for product descriptions: 700 words at least, 1500 at most, checked rather than hoped for. **Not deployed yet, and needs an `AI_API_KEY`.** |

## Missing here, present only in the dashboard

These have no source in git. Export each one from the Supabase dashboard
(Database → Functions, and Edge Functions → Details) and commit it before
anything else — a project that goes down takes them with it.

**Database functions**

- `place_order(...)` — the one that prices orders. The app never sends a
  price; this reads `cart_items`, locks stock, applies the coupon and the
  wallet, writes one order per seller and empties the cart. Its behaviour is
  described in `security_fixes.sql`, section 4.
- `is_admin()`, `can_see_order(...)` — RLS helpers.
- `wallet_debit(...)` — atomic wallet spend.
- `decrement_stock(jsonb)` — kept only so nothing can call it (see
  `security_fixes.sql`, section 3).
- `use_coupon(...)`, `apply_referral(...)` — coupon and referral guards.

**Edge Functions**

| Function | Called by | What it does |
|---|---|---|
| `phone-login` | `lib/providers/auth_provider.dart` | Phone + password sign-in (Supabase Auth is email-first). |
| `admin-delete-user` | `lib/screens/admin/admin_users_screen.dart` | Deletes an auth user; refuses when the account referred others. |
| `create-razorpay-order` | `lib/services/payment_service.dart` | Creates the Razorpay order, priced from variants so the amount matches `place_order`. |
| `verify-razorpay-payment` | `lib/services/payment_service.dart` | Verifies the signature and records it in `verified_payments`, which is the only thing `place_order` trusts for an online payment. |

**Tables** — the ones the app reads and writes are listed in the README's
feature list; `security_fixes.sql` explains the policies that matter most
(role escalation, order money, who may insert an order).

## Deploying a function

Both deploy lines need a linked project, and `supabase link` reads
`supabase/config.toml`. This repo has `supabase/functions/` and no
`config.toml`, so the very first time, run `supabase init` in the repo root
and answer **no** to the VS Code prompt — it will create that file, and it is
worth committing once so the next person does not have to guess. Keep
`functions.verify_jwt` at its default of `true`: the writer is the one function
here that costs money per call, and the free door is the one worth keeping
shut. Then deploy:

```bash
supabase login
supabase link --project-ref rtceqrzicxrxaajfrerl
supabase secrets set --env-file supabase/.env
supabase secrets list                     # names only, never the values
supabase functions deploy send-push --no-verify-jwt
supabase functions deploy generate-product-description
```

The one-click way (after two one-time repo secrets):

1. Repo **Settings → Secrets and variables → Actions**: add
   `SUPABASE_ACCESS_TOKEN` (from
   [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens))
   and `AI_API_KEY` (any OpenAI-compatible provider — see the table below;
   `OPENAI_API_KEY` works too).
2. **Actions → Deploy edge functions → Run workflow.**

That workflow deploys `generate-product-description` from this repo, sets
the AI key, and probes the live URL — its annotation says which copy is
serving (`sign in first: the AI writer answers a signed-in seller only` =
this repo's; anything else = the old dashboard copy is still live). The
same job also runs on PRs to master, where it waits as a failed check you
can simply re-run once the secrets exist.

By hand, the same steps — both deploy lines need a linked project, and
`supabase link` reads `supabase/config.toml`, which this repo has (project
ref, and `verify_jwt = true` for the writer: it is the one function here
that costs money per call, and the free door is the one worth keeping
shut):

## Turning push on

The server side is done: `send-push` is deployed, the `notifications_push_trigger`
on `notifications` and `trg_product_restock` on `products` are both live, and
the Vault secret `push_webhook_secret` matches the function's
`WEBHOOK_SHARED_SECRET`. The only thing left is the client's own Firebase
config, which cannot live in git:

1. **Firebase.** Create the Android app `com.duggustore.app` in the Firebase
   console and download `android/app/google-services.json` into the project
   (`android/app/`). Nothing push-related happens without it —
   `lib/services/push_service.dart` disables itself on purpose, and the
   Gradle build only applies the `google-services` plugin once that file
   exists (`android/app/build.gradle`). For iOS, add
   `ios/Runner/GoogleService-Info.plist` and the APNs key.

Until that file is in place, in-app notifications work (the bell, the inbox)
and push does not — every build quietly runs without it rather than failing.

If the sender or trigger ever need rebuilding from scratch (a fresh Supabase
project, say): deploy `functions/send-push/` with `--no-verify-jwt`, set
`WEBHOOK_SHARED_SECRET` and `FIREBASE_SERVICE_ACCOUNT_JSON` as its secrets,
run `notifications_push.sql`, and set the Vault secret it reads
(`select vault.create_secret('<same value as WEBHOOK_SHARED_SECRET>',
'push_webhook_secret');`).

## Turning on "Continue with Google"

The app side is done: the button, the sign-in call, and the ID-token exchange
are all written and wired (`lib/services/google_auth_service.dart`,
`lib/screens/auth/google_auth_button.dart`). A first-time Google sign-in gets
a `profiles` row from the same `handle_new_user` trigger an email sign-up
gets — nothing on that side needs touching. Three things, none of them code:

1. **Google Cloud.** In a project at
   [console.cloud.google.com](https://console.cloud.google.com), under
   **APIs & Services → Credentials**, create two OAuth 2.0 client ids:
   - A **Web application** client. Its Client ID is what the app itself
     needs (step 3) — it is not a secret, the same way the Firebase
     `api_key` already in `android/app/google-services.json` is not.
   - An **Android** client, package name `com.duggustore.app`, with the
     release keystore's SHA-1 fingerprint (`F7:EC:E3:52:A4:1C:FE:AB:1D:71:
     11:A9:34:E7:AA:9E:9A:EA:EB:98:7C:BD:6D:F4:42:0C:E9:B7:B5:28:FE:EA` — the
     same key `.gitlab-ci.yml` signs the APK with; get it again with
     `keytool -list -v -keystore <the .jks> -alias duggu` if it's ever
     needed). This one carries no secret either; Google matches the app to
     it by package name and signature,
     not by anything the app sends. Add the *debug* keystore's SHA-1 too if
     you also want Google sign-in to work in a debug build.
2. **Supabase.** Authentication → Providers → Google: turn it on, and paste
   the **Web** client's ID and Client Secret (from Google Cloud, next to the
   Web client's ID) into the two fields there. This is the one Google-side
   secret in the whole feature, and it lives only in the Supabase dashboard.
3. **The app.** Add a CI/CD variable `GOOGLE_SERVER_CLIENT_ID` (Settings →
   CI/CD → Variables) set to the **Web** client's ID from step 1 — not
   masked, since it is public by design. `.gitlab-ci.yml` already passes it
   through as `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`; the next push to
   `master` picks it up. Until it is set, the button stays hidden rather
   than showing and failing.
