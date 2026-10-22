# Deployment Guide

Complete deployment instructions for Infinity across all platforms.

---

## Prerequisites

### Accounts Required
- [ ] **Supabase Project** (PostgreSQL + Auth + Edge Functions + Storage + Realtime)
- [ ] **Firebase Project** (FCM for push notifications)
- [ ] **Razorpay Account** (Online payments)
- [ ] **OpenAI-compatible API Provider** (AI descriptions: OpenAI, Groq, OpenRouter, DeepSeek, Together)
- [ ] **Google Cloud Console** (Google Sign-In OAuth credentials)
- [ ] **Apple Developer Account** (iOS deployment)
- [ ] **Google Play Console** (Android deployment)

### Development Machine
- Flutter SDK ^3.5.0
- Dart ^3.5.0
- Supabase CLI (`npm install -g supabase`)
- Firebase CLI (`npm install -g firebase-tools`)
- Android Studio / Xcode
- Git

---

## Supabase Setup

### 1. Create Project
```bash
# Via Supabase Dashboard or CLI
supabase login
supabase projects create duggu-store --org <your-org> --region <region>
```

### 2. Get Credentials
From Dashboard → Settings → API:
- **Project URL**: `https://<ref>.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- **Service Role Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (keep secret!)

### 3. Run Migrations
```bash
# Link local to remote
supabase link --project-ref <project-ref>

# Push all migrations in order
supabase db push

# Or run individually in order:
supabase migration up --include-all
```

**Migration Order** (from `supabase/` folder):
1. `security_fixes.sql`
2. `realtime.sql`
3. `product_variants_seller.sql`
4. `rider_tip.sql`
5. `payout_requests.sql`
6. `orders_rider_access.sql`
7. `order_items_rider_access.sql`
8. `notifications_push.sql`
9. `support_messages.sql`
10. `delivery_contact_rls.sql`
11. `account_exists.sql`
12. `delete_my_account.sql`
13. `device_tokens.sql`
14. `app_feedback.sql`
15. `app_events.sql`
16. `app_errors.sql`
17. `fix_search_path.sql`

### 4. Create Storage Buckets
```sql
-- Via SQL Editor or Dashboard
INSERT INTO storage.buckets (id, name, public) VALUES
  ('avatars', 'avatars', true),
  ('product_images', 'product_images', true),
  ('seller_documents', 'seller_documents', false),
  ('delivery_documents', 'delivery_documents', false);

-- Policies (example for avatars)
CREATE POLICY "Avatar upload" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Avatar read" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'avatars');
```

### 5. Deploy Edge Functions
```bash
# Deploy all
supabase functions deploy send-push
supabase functions deploy generate-product-description
supabase functions deploy create-razorpay-order
supabase functions deploy verify-razorpay-payment
supabase functions deploy phone-login
```

### 6. Set Function Secrets
Dashboard → Edge Functions → Secrets (or CLI):
```bash
# send-push
supabase secrets set WEBHOOK_SHARED_SECRET=<random-64-char-string>
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{...}'
supabase secrets set SUPABASE_URL=https://<ref>.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>

# generate-product-description
supabase secrets set AI_API_KEY=<your-openai-or-groq-key>
supabase secrets set AI_MODEL=gpt-4o-mini
supabase secrets set AI_BASE_URL=https://api.openai.com/v1
supabase secrets set AI_TEMPERATURE=0.7
supabase secrets set AI_REQUEST_TIMEOUT_MS=90000
supabase secrets set AI_BUDGET_MS=120000
supabase secrets set AI_MAX_PASSES=3
supabase secrets set AI_RATE_MAX=8

# create-razorpay-order / verify-razorpay-payment
supabase secrets set RAZORPAY_KEY_ID=<rzp_test_...>
supabase secrets set RAZORPAY_KEY_SECRET=<secret>

# phone-login
supabase secrets set SUPABASE_URL=https://<ref>.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

### 7. Configure Auth
Dashboard → Authentication → Settings:
- **Site URL**: `https://<your-domain>` (or `http://localhost:3000` for dev)
- **Redirect URLs**: Add `com.duggustore.app://reset-password`
- **Email Templates**: Customize confirm signup, reset password
- **Providers**: Enable Email, Google
- **Security**: Enable "Leaked password protection" (recommended)

