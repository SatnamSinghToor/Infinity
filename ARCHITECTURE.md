# Architecture Deep Dive

Detailed technical architecture of the Infinity Flutter application.

---

## State Management

### Provider Pattern
The app uses **Provider** (`^6.1.2`) for all shared state. Providers are registered at the app root in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CartProvider()),
    ChangeNotifierProvider(create: (_) => ProductProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => OrderProvider()),
    ChangeNotifierProvider(create: (_) => WishlistProvider()),
    ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ChangeNotifierProvider(create: (_) => WalletProvider()),
    ChangeNotifierProvider(create: (_) => EditModeProvider()),
    ChangeNotifierProxyProvider2<AuthProvider, ProductProvider, DeliveryEtaProvider>(
      create: (_) => DeliveryEtaProvider(),
      update: (_, auth, products, eta) => eta
        ..setInputs(
          lat: auth.deliveryLat,
          lng: auth.deliveryLng,
          sellersWithProducts: { for (final p in products.allProducts) p.sellerId },
        ),
    ),
  ],
  child: MaterialApp(...),
)
```

### Provider Responsibilities

| Provider | Scope | Key Methods |
|----------|-------|-------------|
| `AuthProvider` | App-wide | `signIn`, `signUp`, `signOut`, `loadAddresses`, `switchRole`, `becomeSeller` |
| `CartProvider` | Customer | `addToCart`, `loadCart`, `syncToServer`, `retrySync`, `increaseQuantity` |
| `ProductProvider` | Customer/Seller | `_loadFromSupabase`, `setCategory`, `setBrand`, `setSearchQuery` |
| `OrderProvider` | Customer/Seller/Delivery | `loadOrders`, `watchAllStatuses`, `cancelOrder` |
| `WishlistProvider` | Customer | `loadWishlist`, `toggle`, `addAllToCart` |
| `NotificationProvider` | All roles | `loadNotifications`, `watchLive`, `markRead` |
| `WalletProvider` | Customer/Seller | `loadTransactions`, `topUp`, `spend` |
| `EditModeProvider` | Admin | `set(bool)` — toggles edit pencils |
| `DeliveryEtaProvider` | Customer | `setInputs(lat, lng, sellers)` — computes ETA per seller |

### Data Flow Patterns

1. **Optimistic UI + Background Sync** (Cart):
   ```dart
   // Local change immediate
   _items[index].quantity++;
   notifyListeners();
   // Server sync fire-and-forget
   upsertQuantity(item, newQuantity);
   ```

2. **Realtime Subscriptions** (Orders, Notifications, Banners):
   ```dart
   SupabaseService.client
     .from('orders')
     .stream(primaryKey: ['id'])
     .eq('delivery_id', userId)
     .listen((_) => _load(silent: true));
   ```

3. **Proxy Provider for Derived State** (DeliveryEta):
   - Depends on `AuthProvider` (address) + `ProductProvider` (sellers)
   - Recomputes when either changes

---

## Navigation & Routing

### Role-Based Root Router
`RootRouter` decides the root screen based on auth state and role:

```dart
Widget _screen(BuildContext context) {
  final auth = context.watch<AuthProvider>();

  if (!auth.initialized) return loadingScreen;

  if (!auth.isLoggedIn) {
    if (auth.isGuest) return const MainShell();      // Customer guest
    if (_onboardingSeen == false) return OnboardingScreen(...);
    return const LoginScreen();
  }

  _syncUserData(auth);  // Load cart, orders, notifications, wallet

  switch (auth.role) {
    case UserRole.seller:     return const SellerDashboardScreen();
    case UserRole.delivery:   return const DeliveryDashboardScreen();
    case UserRole.admin:      return const AdminDashboardScreen();
    case UserRole.customer:   return const MainShell();
  }
}
```

### Screen Frames

| Role | Frame | Bottom Nav | Persistent Tabs |
|------|-------|------------|-----------------|
| Customer | `MainShell` | `BottomNavWidget` | Home, Categories, Cart, Profile |
| Seller | `SellerDashboardScreen` | `RoleBottomNav` | Home, Products, Orders, More |
| Delivery | `DeliveryDashboardScreen` | `RoleBottomNav` | Home, Deliveries, Earnings, More |
| Admin | `AdminDashboardScreen` | `RoleBottomNav` | Home, Users, Moderation |

- **Customer**: `IndexedStack` keeps all 4 tabs alive (scroll position preserved)
- **Roles**: Push new screens over dashboard; bottom nav only on Home tab

### Deep Links
- `com.duggustore.app://reset-password` → `ResetPasswordScreen`
- Handled by `DeepLinkService` + `AppLinks` package
- Registered in `AndroidManifest.xml` / `Info.plist`

