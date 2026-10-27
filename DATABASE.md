# Database Schema Reference

Complete Supabase/PostgreSQL schema for Infinity.

---

## Tables

### Core Auth & Profiles

#### `auth.users` (Supabase managed)
```sql
-- Extended via profiles table
id uuid PRIMARY KEY
email text
encrypted_password text
email_confirmed_at timestamptz
created_at timestamptz
updated_at timestamptz
raw_app_meta_data jsonb
raw_user_meta_data jsonb
```

#### `public.profiles`
```sql
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  phone text,
  role text NOT NULL DEFAULT 'customer' 
    CHECK (role IN ('customer', 'seller', 'delivery', 'admin')),
  is_online boolean NOT NULL DEFAULT false,
  avatar_url text,
  referral_code text UNIQUE,
  referred_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_read ON public.profiles
  FOR SELECT TO authenticated USING (id = auth.uid() OR public.is_admin());

CREATE POLICY profiles_write ON public.profiles
  FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Trigger: protect_profile_role() prevents non-admin from setting role='admin'
```

#### `public.is_admin()` Helper
```sql
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;
```

---

### Seller & Store

#### `public.sellers`
```sql
CREATE TABLE public.sellers (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name text NOT NULL,
  owner_name text NOT NULL,
  email text NOT NULL,
  phone text,
  gstin text,
  pan text,
  bank_account jsonb,           -- {account_number, ifsc, holder_name}
  upi_id text,
  commission_rate numeric DEFAULT 10,  -- percentage
  kyc_status text DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'approved', 'rejected')),
  kyc_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- RLS: seller owns row; admin full access
```

#### `public.stores`
```sql
CREATE TABLE public.stores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  address text NOT NULL,
  latitude double precision,
  longitude double precision,
  radius_km numeric DEFAULT 5,
  open_time time DEFAULT '09:00',
  close_time time DEFAULT '22:00',
  is_active boolean DEFAULT true,
  banner_url text,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX stores_owner_idx ON public.stores(owner_id);
CREATE INDEX stores_location_idx ON public.stores USING GIST (
  ll_to_earth(latitude, longitude)
);

-- RLS: owner_id = auth.uid() for write; public read for active stores
```

#### `public.seller_documents`
```sql
CREATE TABLE public.seller_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('pan', 'gstin', 'bank_passbook', 'owner_id', 'business_registration')),
  file_url text NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
```

---

### Delivery Partner

#### `public.delivery_partners`
```sql
CREATE TABLE public.delivery_partners (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  email text NOT NULL,
  phone text,
  vehicle_type text NOT NULL CHECK (vehicle_type IN ('bike', 'scooter', 'bicycle', 'ev_scooter')),
  vehicle_number text,
  license_number text,
  bank_account jsonb,           -- {account_number, ifsc, holder_name}
  upi_id text,
  kyc_status text DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'approved', 'rejected')),
  kyc_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

#### `public.delivery_partner_documents`
```sql
CREATE TABLE public.delivery_partner_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('license', 'vehicle_rc', 'insurance', 'owner_id', 'bank_passbook')),
  file_url text NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
```

#### `public.delivery_tracking`
```sql
CREATE TABLE public.delivery_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  partner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  accuracy double precision,
  speed double precision,
  heading double precision,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX delivery_tracking_order_idx ON public.delivery_tracking(order_id, recorded_at);

-- RLS: partner sees own; customer sees their order's tracking; admin all
-- Realtime enabled for live map
```

#### `public.delivery_earnings`
```sql
CREATE TABLE public.delivery_earnings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  amount numeric NOT NULL,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX delivery_earnings_partner_idx ON public.delivery_earnings(partner_id, created_at);
```

#### `public.delivery_ratings`
```sql
CREATE TABLE public.delivery_ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  delivery_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (order_id, delivery_id)
);
```

---

### Products & Catalog

#### `public.categories`
```sql
CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  parent_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  sort_order integer DEFAULT 0,
  image_url text,              -- Card background image
  icon_url text,               -- Full-card replacement image
  is_active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- RLS: public read active; admin write