### 8. Configure Realtime
Dashboard → Realtime → Publications:
- Ensure tables are added: `orders`, `notifications`, `delivery_tracking`, `banners`

---

## Firebase Setup

### 1. Create Project
Firebase Console → Add Project → `duggu-store`

### 2. Android App
- Package name: `com.duggustore.app`
- Download `google-services.json` → place in `android/app/`
- SHA-1 fingerprint: Add in Project Settings → Android app

### 3. iOS App
- Bundle ID: `com.duggustore.app`
- Download `GoogleService-Info.plist` → place in `ios/Runner/`
- Enable Push Notifications capability in Xcode

### 4. FCM Configuration
- Cloud Messaging → Server key (legacy) or Service Account (recommended)
- Generate Service Account key: Project Settings → Service Accounts → Generate New Private Key
- Save JSON → use for `FIREBASE_SERVICE_ACCOUNT_JSON` secret

### 5. Android Notification Sound
```bash
# Place custom sound in:
android/app/src/main/res/raw/order_alert.mp3
# (Referenced in push_service.dart _loudChannelId)
```

---

## Razorpay Setup

### 1. Create Account
- Sign up at https://dashboard.razorpay.com
- Complete KYC for live mode

### 2. Get Keys
Dashboard → Settings → API Keys:
- **Test**: `rzp_test_...` + secret
- **Live**: `rzp_live_...` + secret (after activation)

### 3. Webhooks (Optional)
- Not required: verification done via `verify-razorpay-payment` edge function
- If needed: `https://<ref>.supabase.co/functions/v1/verify-razorpay-payment`

### 4. Configure in Supabase Secrets
```bash
supabase secrets set RAZORPAY_KEY_ID=rzp_test_...
supabase secrets set RAZORPAY_KEY_SECRET=...
```

---

## Google Sign-In Setup

### 1. Google Cloud Console
- Create project or use Firebase project
- APIs & Services → Credentials → Create Credentials → OAuth Client ID
- **Android**: Package `com.duggustore.app`, SHA-1
- **iOS**: Bundle ID `com.duggustore.app`
- **Web**: Authorized redirect URIs (for Supabase OAuth)

### 2. Configure in Supabase
Dashboard → Authentication → Providers → Google:
- Enable Google
- Add Client ID / Secret from Google Cloud Console
- Authorized redirect: `https://<ref>.supabase.co/auth/v1/callback`

### 3. Update Flutter
`lib/services/google_auth_service.dart` uses `google_sign_in` package with auto-config from `google-services.json` / `GoogleService-Info.plist`.

---

## AI Provider Setup

### Option A: OpenAI
```bash
supabase secrets set AI_API_KEY=sk-...
supabase secrets set AI_MODEL=gpt-4o-mini
supabase secrets set AI_BASE_URL=https://api.openai.com/v1
```

### Option B: Groq (Fast, Free Tier)
```bash
supabase secrets set AI_API_KEY=gsk_...
supabase secrets set AI_MODEL=openai/gpt-oss-120b
supabase secrets set AI_BASE_URL=https://api.groq.com/openai/v1
```

### Option C: OpenRouter (Multiple Models)
```bash
supabase secrets set AI_API_KEY=sk-or-...
supabase secrets set AI_MODEL=anthropic/claude-3-haiku
supabase secrets set AI_BASE_URL=https://openrouter.ai/api/v1
```

### Option D: DeepSeek
```bash
supabase secrets set AI_API_KEY=sk-...
supabase secrets set AI_MODEL=deepseek-chat
supabase secrets set AI_BASE_URL=https://api.deepseek.com/v1
```

### Test AI Function
```bash
curl -X POST https://<ref>.supabase.co/functions/v1/generate-product-description \
  -H "Authorization: Bearer <user_jwt>" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Product", "category": "Grocery", "unit": "1 kg"}'
```

---

## Flutter App Configuration

### 1. Update Supabase Credentials
`lib/services/supabase_service.dart`:
```dart
static const String supabaseUrl = 'https://<your-ref>.supabase.co';
static const String supabaseAnonKey = '<your-anon-key>';
```

### 2. Update App Constants
`lib/utils/constants.dart`:
```dart
static const String appName = 'Infinity';
static const Color primaryColor = Color(0xFFFF5A00); // Your brand color
```

### 3. Deep Links
**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<activity android:name=".MainActivity" ...>
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.duggustore.app" android:host="reset-password" />
  </intent-filter>