---

## UI Architecture

### Design Tokens (`lib/utils/tokens.dart`)

```dart
// Spacing (4pt grid)
AppSpacing.gutter = 16;
AppSpacing.listGap = 12;
AppSpacing.cardPadding = 16;

// Radius
AppRadius.card = 16;
AppRadius.button = 14;
AppRadius.pill = 999;

// Control heights
AppControl.md = 44;  // Standard button
AppControl.lg = 48;  // Primary action

// Type scale (Poppins)
AppType.display = 28/w700;
AppType.title = 21/w700;
AppType.body = 14.5/w500;
AppType.caption = 12.5/w500;
```

### Theme System

Two-layer approach:
1. **AppConstants** — Legacy colors (screens not yet migrated)
2. **AppTokens** — Semantic tokens via `ThemeExtension`

```dart
// Light (shipped)
AppTokens.light = AppTokens(
  surface: 0xFFF7F7F7,
  card: 0xFFFFFFFF,
  primary: 0xFFFF6A00,
  border: 0xFFEBEBEB,
  ...
);

// Dark (ready, not shipped — main.dart forces ThemeMode.light)
AppTokens.dark = AppTokens(
  surface: 0xFF141110,
  card: 0xFF1F1B19,
  primary: 0xFFFF7A1A,
  border: 0xFF332C28,
  ...
);
```

Usage:
```dart
// New code
Container(color: context.tokens.card)

// Legacy
Container(color: AppConstants.cardColor)
```

### Animations

| Animation | Duration | Usage |
|-----------|----------|-------|
| `AppDurations.fast` (150ms) | Press, tick, highlight |
| `AppDurations.base` (250ms) | Sheet, fade, expanding card |
| `AppDurations.slow` (450ms) | Screen transitions |

- Page transitions: `CupertinoPageTransitionsBuilder` on both platforms
- Tab switch: `FadeTransition` + `ScaleTransition` (380ms)
- Promo carousel: Auto-drift 650ms slide + 3s rest
- Live list entrance: `LiveEntrance` (staggered fade-in)

---

## Offline & Resilience

### Cart Persistence
- Local state always reflects user actions immediately
- Background sync to Supabase (`cart_items` table)
- `syncFailed` flag → Cart screen shows "Resend" button
- Guest cart merges into account cart on login

### Loading States
- `isLoading` / `loadFailed` on every provider
- Screens show `RoleBody(loading: ..., failed: ..., onRetry: ...)`
- Empty state ≠ failed state (distinguished explicitly)

### Error Reporting
- `ErrorReporter.start()` in `main()` hooks:
  - `FlutterError.onError` (build errors)
  - `PlatformDispatcher.onError` (async errors)
  - Custom `ErrorWidget.builder` (friendly card instead of red screen)
- Reports to `app_errors` table (fingerprinted, throttled 5min)
- Guest errors logged locally only

### Analytics
- `Analytics.start()` logs `app_open`
- Catalog-validated events only (unknown events dropped)
- Guest events not recorded
- Max 200 events/session, 60-char text limit

---

## Performance Optimizations

### Image Loading
- `AppNetworkImage` wraps `CachedNetworkImage`
- Banner images pre-cached before carousel shows
- `precacheImage` with 8s timeout
- Asset images for bundled festival art

### List Rendering
- `ListView.builder` / `GridView.builder` everywhere
- `shrinkWrap: true` + `NeverScrollableScrollPhysics` for nested scrollers
- `IndexedStack` keeps customer tabs alive (no rebuild)

### Realtime Efficiency
- Streams use `primaryKey: ['id']` for diffing
- Debounced reloads (400ms) on live updates
- Selective column selection (not `select(*)`)

### Font Loading
- Poppins weights bundled in `assets/fonts/`
- `AppFonts.prepare()` loads all weights at startup
- `google_fonts` never downloads (pinned to 8.2.1)

---

## Security Architecture

### Client-Side
- No secrets in code (Supabase anon key is public by design)
- Razorpay key ID from edge function (not in app)
- FCM service account only in edge function env
- AI API key only in edge function env

### Database (RLS + Triggers)
```sql
-- Example: orders policy
CREATE POLICY orders_customer ON orders
  FOR SELECT TO authenticated
  USING (customer_id = auth.uid());

CREATE POLICY orders_seller ON orders
  FOR SELECT TO authenticated
  USING (seller_id = auth.uid());

CREATE POLICY orders_delivery ON orders
  FOR SELECT TO authenticated
  USING (delivery_id = auth.uid());

-- Trigger: protect_order_money
CREATE TRIGGER trg_protect_order_money
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION protect_order_money();
```