```

#### `public.products`
```sql
CREATE TABLE public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price numeric NOT NULL,           -- Base price
  discount_price numeric,           -- Sale price (if < price)
  image_url text,                   -- Main image (legacy single)
  image_urls text[] DEFAULT '{}',   -- Gallery images
  unit text DEFAULT '1 pc',         -- e.g., "500g", "1L", "1 kg"
  rating numeric DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
  is_veg boolean DEFAULT true,
  stock integer DEFAULT 999,
  is_active boolean DEFAULT true,
  seller_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  store_id uuid REFERENCES public.stores(id) ON DELETE SET NULL,
  category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  brand text,                       -- Company brand (Apple, Amul, etc.)
  about_highlights text[] DEFAULT '{}',  -- Bullet points for "About this item"
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX products_seller_idx ON public.products(seller_id);
CREATE INDEX products_category_idx ON public.products(category_id);
CREATE INDEX products_active_idx ON public.products(is_active) WHERE is_active = true;
CREATE INDEX products_store_idx ON public.products(store_id);

-- RLS: seller owns via seller_id; admin full; public read active
```

#### `public.product_variants`
```sql
CREATE TABLE public.product_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  name text NOT NULL,               -- e.g., "500g", "1kg", "Pack of 6"
  price numeric NOT NULL,           -- Variant-specific price
  stock integer DEFAULT 999,
  is_active boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX product_variants_product_idx ON public.product_variants(product_id);

-- RLS: seller via product.seller_id (see product_variants_seller.sql)
```

---

### Orders & Cart

#### `public.orders`
```sql
CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  delivery_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'pending' 
    CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready_for_pickup', 'out_for_delivery', 'delivered', 'cancelled')),
  total_amount numeric NOT NULL DEFAULT 0,
  delivery_address text NOT NULL,
  delivery_latitude double precision,
  delivery_longitude double precision,
  delivery_fee numeric DEFAULT 0,
  wallet_used numeric DEFAULT 0,
  tip numeric DEFAULT 0,
  payment_method text CHECK (payment_method IN ('cod', 'online', 'wallet', 'wallet+cod', 'wallet+online')),
  payment_status text DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  payment_id text,                  -- Razorpay payment_id for online
  seller_payout numeric DEFAULT 0,  -- Amount seller receives after commission
  delivery_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  confirmed_at timestamptz,
  delivered_at timestamptz
);

CREATE INDEX orders_customer_idx ON public.orders(customer_id, created_at DESC);
CREATE INDEX orders_seller_idx ON public.orders(seller_id, created_at DESC);
CREATE INDEX orders_delivery_idx ON public.orders(delivery_id, status) WHERE delivery_id IS NOT NULL;
CREATE INDEX orders_status_idx ON public.orders(status) WHERE status IN ('ready_for_pickup', 'out_for_delivery');

-- RLS: customer reads own; seller reads own; delivery reads assigned; admin all
-- Trigger: protect_order_money() prevents customer from changing amounts
-- Trigger: notify_push_on_insert() sends push for new orders
-- Realtime enabled
```

#### `public.order_items`
```sql
CREATE TABLE public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  variant_id uuid REFERENCES public.product_variants(id) ON DELETE SET NULL,
  quantity integer NOT NULL DEFAULT 1,
  price_at_purchase numeric NOT NULL,  -- Price snapshot at order time
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX order_items_order_idx ON public.order_items(order_id);

-- RLS: same as orders (via order join)
```

#### `public.cart_items`
```sql
CREATE TABLE public.cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,  -- Legacy compat
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  variant_id uuid REFERENCES public.product_variants(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1,
  variant text,                       -- Legacy: variant name
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (customer_id, product_id, variant_id)
);

CREATE INDEX cart_items_customer_idx ON public.cart_items(customer_id);

-- RLS: customer owns
```

---

### Wallet & Payments

#### `public.wallet_transactions`
```sql
CREATE TABLE public.wallet_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  amount numeric NOT NULL,            -- Positive = credit, negative = debit
  type text NOT NULL CHECK (type IN ('CREDIT', 'DEBIT', 'REFUND', 'BONUS', 'TOPUP', 'PAYOUT')),
  reference_id uuid,                  -- Order ID, payout ID, etc.
  reference_type text,                -- 'order', 'payout', 'referral', 'coupon'
  balance_after numeric NOT NULL,     -- Running balance
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX wallet_transactions_user_idx ON public.wallet_transactions(user_id, created_at DESC);