</activity>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.duggustore.app</string>
    </array>
  </dict>
</array>
```

### 4. Build Configuration

**Android** (`android/app/build.gradle`):
```gradle
defaultConfig {
    applicationId "com.duggustore.app"
    minSdkVersion 23
    targetSdkVersion 34
    versionCode flutterVersionCode.toInteger()
    versionName flutterVersionName
    multiDexEnabled true
}

dependencies {
    // google-services plugin applied automatically when google-services.json exists
    implementation platform('com.google.firebase:firebase-bom:33.0.0')
}
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Infinity needs your location to find nearby stores and calculate delivery time.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Infinity needs your location to find nearby stores and calculate delivery time.</string>
<key>NSCameraUsageDescription</key>
<string>Infinity uses camera for product photos and visual search.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Infinity accesses photo library for product images and profile pictures.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Infinity uses microphone for voice search.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Infinity uses speech recognition for voice search.</string>
```

---

## Building & Releasing

### Android

#### Debug APK
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### Release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Signing (Release)
`android/key.properties`:
```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=upload
storeFile=<path-to-keystore.jks>
```

`android/app/build.gradle`:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### iOS

#### Build
```bash
flutter build ios --release
# Output: build/ios/iphoneos/Runner.app
```

#### Archive (App Store Connect)
```bash
# Open in Xcode
open ios/Runner.xcworkspace

# Product → Archive → Distribute App → App Store Connect
# Or command line:
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/ios/export -exportOptionsPlist ios/ExportOptions.plist
```

### Web

```bash
flutter build web --release
# Output: build/web/
# Deploy to Firebase Hosting, Netlify, Vercel, or any static host
firebase deploy --only hosting
```

**Web Config** (`web/index.html`):
```html
<script>
  // Supabase CORS: Add your domain to Supabase Dashboard → Auth → URL Configuration
  // Firebase: Add web app in Firebase Console, copy config to web/index.html
</script>
```

---

## Environment-Specific Configs

### Development
```bash
# .env.local (for supabase functions serve)
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<local-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<local-service-role-key>
FIREBASE_SERVICE_ACCOUNT_JSON={...}
WEBHOOK_SHARED_SECRET=dev-secret
AI_API_KEY=<dev-key>
RAZORPAY_KEY_ID=rzp_test_...
RAZORPAY_KEY_SECRET=...
```

### Staging
- Separate Supabase project
- Separate Firebase project
- Test Razorpay keys
- Test AI keys

### Production
- Production Supabase project
- Production Firebase project
- Live Razorpay keys
- Production AI keys
- All secrets in Supabase Vault / Dashboard (not in code)

---

## CI/CD Pipeline (GitHub Actions Example)

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    tags: ['v*']

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.5.0' }
      - run: flutter pub get
      - run: flutter gen-l10n
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with: { name: app-bundle, path: build/app/outputs/bundle/release/app-release.aab }

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.5.0' }
      - run: flutter pub get
      - run: flutter gen-l10n
      - run: flutter build ios --release --no-codesign
      - uses: actions/upload-artifact@v4
        with: { name: ios-app, path: build/ios/iphoneos/Runner.app }

  deploy-supabase:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
      - run: supabase db push
      - run: |
          for fn in send-push generate-product-description create-razorpay-order verify-razorpay-payment phone-login; do
            supabase functions deploy $fn
          done
      - name: Set secrets
        run: |
          supabase secrets set WEBHOOK_SHARED_SECRET=${{ secrets.WEBHOOK_SHARED_SECRET }}
          supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='${{ secrets.FIREBASE_SERVICE_ACCOUNT_JSON }}'
          supabase secrets set AI_API_KEY=${{ secrets.AI_API_KEY }}
          supabase secrets set RAZORPAY_KEY_ID=${{ secrets.RAZORPAY_KEY_ID }}
          supabase secrets set RAZORPAY_KEY_SECRET=${{ secrets.RAZORPAY_KEY_SECRET }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

  release-android:
    needs: [build-android, deploy-supabase]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with: { name: app-bundle, path: build/ }
      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
          packageName: com.duggustore.app
          releaseFiles: build/app-release.aab
          track: production
          status: completed

  release-ios:
    needs: [build-ios, deploy-supabase]
    runs-on: macos-latest
    steps:
      - uses: actions/download-artifact@v4
        with: { name: ios-app, path: build/ }
      - uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/Runner.app
          api-key: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
          api-issuer: ${{ secrets.APP_STORE_CONNECT_ISSUER }}
```

