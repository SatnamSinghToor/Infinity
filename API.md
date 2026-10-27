# API Reference

Client-side services, Supabase Edge Functions, and RPC interfaces.

---

## Supabase Client (`lib/services/supabase_service.dart`)

```dart
class SupabaseService {
  static const String supabaseUrl = 'https://rtceqrzicxrxaajfrerl.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  static final SupabaseClient client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,  // No PKCE storage needed
      autoRefreshToken: true,
    ),
  );
}
```

**Usage**: `SupabaseService.client.from('table').select(...)`  
**Auth**: `SupabaseService.client.auth.signInWithPassword(...)`

---

## Edge Functions

All functions deployed to Supabase. Called via:
```dart
final response = await SupabaseService.client.functions.invoke('function-name', body: {...});
```

### 1. `send-push`

**Trigger**: Database trigger `notify_push_on_insert()` on `notifications` INSERT  
**Auth**: Shared secret header (`x-webhook-secret`)  
**Not called directly from client**

```typescript
// Payload from trigger
interface NotifyPayload {
  user_id: string;
  title: string;
  body: string;
  type?: string;
  order_id: string | null;
  loud?: boolean;        // true for new order / assigned run
}

// Response
{ sent: number, total: number }
```

**Behavior**:
- Fetches FCM tokens from `device_tokens` for `user_id`
- Sends via Firebase Admin SDK (FCM v1 API)
- Loud notifications → custom channel `duggu_order_alert` with `order_alert` sound + vibration pattern
- Deletes invalid tokens (UNREGISTERED, NOT_FOUND, INVALID_ARGUMENT)

---

### 2. `generate-product-description`

**Called from**: `ProductDescriptionService.generateDescription()` → Seller "Generate with AI" button  
**Auth**: User JWT (automatically sent by Supabase SDK)  
**Rate Limit**: 8 requests / 10 minutes per user (configurable via `AI_RATE_MAX`)

```typescript
// Request
interface RequestBody {
  name?: string;           // Required
  category?: string;
  unit?: string;
  description?: string;    // Seller's notes
  store?: string;          // Store name
  minWords?: number;       // Default 700
  maxWords?: number;       // Default 1500
}

// Response (success)
{
  description: string;     // 700-1500 words, 8 sections + highlights
  highlights: string[];    // 6-8 short lines
  word_count: number;
  min_words: number;
  max_words: number;
  in_range: boolean;       // true if 700-1500
  short_by: number;        // Words below 700 (0 if in_range)
  passes: number;          // AI continuation passes used
  out_of_time: boolean;    // Hit budgetMs limit
  model: string;           // e.g., "gpt-4o-mini"
  fallback: boolean;       // true if composed without AI
  fallback_reason: string; // 'no_key' | 'bad_key' | 'bad_address' | 'timeout' | 'provider_limit' | 'upstream' | 'not_json' | 'crashed'
}

// Response (error)
{ error: string, code: string, retry_after_minutes?: number }
```

**AI Providers** (via env secrets):
| Provider | `AI_BASE_URL` | `AI_MODEL` Example |
|----------|---------------|-------------------|
| OpenAI | `https://api.openai.com/v1` | `gpt-4o-mini` |
| Groq | `https://api.groq.com/openai/v1` | `openai/gpt-oss-120b` |
| OpenRouter | `https://openrouter.ai/api/v1` | `anthropic/claude-3-haiku` |
| DeepSeek | `https://api.deepseek.com/v1` | `deepseek-chat` |
| Together | `https://api.together.xyz/v1` | `meta-llama/Llama-3-70b` |

**Secrets Required**:
```
AI_API_KEY (or OPENAI_API_KEY / GROQ_API_KEY)
AI_MODEL (optional)
AI_BASE_URL (optional)
AI_TEMPERATURE (optional, default 0.7)
AI_REQUEST_TIMEOUT_MS (optional, default 90000)
AI_BUDGET_MS (optional, default 120000)
AI_MAX_TOKENS (optional)
AI_MAX_PASSES (optional, default 3)
AI_RATE_MAX (optional, default 8)
```

**Fallback Behavior**: If no key / provider error / timeout → composes description from seller's notes using same structure, marks `fallback: true`, `model: "duggu-composed"`.

