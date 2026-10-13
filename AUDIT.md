# Duggu Store — Deep Audit

**Date:** 24 September 2026
**Branch:** `arena/01a0cdd1-duggustore`
**Status:** living document — ✅ items are done on this branch, the rest are open
**Scope:** poora app — customer + seller + delivery + admin, backend wiring, CI, release readiness

---

## Kaise nikala (evidence)

| Kya dekha | Kaise |
|---|---|
| 125 Dart files, **36,813 lines** in `lib/`, 2,480 lines in `test/`, **136 tests** | file counts |
| Har screen ka inbound reference (kaun kholta hai) | script: har screen class ko `lib/` + `test/` me search kiya |
| **33 Supabase tables**, 5 Edge Function calls, 1 RPC | `.from('...')`, `functions.invoke`, `.rpc` greps |
| CI config, 4 `supabase/*.sql`, secrets/ignore hygiene | direct read |
| Formatter/analyzer gate ka behaviour | CI runs is session me |

**Jo main verify nahi kar sakta (sandbox me supabase.co block hai — HTTP 000):** live DB ka actual state, Edge Function ke bodies, FCM console. Backend ke jitne claims neeche hain wo repo me jo likha/dikhta hai uske aadhar par hain, aur jahan unverifiable hai wahan likha hai.

---

## P0 — Release blockers (ye 5 ke bina Play Store par nahi ja sakta)

### 1. `applicationId` abhi bhi placeholder hai
`android/app/build.gradle:43` → `com.example.duggu`, aur line 42 par khud Flutter ka comment: *"TODO: Specify your own unique Application ID"*. Ek baar Play Store par is ID se upload kar diya, to phir badla nahi ja sakta. ✅ **Fix ho gaya** is branch me: `com.duggustore.app` — Android ke
`namespace` + `applicationId` (`android/app/build.gradle`), `MainActivity.kt`
ka package (folder `com/duggustore/app/` me move kiya) aur iOS ke saare 6
bundle identifiers. Ab isko badalna ek search-replace ka kaam hai, aur Play
par pehle upload se pehle hi karna hoga.

### 2. Release APK debug key se sign ho raha hai — ⚠️ aadha fix (warning + CI hook)
`android/app/build.gradle` — signing ab do shakhon me hai: `key.properties`
ho to release keystore, warna **log me saaf warning** ke saath debug key.
✅ Warning aur CI ka signing step dono is branch me hain; **baaki:** keystore
banana aur 4 GitHub secrets (`ANDROID_KEYSTORE_BASE64`,
`ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`) daalna
— ye aapke machine/secrets ka kaam hai. Pehle ye ek line thi:
`signingConfig = keystorePropertiesFile.exists() ? release : debug`. `android/key.properties` repo me nahi hai (bilkul sahi, `.gitignore` me hai, aur `key.properties.example` rakha hua hai) — lekin iska matlab abhi koi bhi "release" build **debug key** se sign hota hai, jo Play Store reject karta hai. Keystore banwa kar `key.properties` daalna padega (CI secret me).

### 3. Poora backend repo ke bahar rehta hai
Repo me sirf 4 helper SQL files hain: `account_exists.sql`, `app_feedback.sql`, `device_tokens.sql`, `security_fixes.sql`.
App **33 tables** use karta hai (`products`, `orders`, `cart_items`, `stores`, `sponsored_slots`, `delivery_tracking`, `coupons`, `coupon_usages`, …) aur **5 Edge Functions** call karta hai:

| Function | Kahan se | Kya karta hai |
|---|---|---|
| `phone-login` | `auth_provider.dart:296` | phone + password login |
| `admin-delete-user` | `admin_users_screen.dart:87` | admin account delete |
| `generate-product-description` | `product_description_service.dart` | AI product description — ✅ **source ab repo me hai** (`supabase/functions/generate-product-description/`) |
| `create-razorpay-order` | `payment_service.dart:102` | Razorpay order + variant pricing |
| `verify-razorpay-payment` | `payment_service.dart:45` | payment verify → `verified_payments` |

- ✅ **Deploy ka rasta bhi ab repo me hai** (25 September): **Actions →
  Deploy edge functions** workflow — `SUPABASE_ACCESS_TOKEN` + `AI_API_KEY`
  repo secrets ke saath ek click me function deploy + key set + live probe
  (detail `supabase/README.md` me). Saath me **Backend probe** workflow,
  jo bina login ke bata deta hai ki live function nayi hai ya purani —
  "button kaam nahi kar raha" ka jawab ek run me.

**In sab ka source git me nahi tha** (ek ab hai: `generate-product-description`,
25 September ko is list se nikaal ke repo me likha gaya) — pehle sirf comments me naam hain (`security_fixes.sql` me likha hai *"the current place_order is in the last migration"*, *"verify-razorpay-payment (v4)"*, *"create-razorpay-order (v6)"*). Nateeja:- naye laptop/CI se backend dobara banaya nahi ja sakta;
- backend ke changes ka koi review/PR nahi hota;
- agar Supabase project gaya, to paisa-waala logic (`place_order`) bhi gaya.

`supabase/functions/` + `supabase/migrations/` me sab kuch daalna padega. Ye **sabse bada single item** hai.

### 4. Push notifications aaj kuch bhej hi nahi sakti — ✅ server-side ho gaya, ek step baaki (aapka)
- ✅ **Sender deployed aur trigger se wired hai**: `send-push` (v15, `supabase/functions/send-push/index.ts`)
  live hai, `notifications` insert par `notifications_push_trigger` isse
  `x-webhook-secret` ke saath call karta hai (`supabase/notifications_push.sql`),
  aur Vault ka `push_webhook_secret` function ke `WEBHOOK_SHARED_SECRET` se match karta hai.
  25 September ko isme ek real bug bhi mila aur theek hua: message me
  `notification` block hi nahi tha, sirf `data` — Android/`push_service.dart`
  dono data-only message par koi heads-up nahi dikhate the, to jo bhi bhejta
  tha wo kahi pahunchta hi nahi tha. Ab dono (`notification` + `data`) jaate hain.
- ✅ **Stock wapas aane par alert bhi live hai**: `trg_product_restock` trigger
  `stock_alerts` walon ko ek `notifications` row deta hai, jo upar wale
  trigger se push ban jaati hai — koi doosra HTTP call nahi chahiye.
