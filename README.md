# Infinity — Hyperlocal Multi-Vendor Marketplace

A Flutter-based multi-role e-commerce platform for same-day delivery of groceries, daily needs, and festival shopping from local stores. Built with Supabase backend, Razorpay payments, Firebase push notifications, and AI-powered product descriptions.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Roles & Apps](#roles--apps)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Backend & Database](#backend--database)
- [Key Features](#key-features)
- [Security](#security)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Deployment](#deployment)
- [Testing](#testing)
- [Contributing](#contributing)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ Customer │ │  Seller  │ │ Delivery │ │  Admin   │           │
│  │   App    │ │  Dashboard│ │ Partner  │ │ Dashboard│           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
└───────┼─────────────┼─────────────┼─────────────┼───────────────┘
        │             │             │             │
        └─────────────┼─────────────┼─────────────┘
                      ▼
        ┌─────────────────────────────────────────┐
        │           SUPABASE BACKEND              │
        │  ┌─────────┐ ┌──────────┐ ┌───────────┐ │
        │  │  Auth   │ │ Database │ │  Realtime │ │
        │  │         │ │ (Postgres)│ │           │ │
        │  └─────────┘ └──────────┘ └───────────┘ │
        │  ┌─────────┐ ┌──────────┐ ┌───────────┐ │
        │  │ Storage │ │  Edge    │ │  Webhooks │ │
        │  │         │ │ Functions│ │           │ │
        │  └─────────┘ └──────────┘ └───────────┘ │
        └─────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
    ┌────────┐  ┌──────────┐  ┌───────────┐
    │ Razorpay│ │ Firebase │  │  OpenAI/  │
    │Payments │ │   FCM    │  │  Groq AI  │
    └────────┘  └──────────┘  └───────────┘
```

---

## Roles & Apps

The single Flutter codebase serves **four distinct roles**, each with its own dashboard and navigation:

| Role | Entry Point | Bottom Nav Tabs | Key Capabilities |
|------|-------------|-----------------|------------------|
| **Customer** | `MainShell` | Home, Categories, Cart, Profile | Browse, search, order, track, wallet, wishlist |
| **Seller** | `SellerDashboardScreen` | Home, Products, Orders, More | Manage products/orders, store profile, earnings, payouts |
| **Delivery Partner** | `DeliveryDashboardScreen` | Home, Deliveries, Earnings, More | Accept runs, navigate, mark delivered, track earnings |
| **Admin** | `AdminDashboardScreen` | Home, Users, Moderation | Platform stats, user management, category editor, store editor |

Role is stored in `profiles.role` and enforced by RLS policies and database triggers.

---

## Tech Stack

### Frontend (Flutter)
| Component | Version | Purpose |
|-----------|---------|---------|
| Flutter SDK | ^3.5.0 | Cross-platform framework |
| Provider | ^6.1.2 | State management |
| Google Fonts | ^8.2.1 | Poppins typography (pinned pre-9.0) |
| Iconsax Flutter | ^1.0.1 | Icon set |
| Intl | ^0.20.0 | Localization & formatting |

### Backend & Services
| Service | Version | Purpose |
|---------|---------|---------|
| Supabase (Dart) | ^2.6.0 | Auth, Database, Realtime, Storage, Edge Functions |
| Razorpay Flutter | ^1.3.7 | Online payments (UPI, Cards, Wallets) |
| Firebase Core/Messaging | ^5.0.0 / ^17.0.0 | Push notifications |
| Flutter Local Notifications | ^22.3.2 | Heads-up notifications on device |
| App Links | ^7.2.2 | Deep linking (password reset, email verification) |

### Maps & Location
| Package | Version | Purpose |
|---------|---------|---------|
| Flutter Map | ^8.3.2 | OpenStreetMap tiles (no Google Maps API key needed) |
| Latlong2 | ^0.10.1 | Coordinate handling |
| Geolocator | ^14.1.1 | Device location |

### Media & AI
| Package | Version | Purpose |
|---------|---------|---------|
| Image Picker | ^1.1.2 | Camera/gallery for avatars & product photos |
| Google ML Kit (Segmentation, Labeling, Text) | ^0.2.1 / ^0.16.1 / ^0.17.1 | Visual search & background removal |
| Speech to Text | ^7.5.0 | Voice search |
| Flutter TTS | ^4.2.5 | Push notification announcements |
| Cached Network Image | ^4.0.4 | Efficient image loading |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| Shared Preferences | 2.3.2 | Local persistence (session, address, onboarding) |
| Share Plus | ^13.3.1 | System share sheet |
| PDF | ^3.11.1 | Invoice generation |
| Path Provider | ^2.1.3 | File system access |
| URL Launcher | ^6.3.1 | Phone, maps, browser |
| Google Sign In | ^7.2.0 | OAuth authentication |

---

## Project Structure

```
lib/
├── main.dart                          # App entry, providers, theme, error reporting
├── l10n/                              # Localization (English, generated via gen-l10n)
│   ├── app_en.arb                     # English translations (1300+ keys)
│   ├── app_localizations.dart
│   └── app_localizations_en.dart
├── theme/
│   └── app_theme.dart                 # Material3 theme, Poppins, orange palette
├── utils/
│   ├── constants.dart                 # App constants, colors, popular brands
│   ├── tokens.dart                    # Design tokens (spacing, radius, type, colors for light/dark)
│   ├── format.dart                    # Currency, date formatting
│   ├── checkout_math.dart             # Cart/checkout calculations (delivery fee, free threshold)
│   ├── search_match.dart              # Search relevance scoring
│   ├── safe_state.dart                # Mounted-check setState helper
│   ├── launch_actions.dart            # Phone, maps, browser intents
│   ├── indian_ids.dart                # PAN, Aadhaar, GSTIN validation
│   ├── description_sections.dart      # AI description section definitions
│   └── app_fonts.dart                 # Local font loading (Poppins weights)
├── models/
│   ├── product.dart                   # Product + variants, gallery, brand logic
│   ├── product_variant.dart           # Size/pack variants with own price/stock
│   ├── order.dart                     # Order with items, status steps, delivery fee
│   ├── cart_item.dart                 # Cart line (product + optional variant)
│   ├── address.dart                   # Delivery address with lat/lng
│   ├── review.dart                    # Product review with rating
│   ├── payout_request.dart            # Seller payout request
│   ├── payment_method.dart            # Saved UPI/Card
│   ├── wallet_transaction.dart        # Wallet ledger entry
│   ├── festival.dart                  # Festival calendar entry
│   └── app_notification.dart          # In-app notification
├── providers/
│   ├── auth_provider.dart             # Auth state, profile, roles, addresses, guest mode
│   ├── cart_provider.dart             # Local + server cart, sync, guest merge
│   ├── product_provider.dart          # Products, categories, brands, variant counts
│   ├── order_provider.dart            # Orders, live status watching
│   ├── wishlist_provider.dart         # Wishlist CRUD
│   ├── notification_provider.dart     # In-app notifications, realtime
│   ├── wallet_provider.dart           # Balance, transactions, top-up
│   ├── edit_mode_provider.dart        # Admin edit mode toggle
│   └── delivery_eta_provider.dart     # ETA from address + nearest seller
├── services/
│   ├── supabase_service.dart          # Supabase client singleton
│   ├── analytics.dart                 # First-party events (app_events table)
│   ├── error_reporter.dart            # Uncaught errors → app_errors table
│   ├── push_service.dart              # FCM + local notifications, loud channel
│   ├── payment_service.dart           # Razorpay checkout wrapper
│   ├── product_description_service.dart # AI description generation client
│   ├── google_auth_service.dart       # Google Sign-In flow
│   ├── location_tracking_service.dart # Delivery partner live location
│   ├── route_service.dart             # OSRM routing for delivery navigation
│   ├── geocoding_service.dart         # Address ↔ coordinates (Nominatim)
│   ├── device_location_service.dart   # Current location permission + fetch
│   ├── deep_link_service.dart         # App links handling (reset password)
│   ├── invoice_service.dart           # PDF invoice generation
│   ├── background_removal_service.dart # ML Kit subject segmentation
│   ├── visual_search_service.dart     # ML Kit image labeling + text recognition
│   ├── voice_sound.dart               # Voice search chimes
│   └── search_history.dart            # Local search history
├── screens/
│   ├── main_shell.dart                # Customer bottom nav frame (4 tabs)
│   ├── home_screen.dart               # Customer home: chips, banners, sections
│   ├── categories_screen.dart         # Category tree browser
│   ├── cart_screen.dart               # Cart with bill, coupon, wallet, checkout
│   ├── profile_screen.dart            # Account, addresses, wallet, help, settings
│   ├── product_list_screen.dart       # Filtered product grid
│   ├── product_detail_screen.dart     # Gallery, variants, reviews, add to cart
│   ├── search_screen.dart             # Text, voice, visual search
│   ├── order_tracking_screen.dart     # Live map + status steps
│   ├── order_detail_screen.dart       # Full order info, invoice, review
│   ├── orders_screen.dart             # Order history with live status
│   ├── wishlist_screen.dart           # Saved items
│   ├── wallet_screen.dart             # Balance, transactions, top-up
│   ├── payment_methods_screen.dart    # Saved UPI/Card management
│   ├── notifications_screen.dart      # Inbox + archive, swipe actions
│   ├── onboarding_screen.dart         # 3-step walkthrough → Login
│   ├── splash_screen.dart             # Brand splash
│   ├── store_screen.dart              # Seller storefront
│   ├── support_chat_screen.dart       # Admin chat per account
│   ├── kyc_documents_screen.dart      # Document upload for seller/delivery
│   ├── auth/
│   │   ├── login_screen.dart          # Email/password, Google, phone
│   │   ├── register_screen.dart       # Sign up with referral
│   │   ├── reset_password_screen.dart # Deep link target
│   │   └── otp_screen.dart            # Phone OTP (if enabled)
│   ├── seller/
│   │   ├── seller_dashboard_screen.dart
│   │   ├── seller_products_screen.dart
│   │   ├── seller_orders_screen.dart
│   │   ├── seller_product_detail_screen.dart
│   │   ├── add_product_screen.dart    # Form + AI description generator
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
│   │   └── delivery_navigate_screen.dart # OSM navigation
│   └── admin/
│       ├── admin_dashboard_screen.dart
│       ├── admin_users_screen.dart
│       ├── admin_moderation_screen.dart
│       └── admin_categories_screen.dart
├── widgets/
│   ├── bottom_nav.dart                # Customer bottom nav
│   ├── role_bottom_nav.dart           # Role-specific bottom navs
│   ├── role_common.dart               # RoleBody, RoleStatCard, RoleEmpty*
│   ├── product_card.dart              # Product grid card (customer)
│   ├── product_hero.dart              # Detail screen hero image
│   ├── product_gallery.dart           # Image gallery with thumbnails
│   ├── variant_sheet.dart             # Bottom sheet for variant selection
│   ├── category_tile.dart             # Category list tile
│   ├── category_icon_tab.dart         # Home chip strip tab
│   ├── category_picker_sheet.dart     # Category picker for add product
│   ├── cart_action.dart               # Floating cart pill
│   ├── checkout_address_sheets.dart   # Address picker for checkout
│   ├── delivery_address_sheet.dart    # Address picker (live/map/typed/saved)
│   ├── notification_bell.dart         # Header bell with unread badge
│   ├── home_all_sections.dart         # Home "All" tab sections
│   ├── home_brand_store_sections.dart # Brand & store rows
│   ├── chip_store_sections.dart       # Store page for category chips
│   ├── festival_sections.dart         # Festival tab content
│   ├── festival_artwork.dart          # Festival decorative art
│   ├── ganesh_art.dart                # Ganesh festival artwork
│   ├── run_stops.dart                 # Delivery pickup/drop card
│   ├── live_entrance.dart             # Fade-in animation for live lists
│   ├── pressable.dart                 # Press feedback wrapper
│   ├── plain_app_bar.dart             # Simple app bar
│   ├── gradient_app_bar.dart          # Gradient app bar for role screens
│   ├── partner_profile.dart           # Seller/delivery profile header
│   ├── app_network_image.dart         # CachedNetworkImage wrapper
│   ├── app_lifecycle_recovery.dart    # App lifecycle handling
│   ├── adaptive_image.dart            # Asset/network image with fallback
│   ├── voice_search_button.dart       # Voice/photo search trigger
│   ├── voice_search_sheet.dart        # Voice/photo input sheet
│   ├── edit_tools.dart                # Admin edit pencils
│   ├── edit_badge.dart                # Admin edit badge
│   ├── osm_attribution.dart           # OpenStreetMap copyright
│   ├── night_sky.dart                 # Night mode animated sky
│   ├── listing_common.dart            # Shared listing utilities
│   └── form_section.dart              # Form section wrapper
└── widgets/ (continued)
    └── ...
```

---

## Backend & Database

### Supabase Project
- **URL**: `https://rtceqrzicxrxaajfrerl.supabase.co`
- **Database**: PostgreSQL with Row Level Security (RLS)
- **Auth**: Email/password, Google OAuth, Phone (via edge function)
- **Realtime**: Orders, notifications, delivery_tracking, banners
- **Storage Buckets**: `avatars`, `product_images`, `seller_documents`, `delivery_documents`

### Key Tables
| Table | Purpose | RLS Highlights |
|-------|---------|----------------|
| `profiles` | User accounts, role, online status | Self read/write; role change blocked for admin |
| `sellers` | Business profile for sellers | Owner-only write |
| `delivery_partners` | Partner profile | Owner-only write |
| `stores` | Store location & details | Seller owns via `owner_id` |
| `products` | Product catalog | Seller owns via `seller_id`; admin full access |
| `product_variants` | Size/pack variants | Seller owns via product |
| `orders` | Customer orders (one per seller) | Customer reads own; seller reads own; delivery reads assigned |
| `order_items` | Line items per order | Same as orders |
| `cart_items` | Persistent cart | Customer owns |
| `wallet_transactions` | Wallet ledger | User reads own; system writes |
| `payout_requests` | Seller payout requests | Seller creates; admin approves |
| `delivery_earnings` | Partner earnings per delivery | Partner reads own |
| `notifications` | In-app notifications | User reads own; system writes |
| `device_tokens` | FCM tokens per user | User owns token |
| `reviews` | Product reviews | Customer writes; public read |
| `festivals` | Festival calendar | Admin writes; public read |
| `banners` | Home carousel banners | Admin writes; public read |
| `categories` | Category tree | Admin writes; public read |
| `app_events` | Analytics events | User writes own; admin reads all |
| `app_errors` | Error reports | User writes own; admin reads all |
| `support_messages` | Customer ↔ Admin chat | Thread per user; admin reads all |

### Security Functions (Applied via Migrations)
- `protect_profile_role()` — Blocks non-admin from setting role=admin
- `protect_order_money()` — Blocks customers from changing order amounts
- `apply_referral()` — Referral bonus (₹50 each), caller must be the new user
- `use_coupon()` — Coupon redemption, caller must be the user
- `place_order()` — **Server-side pricing**: reads cart, calculates totals, locks stock, creates orders, empties cart atomically
- `verify_razorpay_payment()` — Validates payment signature, records in `verified_payments`
- `payout_balance()` — Seller/partner available balance
- `claim_device_token()` / `release_device_token()` — FCM token management

### Edge Functions
| Function | Trigger | Purpose |
|----------|---------|---------|
| `send-push` | `notifications` INSERT trigger | Sends FCM push via Firebase Admin SDK |
| `generate-product-description` | Seller "Generate with AI" button | AI product descriptions (700-1500 words) |
| `create-razorpay-order` | Checkout | Creates Razorpay order for cart total |
| `verify-razorpay-payment` | Payment success callback | Verifies signature, records payment |
| `phone-login` | Phone sign-in | Looks up email by phone, does password grant |

---

## Key Features

### Customer App
- **Home Screen**: Dynamic chip strip (All, **Diwali**, Festival, Electronics, Beauty, Pharmacy, Gifting, Decor, Kids, Imported), auto-sliding promo carousel, brand/store sections, festival sections
- **Search**: Text search, **voice search** (speech-to-text), **visual search** (ML Kit image labeling + OCR)
- **Product Variants**: Multiple sizes/packs per product with individual pricing & stock
- **Cart**: Persistent (Supabase), guest merge on login, coupon support, wallet apply, tip for delivery
- **Checkout**: Address picker (current location, map, typed, saved), payment method selection (COD, Online, Wallet), free delivery ≥₹299 per store
- **Order Tracking**: Live map (OpenStreetMap via flutter_map), 4-step status (Placed → Preparing → On Way → Delivered)
- **Wallet**: Top-up via Razorpay, transaction history, referral bonus (₹50 each)
- **Wishlist**: Save products, add all to cart
- **Notifications**: In-app inbox with archive/delete, realtime updates, push with loud channel for orders
- **Multi-language**: Flutter gen-l10n, currently English (extensible)

### Diwali Storefront (Home tab)

A full festive storefront built with Flutter widgets and Dart — no HTML or
WebView. Open it from the **Diwali** chip on Home or the `/diwali` named
route. It has the dark fairy-light hero, six arch tiles, sticky light header,
18 content sections, product carousels, editorial banners, gifting filters,
cart/stepper, wishlist, live search, hover states, scroll reveals and three
responsive layouts (phone / tablet / desktop). Everything is local assets and
bundled fonts, so it works offline. See [`lib/diwali/README.md`](lib/diwali/README.md)
for the architecture, integration switch and CI checks. The static design
reference lives in [`festive-ui/`](festive-ui/README.md).

### Seller Dashboard
- **Overview**: Stats cards (orders, products, balance, rating, sold out, low stock), 7-day sales chart, category distribution
- **Products**: CRUD with variants, image upload, **AI description generator** (700-1500 words, structured sections), stock management
- **Orders**: Live status updates, order details, payout per order
- **Store Profile**: Business name, address (map picker), timings, banner
- **Earnings**: Net earnings, payout requests, transaction history
- **Returns**: Customer return requests with approve/reject
- **Reviews**: Product ratings & reviews
- **Boost Requests**: Sponsored slot requests

### Delivery Partner Dashboard
- **Online/Offline Toggle**: Controls order assignment
- **Today's Performance**: Earnings, runs, cash collected, orders
- **Active Runs**: Pickup store + address, drop address, navigate (OSRM), call customer, mark delivered
- **Available Orders**: Nearby ready-for-pickup orders with earnings preview (fee + tip)
- **Earnings**: 7/30 day chart, total, available balance (payout_balance), cash in hand
- **Performance**: Success rate, cancellation rate, ratings
- **Navigation**: Turn-by-turn on OpenStreetMap

### Admin Dashboard
- **Platform Stats**: Products, orders, sellers, delivery partners counts
- **Store Editor**: Opens customer app in edit mode (pencils on banners, chips, categories)
- **Categories**: Full CRUD with hierarchy, images, sort order
- **Users**: All accounts with role, online status, actions
- **Moderation**: Returns, issues, sponsored slots queues

### AI Product Description Generator
- **Length Rule**: 700-1500 words (enforced server-side)
- **Structure**: 8 sections (What it is, Why you'll like it, Specifications, How to use, Storage, Good to know, FAQ, About seller) + 6-8 highlights
- **Honesty Constraints**: No invented prices, certifications, medical claims, guarantees
- **Fallback**: Composes from seller's notes if AI unavailable (no key, timeout, provider error)
- **Rate Limit**: 8 requests per 10 minutes per seller
- **Providers**: OpenAI-compatible (OpenAI, Groq, OpenRouter, DeepSeek, Together)
- **Reasoning Models**: Supports gpt-oss, o1, qwen3, deepseek-r1 with thinking budget

### Push Notifications
- **Two Channels**: Default (updates) + Loud (new order/assigned run) with custom sound & vibration pattern
- **Targeted**: Per-user via `device_tokens` table
- **Background**: Works when app closed via background isolate
- **TTS Announcement**: Speaks order title aloud for loud notifications
- **Deep Link**: Opens notifications screen on tap

---

## Security

### Authentication
- Supabase Auth with implicit flow (PKCE not needed for email/password)
- Session persistence via SharedPreferences (recovery on launch)
- Google Sign-In (OAuth)
- Phone login via edge function (looks up email, does password grant)
- Password reset via deep link (`com.duggustore.app://reset-password`)

### Database Security
- **Row Level Security** on all tables
- **Triggers** prevent privilege escalation:
  - `protect_profile_role`: No self-promotion to admin
  - `protect_order_money`: Customers cannot modify order amounts
- **Server-side order pricing**: `place_order()` is the only way to create orders
- **Verified payments**: Only `verify-razorpay-payment` can mark payments verified

### Data Protection
- Guest activity not recorded in analytics/errors
- Error fingerprints (not raw messages) stored
- Rate limiting on AI endpoint
- FCM tokens scoped to user, released on sign-out
- No card/UPI details stored (Razorpay handles)

---

## Getting Started

### Prerequisites
- Flutter SDK ^3.5.0
- Dart ^3.5.0
- Supabase project (URL + anon key)
- Firebase project with `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
- Razorpay account (key ID + secret for edge functions)
- OpenAI-compatible API key (for AI descriptions)

### Installation

```bash
# Clone repository
git clone <repository-url>
cd DUGGUSTORE-master

# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run
flutter run
```

### Required Supabase Setup
1. Run all SQL migrations in `supabase/` folder (order matters)
2. Deploy edge functions:
   ```bash
   supabase functions deploy send-push
   supabase functions deploy generate-product-description
   supabase functions deploy create-razorpay-order
   supabase functions deploy verify-razorpay-payment
   supabase functions deploy phone-login
   ```
3. Set edge function secrets:
   ```
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
3. Enable FCM in Firebase Console
4. Add `order_alert` sound to `android/app/src/main/res/raw/`

### Required Razorpay Setup
1. Create Razorpay account
2. Add Key ID + Secret to edge function environment
3. Configure webhook for payment verification (handled by `verify-razorpay-payment`)

---

## Environment Configuration

### Supabase Service (`lib/services/supabase_service.dart`)
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### App Constants (`lib/utils/constants.dart`)
```dart
static const String appName = 'Infinity';
static const Color primaryColor = Color(0xFFFF5A00); // Brand orange
```

### Deep Links
- Android: `android/app/src/main/AndroidManifest.xml` — `com.duggustore.app://reset-password`
- iOS: `ios/Runner/Info.plist` — `com.duggustore.app`

---

## Deployment

### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release
```
- Ensure `google-services.json` is present for push notifications
- `geolocator_android` pinned to 4.6.1 in `dependency_overrides`

### iOS
```bash
flutter build ios --release
```
- Add `GoogleService-Info.plist` to Runner
- Configure push capabilities in Xcode

### Web
```bash
flutter build web --release
```
- Output in `build/web/`
- Configure Supabase CORS for your domain

### Edge Functions
```bash
supabase functions deploy <function-name>
```
Set secrets in Supabase Dashboard → Edge Functions → Secrets.

---

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Specific test file
flutter test test/product_card_test.dart
```

### Test Suites
| Test File | Coverage |
|-----------|----------|
| `widget_test.dart` | Basic widget tests |
| `cart_provider_test.dart` | Cart logic, stock, sync |
| `product_card_test.dart` | Product card rendering |
| `checkout_math_test.dart` | Delivery fee, free threshold |
| `search_history_test.dart` | Local search history |
| `theme_mode_test.dart` | Theme tokens light/dark |
| `tokens_test.dart` | Design token values |
| `role_screens_test.dart` | Role-based navigation |
| `analytics_test.dart` | Event catalog, cleaning |
| `error_reporter_test.dart` | Fingerprinting, throttling |
| `visual_search_test.dart` | ML Kit integration |
| `variant_choice_test.dart` | Variant selection logic |
| `indian_ids_test.dart` | PAN/Aadhaar/GSTIN validation |
| `festival_window_test.dart` | Festival chip visibility |

---

## Contributing

### Code Style
- Follows `flutter_lints` (v6.0.0)
- Run `flutter analyze` before committing
- Format with `dart format .`

### Architecture Principles
1. **Single source of truth**: Providers own state; screens only read
2. **Server-authoritative**: Money, stock, order status decided on server
3. **Graceful degradation**: Offline-first where possible; failed loads show retry, not empty state
4. **Explicit over implicit**: Named events, typed models, catalog-validated analytics
5. **Design tokens**: Use `context.tokens` for colors, `AppSpacing`/`AppRadius` for layout

### Adding a New Feature
1. Define data model in `lib/models/`
2. Add provider if shared state needed
3. Create service for external API calls
4. Build screens in `lib/screens/<role>/`
5. Add localization keys to `app_en.arb`
6. Write tests in `test/`
7. Update this README if architecture changes

---

## License

Private project — not for public distribution.

---

## Support

For issues, check:
- `app_errors` table in Supabase (admin view)
- `app_events` for user behavior
- Edge function logs in Supabase Dashboard
- Flutter console for client-side errors