---

### 3. `create-razorpay-order`

**Called from**: `PaymentService.payForCart()` → Checkout "Pay Online"  
**Auth**: User JWT

```typescript
// Request
{
  receipt: string;           // "duggu_<timestamp>"
  coupon_code?: string;
  wallet_amount?: number;    // Rupees
  tip?: number;              // Rupees
}

// Response
{
  key_id: string;            // Razorpay key ID (public)
  amount: number;            // Paise (₹ * 100)
  order_id: string;          // Razorpay order_id
}
```

**Behavior**:
- Reads user's cart from `cart_items`
- Calculates per-seller totals, delivery fees (₹25, free ≥₹299), coupon, wallet, tip
- Creates one Razorpay order per seller? No — single order for full cart
- Returns amount in **paise** for Razorpay SDK

---

### 4. `verify-razorpay-payment`

**Called from**: `PaymentService` → Razorpay `EVENT_PAYMENT_SUCCESS` callback  
**Auth**: User JWT

```typescript
// Request
{
  order_id: string;          // Razorpay order_id
  payment_id: string;        // Razorpay payment_id
  signature: string;         // Razorpay signature
}

// Response
{
  valid: boolean;
  // If valid: inserts into verified_payments, marks order payment_status='paid'
}
```

**Behavior**:
- Verifies signature using Razorpay secret (server-side only)
- On success: inserts row in `verified_payments` (unique on `payment_id`)
- `place_order()` checks `verified_payments` before accepting online payment

---

### 5. `phone-login`

**Called from**: `AuthProvider.signInWithPhone()`  
**Auth**: None (public function, but validates credentials)

```typescript
// Request
{
  phone: string;             // "9876543210"
  password: string;
}

// Response (success)
{
  // Full GoTrue session object (access_token, refresh_token, user, expires_at, etc.)
  // Client calls SupabaseService.client.auth.recoverSession(response)
}

// Response (error)
{ error: string }  // 'multiple_accounts' | 'invalid_credentials' | generic
```

**Behavior**:
- Looks up email for phone in `profiles`
- Performs `signInWithPassword` server-side
- Returns session for client to recover

---

## Database RPC Functions

Called via:
```dart
final result = await SupabaseService.client.rpc('function_name', params: {...});
```

### `apply_referral(p_new_user_id, p_referral_code)`
```sql
-- Caller MUST be the new user (auth.uid() = p_new_user_id)
-- Finds referrer by referral_code
-- Awards ₹50 to referrer + ₹50 to new user (wallet_transactions)
-- Sets profiles.referred_by
```
**Returns**: `void`

### `use_coupon(p_coupon_code, p_user_id, p_subtotal)`
```sql
-- Caller MUST be the user (auth.uid() = p_user_id)
-- Validates coupon: active, min_order_value, not already used
-- Records in coupon_usages
```
**Returns**: `TABLE(coupon_id uuid, discount_percent integer, max_discount integer)`

### `place_order(p_address, p_address_id, p_coupon_code, p_wallet_amount, p_payment_method, p_payment_id, p_delivery_note)`
```sql
-- THE ONLY WAY TO CREATE ORDERS
-- 1. Reads caller's cart_items
-- 2. For each seller: computes subtotal, delivery fee (₹25, free ≥₹299)
-- 3. Validates coupon via use_coupon()
-- 4. Validates wallet (capped at balance via payout_balance())
-- 5. For online: checks verified_payments for payment_id ≥ amount_due
-- 6. Locks stock (products + variants)
-- 7. Creates one order per seller with order_items
-- 8. Empties cart
-- 9. All or nothing (transaction)
```
**Params**:
```typescript
{
  p_address: string;           // Delivery address text
  p_address_id?: string;       // Saved address UUID
  p_coupon_code?: string;
  p_wallet_amount?: number;    // Rupees
  p_payment_method?: string;   // 'cod' | 'online' | 'wallet' | 'wallet+cod' | 'wallet+online'
  p_payment_id?: string;       // Razorpay payment_id (for online)
  p_delivery_note?: string;
}
```
**Returns**: `SET OF orders` (one per seller)