- **Sirf ek cheez baaki hai, aur wo git me ho hi nahi sakti**:
  `android/app/google-services.json` (aur iOS chahiye to
  `ios/Runner/GoogleService-Info.plist`) — Firebase console se aapko download
  karke deni hai. Isके bina `PushService` khud ko disable kar leta hai
  (`push_service.dart:14-18`; `main.dart:28`), aur Gradle bhi plugin apply
  nahi karta (`android/app/build.gradle:11`). Steps `supabase/README.md` me.

### 5. Apne hi security audit ke 3 items pending hain
`supabase/security_fixes.sql:184-190` — *"6. Still to do"*:
1. Supabase dashboard → Auth settings → **"Leaked password protection" chalu karo** (code se nahi hota).
2. `public.can_see_order` ko **fixed `search_path`** do.
3. Purana `place_order(uuid, uuid, text, double precision, double precision, numeric, numeric, jsonb)` overload **drop karo** (execute to chhina hua hai, par pada hua hai).

Baaki security kaam (role escalation block, order money protection, server-side pricing, coupon/referral guards) ho chuka hai — wo solid hai.

---

## P1 — Code likha hua hai par app me pahunch hi nahi sakte

Reference-count karke nikala: teen jagah aise hain jahan poora feature/code hai lekin **koi button usko kholta hi nahi**.

### 1. Live order tracking — ✅ FIXED (order detail par "Track Order" button)
- `lib/screens/order_tracking_screen.dart` — 300+ lines, `flutter_map` + OpenStreetMap, `DeliveryEtaProvider`, aur `delivery_tracking` table par **Realtime stream** (`order_tracking_screen.dart:266-282`).
- **Kahin se push nahi hoti** — `OrderTrackingScreen` poore `lib/` me sirf apne hi file me hai. `order_detail_screen.dart` me koi "Track order" button nahi (usme sirf Rate Partner / Report Problem / Cancel hai).
- Doosri taraf kaam **already complete hai**: delivery partner ka `LocationTrackingService` har active order ke liye `delivery_tracking` me lat/lng upsert karta hai (`location_tracking_service.dart:59-65`), aur delivery dashboard har load par `syncActiveOrders()` call karta hai (`delivery_dashboard_screen.dart:97`).
- Yaani: **customer ki taraf darwaza hi nahi hai**, baaki sab pipe laga hua hai. `README` aur `pubspec.yaml` dono is feature ko advertise karte hain.

**Fix chhota hai** (ek button): `order_detail_screen` me active order par "Track order" → `OrderTrackingScreen(orderId:)`.

### 2. Admin categories editor — ✅ FIXED (dashboard par "Categories" tile)
`lib/screens/admin/admin_categories_screen.dart` — poora CRUD: main + sub category add/edit/delete, "Show in the app" toggle, per-category product count. **0 references** — admin dashboard par iska koi button nahi (`admin_dashboard_screen.dart` kholta hai: users, moderation, banners, festivals). Matlab admin app se **categories manage hi nahi kar sakta**; sirf banners/festivals edit ho sakte hain.

### 3. `InfoScreen` — ❌ audit galat tha (chhoot gaya)
Pehla nateeja galat tha: orphan dhoondhne wala script usi file ke andar
ke reference nahi ginta tha, aur `AboutScreen`, `PoliciesScreen`,
`TermsScreen` teeno `return const InfoScreen(...)` se isi ko render karte
hain — yaani ye **live hai**, mara hua nahi. Isliye ise delete nahi kiya
gaya. (Wahi script `OrderTrackingScreen` aur `AdminCategoriesScreen` ke liye
bhi thi, par un dono ko alag se `grep` kar ke check kiya gaya tha: unke naam
poore `lib/` me sirf unhi ki file me the — wo dono sach me orphan the.)

---

## P1 — Customer side par wahi purani problem jo roles me theek ki thi

Pichhle kaam me humne seller/delivery/admin ke **25/25 screens** me "fail hui request khaali list jaisi na dikhe" laaya. Customer side ka hisaab:

| | Count |
|---|---|
| Role screens jinme honest failed state hai | **25 / 25** |
| Customer screens jinme hai | **1 / 28** (sirf `home_screen.dart` ka product grid — `home_screen.dart:1233-1258`, "Couldn't load products" + Retry) |

Bacha hua 27 me se, sabse zyada chubhne wale (ye sab **load fail hone par "khaali" dikhate hain**):

| Screen | Fail par kya dikhta hai | Proof |
|---|---|---|
| Cart | "Your cart is empty · Add items from the store to get started" | `cart_screen.dart:249-259`, provider `cart_provider.dart:100-102` sirf `debugPrint` |
| Wishlist | "Your wishlist is empty" | `wishlist_screen.dart:92`, provider me failed flag hi nahi |
| Orders | "No orders yet!" | `orders_screen.dart:35`, `order_provider.dart` me `loadFailed` nahi |
| Notifications | empty inbox | `notification_provider.dart` 5 silent catches |
| Wallet | "No transactions yet" | `wallet_screen.dart:80-90`, koi failed state nahi |
| Payment methods | 3 silent `catch` → "no saved cards" jaisa | `payment_methods_screen.dart` |
| Brands / Order support / KYC / Profile / Product detail | 1-3 silent catches each | greps + reads |

✅ **Aath screens par fix ho gaya:** cart, wishlist, orders, notifications,
wallet, payment methods, brands aur order help. Paanch providers (`cart`,
`wishlist`, `order`, `notification`, `wallet`) ab `loadFailed` rakhte hain, aur
teen screens (`payment_methods`, `brands`, `order_support`) apna `_loadFailed`;
sab `RoleError` + "Try again" dikhate hain, aur genuinely khaali list waise hi
khaali padhi jaati hai. `test/customer_states_test.dart` isko pin karta hai.

✅ **Baad me ye bhi ho gaya:** `kyc_documents_screen` (fail par poora
RoleError — warna "abhi upload nahi kiya" dikhta tha, jo aadmi ko dobara PAN
upload karne bhej deta hai) aur customer `product_detail_screen` (options aur
reviews ab inline batate hain + "Try again" — naya `RoleInlineError`, kyunki
poora page replace karna galat hota).
✅ **Referral row bhi ho gaya:** `profile_screen` ka referral-code row fail
par chup-chaap ghayab ho jaata tha — theek hi tha, par customer ko kabhi pata
hi nahi chalta ki code hai bhi. Ab "Couldn't load your friends code — tap to
retry" dikhta hai, aur tap par dobara koshish. `test/order_detail_test.dart`
isko pin karta hai.