-- RLS: user reads own; system writes via RPC
```

#### `public.payout_requests`
```sql
CREATE TABLE public.payout_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount numeric NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid')),
  bank_account jsonb NOT NULL,        -- Snapshot at request time
  requested_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  processed_by uuid REFERENCES auth.users(id),
  rejection_reason text,
  utr_number text,                    -- Bank transfer reference
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX payout_requests_seller_idx ON public.payout_requests(seller_id, status);
```

#### `public.verified_payments`
```sql
CREATE TABLE public.verified_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  payment_id text NOT NULL,           -- Razorpay payment_id
  order_id_razorpay text NOT NULL,    -- Razorpay order_id
  amount numeric NOT NULL,
  verified_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (payment_id)
);

-- RLS: service role only (edge function writes)
```

#### `public.payment_methods`
```sql
CREATE TABLE public.payment_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('upi', 'card')),
  label text NOT NULL,                -- e.g., "Google Pay", "HDFC Bank"
  detail text NOT NULL,               -- UPI ID or last 4 digits
  is_default boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX payment_methods_user_idx ON public.payment_methods(user_id);

-- RLS: user owns
```

---

### Notifications & Communication

#### `public.notifications`
```sql
CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL,                 -- 'order', 'delivery', 'stock', 'promo', 'wallet', 'account'
  title text NOT NULL,
  body text NOT NULL,
  data jsonb DEFAULT '{}',            -- {order_id, deep_link, ...}
  read_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX notifications_user_idx ON public.notifications(user_id, created_at DESC);
CREATE INDEX notifications_unread_idx ON public.notifications(user_id, read_at) WHERE read_at IS NULL;

-- RLS: user owns
-- Trigger: notify_push_on_insert() → send-push edge function
-- Realtime enabled
```

#### `public.support_messages`
```sql
CREATE TABLE public.support_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,  -- Customer ID
  sender_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body text NOT NULL CHECK (length(trim(body)) BETWEEN 1 AND 2000),
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz
);

CREATE INDEX support_messages_thread_idx ON public.support_messages(thread_id, created_at);

-- RLS: customer reads own thread; admin reads all; sender must be thread owner or admin
-- Realtime enabled
```

#### `public.device_tokens`
```sql
CREATE TABLE public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'macos', 'windows', 'linux', 'fuchsia')),
  created_at timestamptz NOT NULL DEFAULT now(),
  last_used_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, token)
);

CREATE INDEX device_tokens_user_idx ON public.device_tokens(user_id);
CREATE INDEX device_tokens_token_idx ON public.device_tokens(token);