### `payout_balance()`
```sql
-- Returns available balance for caller (seller or delivery partner)
-- earned - outstanding (pending payouts)
```
**Returns**: `TABLE(earned numeric, outstanding numeric)`

### `claim_device_token(p_token, p_platform)`
```sql
-- Registers FCM token for current user
-- Upserts into device_tokens
```
**Returns**: `void`

### `release_device_token(p_token)`
```sql
-- Deletes token from device_tokens (on sign-out)
```
**Returns**: `void`

---

## Client Services

### `AuthProvider` (`lib/providers/auth_provider.dart`)

```dart
// Authentication
Future<bool> signUp({required email, password, fullName, phone, referralCode})
Future<bool> signIn({required email, password})
Future<bool> signInWithGoogle()
Future<bool> signInWithPhone({required phone, password})
Future<String?> sendPasswordReset(String email)
Future<bool> completeAuthCallback(Uri uri)  // Returns true if recovery link
Future<String?> updatePassword(String newPassword)
Future<void> signOut()

// Profile
Future<bool> updateProfile({required fullName, phone})
Future<bool> updateAvatar(Uint8List bytes)
Future<bool> switchRole(UserRole newRole)
Future<bool> becomeSeller({required businessName, ownerName})
Future<bool> becomeDeliveryPartner({required fullName, vehicleType, vehicleNumber})
Future<bool> setOnlineStatus(bool online)
Future<void> refreshProfile()  // Retry stale profile load

// Addresses
Future<void> loadAddresses()
Future<bool> addAddress(Address)
Future<bool> updateAddress(String id, Address)
Future<bool> setDefaultAddress(String id)
Future<bool> deleteAddress(String id)
Address? getDefaultAddress()
void setLocalAddress(String, {lat, lng})  // Guest/local
String get address  // Account default OR local
double? get deliveryLat
double? get deliveryLng

// State
bool get isLoggedIn
bool get isGuest
bool get initialized
UserRole get role
bool get isOnline
List<Address> get addresses
String? get avatarUrl
bool get profileStale  // Profile load failed, retrying
```

### `CartProvider` (`lib/providers/cart_provider.dart`)

```dart
// State
List<CartItem> get items
bool get isLoading
bool get loadFailed
bool get syncFailed
int get itemCount
double get totalAmount

// Actions
Future<void> loadCart()  // Load from server, merge guest items
Future<bool> syncToServer()  // Force full sync before checkout
Future<bool> retrySync()  // Retry after syncFailed

bool addToCart(Product, {variantId, variantName, variantPrice})
bool chooseVariant(Product, {required variantId, variantName, variantPrice})
void removeFromCart(productId, {variantId})
bool increaseQuantity(productId, {variantId})
void decreaseQuantity(productId, {variantId})
void clearCart()
int getQuantity(productId, {variantId})
bool isInCart(productId, {variantId})
bool canAddMore(Product, {variantId})  // Stock check
void resetLocal()  // On sign-out
```

### `ProductProvider` (`lib/providers/product_provider.dart`)

```dart
// State
String get selectedCategory
String? get selectedBrand
String get searchQuery
List<Product> get allProducts
List<Product> get filteredProducts  // Category + brand + search
List<String> get categories
List<IconData> get categoryIcons
bool get isLoading
bool get loadFailed
bool get usingLiveData

// Category/brand/search
void setCategory(String)
void setBrand(String?)
void setSearchQuery(String)
Future<void> reload()

// Lookups
Product? getProductById(String id)
int variantCount(String productId)
String? categoryImage(String name)
bool pictureRemoved(String name)
String? categoryCardImage(String name)
List<String> subCategoriesOf(String parent)
bool inCategoryGroup(Product, String parent)

// Constants
static const homeChips = [HomeChip('All', Iconsax.category), ...]
```

### `OrderProvider` (`lib/providers/order_provider.dart`)

```dart
// State
List<Order> get orders
bool get isLoading
bool get loadFailed

// Actions
Future<void> loadOrders()
Future<void> watchAllStatuses()  // Realtime subscription
void stopWatching()
Future<bool> cancelOrder(String orderId)
static const freeDeliveryThreshold = 299.0
static const deliveryFee = 25.0
```

