# Contributing Guide

Thank you for contributing to Infinity!

---

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- No harassment, discrimination, or spam

---

## Development Setup

### Prerequisites
- Flutter SDK ^3.5.0
- Dart ^3.5.0
- Supabase CLI
- Firebase CLI
- Android Studio / Xcode
- Git

### Clone & Install
```bash
git clone <repository-url>
cd DUGGUSTORE-master
flutter pub get
flutter gen-l10n
```

### Run Locally
```bash
# Requires local Supabase (supabase start) or dev project credentials
flutter run

# For specific device
flutter run -d <device-id>
```

---

## Code Style

### Formatting
```bash
dart format .
flutter analyze
```

### Linting
- Follows `flutter_lints` v6.0.0 (in `analysis_options.yaml`)
- Zero warnings required for PR merge

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `ProductProvider` |
| Functions/Variables | camelCase | `loadCart`, `itemCount` |
| Constants | lowerCamelCase | `primaryColor` |
| Private | `_prefix` | `_items`, `_loadFromSupabase()` |
| Files | snake_case | `product_provider.dart` |

---

## Architecture Principles

1. **Single Source of Truth**: Providers own state; screens only read
2. **Server-Authoritative**: Money, stock, order status decided on server
3. **Graceful Degradation**: Offline-first where possible; failed loads show retry
4. **Explicit Over Implicit**: Named events, typed models, catalog-validated analytics
5. **Design Tokens**: Use `context.tokens` for colors, `AppSpacing`/`AppRadius` for layout

---

## Git Workflow

### Branch Naming
```
feature/<short-description>    # New feature
fix/<short-description>        # Bug fix
refactor/<short-description>   # Code improvement
docs/<short-description>       # Documentation
chore/<short-description>      # Maintenance
```

### Commit Messages
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `perf`, `security`

Example:
```
feat(cart): add guest cart merge on login

When a guest adds items then signs in, their local cart now merges
with the server cart instead of being replaced.

Closes #123
```

### Pull Requests
1. Create from `feature/*` or `fix/*` branch
2. Target `main` branch
3. Fill PR template
4. Pass CI: `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed .`
5. Code review by maintainer
6. Squash merge

---

## Adding Features

### New Screen (Customer)
1. Add to `lib/screens/` or `lib/screens/auth/`
2. Register in `MainShell._builders` + `MainShell.tab` constant
3. Add `BottomNavWidget` item
4. Pad bottom for cart pill (96px + safe area)
5. Add localization keys to `lib/l10n/app_en.arb`
6. Run `flutter gen-l10n`
7. Write widget test in `test/`

### New Screen (Seller/Delivery/Admin)
1. Add to `lib/screens/<role>/`
2. Add to role's `RoleBottomNav` items
3. Push via `Navigator.push` from dashboard

### New Provider
1. Create in `lib/providers/`
2. Register in `main.dart` `MultiProvider`
3. Use `ChangeNotifier` or `ChangeNotifierProxyProvider` for derived state

### New Model
1. Create in `lib/models/`
2. Add `fromSupabaseRow` factory
3. Add `toRow` / `toJson` for writes
4. Add tests

### New Edge Function
1. Create `supabase/functions/<name>/index.ts`
2. Add secrets documentation
3. Deploy: `supabase functions deploy <name>`
4. Call from service: `SupabaseService.client.functions.invoke('<name>', body: {...})`

### New Database Migration
1. Create `supabase/<name>.sql`
2. Follow RLS patterns (see DATABASE.md)
3. Test locally: `supabase db push`
4. Document in DATABASE.md

---

## Testing

### Unit Tests
```bash
flutter test test/<name>_test.dart
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Required Coverage
- New providers: 80%+
- New services: 80%+
- Pure functions: 100%
- UI widgets: snapshot tests

---

## Localization

### Adding Strings
1. Add to `lib/l10n/app_en.arb`
2. Run `flutter gen-l10n`
3. Use in code: `AppLocalizations.of(context).yourKey`

### Adding Language
1. Copy `app_en.arb` to `app_<locale>.arb` (e.g., `app_hi.arb`)
2. Translate all values
3. Add locale to `supportedLocales` in `main.dart`
4. Run `flutter gen-l10n`

---

## Documentation

### Update When
- New feature added
- Architecture changed
- API modified
- Deployment process changed

### Files to Update
- `README.md` — Overview, getting started
- `ARCHITECTURE.md` — Technical deep dive
- `DATABASE.md` — Schema changes
- `API.md` — New endpoints, RPCs, services
- `DEPLOYMENT.md` — New deployment steps
- `CHANGELOG.md` — User-facing changes

---

## Release Process

### Version Bump
```bash
# patch: 1.0.0 → 1.0.1
# minor: 1.0.0 → 1.1.0
# major: 1.0.0 → 2.0.0
# Update pubspec.yaml version: X.Y.Z+<build_number>
```

### Release Checklist
- [ ] All tests pass
- [ ] `flutter analyze` clean
- [ ] CHANGELOG.md updated
- [ ] Version bumped in `pubspec.yaml`
- [ ] Git tag created: `git tag vX.Y.Z`
- [ ] CI/CD pipeline runs
- [ ] Supabase migrations deployed
- [ ] Edge functions deployed
- [ ] Mobile builds uploaded to stores
- [ ] Web deployed

---

## Getting Help

- Check existing issues
- Search codebase for patterns
- Ask in team chat
- Pair programming for complex changes

---

## License

By contributing, you agree your contributions will be licensed under the project's private license.