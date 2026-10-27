# Diwali home screen — Flutter implementation

The festive storefront that ships **inside the app**, written entirely with
Flutter widgets and Dart. No HTML, no WebView, no new runtime dependency.

## Where it appears

| Entry point | What happens |
| --- | --- |
| **Home → "Diwali" chip** | `HomeScreen` swaps its scrolling body for the full-bleed storefront. The chip strip stays pinned, so "All" and the other storefronts are one tap away. |
| `Navigator.pushNamed(context, kDiwaliRoute)` (`/diwali`) | Opens the same storefront as a standalone route with its own bottom bar and a back arrow. Registered in `lib/main.dart`. |
| `kDiwaliAsHome = true` in `diwali_config.dart` | `MainShell` makes it the Home tab itself and hides its own bottom bar there. Off by default so the existing Home is untouched. |

## Files

| File | Responsibility |
| --- | --- |
| `diwali_config.dart` | The single integration switch, asset root and route name. |
| `diwali_theme.dart` | Sampled palette, bundled type styles, three breakpoints, spacing, radii and motion. |
| `diwali_data.dart` | Immutable content models (products, arches, tiles, diamonds, calendar, brands) and the whole catalogue. A CMS swap replaces only this file. |
| `diwali_store.dart` | A `ChangeNotifier` for cart, wishlist, search, address, tabs and voice, exposed through `DiwaliScope` (`InheritedNotifier`). |
| `diwali_painters.dart` | `CustomPainter`s for fairy lights, the diamond rules, arch shadows, the bow, lotus, sparkles and the diamond clip. |
| `diwali_icons.dart` | Hand-drawn line glyphs for the tab strip and bottom nav, plus the reusable circle button. |
| `diwali_reveal.dart` | Scroll-triggered enter animation, hover lift and press feedback. Respects the OS reduced-motion flag. |
| `diwali_product_card.dart` | Product tile (all states: measurement, wishlist, price-drop ribbon, rating, variants, low stock, ADD → stepper, "Similar"), section heading and the carousel. |
| `diwali_decor_cards.dart` | Hero arches, editorial arch rails, category grids, diamond categories, gift chips, brands, calendar and promo banners. |
| `diwali_sections.dart` | The 18-section page body: dark hero, tab strip, rails, banners, editorial blocks and footer. |
| `diwali_home.dart` | `DiwaliPage` route wrapper and `DiwaliHomePage`: sticky header, live search overlay, cart bar/panel, bottom nav and back-to-top. |
| `diwali_utils.dart` | Indian-grouped rupee formatting. |

Tests live in `test/diwali_storefront_test.dart`.

## Assets

- `assets/diwali/` — 78 locally optimised progressive JPEGs (max 760 px), shared
  with the static reference. Run `python3 tools/sync_diwali_assets.py` after
  changing `festive-ui/assets/img/`; it also verifies that every image named in
  `diwali_data.dart` exists.
- `assets/fonts/DiwaliSerif-*.ttf` (DM Serif Display),
  `assets/fonts/DiwaliDisplay-Regular.ttf` (Rozha One) and the existing bundled
  Poppins faces. All are registered in `pubspec.yaml`; no font is fetched at
  runtime. The two display families are Latin subsets, so `DiwaliText` adds
  Poppins as a `fontFamilyFallback` — that is where `₹` comes from.

These are representative locally bundled photographs, not crops of the
proprietary reference screenshots. Drop replacement files into
`assets/diwali/` under the same names to match the originals exactly.

## Responsive behaviour

`DiwaliLayout` switches at 600 and 1024 logical pixels:

- **Compact (<600)** — 3 hero arches, 4 diamonds, one-and-a-bit product cards
  visible per rail, touch scrolling, compact type.
- **Medium (600–1024)** — 3 hero arches, 4 diamonds, wider rails with arrow
  controls, larger headings and banners.
- **Expanded (≥1024)** — 6 hero arches in one row, 8 diamonds, up to five
  product cards visible, content capped at 1180 px and centred.

Every horizontal rail is a `ListView` with its own `ScrollController`, so it
scrolls independently of the page and never forces a fixed page width.

## Motion

- Fairy lights twinkle on a looping `AnimationController` (one per string,
  disposed with the widget).
- Sections fade, slide and scale in the first time their top edge enters the
  bottom 95% of the viewport, with a short stagger per card. A
  `DiwaliRevealScope` shares the page `ScrollController` with every reveal.
- The light header fades and slides in as the dark hero scrolls away; a
  back-to-top button appears after 900 px.
- Pointer devices get a lift + shadow on cards and a scale on buttons; touch
  devices get press feedback instead, so scrolling never triggers a hover.
- `disableAnimations` (OS reduced motion) skips all entrance animations.

## Interactions

ADD → stepper, cart with live totals and savings, checkout confirmation,
wishlist hearts, live search with result grid and no-results state, voice
"listening" state, address and help sheets, product detail sheet, gift-filter
chips, category tabs, sticky header, and back-to-top.

## Validation

The Flutter SDK is not installed in the working sandbox, so
`.github/workflows/diwali-analyze.yml` runs the real checks in CI. Because
this module imports only Flutter's own libraries, the workflow copies
`lib/diwali/`, the assets and the test into a tiny throwaway package on
current stable Flutter and runs:

- `flutter analyze --no-fatal-infos` → **no issues found**;
- `flutter test` → **13 passing tests**, including layout smoke tests that
  pump the entire storefront at 360×640, 820×1180 and 1440×900 and assert
  that no render exception occurs;
- a second job runs `flutter analyze` on the **full app** and asserts there
  are no errors in any file touched by the integration.

Locally the same sources were also parsed with tree-sitter-dart (zero syntax
errors), the asset/pubspec graph was verified with
`tools/sync_diwali_assets.py`, and the font files were checked for glyph
coverage with fontTools.

The repo's original `flutter-ci.yml` is pinned to Flutter 3.24 / Dart 3.5
while `cloud_firestore ^7` needs Dart ≥3.6, so its `flutter pub get` step
fails before analysis regardless of this work; `flutter_lints` was pinned back
to `^4.0.0` so that the constraint is at least satisfiable there.