### `WalletProvider` (`lib/providers/wallet_provider.dart`)

```dart
// State
double get balance
List<WalletTransaction> get transactions
bool get isLoading

// Actions
Future<void> loadTransactions()
Future<bool> topUp(double amount)  // Opens Razorpay
Future<bool> spend(double amount, String reason, String? referenceId)
```

### `NotificationProvider` (`lib/providers/notification_provider.dart`)

```dart
// State
List<AppNotification> get notifications
int get unreadCount
bool get isLoading

// Actions
Future<void> loadNotifications()
Future<void> watchLive()  // Realtime
void stopWatching()
Future<void> markRead(String id)
Future<void> markAllRead()
Future<void> archive(String id)
Future<void> unarchive(String id)
Future<void> delete(String id)
Future<void> clearAll()
Future<void> clearArchive()
```

### `DeliveryEtaProvider` (`lib/providers/delivery_eta_provider.dart`)

```dart
// State
DeliveryStatus get status  // ok, noLocation, noStore, outOfRange
String? get label  // "12 min", "Set address", etc.
String? get storeName
String? get distanceLabel  // "2.3 km"

// Input
void setInputs({required lat, lng, sellersWithProducts})
```

### `PushService` (`lib/services/push_service.dart`)

```dart
static GlobalKey<NavigatorState>? navigatorKey
static VoidCallback? onPush  // Set by RootRouter

static Future<void> start()  // Call from main()
static Future<void> releaseForSignOut()  // Call before signOut()
```

### `PaymentService` (`lib/services/payment_service.dart`)

```dart
static Future<RazorpayPaymentResult> payForCart({
  String? contactPhone,
  String? contactEmail,
  String couponCode = '',
  int walletAmount = 0,
  int tip = 0,
})

class RazorpayPaymentResult {
  final bool success
  final String? paymentId
  final String? errorMessage
  const RazorpayPaymentResult.success(this.paymentId)
  const RazorpayPaymentResult.failure(this.errorMessage)
}
```

### `ProductDescriptionService` (`lib/services/product_description_service.dart`)

```dart
static const minWords = 700
static const maxWords = 1500

static Future<AiDescriptionResult> generateDescription({
  required String name,
  String? category,
  String? unit,
  String? description,
  String? store,
  int? minWords,
  int? maxWords,
})

class AiDescriptionResult {
  final String description
  final List<String> highlights
  final int wordCount
  final int minWords
  final int maxWords
  final bool inRange
  final int shortBy
  final int passes
  final bool outOfTime
  final String model
  final bool fallback
  final String? fallbackReason
}
```

### `Analytics` (`lib/services/analytics.dart`)

```dart
static void start()  // Logs 'app_open'
static void log(String name, [Map<String, Object?> props = {}])

// Catalog (validated events)
static const catalog = {
  'app_open': {},
  'product_view': {'product_id'},
  'add_to_cart': {'product_id', 'quantity'},
  'search': {'term', 'results'},
  'checkout_started': {'items', 'subtotal'},
  'order_placed': {'total', 'items', 'payment', 'coupon'},
  'coupon_failed': {'code', 'reason'},
}

// Limits
static const maxPerSession = 200
static const maxTextLength = 60
```

### `ErrorReporter` (`lib/services/error_reporter.dart`)

```dart
static void start()  // Hooks FlutterError, PlatformDispatcher, ErrorWidget
static Future<void> report(Object error, StackTrace? stack, {String source = 'unknown'})

// Limits
static const maxPerSession = 10
static const window = Duration(minutes: 5)
```

---

## Realtime Subscriptions

```dart
// Orders (customer, seller, delivery)
SupabaseService.client
  .from('orders')
  .stream(primaryKey: ['id'])
  .eq('customer_id', userId)  // or seller_id, delivery_id
  .listen((rows) => ...)

// Notifications
SupabaseService.client
  .from('notifications')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .listen((rows) => ...)

// Delivery tracking (customer watching their order)
SupabaseService.client
  .from('delivery_tracking')
  .stream(primaryKey: ['id'])
  .eq('order_id', orderId)
  .listen((rows) => ...)

// Banners (admin edits on Home)
SupabaseService.client
  .from('banners')
  .stream(primaryKey: ['id'])
  .eq('is_active', true)
  .order('sort_order')
  .listen((rows) => ...)
```

