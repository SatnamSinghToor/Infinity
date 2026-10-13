# Duggu

**Duggu** is a Flutter-based multi-vendor quick-commerce (grocery delivery) app — "Store me, same day delivery." It supports four roles — **customer**, **seller**, **delivery partner**, and **admin** — all backed by a single Supabase project (Postgres + Auth + Storage + Edge Functions + Realtime).

## Features

### Customer
- Splash → Home flow with category tabs, dynamic admin-curated home sections, and a product grid
- Search, wishlist, and product reviews
- Product variants (size/flavor) picker, "Notify me when back in stock" alerts
- Cart with quantity/variant management, wallet balance and coupon codes at checkout
- Razorpay online payments or cash on delivery
- Order tracking with live delivery-partner location on an OpenStreetMap
  view (no API key needed) — "Track Order" sits on every order still on its
  way, fed by the delivery partner's phone
- In-app notifications, order history, address book, payment methods (push
  itself needs the one step listed under *Known gaps* below)
- Rate a delivered order's products and its delivery partner
- Report a problem or request a return on any order, and track ticket status

### Seller
- Earnings with a way out: ask for a payout, watch it move through pending →
  approved → paid (see `supabase/payout_requests.sql`)
- Seller onboarding (creates a business profile) and KYC document upload
- Product catalog management with AI-assisted descriptions and image uploads
- Store profile (banner, logo, address, delivery radius, open/closed status)
- Order fulfillment: confirm → prepare → mark ready for pickup, or cancel
- Request a sponsored ("boosted") product slot, pending admin approval
- Dashboard stats: products, orders, and average customer rating

### Delivery Partner
- Onboarding + KYC document upload
- Online/offline toggle, claim orders ready for pickup, mark delivered
- Live location broadcast while a delivery is in progress
- Earnings history and average customer rating, with the same payout
  requests as a seller's

### Admin
- User management (view/delete accounts)
- Approve/reject return requests and order issue tickets, with refund amounts
- Approve/reject sponsored slot requests
- Payout queue: approve or reject what a seller or delivery partner has asked
  for, then mark it paid with the bank's reference
- Dashboard stats: products, orders, sellers, delivery partners, recent orders

## Tech Stack

