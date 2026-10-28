# Diwali Festive storefront

A pixel-matched recreation of the Blinkit Diwali home screen, built as a
self-contained Flutter module that drops into this app without any host glue.

```
lib/diwali_festive/            ~6.3k lines, 9 files
  festive.dart                 barrel + kDiwaliFestiveRoute
  festive_tokens.dart          palette, type, breakpoints, metrics, motion
  festive_data.dart            models, copy, asset ids, catalogue
  festive_store.dart           ChangeNotifier cart/search/tab state
  festive_art.dart             custom painters (glyphs, fairy lights, backdrop)
  festive_widgets.dart         header, search, tab strip, nav, cart bar, pills
  festive_cards.dart           wordmark, banner title, arch tiles, product card, rail
  festive_sheets.dart          search / cart / product sheets
  festive_home.dart            DiwaliFestiveScreen
```

Route: `kDiwaliFestiveRoute` is already registered in `lib/main.dart`
(`/diwali-festive`), so `Navigator.pushNamed(context, kDiwaliFestiveRoute)` works
today. `DiwaliFestiveScreen()` can also be used directly — every callback is
optional and defaults to sensible internal behaviour.

---

## 1. How it matches the reference

The source capture is 900 × 2000 px ≈ **360 × 800 dp**, i.e. 2.5 px per dp.
Geometry was measured off the screenshot (flat-region colour sampling, glyph
bboxes) and expressed in dp:

| Element | Reference |
| --- | --- |
| Header gradient | `#4C0010 → #600020`, bulb string (toran) over the top edge |
| Banner | wine radial `#9A0046 → #6E012A`, centre `Alignment(0, −0.92)`, r 1.05 |
| Wordmark "Diwali" | Playfair Bold, 36.4 dp, 110 × 39.2 dp block, gold `#F5D69C` |
| Eyebrow / date | 14.4 dp / 9.7 dp, gold |
| Search pill | 42 dp tall, 12 dp radius, hint 19.2 dp |
| Arch tiles | 3-across, 106.4 × 120.4 dp (aspect **1.132**), first row `y ≈ 292`, row gap 10 dp |
| Tile caption | 11.4 dp, two lines, `Lights, Diya / & Decor` |
| Tab strip | 54 dp, wine `#5F001D`, icon 21 dp, label 7.6 dp, active underline 34 × 4 dp |
| Rail heading | 15.1 dp semibold, subtitle 12 dp |
| Nav bar | 56 dp, labels 7.4 dp, Zomato chip `#E23744` |
| Body palette | ink `#333`, soft `#6B6B6B`, hairline `#EDE7E1`; ADD green `#0C831F` |

Anything the capture leaves ambiguous (off-screen rails, hover, empty states,
dark mode) is a deliberate production decision noted in the code comments.

## 2. Design system

`festive_tokens.dart` is the single source of truth:

* **`FestiveColors`** — light and dark sets, resolved through `FestivePalette`.
  `paletteOf(context)` reads the `FestivePalette` theme extension and falls back
  to the current `Theme.brightness`, so dark mode works even if the host app
  never registers the extension.
* **`FestiveType`** — `body()` (Poppins, theme-inherited) and `serif()`
  (Playfair Display) helpers; no inline `TextStyle` anywhere else.
* **`FestiveBreakpoints`** — `compact < 600 ≤ medium < 1024 ≤ expanded`,
  content capped at **1180 dp**.
* **`FestiveMetrics`** — the fixed chrome heights (`0` magic numbers outside it).
* **`FestiveMotion`** — 160 / 260 / 460 / 620 ms with shared curves, plus
  `FestiveMotion.reduced(context)` which honours *disable animations* and
  *accessible navigation*.
* **`clampTextScaler`** — caps layout text scale at 1.35 × so the three-line
  header can never overflow its 150 dp; content stays legible instead of
  clipping.

## 3. Responsiveness

Everything is derived from `LayoutBuilder` + `MediaQuery`, no fixed widths.

| | compact (< 600) | medium (600–1023) | expanded (≥ 1024) |
| --- | --- | --- | --- |
| Type scale | 1.00 | 1.08 | 1.16 |
| Side gutter | 12 | 20 | 28 |
| Section gap | 18 | 24 | 30 |
| Tile grid | 3 columns | 4 | 6 |
| Rail visible cards | 3.25 | 4.3 | 6.3 |
| Fairy bulbs | 22 | 34 | 34 |
| Rail arrows | — (swipe) | ← → | ← → |
| Content width | viewport | viewport | capped at 1180, centred |

The 3.25-card rail is intentional: the quarter card peeking past the edge is
what makes the row read as scrollable in the screenshot.

Text scaling is handled twice — `clampTextScaler` guards the chrome, while the
product card and rail re-derive their heights from
`MediaQuery.textScalerOf(context)` so 1.35 × text grows the card instead of
overlapping the price row.