---

## Webhooks & External APIs

### Razorpay Webhook
- **Not used**: Verification done via `verify-razorpay-payment` edge function called from client
- Client receives `payment_id`, `order_id`, `signature` from Razorpay SDK
- Sends to edge function for server-side verification

### Firebase FCM
- **Upstream**: `send-push` edge function → Firebase Admin SDK → FCM v1 API
- **Downstream**: `FirebaseMessaging.onMessage` (foreground), `onBackgroundMessage` (background), `onMessageOpenedApp` (tap)
- **Token**: `FirebaseMessaging.instance.getToken()` → stored in `device_tokens` via `claim_device_token()`

### Google Sign-In
- `GoogleAuthService.signIn()` → returns `GoogleSignInAuthentication`
- Client sends ID token to Supabase: `supabase.auth.signInWithIdToken(provider: 'google', token: idToken)`

### OpenStreetMap / OSRM
- Tiles: `flutter_map` + OpenStreetMap (no API key)
- Routing: `RouteService` → `router.project-osrm.org` (free, no key)
- Geocoding: `GeocodingService` → `nominatim.openstreetmap.org` (free, rate limited)

### ML Kit (On-Device)
- **Subject Segmentation**: `GoogleMlKitSubjectSegmentation` → background removal
- **Image Labeling**: `GoogleMlKitImageLabeling` → visual search labels
- **Text Recognition**: `GoogleMlKitTextRecognition` → OCR for visual search

---

## Error Codes

### Edge Function Errors
| Code | HTTP | Meaning |
|------|------|---------|
| `AI_AUTH` | 401 | Not signed in |
| `AI_RATE_LIMIT` | 429 | Too many requests, retry_after_minutes |
| `AI_NO_NAME` | 400 | Product name required |
| `AI_EMPTY` | 502 | AI returned nothing |
| `AI_INTERNAL` | 500 | Unexpected error |
| `BAD_METHOD` | 405 | Not POST |
| `TOO_LARGE` | 413 | Request > 40KB |
| `BAD_JSON` | 400 | Invalid JSON |
| `FORBIDDEN` | 403 | Invalid webhook secret (send-push) |

### RPC Errors
| Code | Meaning |
|------|---------|
| `P0001` | Coupon errors: `INVALID_COUPON`, `MIN_ORDER:<value>`, `ALREADY_USED` |
| `42501` | RLS/trigger violation (protect_profile_role, protect_order_money) |

### Razorpay Errors
- Handled in `PaymentService` → `RazorpayPaymentResult.failure(message)`

---

## Rate Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| `generate-product-description` | 8 | 10 minutes |
| `send-push` | Per notification | Trigger-controlled |
| `create-razorpay-order` | Per checkout | User-initiated |
| `verify-razorpay-payment` | Per payment | User-initiated |
| Nominatim geocoding | 1 req/sec | Per IP (OSM policy) |
| OSRM routing | Unlimited | Fair use |

---

## Versioning & Compatibility

- **Flutter App**: Version in `pubspec.yaml` (`version: 1.0.0+1`)
- **Edge Functions**: Deployed independently, backward compatible
- **Database**: Migrations only additive; breaking changes require coordinated deploy
- **Supabase Client**: Pinned to `^2.6.0` (plain Dart client, not `supabase_flutter`)

---

## Testing Edge Functions Locally

```bash
# Start local Supabase
supabase start

# Serve function locally
supabase functions serve generate-product-description --env-file .env.local

# Test with curl
curl -X POST http://localhost:54321/functions/v1/generate-product-description \
  -H "Authorization: Bearer <user_jwt>" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Product", "category": "Grocery"}'
```

---

## Monitoring Endpoints

| Metric | Source |
|--------|--------|
| Order success rate | `app_events` (`order_placed` / `checkout_started`) |
| AI fallback rate | `generate-product-description` logs (`fallback: true`) |
| Push delivery rate | `send-push` response (`sent` / `total`) |
| Cart sync failures | `CartProvider.syncFailed` flag |
| Error volume | `app_errors` table count |
| Active users | `profiles` with recent `app_events` |