✅ **Baaki silent catches bhi ho gaye — ab `lib/` me ek bhi khaali `catch`
nahi.** Jo likhne par chup the: payment method **set default / delete**,
delivery ka **run accept** (`.select('id')` se pata chalta hai ki doosre
partner ne pehle le liya — alag message), **delivered mark** (order write aur
earnings write ab alag: order gaya par fee na likhi to "tell the admin"), aur
**online switch** (`setOnlineStatus` ab `Future<bool>` — server na maane to
switch khud wapas palat-ta hai aur wajah dikhata hai). Sabke liye ek shared
one-line notice: `roleSay()` (`role_common.dart`). `_loadProfile` fail hone
par seller/admin chup-chaap customer shell me land ho jaate the — ab
`profileStale` flag hai, 2s/6s/15s par background retries (router notify par
khud re-route ho jaata hai), Profile screen par "Couldn't load your account
details" + Try again (`refreshProfile()`), aur sign-out flag saaf karta hai.
Cart ka background sync fail ho to `syncFailed` flag + cart screen par notice
+ **Resend** (`retrySync()` poora cart dobara bhejta hai — server apni copy
se hi price karta hai, isliye ye checkout se pehle pakdana zaroori tha).
Product requests ki list fail ho to inline retry. Aur jo catches genuinely
best-effort hain (sign-out server call, phone par saved address / onboarding
/ theme, home ke festivals-banners, stock-alert bell) unke paas ab likha hai
ki wo chup kyun reh sakte hain. `test/silent_catch_test.dart` (10 tests) poora
hisaab pin karta hai — including "kahin bhi `catch (…) {}` wapas nahi aaya".

### Order detail apna order khud bana leta tha — ✅ FIXED
`order_detail_screen.dart` apna order `orderProvider.orders.firstWhere(…,
orElse: () => Order(id: orderId, items: [], totalAmount: 0, …))` se dhoondhta
tha — yaani id na mile to **ek khaali order bana leta tha**. Uske neeche wala
"Order Not Found" branch mara hua tha: `order.id != orderId` kabhi sach nahi
hota, kyunki stub ka `id` wahi `orderId` hai. Asar: order na hone par customer
ko **₹0 ka khaali order** dikhta tha, aur asli "nahi mila" kabhi dikhta hi
nahi. Sabse zyada chubhta tha notification se — `notifications_screen.dart:74`
seedha `OrderDetailScreen(orderId:)` kholta hai, jab list load bhi nahi hui
hoti.
Ab: `OrderProvider.findOrder()` — pehle memory, phir `orders` se
`.maybeSingle()` — aur do "kuch nahi hai" ke case alag: **load fail**
(`RoleError` + Try again) aur **is account ka order nahi** (`RoleEmpty`).
Ek hi jagah `Order.fromSupabaseRow` + `Order.selectColumns`, matlab list aur
detail screen kabhi alag order nahi dikha sakte. `delivery_fee` aur
`wallet_used` bhi ab padhe jaate hain, isliye "Delivery Fee: FREE" hamesha
ke liye khatam, status card asli status ke hisaab se steps bharta hai, aur
cancel ab jhooth nahi bolta (`updateOrderStatus` → `Future<bool>`; backend
mana kare to purana status wapas).
`test/order_detail_test.dart` — 13 tests: row se order, missing columns,
product-less item, journey ke steps, aur screens/providers ke source pins.

---

## P2 — Product/backend gaps

0. **Backend ka inventory** `supabase/README.md` me hai: kaunsi DB functions
   aur Edge Functions sirf dashboard me rehti hain, aur unhe kaise export +
   deploy karna hai. Isi list me `place_order` aur Razorpay waale hain.
1. **Payout/settlement flow — ✅ FIXED (request → admin approve → paid).**
   Pehle: seller `business_details_screen.dart:207` "Payout Details" collect
   karta tha aur `seller_earnings_screen.dart:48` per-order `seller_payout`
   dikhata tha — par paisa nikalne ka koi UI nahi (delivery me bhi nahi).
   Ab: dono Earnings screens par **"Payouts & withdrawals"**, ek shared
   `PayoutsScreen` (available balance, request dialog, apni requests ka
   status), aur admin ke **Moderation → Payouts** me queue jahan approve /
   reject / **mark as paid** (bank reference ke saath) hota hai.
   Paisa **server** check karta hai: `payout_balance()` aur
   `request_payout()` `supabase/payout_requests.sql` me hain — earned minus
   already-asked-for se zyada koi maang nahi sakta, aur apni request khud
   approve karna RLS se band hai (update sirf admin par).
   **Baaki:** asli transfer manual/human kaam hai (RazorpayX waghairah se
   kar sakte hain) — app sirf "paid" record karta hai, khud paisa nahi
   bhejta, aur jhoothi "paid" nahi likhta.