---

## Post-Deployment Verification

### Smoke Tests
```bash
# 1. Auth flow
flutter run --release  # Test on device
# - Sign up → email confirm → login
# - Google Sign-In
# - Phone login (if enabled)
# - Password reset deep link

# 2. Customer flow
# - Browse home, search, categories
# - Add to cart (with variants)
# - Checkout: address, COD, online, wallet
# - Order tracking

# 3. Seller flow
# - Login as seller
# - Add product with AI description
# - Manage orders
# - Request payout

# 4. Delivery flow
# - Login as delivery
# - Go online
# - Accept order, navigate, deliver

# 5. Admin flow
# - Login as admin
# - View stats
# - Edit categories
# - Open store editor
```

### Monitoring Checks
- [ ] Supabase Dashboard → Logs → Edge Functions (no errors)
- [ ] Supabase Dashboard → Database → Realtime (connections active)
- [ ] Firebase Console → Cloud Messaging → Delivery reports
- [ ] Razorpay Dashboard → Payments → Success rate
- [ ] App Store Connect / Play Console → Crash reports

---

## Rollback Procedures

### Supabase
```bash
# Revert migration
supabase migration down

# Or restore from backup (Dashboard → Backups)
```

### Edge Functions
```bash
# Redeploy previous version (git tag)
git checkout v1.0.0
supabase functions deploy <function-name>
```

### Mobile Apps
- **Android**: Play Console → Release → Halt rollout / Promote previous version
- **iOS**: App Store Connect → Remove from sale / Submit previous build
- **Web**: Re-deploy previous `build/web/` to hosting

---

## Security Checklist

- [ ] Supabase Service Role Key only in Edge Function secrets (never in app)
- [ ] Razorpay Secret only in Edge Function secrets
- [ ] AI API Key only in Edge Function secrets
- [ ] Firebase Service Account only in Edge Function secrets
- [ ] `google-services.json` / `GoogleService-Info.plist` not in git (gitignored)
- [ ] RLS enabled on all tables
- [ ] Security triggers active (`protect_profile_role`, `protect_order_money`)
- [ ] `place_order` is only way to create orders
- [ ] `verify_razorpay_payment` validates all online payments
- [ ] Rate limits on AI endpoint
- [ ] FCM tokens scoped to user, released on sign-out
- [ ] Deep link domain verified in Firebase/Apple/Google

---

## Cost Estimation (Monthly)

| Service | Free Tier | Paid Estimate (10k MAU) |
|---------|-----------|------------------------|
| Supabase | 500MB DB, 2GB bandwidth, 50k MAU | $25/mo (Pro) |
| Firebase FCM | Unlimited | Free |
| Razorpay | 2% per transaction | Volume-based |
| OpenAI API | $5 trial | ~$50-200/mo (depends on AI usage) |
| Groq | Free tier generous | Free / $0.27/M tokens |
| Google Maps | N/A (using OSM) | Free |

---

## Support & Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Push not working | Check `google-services.json`, FCM token in `device_tokens`, `send-push` logs |
| AI description fails | Check `AI_API_KEY`, provider status, function logs |
| Payment fails | Verify Razorpay keys, `create-razorpay-order` / `verify-razorpay-payment` logs |
| Realtime not updating | Check publication includes table, RLS allows read |
| Location permission denied | Check `NSLocationWhenInUseUsageDescription` / Android manifest |
| Build fails on iOS | Run `pod install` in `ios/`, check Xcode signing |
| `geolocator_android` compile error | `dependency_overrides` in `pubspec.yaml` pins to 4.6.1 |

### Debug Commands
```bash
# Supabase logs
supabase functions logs send-push --follow

# Flutter device logs
flutter logs --device-id <id>

# Database query
supabase db shell
# Then: SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;

# Test edge function locally
supabase functions serve generate-product-description --env-file .env.local
```

---

## Maintenance Windows

- **Supabase**: Automatic maintenance (usually weekends), check status page
- **Firebase**: Rare, announced via console
- **Razorpay**: Scheduled maintenance (usually 1-3 AM IST)
- **AI Providers**: Check provider status pages

Schedule app updates outside peak hours (10 PM - 6 AM IST).