- [Flutter](https://flutter.dev/) (SDK `^3.5.0`) / Dart
- State management: [`provider`](https://pub.dev/packages/provider)
- Backend: [Supabase](https://supabase.com/) — Postgres with Row Level Security, Auth, Storage, Edge Functions, and Realtime
- Payments: `razorpay_flutter`
- Images: `image_picker` (avatars, product photos, store branding, KYC docs)
- Live tracking: `flutter_map` + `latlong2` (OpenStreetMap tiles) + `geolocator`
- Fonts/UI: `google_fonts` (faces bundled in `assets/fonts/`, never downloaded — see `lib/utils/app_fonts.dart`), `iconsax_flutter`

## Project Structure

```
lib/
├── l10n/             # the app's strings (app_en.arb -> generated AppLocalizations)
├── models/           # Product, CartItem, Order, Review, WalletTransaction, ...
├── providers/        # Auth/Cart/Wishlist/Order/Product/Notification/Wallet providers
├── screens/          # Customer, seller/, delivery/, admin/ screens
├── services/         # Supabase client, payments, location tracking
├── utils/            # App-wide constants (theme, categories)
├── widgets/          # Reusable widgets (product card, bottom nav, home sections, ...)
└── main.dart
```

## Known gaps

`AUDIT.md` is the honest list: what is built but unreachable, what is
missing, and in which order it is worth doing. `supabase/README.md` lists the
backend pieces that exist only in the Supabase project and must be exported
into `supabase/` — `place_order`, the Razorpay functions and `phone-login`
among them.

The seller's AI product description is written into
`supabase/functions/generate-product-description/`, and the feature has a
number at its centre: **700 words at the shortest, 1500 at the longest**. The
app asks for that range and counts it live under the box; the function checks
what came back and continues or cuts until the page is inside it. If no AI key
is set, or the provider is down, the function composes the page from the
seller's own notes and says so, instead of handing the seller a failure they
cannot act on. Which failure it was is said out loud as well: the server sorts
the provider's answer into one word (`bad_key`, `bad_address`, `timeout`,
`upstream`, …) and that travels with the page, because "the writer is busy, try
again in a minute" used to be what a wrong API key sounded like — and a wrong
key is not something a seller waits out.

Push's server side is live: `supabase/functions/send-push/` is deployed and
`supabase/notifications_push.sql`'s trigger is applied, both checked into
this repo. The one thing left is the client's own Firebase config
(`android/app/google-services.json`), which cannot live in git — see
`supabase/README.md`. Until that file is added, the in-app inbox works and
push does not.

"Continue with Google" is written the same way: the button
(`lib/screens/auth/google_auth_button.dart`) and the sign-in call
(`lib/providers/auth_provider.dart`'s `signInWithGoogle`,
`lib/services/google_auth_service.dart`) render nothing and do nothing until
a Google Cloud **Web** OAuth client id is built into the app as
`GOOGLE_SERVER_CLIENT_ID` (a `--dart-define`, wired into `.gitlab-ci.yml` —
not a secret, just an id) and Google is turned on as a provider in Supabase
Authentication. A brand-new Google sign-in gets a `profiles` row from the
same database trigger an email sign-up gets, so nothing else in the app had
to change. Setup steps are in `supabase/README.md`.

Crash reporting is first-party: uncaught errors go to `app_errors` (run
`supabase/app_errors.sql` to create it) and a readable card replaces the red
screen. Guests' errors stay in the device log — the table is filed per account
so an admin can follow up.

Analytics is first-party too, and deliberately small: `app_events` (run
`supabase/app_events.sql`) takes seven named events — app opened, product
opened, added to cart, searched, checkout started, order placed, coupon
refused — and each one may carry only the fields listed in
`Analytics.catalog`. No names, no phones, no cart contents; a guest's activity
is not recorded at all. Queries for "searched for, found nothing" and
"checkouts that did not become orders" are in the SQL file.

## Release

The app's id is `com.duggustore.app` on both platforms. It can never be
changed after the first Play upload, so change it *now* if you want another
one — `android/app/build.gradle` (`namespace` + `applicationId`), the folder
`android/app/src/main/kotlin/com/duggustore/app/`, and the six
`PRODUCT_BUNDLE_IDENTIFIER` lines in `ios/Runner.xcodeproj/project.pbxproj`.

iOS deployment target is **15.5** (`ios/Podfile`, the three
`IPHONEOS_DEPLOYMENT_TARGET` settings in `Runner.xcodeproj` and
`Flutter/AppFrameworkInfo.plist` all say so), because `google_mlkit_commons`
— pulled in by visual search and background removal — refuses to build below
it. CI's `Build iOS` job keeps that honest on `main`, or on any commit that
says `[ios]`.

Signing: a release build without `android/key.properties` is signed with the
debug key, which Play rejects. Android Studio's log says so out loud on every
such build. To sign properly, make the keystore once
(`android/key.properties.example` has the command), or in CI set these four
repository secrets and `.github/workflows/flutter-ci.yml` will sign the
release job itself: `ANDROID_KEYSTORE_BASE64` (the .jks, base64ed),
`ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.

## Getting Started

### Prerequisites

- Flutter SDK installed (`flutter --version`)
- An Android or iOS emulator or physical device. Those are the only two targets this app ships.

### Setup

```bash
flutter pub get
flutter run
```

### Backend (Supabase)

The Supabase URL and publishable (anon) key live in
`lib/services/supabase_service.dart`. Update these if pointing at a different
Supabase project. Row Level Security policies on every table scope access by
role (customer/seller/delivery/admin), so most features work out of the box
against a schema matching this app's.

Some features need a settled server. Run these once in the Supabase SQL
editor (each file explains itself):

- `supabase/account_exists.sql` — the login screen's new-or-known check
- `supabase/app_feedback.sql` — Contact Us / Product Requests / Rate Us
- `supabase/device_tokens.sql` — where push tokens are kept
- `supabase/security_fixes.sql` — the RLS and money fixes
- `supabase/payout_requests.sql` — payouts, with the server checking the amount
- `supabase/notifications_push.sql` — applied: push on a new notification,
  and the "back in stock" alert
- `supabase/app_errors.sql` — where the app files the errors it could not
  survive (there is no Crashlytics/Sentry; see `lib/services/error_reporter.dart`)
- `supabase/app_events.sql` — what the app saw happen: opened, viewed, added,
  searched, checked out, abandoned (see `lib/services/analytics.dart`)

`supabase/README.md` lists what still lives only in the dashboard and should
be exported here.

## Development

```bash
flutter analyze   # static analysis (see analysis_options.yaml)
flutter test      # run tests
dart format lib   # formatting
```

### Strings

User-facing text comes from `lib/l10n/app_en.arb`; `flutter pub get` generates
`AppLocalizations` from it (see `l10n.yaml`), and `main.dart` installs the
delegates once for the whole app. Adding a string is a line in the `.arb` with
a description for translators, then `AppLocalizations.of(context).yourKey`
where it is shown. Another language is another `app_<code>.arb` in the same
folder — nothing else changes. `test/l10n_test.dart` fails if a screen asks for
a key the English file does not have, so the two cannot drift apart.

## Author

**Satnam Singh Toor (ਲਲੌਦਾ)**