2. **Coupon ka per-user guard client app use hi nahi karta.** `security_fixes.sql` me `use_coupon(...)` function hai jo `coupon_usages` me row daalta hai aur dobara use rokta hai — lekin app me (`use_coupon` grep) **kahin call nahi hota**; checkout seedha `from('coupons').select(...)` karta hai (`checkout_screen.dart:79-95`). Guard sirf tab lagta hai jab `place_order` server-side khud enforce kare — aur us function ka source repo me nahi hai (P0 #3), yaani **verify karna padega**. Agar enforce nahi hai, to ek hi coupon unlimited baar chalega.
   ✅ **Client side ka hissa ho gaya:** coupon/wallet ka hisaab ab ek hi
   tested jagah hai (`lib/utils/checkout_math.dart`), aur order place hone ke
   baad checkout apne "promise" ko server ke `placed_total` se milaata hai —
   coupon chup-chaap lagu na hua ho to confirmation screen par saaf likha
   aata hai ("this coupon could not be applied…"), bharose se pehle. Ye
   comparison sirf tab hoti hai jab wallet paisa involved na ho, kyunki
   wallet ka hisaab server order total me kaise likhta hai wo client ko
   dikhta nahi.
   **Baaki:** asli per-user enforcement `place_order` ke andar hai — us
   function ka source repo me nahi hai (P0 #3), isliye "verify karna
   padega" abhi bhi baaki hai. SQL attach hone par `ALREADY_USED` par saaf
   message dena chahiye, taaki ye notice sirf aakhri safety net rahe.
3. **Server-side job koi nahi** — poore repo me `pg_cron` / scheduled function nahi: stock alerts bhejna, purane cart/notification cleanup, sponsored slot expiry, order auto-timeout — inme se kuch nahi.
4. **Localization nahi hai — ⚙️ pipeline lag gaya, strings baaki.**
   Ab: `flutter_localizations` (pubspec + `generate: true`), `l10n.yaml`,
   `lib/l10n/app_en.arb`, aur `main.dart` me delegates + supportedLocales.
   Pehla widget (`bottom_nav.dart`) apne chaar labels arb se leta hai, aur
   `test/l10n_test.dart` pin karta hai ki jo key koi screen maangta hai wo
   arb me maujood ho aur har string ki description bhi ho. Naya language =
   ek nayi `app_<code>.arb`, aur bas.
   ✅ **Pehla customer screen bhi ho gaya:** `cart_screen.dart` ke saare 18
   user strings (heading, search hint, empty state, load-failed, clear-cart
   dialog, bill card, checkout button) ab arb se aate hain — English wahi
   hai, isliye screen par kuch badla nahi. `test/customer_states_test.dart`
   ka pin bhi update hua: ab wo screen se key maangta hai
   (`l10n.cartLoadFailed`) *aur* arb se asli jumla, yaani sentence gayab
   nahi ho sakta.
   ✅ **Wishlist aur Orders bhi migrate ho gaye:** `wishlist_screen.dart`
   (13 keys — heading, load-failed, clear dialog, empty state, item count,
   "add all to cart" + notice) aur `orders_screen.dart` (5 keys — heading,
   load-failed, empty state, order card ka "Total") ab arb se padhte hain.
   ✅ **Wallet aur Payment methods bhi:** wallet ke 5 keys (heading,
   balance label, history heading, load-failed, empty) aur payment methods
   ke 20 keys (heading, load-failed, add dialog ke saare labels/hints,
   empty, DEFAULT badge, set-default, aur dono write-failed notices —
   silent-catch round ke jumle bhi ab arb me hain). Arb me ab **67 keys**
   hain. `customer_states_test` ka `migrated` map in chaaron ko dual-pin
   karta hai (key screen me, jumla arb me).
   ✅ **Notifications bhi ho gaya** — 606-line screen ka sabse bada hissa
   (38 keys): app-bar heading, ⋮ menu (mark all read / archive all / clear
   all / clear archive), dono tabs (unread count ke saath), swipe hints
   aur swipe labels, per-notification ⋮ menu (mark read/unread, move to
   inbox, archive, delete), Undo, saare snackbar jumle, clear dialog
   (title + `{count,plural,...}` body + Cancel/Delete), dono empty states,
   aur \"5m ago / 3h ago / 2d ago\" waale time labels (plural placeholders).
   ✅ **Brands, Order Help aur Help & Support ke saare page bhi:**
   `brands_screen` (3 keys), `order_support_screen` (17 keys — dono
   headings, Report a Problem / Request Return buttons, dialog ke fields
   aur Cancel/Submit, dono snackbar, empty state) aur `help_screens.dart`
   (67 keys — About / Policies / Terms / FAQ ke saare paragraph, Contact
   aur Product Requests forms, Rate Us sheet, aur share ka message).
   Paise waale jumle ab placeholders hain (`{fee}`, `{threshold}`,
   `{amount}`), isliye `₹29`/`₹499` sirf ek jagah se aate hain. `shareApp()`
   ab l10n leta hai. Arb me ab **189 keys**. `customer_states_test` ka
   purana `screens` map khaali ho gaya, isliye hata diya — ab har customer
   screen `migrated` map se dual-pin hota hai (8 screens), aur
   `silent_catch_test` bhi apne jumle arb me dhoondta hai.
   ✅ **Profile screen bhi ho gaya** — 43 keys: heading, account card
   (Welcome / Login), saare section headings (Personal Data, App Settings,
   Help & Support, About & Community, Work with Duggu), har row ka label
   (My Orders, Addresses, My Wallet, Payment Methods, Wishlist, Change
   Theme, Contact Us, FAQ, Product Requests, Policies, Terms, Notification,
   About Us, Rate Us, Share App, Logout), dono role dialogs (Business
   name / Owner name / Full name / Vehicle type + Bike-Scooter-Bicycle-EV
   Scooter), aur referral row (Friends Code: {code}, copied notice,
   couldn't-load note). Arb me ab **232 keys**.
   ✅ **Order detail bhi ho gaya** — 48 keys: dono "kuch nahi" ke branch
   (load-failed + retry, aur "Order not found" ka matlab), Track Order,
   Order Information / Delivery Address / Order Items / Payment Summary
   ke headings aur unke rows, bill ke labels (Subtotal, Delivery Fee,
   FREE, Wallet Applied, Total), status card (`Order {status}` + Placed /
   Preparing / On Way / Delivered), `Qty: {count}`, review dialog
   (`Review {product}`), delivery rating dialog, aur cancel dialog
   (`Order {id} cancelled`). Arb me ab **280 keys**.
   ✅ **Product detail bhi ho gaya** — 49 keys: "ye product ab nahi hai",
   share ka message, `{amount} Saved` badge, options aur reviews ke inline
   failures, Store Details card (`{count,plural,...} Products`), Visit
   Store, Returnable / Cancellable, specifications ke labels, About this
   Item / Why Choose ke bullets (Brand: {brand}, Sold by {store}, You save
   {amount}…), Notify me / Go to Cart, Similar Products, aur admin ka
   hide-product bar + dialog. Arb me ab **329 keys**.
   ✅ **Checkout bhi ho gaya** — 44 keys: dono payment labels aur unke
   codes, coupon ke teen error (invalid / min order / network) aur
   "Coupon {code} applied", address form ke labels, Order Summary ke
   saare rows, wallet switch (₹{amount} available), PLACE ORDER, Saved
   Addresses + Manage + DEFAULT, aur confirmation screen (Order Placed
   Successfully, Order ID: {id}, Delivering to: {address}, Expected
   delivery: {eta}, Total: {amount}, Continue Shopping). Sabse zaroori:
   "server ne zyada charge kiya" ke dono notices (`Final total {total} —
   this coupon could not be applied…` aur `Final total {total}, not
   {promised}…`) — paise ka jumla ab bhi wahi hai, bas ek jagah likha hai.
   Arb me ab **373 keys**.
   ✅ **Home bhi ho gaya** (teen files) — `home_screen` (20 keys: free
   delivery ka promo card, header ke ETA jumle (Delivery in / Set your
   address / Nearest store: {store} / Outside delivery area), address ka
   hint, search ka hint, See All, `{count} products found`, dono fail/empty
   states + Retry), `home_all_sections` (Deals worth grabbing, Bestsellers,
   `+{count} more`, See all products) aur `home_brand_store_sections`
   (Shop by Brand / Local Brands + subtitles, `{count,plural,...} products`,
   Store fallback naam, Open/Closed, `{count,plural,...} items`).
   Promo slides ab ek function hain jo l10n leta hai, aur `_promoDot` bhi.
   Arb me ab **406 keys**.
   ✅ **Address, KYC, store aur search bhi ho gaye** — address form +
   list (95%): Home/Work/Other/Current location **codes** database me hi
   rehte hain, sirf dikhne waala naam badalta hai; delivery sheet ke saare
   cards/toasts; KYC ke document naam + status (PENDING/VERIFIED/REJECTED
   ab translate hote hain, DB code nahi badla); store page ke Open/Closed
   aur khaali shelf; search ke hint, photo ke teen fail messages, results
   ka plural count aur dono empty states.
   ✅ **Edit tools bhi ho gaye** — admin ke pencil sheet ke saare tools aur
   unke hints (91 keys: card badalna, banner, festival, sub-category,
   delete/hide/move ke confirmations aur unke "ho gaya" toasts), text
   dialogs ke Cancel/Save, link-target sheet, aur edit-mode switch
   ("Edit mode" / "Editing — tap to finish"). Ek hi jagah anokhi baat:
   banner ke button ka default `'Shop now'` database me hi rehta hai,
   kyunki wahi value save hoti hai jo sab customers dekhte hain.
   ✅ **Chip ke store page aur order tracking bhi** — har chip page ke
   apne headings (Shop by category, Top Deals / Top picks / Top buys,
   Beauty ka "Elevate Your Everyday Glow", Gifting ka "Perfect Gifts for
   Everyone"), hero ke words (screen ke naam data me hi rehte hain),
   "Featured" aur "Up to {percent}% OFF" ke tags; tracking screen ka
   poora timeline (Placed/Preparing/On Way/Delivered), Order Summary,
   Total, "Order {id}", "Expected delivery: {eta}" aur partner ka
   intezaar.
   ✅ **Voice/photo search sheet, listing ke chips aur cart pill** —
   voice sheet ke saare bubbles aur tips, sun-ne ke teen fail messages,
   shopping list ka heading aur Clear all, Camera/Gallery/Upload/Speak,
   "Listening…"; listing ka Sort sheet aur uske paanch options, Offers /
   In stock chips, "Delivering to: {address}" aur khaali-shelf ke teen
   jumle; niche wala "View cart" pill.
   ✅ **Festival page aur Bhog section bhi** — hero ka kicker/title
   fallback, Ganesh ke do darshan cards, sub-category ke product counts,
   "Festive picks"/"{chip} picks", khaali page ke teen jumle; Bhog ke
   chaar tile heading aur uska banner. Search ke terms (rice flour,
   jaggery…) aur "Festival" category ka naam database ke saath juda hai,
   isliye wo waise hi rehte hain.
   ✅ **Login, Sign Up, Skip aur Forgot Password bhi** — heading, hint,
   dono "no account" lines, chhota print (Terms/Privacy links ke saath),
   Continue/Sign Up, register ke saare fields aur button ke niche ka note,
   reset page ke saare jumle. `login_layout_test` ke host me ab app ke
   waale localization delegates bhi lagte hain, warna page ko strings hi
   nahi milti.
   ✅ **Seller ka dashboard aur products page bhi** — greeting aur uske
   niche ki line, chaar stat cards (reviews ka count plural ke saath, net
   earnings), low-stock warning, quick actions (Add Product/Orders/Store),
   My Products strip aur View All, Recent Orders, dono empty states, nav
   ke chaar labels; products page ka title, loading/error, search hint,
   chaar filter chips, chhota "Hidden" badge, stock ka jumla (out of stock
   / low / in stock), Edit/Boost/Hide/Unhide/Delete menu, delete aur boost
   dialogs (boost ka fee wala dropdown bhi), aur saare snackbars.
   ✅ **Delivery ka poora role bhi ho gaya** — chaaron screens: dashboard
   (online/offline line, switch fail hone par wajah, teen stat cards —
   review count plural ke saath, My Deliveries / Available Orders ke
   headings aur empty notes, Delivered/Accept/View All), runs page (dono
   tabs apne count ke saath, dono empty states, claim-race / accept /
   mark-delivered / fee-not-recorded ke saare notices), earnings (total,
   payouts button, empty, note na ho to "Delivery fee" fallback) aur More
   (teen tiles + Log Out). DB waali values (order status, earnings ka
   `note`) waise hi rehti hain jaise address ke codes rehte hain.
   `role_screens_test` ab chaaron screens dual-pin karta hai — screen key
   maangta hai, arb jumla rakhta hai, aur wapas hardcoded hona bhi pakadta
   hai; `silent_catch_test` ke delivery pins bhi ab jumle arb me dhoondte
   hain.
   ✅ **Admin ke saare 10 screens bhi ho gaye** — users (delete dialog + har
   backend-refusal ka apna message), moderation hub (chaar tiles + pending
   counts), order issues aur return requests (resolve/approve dialogs,
   refund field, Reject/Approve, Order: {id}), sponsored slots (product,
   days · fee, reject reason), dashboard (chaar stat cards, store-editor
   card, Categories tile, Recent Orders), payouts (Waiting on you ({count}),
   Decided, Send to {method}, Partner says, mark-paid dialog reference ke
   saath), banners (upload sheet, link label, move up/down, delete),
   categories (new/edit sub-main headings, Show in the app, plural counts,
   " · hidden" suffix, products-in-category warning) aur festivals (editor
   ke saare fields, chhonewali six preset ke naam, From/To, LIVE badge,
   " · pooja"/" · off" suffix, aaj ka festival waala note). Saath me ek
   bug bhi gaya: categories ka `_load` fail hone par sirf toast deta tha —
   `_loadFailed` flag set hi nahi hota tha, yaani screen khaali dikhti
   thi; ab RoleError dikhta hai. DB me likhi values ('Not approved',
   'Approved. The transfer will follow.', rejection reasons) aur
   `_fmt` ke English month-naam (aaj ke din India me standard) code me hi
   rehte hain. `role_screens_test` ka dual-pin ab admin ko bhi ginta hai.
   ✅ **Seller ke baaki das screens bhi ho gaye** — poora role ab arb se
   padhta hai. Reviews (empty state, product fallback), boost requests
   (status, Product: {name}, days · fee, Reason: {reason}), earnings (Net
   Payout, Total Sales / Commission Paid stat cards, Delivered Orders
   ({count}), per-order subtitle, payouts button), More (do section labels
   + saat tiles), business details (status badge, saare field labels,
   Compliance / Payout Details headings, teen snackbar), product detail
   (Hidden badge, stock, Description / Highlights, reviews ka fail-retry),
   orders (pipeline ke teen buttons — Confirm Order / Start Preparing /
   Mark Ready for Pickup, cancel dialog, Active/All chips, Order: {id}),
   store profile (Approved / Pending Approval chips, saare fields, Store
   Open, pin card — set/not set + madad, address-swap dialog, Add {what}),
   location picker (GPS/permission ke paanch toast, bottom card ke teen
   headline, aur ab store profile picker ko apna wording bhi deta hai —
   constructor defaults sirf fallback hain) aur add product (photo strip
   ke saare jumle, MAIN badge, remove-background switch, brand chips —
   My store: {name} / Company brand, AI generate, Update/Save). DB codes
   (order status ka `_statusLabel` transform, `Application status:` ke
   aage ka DB value) aur `'1 pc'` jaise defaults code me hi rehte hain.
   `role_screens_test` ab seller ki **saare 12** screens dual-pin karta
   hai (dashboard aur products pehle se the), aur `payouts_test` dono
   earning screens ka pin ab key ya sentence — dono taraf se — accept
   karta hai.
   **Baaki:** bache hue customer widgets (categories screen, deals,
   splash, onboarding…). Arb me ab **1163 keys**.
5. **Production me app "blind" hai — ✅ dono taraf se fix (first-party).**
   Ab `lib/services/error_reporter.dart` uncaught errors ko pakadta hai
   (`FlutterError.onError`, `platformDispatcher.onError`) aur
   `supabase/app_errors.sql` waali table me file karta hai — message, stack,
   platform, fingerprint (ids/numbers hata ke, taaki ek bug ek row bane).
   Guest ka error sirf device log me jaata hai, kyunki table account-wise hai
   aur admin use follow-up ke liye padhta hai. Red screen ki jagah ab ek
   padhne layak card aata hai. Throttle: ek message paanch minute me ek baar,
   poore session me max 10 — aur reporter khud kabhi crash nahi karta.
   ✅ **Analytics bhi ho gaya, aur wahi pehla-faisla:** `lib/services/analytics.dart`
   ek chhota, naam-wala set bhejta hai — `app_open`, `product_view`,
   `add_to_cart`, `search`, `checkout_started`, `order_placed`,
   `coupon_failed` — aur har event sirf wahi fields le jaata hai jo uske
   catalog me likhe hain; baaki drop. `supabase/app_events.sql` bhi
   account-wise hai: guest ka kuch record nahi hota aur padhne ka haq sirf
   admin ko hai. Har event apni ek row hai, background me jaati hai — tap
   kabhi wait nahi karta, koi timer screen ke baad zinda nahi rehta, aur
   fail hone par event chup-chaap chhoot jaata hai (session me max 200). Search ka term (60 akshar tak, bas wahi ek text)
   isliye rakha jaata hai ki "kya dhoonda aur nahi mila" hi asli stocking
   list hai. `test/analytics_test.dart` sab pin karta hai.
6. **Dark mode aadha bana hua hai — ✅ ab ye jaan-boojh kar light-only hai, aur enforced hai.**
   `tokens.dart` me poora `AppTokens.dark` palette hai, par `main.dart`
   `ThemeMode.light` hold karta hai kyunki **123 me se 79 files** abhi bhi
   apne rang `AppConstants` se lete hain — system ke saath dark pe jaana aadhi
   screen dark aur aadhi pale kar deta. Ab ye faisla test se bandha hua hai
   (`test/theme_mode_test.dart`): (a) jab tak dono palettes use ho rahe hain,
   light palette aur `AppConstants` ke rang barabar rehne chahiye — warna
   token-driven widget ka rang apne padosi se alag dikhne lagta hai; (b) apne
   rang naam karne waali files ki ginti **79 se badh nahi sakti**, aur wahi
   number migration ka kaam bhi batata hai; (c) `ThemeMode.light` hataana sirf
   tab allowed hai jab wo ginti 0 ho — guard khud bata dega kaunsi file bachi
   hai.
   **Dark ship karne ke liye:** un files ko `context.tokens` par le jao, phir
   `themeMode` badlo. (Aaj `context.tokens` sirf 4 widgets use karte hain:
   dono nav bars, notification bell, aur `main.dart` ka theme.)
7. **iOS CI me build hota hi nahi — ✅ job jod diya.** Ab `build-ios` job
   (macos-latest, `flutter build ios --debug --no-codesign`) `main`/`master`
   par chalta hai, ya kisi bhi branch par jab commit message me `[ios]` ho —
   macOS minutes mehange hain, isliye default off aur `[ios]` par on.
   Fail hone par log se lines check-run annotations me aati hain.
8. **Fonts runtime par download hote the — ✅ ab app ke andar hain.**
   `assets/fonts/` me Poppins ke chhe faces (Regular, Italic, Medium,
   SemiBold, Bold, ExtraBold — bas wahi jo code maangta hai) aur Playfair
   Display ke do (Bold, BoldItalic) hain, usi naam se jis naam se
   `google_fonts` dhoondhta hai — isliye 39 files ke `GoogleFonts.poppins(...)`
   calls jaise the waise hain, package file disk par paata hai aur network
   par jaata hi nahi. `lib/utils/app_fonts.dart` `allowRuntimeFetching`
   band karta hai (missing face ab development me system font dikhata hai,
   production me download nahi), dono OFL licences register karta hai, aur
   pehle frame ke chaar faces load hone tak (max 3 s, fail par bhi launch)
   rukta hai — splash ab seedha Poppins me aata hai, offline bhi.
   `test/fonts_test.dart` code ke har `GoogleFonts.*(fontWeight: …)` ko
   padh kar uski file maangta hai, taaki naya weight bina file ke CI me hi
   pakda jaaye. ~1.4 MB assets. (Chip-store ka ek Playfair italic w600 →
   w700 hua, kyunki static SemiBoldItalic kahin available nahi.)
9. **ML Kit features first-use par model download karte hain — ✅ dono taraf sambhal gaya.**
   Seller side pehle se theek thi: `background_removal_service.dart` model
   aa jaane tak chaar baar retry karta hai, aur fail hone par screen saaf
   kehti hai ("Couldn't remove the background — saving the original photo").
   Customer ki photo search galat baat keh rahi thi: dono engines fail hone
   par bhi "Try a clearer picture" — jabki sach ye tha ki phone ne photo
   padha hi nahi (pehli baar, bina internet, model download hi nahi hua).
   Ab `VisualSearchService.termsFor` ek `PhotoSearch` deta hai — terms ke
   saath `unavailable` — aur screen us case me kehti hai ki scanner ko ek
   baar download karna hai, internet check karke dobara try karo. Failures
   `ErrorReporter` me bhi jaate hain (`visual_search.text` /
   `.labels`), taaki asli wajah app_errors me padhi ja sake.
   `test/visual_search_test.dart` pin karta hai ki "kuch nahi mila" aur
   "padha hi nahi ja saka" alag rehne chahiye.
10. **Perf/format leftovers:** ✅ **ho gaya.** `home_all_sections.dart` ke teeno grids ab `SliverGrid` hain aur page unhe seedha apne `CustomScrollView` me faila deta hai (`...HomeAllSections.slivers(context)`) — pehle poora "All" tab ek hi box tha, isliye pehle frame par hi har shelf aur uske har card ka layout ho jaata tha (6 bestseller + har group ke 8 tiles + 5 shelves × 6 cards). Sizing bilkul wahi hai — `_cellSize` dono shapes ke liye ek hi hisaab lagata hai — aur `ProductShelf` ka box version bacha hua hai kyunki chip-store aur festival pages usi ko use karte hain. `test/home_sections_test.dart` ise pin karta hai. Poore `lib/` me **0** `Image.network` (ye saaf hai ✓).
11. **Seller ka AI product description kaam nahi karta tha — ✅ theek kiya,
    aur ab 700–1500 words ka rule server bhi maanta hai aur app bhi.**
    Pehle: `add_product_screen.dart` `functions.invoke('generate-product-description')`
    karta tha, aur us function ka **repo me koi source hi nahi tha** (wo sirf
    Supabase dashboard me tha — upar §3). Client ne reply ko `data as Map`
    cast kiya, aur chahe function missing ho, provider key missing ho, reply
    json na ho ya `description` field hi na ho — sab ek hi `catch` me girke
    "Could not generate description" bolte the. Worse: 200 reply me
    `description` na ho to seller ne jo type kiya tha wo **empty string se
    mit jaata tha**.
    Ab: (a) function `supabase/functions/generate-product-description/index.ts`
    me hai — deployed **jwt verification ke saath** (koi random visitor paid AI
    calls na bhare), rate-limit ke saath (8 / 10 min / user), aur `AI_API_KEY`
    na ho ya provider 500 de de to bhi jawab aata hai: server seller ke apne
    notes se page khud compose kar deta hai aur saaf bolta hai ki ye AI ne
    nahi likha (`model: "duggu-composed"`, `fallback: true`).
    (b) **Length ab rule hai, wish nahi:** 700 se kam par writer ko
    "yahan se aage likho" dobara bolta hai (`AI_MAX_PASSES` tak), 1500 se zyada
    ho to aakhri poori sentence par kaat deta hai — aur `AI_BUDGET_MS` (default
    120s) khatam ho jaaye to jo likha hai wo `in_range: false` ke saath wapas
    aata hai, fail hone ke bajaye. (c) App side pe naya
    `lib/services/product_description_service.dart` har reply ko decode karta
    hai (Map ho ya json String), har failure ko ek **naam** deta hai
    (`notDeployed` / `rateLimited` / `timedOut` / `offline` / …) aur har naam ka
    apni ek line hai `app_en.arb` me — 15 nayi strings. (d) Description box ke
    neeche live word count hai (`{count} words · target 700–1500`), box 4 line
    se 10 line hua (warna 900-word page dikh hi nahi karta tha), aur page chhota
    rahe to button "Add more with AI" ho jaata hai — agli tap box ke text ko
    aage badhati hai, dobara se likhti nahi. (e) Failure par box ka text abhi bhi
    waisa hi rehta hai (pehle clear ho jaata tha).
    (f) **Har failure ab apna naam bolta hai.** Pehle seller ke session ka 401,
    server ki apni 8/10-min limit, provider ka 429, galat `AI_API_KEY` ka 401 aur
    galat `AI_BASE_URL` — paanchon ek hi line par aate the: "the AI writer is
    busy right now, try again in a minute" (yaani aisa jaise kuch fake error ho,
    kyunki minute bhar baad bhi wahi jawab aata tha). Ab server provider ke jawab
    ko ek word me sort karta hai aur wo `fallback_reason` banke reply ke saath app
    tak aata hai — `no_key`, `bad_key`, `bad_address`, `bad_request`, `timeout`,
    `provider_limit`, `upstream`, `not_json`, `crashed`. Seller ko page milta rehta
    hai, par line ye batati hai ki agli tap kaam karegi ya server theek karna
    padega; aur in do aakhri wale cases me Retry button dikhta hi nahi (ek aisa
    button jo wahi wall dobara todna de, wo jhooth hai). Rate-limit ka jawab ab
    minutes ginta hai, aur `AI_RATE_MAX` se testing ke waqt upar kiya ja sakta
    hai. Jo codes app samajhti hai wo test me dono taraf se pin hain, taaki ek
    adha update kabhi "unknown error" me na badle.
    `test/product_description_ai_test.dart` ye sab pin karta hai:
    app aur function ke 700/1500 barabar hon, count ek jaisa ho, aur har
    failure ka ek message ho. **Baaki (aapke dashboard ka kaam):** function
    deploy karna + `AI_API_KEY` (aur chaho to `AI_MODEL`/`AI_BASE_URL`) set
    karna — steps `supabase/README.md` me hain. Sandbox se `supabase.co` block
    hai, isliye live endpoint par test nahi kar saka; logic ek offline
    harness se verify kiya gaya tha (function ka pure aadha `Deno`/net se
    azaad hai, isliye test ho jaata hai).

---

## P2 — Tests aur CI

- **156 tests / 2,896 lines** vs 37,637 lines of app. Jo covered hai: models, tokens, nav tokens, product card, login layout, role screens, ek "one line" rule, customer ke failed states, payouts ke paise waale rules, crash reporter, aur ab order detail (row → order, do "kuch nahi" ke case, cancel/announce) aur checkout ka coupon/wallet ka hisaab (`checkout_math_test.dart`), aur home ka "All" tab slivers me hi bana rahe (`home_sections_test.dart`), aur analytics sirf catalog wale events bheje (`analytics_test.dart`), aur har maanga hua font face bundle me ho (`fonts_test.dart`), aur koi bhi `catch` khaali na rahe — likhne ki failures loud, profile stale-flag + retry, cart sync-failed + resend (`silent_catch_test.dart`), aur teeno roles — seller ki 12, delivery ki 4, admin ki 10 — screens arb se padhti hain aur wapas hardcoded nahi ho sakti (`role_screens_test.dart`). aur seller ke AI writer ka 700–1500 rule, dono taraf se, plus har failure ka apna naam (`product_description_ai_test.dart`).- Jo **bilkul covered nahi**: checkout + payment + order placement (paisa!), cart/wishlist/order providers, address book, tracking, aur role screens ke data paths (sirf source-scanning rules hain, behaviour tests nahi).
- CI: `flutter analyze --no-fatal-infos` (infos chhupti hain — aaj kitni hain wo pata nahi), koi integration/widget test suite nahi, iOS build **sirf `[ios]`/main par** (macOS minutes mehange hain), aur release build PR par nahi.
- **Artifact quota ne master laal kar diya tha** — PR green, master red, aur fail sirf upload step par: `Failed to CreateArtifact: Artifact storage quota has been hit`. Har `arena/*`/`claude/*`/`kilo/*` push apna ~80 MB debug APK 7 din ke liye rakh leta tha, free plan ka cap 500 MB hai, aur ek session ke 6 pushes wo bhar dete hain. Ab debug APK sirf `master`/`main` push par jaata hai aur 1 din rehta hai; release APK/AAB 30 → 7 din. Jo purge hoke quota khali karega wo GitHub ko 6-12 ghante lagte hain, warna Settings → Actions → Artifacts se khud delete kar do — workflow badalne se existing artifacts chhote nahi hote.
- Achhi baat: format gate + TODO gate chalte hain, aur is session me format diff nikalne ka rasta bhi ban gaya (Format report job) — aage formatter ke chakkar me time nahi jaayega. Master ke CI failures abhi ke liye is quota ki wajah se hain, code ki wajah se nahi: PR #5 ka apna run (Code Quality + Build and Test) green merge hua.

---

## Jo already solid hai (inhe dobara mat chhedna)

- **Server-side pricing** — client apna price nahi bhej sakta; `place_order` cart padhta hai, per-seller order banata hai, stock lock karta hai, coupon/wallet cap khud lagata hai; online payment sirf `verified_payments` se count hota hai. Rolled-back transaction me 11 cases test kiye hue hain (documented).
- **Security fixes** — profile role escalation block, `protect_order_money` trigger, orders par INSERT band, old place_order ka execute revoked, referral/coupon/decrement_stock lockdown.
- **Secrets hygiene** — keystore + `key.properties` git me nahi, client me sirf anon (publishable) key, koi `service_role` key nahi.
- Roles kit + 25 screens ke states, adaptive launcher icon + splash, login ka layout test, ek hi `ProductCard`, perf-A hero flight.

---

## Mera suggested order (chhota se bada, value/effort ke hisaab se)

| # | Kaam | Kyun pehle | Size |
|---|---|---|---|
| 1 | `order_detail` me **"Track order" button** | poora feature (map + realtime + partner broadcast) zinda ho jaayega, 5 minute ka kaam | ~15 min |
| 2 | **Customer states** — cart/wishlist/orders/notifications/wallet ko `role_common` se wrap | wahi bug jo roles me theek kiya, ab customers me | 2-3 ghante |
| 3 | `admin_categories` ka **entry point** dashboard me | ✅ ho gaya (`InfoScreen` ko chhoda, wo live hai) | ~30 min |
| 4 | **`supabase/functions/` + `migrations/` repo me** (place_order, razorpay, phone-login, delete-user) | bina iske release/backup impossible; coupon guard bhi tab verify hoga. AI description aa gaya ✅ | 2-4 ghante (dashboard se copy) || 5 | **Release identity**: `applicationId` + keystore + Play signing | iske bina store par nahi ja sakte | 1-2 ghante |
| 6 | Push: `google-services.json` + **ek sender Edge Function** + stock-alert job | 3-4 ghante |
| 7 | Payout request flow (seller/delivery) | 4-6 ghante |
| 8 | Localization scaffolding + Crashlytics | poora din |

---

### Bottom line

App **feature-wise kaafi aage hai** — payments, wallet, coupons, returns/issues, boosts, KYC, roles, realtime tracking sab likha hua hai; backend ka security aur pricing logic professional level ka hai. Baaki kaam do tarah ka hai:

- **Jo ban chuka hai par uljha hua hai:** live tracking ka button, admin categories ka darwaza, push ka bhejne wala.
- **Jo systemically baaki hai:** backend source-of-truth repo me, release identity (appId + signing), customer-side failure states, payouts, localization, aur tests (khaaskar paise ke raste par).

P0 ke 5 items store-launch ke liye hard blockers hain; P1 ke teen "orphan" items sabse sasta, sabse bada UX win denge.
