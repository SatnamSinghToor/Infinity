# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅        |

---

## Reporting a Vulnerability

**Do NOT create a public GitHub issue for security vulnerabilities.**

Instead, email: **security@duggustore.app** (or your security contact)

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will:
1. Acknowledge within 48 hours
2. Provide timeline for fix
3. Credit reporter (if desired) after resolution

---

## Security Architecture

### Authentication
- **Supabase Auth**: Email/password, Google OAuth, Phone (via edge function)
- **Session**: Implicit flow, persisted in SharedPreferences, recovered on launch
- **Deep Links**: Password reset via `com.duggustore.app://reset-password`
- **Guest Mode**: Browse without account; checkout requires login

### Authorization (Database)
- **Row Level Security (RLS)** on all tables
- **Role-based policies**: customer, seller, delivery, admin
- **Triggers**:
  - `protect_profile_role()`: Blocks non-admin from setting `role='admin'`
  - `protect_order_money()`: Blocks customers from changing order amounts
- **Server-side order creation**: `place_order()` is the ONLY way to create orders

### Data Protection
- **No secrets in client code**: Supabase anon key is public by design
- **Edge function secrets**: Razorpay, Firebase, AI keys only in Supabase Vault
- **Guest privacy**: Analytics & error reporting disabled for guests
- **Error fingerprinting**: Normalized signatures, not raw messages stored
- **FCM tokens**: Scoped to user, released on sign-out

### Payment Security
- **Razorpay**: Card/UPI details never touch our servers
- **Verification**: `verify_razorpay-payment` edge function validates signatures
- **Verified payments table**: Unique constraint on `payment_id` prevents reuse
- **Wallet**: Server-side balance checks, capped at available balance

### Network Security
- **HTTPS only**: All Supabase, Firebase, Razorpay, AI endpoints
- **Certificate pinning**: Not implemented (relying on platform trust store)
- **CORS**: Configured per Supabase project settings

### Android Release Hardening
- Build distributable releases with `scripts/build_android_release.ps1`; it enables Flutter Dart obfuscation and the Android R8 code/resource shrinker.
- Keep the generated files under `release-symbols/` private and backed up. They are required to decode crash traces and are not part of the app bundle.
- Obfuscation slows reverse engineering but does not hide strings, public client keys, or endpoints. Never put service-role, Razorpay secret, or other privileged credentials in the app.

---

## Threat Model

### Attack Vectors Considered

| Vector | Mitigation |
|--------|------------|
| SQL Injection | Parameterized queries via Supabase client; RPCs use `$1` params |
| XSS | Flutter renders safe strings; no `dangerouslySetInnerHTML` equivalent |
| CSRF | Not applicable (token-based auth, no cookies) |
| Auth Bypass | RLS + triggers enforce server-side |
| Price Tampering | `place_order()` reads cart, prices server-side |
| Stock Manipulation | `place_order()` locks stock in transaction |
| Payment Fraud | Razorpay signature verification server-side |
| AI Abuse | Rate limiting (8/10min), auth required, fallback on failure |
| Push Spam | Per-user tokens, loud channel only for orders/runs |
| Data Leakage | RLS ensures users only see their data |
| Privilege Escalation | `protect_profile_role()` trigger |

### Not Yet Mitigated
- **Certificate Pinning**: Consider for high-security environments
- **WAF**: Not configured (Supabase handles DDoS)
- **Audit Logging**: Admin actions not logged separately (RLS policies are the audit)
- **Penetration Testing**: Not yet conducted

---

## Secure Development Practices

### Code Review Checklist
- [ ] No hardcoded secrets
- [ ] RLS policies for new tables
- [ ] Input validation on edge functions
- [ ] Rate limiting on paid endpoints
- [ ] Error messages don't leak internals
- [ ] Guest data not persisted to analytics/errors

### Dependencies
- `flutter pub outdated` monthly
- Security advisories: `dart pub global activate dart_security_advisories`
- Pin versions in `pubspec.yaml` (no `^` for critical deps)

### Secrets Management
| Secret | Where | Rotation |
|--------|-------|----------|
| Supabase Service Role | Edge function secrets | 90 days |
| Razorpay Secret | Edge function secrets | 90 days |
| Firebase Service Account | Edge function secrets | 180 days |
| AI API Key | Edge function secrets | 90 days |
| Webhook Shared Secret | Edge function secrets | 180 days |
| Supabase Anon Key | Client code (public) | N/A |

---

## Incident Response

### Severity Levels
| Level | Examples | Response |
|-------|----------|----------|
| **Critical** | Active data breach, payment fraud, RCE | Immediate (< 1 hour) |
| **High** | Auth bypass, SQLi, stored XSS | < 4 hours |
| **Medium** | Info disclosure, DoS, logic bug | < 24 hours |
| **Low** | Minor info leak, config issue | < 7 days |

### Response Steps
1. **Contain**: Disable affected feature, revoke keys, block IPs
2. **Assess**: Determine scope, data affected, root cause
3. **Fix**: Deploy patch, rotate secrets, run migrations
4. **Verify**: Test fix, monitor for regression
5. **Notify**: Users (if data exposed), authorities (if required)
6. **Postmortem**: Document, improve defenses, update threat model

---

## Compliance

### Data Residency
- Supabase region: Choose during project creation (e.g., `ap-south-1` for India)
- All data stays in selected region

### PCI DSS
- **SAQ A**: Razorpay handles card data; we never touch PAN
- Razorpay is PCI DSS Level 1 certified

### GDPR / DPDP (India)
- **Right to Access**: User can view profile, orders, wallet
- **Right to Rectification**: Edit profile, addresses
- **Right to Erasure**: `delete_my_account.sql` RPC removes personal data
- **Data Portability**: JSON export via profile screen (planned)
- **Consent**: Explicit on signup, privacy policy linked

### Encryption
- **At Rest**: Supabase (PostgreSQL) uses AES-256
- **In Transit**: TLS 1.2+ everywhere
- **Secrets**: Supabase Vault (AES-256-GCM)

---

## Security Testing

### Automated
- `flutter analyze` — static analysis
- Dependency scanning — `dart pub global activate dart_security_advisories`
- Supabase — automated RLS testing via CLI

### Manual (Quarterly)
- Penetration testing (external)
- Dependency audit
- Secret rotation drill
- Incident response tabletop exercise

---

## Contact

Security Team: **security@duggustore.app**

PGP Key: (add if available)

---

## Hall of Fame

Thank you to security researchers who reported vulnerabilities responsibly:

*(None yet — be the first!)*