## 4. Motion and micro-interactions

* **Toran fairy lights** — a single twinkle controller drives opacity + glow of
  every bulb; one `RadialGradient` paint is shared per frame (no per-bulb shader
  allocation). Static when motion is reduced.
* **Backdrop** — slow drifting bokeh + sparkles behind the banner.
* **Entrance** — `FestiveReveal` staggers header → banner → tiles → rails
  (620 ms, ease-out-cubic), disabled under reduced motion.
* **Taps** — `FestiveTap` adds hover lift (4 dp), 1.2 % scale, pointer cursor and
  an ink ripple on desktop; arch tiles tilt slightly on hover.
* **Tab strip** — 1.08 × icon scale, hover wash, animated 34 dp underline.
* **ADD button** — animates into a −/qty/+ stepper (`AnimatedSize` +
  `AnimatedSwitcher`), and the cart bar slides up from the nav bar with an
  `AnimatedBuilder`-driven item count.
* **Search** — pill focus glow, voice chip pulse while "listening", sheet slides
  with a live suggestion list.
* **Rails** — arrow paging with `animateTo`, scroll-position-linked arrow
  enable/disable.

## 5. Assets required

Images (19 of the 78 present in `assets/diwali/`, all referenced by name so
replacements are drop-in):

```
urli-1  urli-2  diya-1  diya-4  candle-1  candle-2  candle-3  toran-1
lights-1  rangoli-1  pooja-1  rose-2  hamper-3  chocolate-1  chocolate-4
towel-2  beauty-4  appliance-2  ethnic-2
```

Fonts, already declared in `pubspec.yaml`:

* `Poppins` — 400 / 500 / 600 / 700 / 800 (UI text)
* `PlayfairDisplay` — 700 (wordmark, banner headings)

```yaml
flutter:
  assets:
    - assets/diwali/
  fonts:  # as already declared in this repo
    - family: Poppins ...
    - family: PlayfairDisplay ...
```

## 6. Dependencies

**None beyond `flutter`.** No `provider`, no `google_fonts`, no `lottie`, no
`flutter_svg`. State is a `ChangeNotifier` behind an `InheritedNotifier`; all
ornament is `CustomPainter`; icons are Material rounded glyphs plus hand-painted
Diwali glyphs (diya, mandala, gift, spark).

## 7. Public API

```dart
DiwaliFestiveScreen({
  FestiveCopy? copy,                 // inject translations / A-B copy
  List<FestiveCategory>? categories,
  List<FestiveTile>? tiles,
  List<FestiveRail>? rails,
  List<FestiveNavDestination>? navigation,
  int initialTab = 1,                // 1 = "Diwali", as in the capture
  bool showBottomNav = true,
  bool showZomatoButton = true,
  ValueChanged<int>? onNavigate,
  ValueChanged<int>? onCategoryTap,
  ValueChanged<FestiveTile>? onTileTap,
  VoidCallback? onZomatoTap,
  double maxContentWidth = 1180,
});
```

Lower-level widgets are exported for reuse: `FestiveHeader`,
`FestiveSearchBar`, `FestiveTabStrip`, `FestiveBottomBar`, `FestiveCartBar`,
`FestiveTileGrid`, `FestiveArchTile`, `FestiveProductCard`, `FestiveRailView`,
`FestiveSearchSheet`, `FestiveCartSheet`, `FestiveProductSheet`, `FairyLights`,
`Sparkle`, `FestiveWordmark`, plus `FestiveStore` / `FestiveStoreScope` and the
`FestiveCopy`, `FestiveProduct`, `FestiveRail`, `FestiveCategory`,
`FestiveTile`, `FestiveNavDestination` models.

## 8. Integration

```dart
Navigator.of(context).pushNamed(kDiwaliFestiveRoute);
```

`lib/main.dart` already maps that route to `const DiwaliFestiveScreen()`.
If you prefer to keep the screen inside an existing shell, embed it directly:

```dart
const DiwaliFestiveScreen(showBottomNav: false)
```

The module never touches global state, `Theme.of` mutations or routes, so it is
safe to embed in a tab, a dialog-sized window, or a full-screen page.

## 9. Accessibility and performance

* Every interactive node has `Semantics(button: true, label: …)`; decorative
  paint is wrapped in `ExcludeSemantics`.
* Contrast checked against both palettes (gold on wine ≥ 4.5:1 for body sizes).
* `Image.asset` sets `cacheWidth` from the laid-out width × DPR, so the phone
  never decodes 1200 px JPEGs for 100 dp cards.
* Painters are `const`, `shouldRepaint` compares only the fields they use, and
  every `AnimationController` is disposed.
* The page is one `CustomScrollView`; each rail is a lazy
  `ListView.separated`, so only visible cards are built and the whole screen
  scrolls as a single gesture.
