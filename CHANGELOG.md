# Changelog

All notable changes to Infinity.

---

## [1.0.0] - 2026-01-15

### Added
- Initial release of Infinity multi-role marketplace
- Customer app: Home, Categories, Cart, Profile, Orders, Wallet, Wishlist
- Seller dashboard: Products, Orders, Earnings, Store Profile, AI descriptions
- Delivery partner dashboard: Runs, Navigation, Earnings, Performance
- Admin dashboard: Platform stats, User management, Category editor, Store editor
- Supabase backend with RLS, Realtime, Edge Functions
- Razorpay integration for online payments
- Firebase FCM push notifications with loud channel
- AI product description generator (700-1500 words, structured)
- Voice search + Visual search (ML Kit)
- Multi-language support (English, gen-l10n)

### Security
- Server-side order pricing via `place_order()` RPC
- `protect_profile_role()` trigger prevents admin self-promotion
- `protect_order_money()` trigger prevents customer amount tampering
- Verified payments table for Razorpay signature validation
- Rate limiting on AI endpoint

---

## [Unreleased]

### Planned
- Dark mode rollout (complete token migration)
- Hindi & regional language support
- PWA web build with service worker
- Meilisearch for product search
- Seller analytics dashboard
- Delivery partner route optimization
- Automated testing pipeline

---

## Versioning

- `pubspec.yaml`: `version: 1.0.0+1` (build number increments per release)
- Git tags: `v1.0.0`, `v1.0.1`, etc.
- Supabase migrations: additive only, versioned by timestamp
- Edge functions: deployed independently, backward compatible