-- RLS: user owns; service role manages via claim_device_token()/release_device_token()
```

---

### Marketing & Promotions

#### `public.banners`
```sql
CREATE TABLE public.banners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sort_order integer DEFAULT 0,
  image_url text NOT NULL,
  link_type text CHECK (link_type IN ('category', 'product', 'url')),
  link_id text,                       -- Category name, product ID, or URL
  title text,                         -- For offer banners (text overlay)
  subtitle text,
  cta_label text,                     -- Button text
  color_from text,                    -- Gradient start (#RRGGBB)
  color_to text,                      -- Gradient end
  accent_color text,                  -- Accent for text
  product_image_urls text[] DEFAULT '{}',  -- For product showcase banners
  is_active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- RLS: public read active; admin write
-- Realtime enabled
```

#### `public.festivals`
```sql
CREATE TABLE public.festivals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  chip_label text,                    -- Short name for Home chip
  color_from text NOT NULL,           -- Gradient start
  color_to text NOT NULL,             -- Gradient end
  artwork_url text,                   -- Festival artwork
  is_active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- RLS: public read active; admin write
```

#### `public.coupons`
```sql
CREATE TABLE public.coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  discount_percent integer NOT NULL CHECK (discount_percent BETWEEN 1 AND 100),
  max_discount integer NOT NULL,      -- Cap in rupees
  min_order_value numeric NOT NULL DEFAULT 0,
  usage_limit integer,                -- NULL = unlimited
  used_count integer DEFAULT 0,
  is_active boolean DEFAULT true,
  valid_from timestamptz NOT NULL DEFAULT now(),
  valid_until timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

#### `public.coupon_usages`
```sql
CREATE TABLE public.coupon_usages (
  coupon_id uuid NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  used_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (coupon_id, user_id)
);
```

#### `public.referrals`
```sql
-- Handled by apply_referral() function
-- profiles.referral_code (unique) + profiles.referred_by
-- Bonus: ₹50 to referrer, ₹50 to new user (wallet_transactions)
```

---

### Reviews & Feedback

#### `public.reviews`
```sql
CREATE TABLE public.reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (product_id, customer_id, order_id)
);

CREATE INDEX reviews_product_idx ON public.reviews(product_id);

-- RLS: customer writes own; public read; seller reads own products' reviews
```

#### `public.app_feedback`
```sql
CREATE TABLE public.app_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  rating integer CHECK (rating BETWEEN 1 AND 5),
  comment text,
  platform text,
  app_version text,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

---

### Analytics & Errors

#### `public.app_events`
```sql
CREATE TABLE public.app_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,                 -- 'app_open', 'product_view', 'add_to_cart', 'search', 'checkout_started', 'order_placed', 'coupon_failed'
  props jsonb DEFAULT '{}',           -- Validated against Analytics.catalog
  platform text,                      -- 'android', 'ios', 'web', etc.
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX app_events_user_idx ON public.app_events(user_id, created_at);
CREATE INDEX app_events_name_idx ON public.app_events(name);

-- RLS: user writes own; admin reads all
```

#### `public.app_errors`
```sql
CREATE TABLE public.app_errors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source text NOT NULL,               -- 'flutter', 'async', 'deep_link_start', etc.
  message text NOT NULL,
  stack text,
  platform text,
  fingerprint text NOT NULL,          -- Normalized error signature
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX app_errors_user_idx ON public.app_errors(user_id, created_at);
CREATE INDEX app_errors_fingerprint_idx ON public.app_errors(fingerprint);

-- RLS: user writes own; admin reads all
```

---

### Product Requests & Returns

#### `public.product_requests`
```sql
CREATE TABLE public.product_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  details text,
  status text DEFAULT 'open' CHECK (status IN ('open', 'done')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

#### `public.return_requests`
```sql
CREATE TABLE public.return_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason text NOT NULL,
  description text,
  status text DEFAULT 'requested' CHECK (status IN ('requested', 'approved', 'rejected', 'picked_up', 'refunded')),
  admin_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

---

### Functions & RPCs

| Function | Purpose | Security |
|----------|---------|----------|
| `protect_profile_role()` | Block self-promotion to admin | Trigger on profiles |
| `protect_order_money()` | Block customer amount changes | Trigger on orders |
| `apply_referral(p_new_user_id, p_referral_code)` | Referral bonus (₹50 each) | SECURITY DEFINER, caller must be new user |
| `use_coupon(p_coupon_code, p_user_id, p_subtotal)` | Validate & record coupon use | SECURITY DEFINER, caller must be user |
| `place_order(p_address, p_address_id, p_coupon_code, p_wallet_amount, p_payment_method, p_payment_id, p_delivery_note)` | **Server-side order creation**: reads cart, prices, locks stock, creates orders, empties cart | SECURITY DEFINER, only way to create orders |
| `verify_razorpay_payment(p_order_id, p_payment_id, p_signature)` | Verify Razorpay signature, record in verified_payments | SECURITY DEFINER |
| `create_razorpay_order(p_receipt, p_coupon_code, p_wallet_amount, p_tip)` | Create Razorpay order for cart | SECURITY DEFINER |
| `phone_login(p_phone, p_password)` | Phone → email lookup + password grant | SECURITY DEFINER |
| `payout_balance()` | Available balance for seller/partner | SECURITY DEFINER |
| `claim_device_token(p_token, p_platform)` | Register FCM token for user | SECURITY DEFINER |
| `release_device_token(p_token)` | Release FCM token on sign-out | SECURITY DEFINER |
| `notify_push_on_insert()` | Trigger on notifications → send-push | Trigger |

---

## Realtime Publications

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE
  public.orders,
  public.notifications,
  public.delivery_tracking,
  public.banners;
```

---

## Storage Buckets

| Bucket | Purpose | Access |
|--------|---------|--------|
| `avatars` | User profile photos | Authenticated upload own; public read |
| `product_images` | Product gallery images | Seller upload own products; public read |
| `seller_documents` | KYC documents | Seller upload own; admin read |
| `delivery_documents` | Partner KYC | Partner upload own; admin read |

---

## Indexes Summary

```sql
-- Performance critical indexes
CREATE INDEX products_seller_idx ON products(seller_id);
CREATE INDEX products_category_idx ON products(category_id);
CREATE INDEX products_active_idx ON products(is_active) WHERE is_active;
CREATE INDEX orders_customer_idx ON orders(customer_id, created_at DESC);
CREATE INDEX orders_seller_idx ON orders(seller_id, created_at DESC);
CREATE INDEX orders_delivery_idx ON orders(delivery_id, status) WHERE delivery_id IS NOT NULL;
CREATE INDEX orders_status_idx ON orders(status) WHERE status IN ('ready_for_pickup', 'out_for_delivery');
CREATE INDEX cart_items_customer_idx ON cart_items(customer_id);
CREATE INDEX notifications_user_idx ON notifications(user_id, created_at DESC);
CREATE INDEX notifications_unread_idx ON notifications(user_id, read_at) WHERE read_at IS NULL;
CREATE INDEX delivery_tracking_order_idx ON delivery_tracking(order_id, recorded_at);
CREATE INDEX wallet_transactions_user_idx ON wallet_transactions(user_id, created_at DESC);
CREATE INDEX app_events_user_idx ON app_events(user_id, created_at);
CREATE INDEX app_errors_fingerprint_idx ON app_errors(fingerprint);
```

---

## Migration Order (supabase/ folder)

1. `security_fixes.sql` — Core security triggers
2. `realtime.sql` — Realtime publication
3. `product_variants_seller.sql` — Variant RLS fix
4. `rider_tip.sql` — Tip column on orders
5. `payout_requests.sql` — Seller payouts
6. `orders_rider_access.sql` — Delivery RLS for orders
7. `order_items_rider_access.sql` — Delivery RLS for order_items
8. `notifications_push.sql` — Notifications + push trigger
9. `support_messages.sql` — Support chat
10. `delivery_contact_rls.sql` — Delivery contact access
11. `account_exists.sql` — Account existence check
12. `delete_my_account.sql` — Account deletion RPC
13. `device_tokens.sql` — FCM token table
14. `app_feedback.sql` — App feedback
15. `app_events.sql` — Analytics events
16. `app_errors.sql` — Error reporting
17. `fix_search_path.sql` — Function search_path fixes

---

## Row Level Security Patterns

### Owner-Only Write
```sql
CREATE POLICY table_owner_write ON table
  FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());
```

### Role-Based Read
```sql
CREATE POLICY table_role_read ON table
  FOR SELECT TO authenticated
  USING (
    customer_id = auth.uid()
    OR seller_id = auth.uid()
    OR delivery_id = auth.uid()
    OR public.is_admin()
  );
```

### Admin Full Access
```sql
CREATE POLICY table_admin ON table
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());
```

### Public Read (Active Only)
```sql
CREATE POLICY table_public_read ON table
  FOR SELECT TO anon, authenticated
  USING (is_active = true);
```

---

## Data Retention & Cleanup

| Table | Retention | Cleanup Strategy |
|-------|-----------|------------------|
| `delivery_tracking` | 30 days | Scheduled job deletes old tracking points |
| `app_events` | 90 days | Partition by month, drop old partitions |
| `app_errors` | 180 days | Admin can purge |
| `notifications` | 1 year | User archive/delete; auto-archive after 30 days read |
| `support_messages` | Indefinite | Ticket-based, no auto-delete |
| `cart_items` | Session | Cleared on order placement or manual clear |

---

## Backup & Recovery

- Supabase automated daily backups (7-day retention on Pro, 30-day on Enterprise)
- Point-in-time recovery available
- Critical tables: `orders`, `wallet_transactions`, `payout_requests`, `verified_payments`
- Edge function secrets backed up separately (not in DB)