### Edge Function Auth
| Function | Auth Method |
|----------|-------------|
| `send-push` | Shared secret header (`x-webhook-secret`) |
| `generate-product-description` | User JWT (Supabase SDK sends automatically) |
| `create-razorpay-order` | User JWT |
| `verify-razorpay-payment` | User JWT |
| `phone-login` | User JWT |

---

## Key Algorithms

### Delivery ETA Calculation
```dart
// DeliveryEtaProvider
1. Get customer lat/lng (from address or live location)
2. Find all sellers with products in cart
3. For each seller: get store lat/lng
4. Compute haversine distance
5. Apply speed factor (configurable per zone)
6. Return nearest store's ETA + buffer
```

### Checkout Math (`lib/utils/checkout_math.dart`)
```dart
// Per seller: delivery fee = 25 (configurable), free if subtotal >= 299
// Wallet capped at balance
// Coupon validated server-side via use_coupon()
// Tip added to delivery partner earnings
```

### Search Relevance (`lib/utils/search_match.dart`)
```dart
// Scores: name match > category match > description match
// Fuzzy matching with typo tolerance
// Returns sorted product list
```

### AI Description Length Enforcement
```typescript
// Edge function: generate-product-description
1. System prompt with per-section word budgets
2. First pass: request full description
3. While wordCount < minWords (700) and passes < maxPasses (3):
   - Request continuation from last stopping point
   - Strip repeated head overlap
4. If wordCount > maxWords (1500): cap at last sentence boundary
5. Fallback: compose from seller notes if AI fails
```

---

## Extensibility Points

### Adding a New Role
1. Add to `UserRole` enum in `auth_provider.dart`
2. Add case in `RootRouter._screen()`
3. Create dashboard screen + `RoleBottomNav` items
4. Add RLS policies for new role
5. Update `roleFromString()` for Supabase sync

### Adding a New Analytics Event
1. Add to `Analytics.catalog` with allowed properties
2. Call `Analytics.log('event_name', {'prop': value})`
3. Event auto-validated, guest-filtered, throttled

### Adding a New Screen to Customer App
1. Add to `MainShell._builders` array
2. Add `MainShell.tab` constant
3. Add `BottomNavWidget` item
4. Screen pads bottom for floating cart pill (96px + safe area)

### Adding a New Edge Function
1. Create `supabase/functions/<name>/index.ts`
2. Deploy: `supabase functions deploy <name>`
3. Call from Flutter: `SupabaseService.client.functions.invoke('<name>', body: {...})`

---

## Migration Strategy (Legacy → Tokens)

The app is mid-migration from `AppConstants` colors to `AppTokens`:

| Status | Components |
|--------|------------|
| **Migrated** | Role nav bars, notification bell, role common widgets, tests |
| **In Progress** | Home screen, product detail, cart, profile |
| **Pending** | Seller screens, delivery screens, admin screens |

Blockers for dark mode:
- Most screens hardcode `AppConstants.*Color`
- `main.dart` forces `ThemeMode.light`
- `test/theme_mode_test.dart` prevents flip until complete

---

## Testing Architecture

### Unit Tests
- Pure functions: `Analytics.cleanProps`, `ErrorReporter.fingerprint`, `checkout_math`
- Provider logic: `CartProvider`, `ProductProvider` (with mocked Supabase)

### Widget Tests
- `WidgetTester` with `MultiProvider` overrides
- `pumpWidget` with `MaterialApp` + providers
- Golden tests for critical UI (product card, tokens)

### Integration Tests
- Not yet implemented
- Candidate: full checkout flow, role switching, AI description

---

## Monitoring & Observability

### Client-Side
- `ErrorReporter` → `app_errors` table
- `Analytics` → `app_events` table
- `debugPrint` for development

### Server-Side
- Edge function logs in Supabase Dashboard
- Postgres `pg_stat_statements` for slow queries
- Realtime connection health via dashboard

### Key Metrics to Watch
- Order placement success rate (via `app_events`: `order_placed` / `checkout_started`)
- AI description fallback rate (`fallback: true` in response)
- Push delivery rate (`sent` / `total` in `send-push` response)
- Cart sync failure rate (`syncFailed` flag)
- Error report volume (spikes = regression)

---

## Future Architecture Considerations

1. **Dark Mode Rollout**: Complete token migration, flip `ThemeMode.system`
2. **Web PWA**: Service worker for offline cart, push via Web Push API
3. **Modularization**: Split into packages (core, customer, seller, delivery, admin)
4. **State Migration**: Evaluate Riverpod or Bloc for complex providers
5. **Backend**: Consider Supabase PostgREST for direct table access vs edge functions
6. **Search**: Add PostgreSQL full-text search or Meilisearch for product search
7. **Internationalization**: Add Hindi, regional languages to `l10n/`