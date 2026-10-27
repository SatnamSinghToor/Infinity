# Infinity — Hyperlocal Multi-Vendor Marketplace

Infinity is a Flutter-based multi-role commerce platform for same-day grocery, daily essentials, and festival shopping from nearby local stores. It is designed for a hyperlocal marketplace where customers, sellers, delivery partners, and admins each work in a connected ecosystem built around local fulfillment, live order tracking, secure payments, and role-based operations.

The application uses Supabase for authentication, database, real-time sync, and RLS-protected access; Razorpay for payment flows; Firebase for push notifications; and AI providers for product description generation.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Roles & Apps](#roles--apps)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Backend & Database](#backend--database)
- [Security](#security)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Deployment](#deployment)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

Infinity is a hyperlocal marketplace built for speed and trust:

- Customers can browse products, place orders, track deliveries, manage wallets, and receive notifications.
- Sellers can manage inventory, add variants, handle payouts, track orders, and generate AI-written product descriptions.
- Delivery partners can accept runs, navigate to pickups and drop-offs, and track earnings.
- Admins can manage users, categories, banners, moderation, and platform operations.

The app is built as a single Flutter codebase with role-aware navigation and shared state management, while critical operations are enforced on the server through Supabase functions and database policies.

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                          │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌──────────┐ │
│  │ Customer   │ │ Seller     │ │ Delivery   │ │ Admin    │ │
│  │ App        │ │ Dashboard  │ │ Partner    │ │ Dashboard│ │
│  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └────┬─────┘ │
└────────┼────────────────┼────────────────┼────────────────┘
         │                │                │
         └────────────────┼────────────────┼────────────────┐
                          ▼
               ┌───────────────────────────────┐
               │         Supabase Backend       │
               │ Auth | Postgres | Storage | RLS │
               │ Realtime | Edge Functions     │
               └──────────────┬────────────────┘
                              │
                ┌─────────────┼─────────────┐
                ▼             ▼             ▼
          ┌────────────┐ ┌────────────┐ ┌────────────┐
          │ Razorpay   │ │ Firebase   │ │ AI / LLM   │
          │ Payments   │ │ FCM        │ │ provider   │
          └────────────┘ └────────────┘ └────────────┘
```

Key design principles:

- One Flutter application for multiple roles
- Shared providers for app state
- Server-authoritative business logic for money, stock, and order state
- RLS-protected database access for security and isolation
- Real-time updates for orders and notifications

---

## Roles & Apps

The app serves four distinct user roles, each with its own UI and permissions.

| Role | Entry Point | Main Capabilities |
|------|-------------|-------------------|
| Customer | `MainShell` | Browse, search, cart, checkout, wallet, orders, tracking |
| Seller | `SellerDashboardScreen` | Products, pricing, payouts, orders, store profile, earnings |
| Delivery Partner | `DeliveryDashboardScreen` | Accept runs, navigate, mark delivered, check earnings |
| Admin | `AdminDashboardScreen` | Users, categories, moderation, content management, stats |

Role assignment is stored in `profiles.role`, and access is enforced through database triggers and Row Level Security (RLS).

---

## Features

### Customer App

- Dynamic home feed with category chips, promo banners, brand sections, and festival storefronts
- Search with text, voice, and visual search support
- Product variants with separate pricing and inventory
- Persistent cart with guest merge after login
- Checkout with address selection, wallet usage, coupons, and multiple payment modes
- Real-time order tracking and delivery status updates
- Wallet management with top-ups, transaction history, and referral rewards
- In-app notifications and push notifications
- Multi-language support using Flutter localization

### Diwali Storefront

The app includes a dedicated Diwali storefront that runs inside the Flutter app without HTML or WebView. It is built with Flutter widgets and Dart and supports:

- Dark festive hero section
- Arch-style product tiles and category blocks
- Sticky light header
- Multiple storefront sections and product rails
- Search, wishlist, cart interactions, and address help flows
- Tablet, desktop, and mobile layouts
- Offline-safe local assets and bundled fonts

See `lib/diwali/README.md` and `festive-ui/README.md` for the detailed implementation and reference design.

### Seller Dashboard

- Overview cards for sales, products, balance, ratings, and stock health
- Product CRUD with variants and images
- AI-generated product descriptions with multiple providers and fallback logic
- Order management with real-time updates and payouts
- Store profile creation, business details, timings, and location management
- Seller earnings, payout requests, returns, reviews, and boost requests

### Delivery Partner Dashboard

- Online/offline toggle for order assignment
- Live run management with pickup and drop locations
- Navigation support using OpenStreetMap-based routing
- Earnings summary and daily performance tracking
- Available order queue and delivery preview earnings

### Admin Dashboard

- Platform stats for users, products, orders, and sellers
- User and role management
- Category and store content management
- Moderation tools for returns, issues, and sponsored listing requests

### AI Product Description Generator

- Generates product descriptions of 700–1500 words
- Structured sections such as overview, benefits, usage, specs, FAQs, and seller context
- Enforces honest content rules and avoids invented claims
- Falls back to seller notes when AI generation is unavailable
- Supports OpenAI-compatible providers including OpenAI, Groq, OpenRouter, DeepSeek, and Together
- Includes rate limiting and model compatibility handling

### Push Notifications

- Default and loud notification channels
- User-specific delivery using `device_tokens`
- Background notification support
- TTS announcements for important order events
- Deep links to app screens when notification is tapped

---

## Tech Stack

### Frontend

| Component | Version | Purpose |
|-----------|---------|---------|
| Flutter SDK | ^3.5.0 | Cross-platform mobile application |
| Provider | ^6.1.2 | State management |
| Google Fonts | ^8.2.1 | Typography |
| Iconsax Flutter | ^1.0.1 | Icon pack |
| Intl | ^0.20.0 | Localization and date/number formatting |

### Backend & Services

| Service | Version | Purpose |
|---------|---------|---------|
| Supabase Dart | ^2.6.0 | Auth, DB, realtime, storage, edge functions |
| Razorpay Flutter | ^1.3.7 | Online payments |
| Firebase Core / Messaging | ^5.0.0 / ^17.0.0 | Push notifications |
| Flutter Local Notifications | ^22.3.2 | Heads-up notifications |
| App Links | ^7.2.2 | Deep linking and reset flow support |

### Maps & Location

| Package | Version | Purpose |
|---------|---------|---------|
| Flutter Map | ^8.3.2 | Map UI and geospatial display |
| Latlong2 | ^0.10.1 | Coordinate calculations |
| Geolocator | ^14.1.1 | Device location access |

### Media & AI

| Package | Version | Purpose |
|---------|---------|---------|
| Image Picker | ^1.1.2 | Media uploads for profiles and products |
| Google ML Kit | ^0.2.1 / ^0.16.1 / ^0.17.1 | Visual search, OCR, segmentation |
| Speech to Text | ^7.5.0 | Voice-enabled search |
| Flutter TTS | ^4.2.5 | Spoken notifications |
| Cached Network Image | ^4.0.4 | Efficient image loading |

### Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| Shared Preferences | 2.3.2 | Session and local persistence |
| Share Plus | ^13.3.1 | Share sheet integration |
| PDF | ^3.11.1 | Invoice generation |
| Path Provider | ^2.1.3 | File system access |
| URL Launcher | ^6.3.1 | Phone, browser, and maps actions |
| Google Sign In | ^7.2.0 | OAuth login |

---

## Project Structure

```text
lib/
├── main.dart                          # App entry, providers, theme, error reporting
├── l10n/                             # Localization resources
│   ├── app_en.arb
│   ├── app_localizations.dart
│   └── app_localizations_en.dart
├── theme/
│   └── app_theme.dart
├── utils/
│   ├── constants.dart
│   ├── tokens.dart
│   ├── format.dart
│   ├── checkout_math.dart
│   ├── search_match.dart
│   ├── safe_state.dart
│   ├── launch_actions.dart
│   ├── indian_ids.dart
│   ├── description_sections.dart
│   └── app_fonts.dart
├── models/
│   ├── product.dart
│   ├── product_variant.dart
│   ├── order.dart
│   ├── cart_item.dart
│   ├── address.dart
│   ├── review.dart
│   ├── payout_request.dart
│   ├── payment_method.dart
│   ├── wallet_transaction.dart
│   ├── festival.dart
│   └── app_notification.dart
├── providers/
│   ├── auth_provider.dart
│   ├── cart_provider.dart
│   ├── product_provider.dart
│   ├── order_provider.dart
│   ├── wishlist_provider.dart
│   ├── notification_provider.dart
│   ├── wallet_provider.dart
│   ├── edit_mode_provider.dart
│   └── delivery_eta_provider.dart
├── services/
│   ├── supabase_service.dart
│   ├── analytics.dart
│   ├── error_reporter.dart
│   ├── push_service.dart
│   ├── payment_service.dart
│   ├── product_description_service.dart
│   ├── google_auth_service.dart
│   ├── location_tracking_service.dart
│   ├── route_service.dart
│   ├── geocoding_service.dart
│   ├── device_location_service.dart
│   ├── deep_link_service.dart
│   ├── invoice_service.dart
│   ├── background_removal_service.dart
│   ├── visual_search_service.dart
│   ├── voice_sound.dart
│   └── search_history.dart
├── screens/
│   ├── main_shell.dart
│   ├── home_screen.dart
│   ├── categories_screen.dart
│   ├── cart_screen.dart
│   ├── profile_screen.dart
│   ├── product_list_screen.dart
│   ├── product_detail_screen.dart
│   ├── search_screen.dart
│   ├── order_tracking_screen.dart
│   ├── order_detail_screen.dart
│   ├── orders_screen.dart
│   ├── wishlist_screen.dart
│   ├── wallet_screen.dart
│   ├── payment_methods_screen.dart
│   ├── notifications_screen.dart
│   ├── onboarding_screen.dart
│   ├── splash_screen.dart
│   ├── store_screen.dart
│   ├── support_chat_screen.dart
│   ├── kyc_documents_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── reset_password_screen.dart
│   │   └── otp_screen.dart
│   ├── seller/
│   │   ├── seller_dashboard_screen.dart
│   │   ├── seller_products_screen.dart
│   │   ├── seller_orders_screen.dart
│   │   ├── seller_product_detail_screen.dart
│   │   ├── add_product_screen.dart
│   │   ├── store_profile_screen.dart
│   │   ├── store_location_picker_screen.dart
│   │   ├── seller_earnings_screen.dart
│   │   ├── seller_reviews_screen.dart
│   │   ├── seller_returns_screen.dart
│   │   ├── seller_more_screen.dart
│   │   └── my_boost_requests_screen.dart
│   ├── delivery/
│   │   ├── delivery_dashboard_screen.dart
│   │   ├── delivery_orders_screen.dart
│   │   ├── delivery_earnings_screen.dart
│   │   ├── delivery_more_screen.dart
│   │   └── delivery_navigate_screen.dart
│   └── admin/
│       ├── admin_dashboard_screen.dart
│       ├── admin_users_screen.dart
│       ├── admin_moderation_screen.dart
│       └── admin_categories_screen.dart
├── widgets/
│   ├── bottom_nav.dart
│   ├── role_bottom_nav.dart
│   ├── role_common.dart
│   ├── product_card.dart
│   ├── product_hero.dart
│   ├── product_gallery.dart
│   ├── variant_sheet.dart
│   ├── category_tile.dart
│   ├── category_icon_tab.dart
│   ├── category_picker_sheet.dart
│   ├── cart_action.dart
│   ├── checkout_address_sheets.dart
│   ├── delivery_address_sheet.dart
│   ├── notification_bell.dart
│   ├── home_all_sections.dart
│   ├── home_brand_store_sections.dart
│   ├── chip_store_sections.dart
│   ├── festival_sections.dart
│   ├── festival_artwork.dart
│   ├── ganesh_art.dart
│   ├── run_stops.dart
│   ├── live_entrance.dart
│   ├── pressable.dart
│   ├── plain_app_bar.dart
│   ├── gradient_app_bar.dart
│   ├── partner_profile.dart
│   ├── app_network_image.dart
│   ├── app_lifecycle_recovery.dart
│   ├── adaptive_image.dart
│   ├── voice_search_button.dart
│   ├── voice_search_sheet.dart
│   ├── edit_tools.dart
│   ├── edit_badge.dart
│   ├── osm_attribution.dart
│   ├── night_sky.dart
│   ├── listing_common.dart
│   └── form_section.dart
└── ...
```

---

## Backend & Database

### Supabase Project

- URL: `https://rtceqrzicxrxaajfrerl.supabase.co`
- Database: PostgreSQL
- Authentication: email/password, Google OAuth, phone authentication via edge functions
- Real-time: orders, notifications, banners, delivery tracking
- Storage buckets: `avatars`, `product_images`, `seller_documents`, `delivery_documents`

### Key Tables

| Table | Purpose | RLS Highlights |
|-------|---------|----------------|
| `profiles` | User accounts, role metadata, online status | User can manage own profile; admin-only role changes |
| `sellers` | Business details and ownership | Seller-owned records |
| `delivery_partners` | Delivery partner profile | Seller or owner control |
| `stores` | Store location and details | Seller-owned via `owner_id` |
| `products` | Product catalog | Seller-owned; admin access for moderation |
| `product_variants` | Variant-level stock and pricing | Tied to product ownership |
| `orders` | Customer order lifecycle | Customer reads own; seller reads own; delivery reads assigned |
| `order_items` | Line items of orders | Same ownership restrictions as orders |
| `cart_items` | Persistent cart entries | User-owned |
| `wallet_transactions` | Wallet ledger and movement history | User reads own |
| `payout_requests` | Seller payout requests | Seller creates; admin approves |
| `delivery_earnings` | Earnings per delivery | Partner sees own earnings |
| `notifications` | In-app notifications | User reads own |
| `device_tokens` | FCM push tokens | User-owned |
| `reviews` | Product reviews | Public read, customer write |
| `festivals` | Festival calendar content | Admin writes, public reads |
| `banners` | Home screen banners | Admin writes, public reads |
| `categories` | Category tree | Admin writes, public reads |
| `app_events` | Analytics and app event stream | User writes own, admin reads all |
| `app_errors` | Client and service error reports | User writes own, admin reads all |
| `support_messages` | Customer-to-admin chat | Thread-based access |

### Security Functions

The following database functions are used to enforce business rules and protect sensitive state:

- `protect_profile_role()` — prevents privilege escalation to admin
- `protect_order_money()` — prevents customer edits to order monetary fields
- `apply_referral()` — assigns referral bonuses with validation
- `use_coupon()` — validates coupon use by the correct user
- `place_order()` — server-side order creation, pricing calculation, stock locking, and cart cleanup
- `verify_razorpay_payment()` — validates Razorpay signatures and records verified payments
- `payout_balance()` — computes available seller/partner payouts
- `claim_device_token()` / `release_device_token()` — manages valid FCM tokens

### Edge Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `send-push` | `notifications` insert | Sends Firebase push notifications |
| `generate-product-description` | Seller AI action | Generates rich product descriptions |
| `create-razorpay-order` | Checkout | Creates Razorpay order payload |
| `verify-razorpay-payment` | Payment callback | Verifies payment signature and records state |
| `phone-login` | Phone auth | Looks up user and completes phone-based sign-in |

---

## Security

### Authentication

- Supabase Auth for email/password and OAuth flows
- Google Sign-In support
- Phone login via edge function
- Persistent sessions with local storage and recovery on app restart
- Deep-link password reset flow

### Database Security

- Row Level Security enabled across core tables
- Trigger-based guardrails to block privilege escalation and tampering
- Server-side validation for monetary and inventory decisions
- Payment verification restricted to backend logic

### Data Protection

- Guest activity is excluded from analytics and error streams
- Error fingerprints are used instead of raw messages when possible
- AI endpoints are rate-limited
- FCM tokens are scoped to the current user and released on sign-out
- No card or UPI data is stored in the app database; Razorpay handles payment details

---

## Getting Started

### Prerequisites

- Flutter SDK ^3.5.0
- Dart ^3.5.0
- Supabase project with URL and anon key
- Firebase project with Android/iOS config files
- Razorpay account with keys
- OpenAI-compatible API key for AI product description generation

### Installation

```bash
# Clone repository
git clone <repository-url>
cd Infinity

# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run the app
flutter run
```

### Required Supabase Setup

1. Run all SQL migrations in the `supabase/` folder in order.
2. Deploy edge functions:

```bash
supabase functions deploy send-push
supabase functions deploy generate-product-description
supabase functions deploy create-razorpay-order
supabase functions deploy verify-razorpay-payment
supabase functions deploy phone-login
```

3. Set required secrets:

```text
WEBHOOK_SHARED_SECRET
FIREBASE_SERVICE_ACCOUNT_JSON
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
AI_API_KEY (or OPENAI_API_KEY / GROQ_API_KEY)
AI_MODEL (optional, default: gpt-4o-mini)
AI_BASE_URL (optional)
AI_RATE_MAX (optional, default: 8)
```

### Required Firebase Setup

1. Add `google-services.json` to `android/app/`
2. Add `GoogleService-Info.plist` to `ios/Runner/`
3. Enable Firebase Cloud Messaging in the Firebase console
4. Add `order_alert` sound to `android/app/src/main/res/raw/`

### Required Razorpay Setup

1. Create a Razorpay account
2. Add your Key ID and Secret to the edge function environment
3. Configure the webhook for payment verification

---

## Environment Configuration

### Supabase Service

File: `lib/services/supabase_service.dart`

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### App Constants

File: `lib/utils/constants.dart`

```dart
static const String appName = 'Infinity';
static const Color primaryColor = Color(0xFFFF5A00);
```

### Deep Links

- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`
- Reset password scheme: `com.duggustore.app://reset-password`

---

## Deployment

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

Notes:

- `google-services.json` must be present for push notifications.
- `geolocator_android` is pinned in `dependency_overrides` for compatibility.

### iOS

```bash
flutter build ios --release
```

Notes:

- Add `GoogleService-Info.plist` to the Runner target.
- Enable push capabilities in Xcode.

### Web

```bash
flutter build web --release
```

Generated output is placed in `build/web/` and may require Supabase CORS configuration depending on your deployment domain.

### Edge Functions

```bash
supabase functions deploy <function-name>
```

Set secrets in the Supabase dashboard under Edge Functions → Secrets.

---

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run a single file
flutter test test/product_card_test.dart
```

### Test Suites

| Test File | Coverage |
|-----------|----------|
| `widget_test.dart` | Core widget rendering |
| `cart_provider_test.dart` | Cart logic, stock, sync |
| `product_card_test.dart` | Product card rendering |
| `checkout_math_test.dart` | Delivery fee and threshold math |
| `search_history_test.dart` | Search history behavior |
| `theme_mode_test.dart` | Theme token logic |
| `tokens_test.dart` | Design token validation |
| `role_screens_test.dart` | Role-based navigation |
| `analytics_test.dart` | Event catalog validation |
| `error_reporter_test.dart` | Fingerprinting and throttling |
| `visual_search_test.dart` | ML Kit integration |
| `variant_choice_test.dart` | Variant selection logic |
| `indian_ids_test.dart` | PAN / Aadhaar / GSTIN validation |
| `festival_window_test.dart` | Festival-related UI logic |

---

## Contributing

### Code Style

- Follow `flutter_lints`
- Run `flutter analyze` before committing
- Use `dart format .` for formatting

### Architecture Principles

1. Keep a single source of truth for app state through providers.
2. Treat backend logic as authoritative for money, stock, and order status.
3. Favor graceful degradation and user-safe fallbacks.
4. Prefer explicit models and named analytics events over ambiguous logic.
5. Use design tokens and shared sizing rules for consistent UI behavior.

### Adding a New Feature

1. Define model updates in `lib/models/`
2. Add shared state logic in `lib/providers/` when needed
3. Create backend or external API integrations in `lib/services/`
4. Build UI under `lib/screens/<role>/`
5. Add localization strings in `lib/l10n/app_en.arb`
6. Add tests in `test/`
7. Update this README if architecture or setup changes

---

## License

This project is private and is not intended for public distribution.

---

## Support

For operational troubleshooting, review:

- Supabase `app_errors` table
- Supabase `app_events` table
- Edge function logs in the Supabase dashboard
- Flutter console output for client-side errors

---

## Summary

Infinity is a production-style hyperlocal marketplace platform that brings together local commerce, role-based operations, secure payments, real-time tracking, and AI-assisted seller tools. It is designed to help a neighborhood marketplace scale across customers, sellers, delivery partners, and administrators within a single, maintainable Flutter application.
