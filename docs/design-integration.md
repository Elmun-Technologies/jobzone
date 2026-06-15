# Figma → code integration guide

The UI is built on a **centralized, token-driven design system**, so matching
the Figma is mostly a matter of updating tokens + dropping in assets — not
rewriting screens. This doc maps every Figma concept to the file that owns it,
plus the step-by-step plan.

## Where each Figma concept lives

| Figma | Code | Notes |
|-------|------|-------|
| Color styles (light + dark) | `lib/design_system/theme/app_colors.dart` → `JzColors.light` / `JzColors.dark` | Semantic tokens: `primary`, `surface`, `border`, `textPrimary`, `success`, `danger`, `chipBackground`, … Change values here → whole app updates. |
| Text styles / type scale | `lib/design_system/theme/app_typography.dart` | Maps to Material `TextTheme` slots (display/headline/title/body/label). |
| Font family | `pubspec.yaml` (`flutter > fonts`) + `app_typography.dart` | See "Adding the Figma font" below. |
| Corner radii | `lib/design_system/theme/app_spacing.dart` → `AppRadius` | `xs/sm/md/lg/xl/pill`. |
| Spacing scale | `app_spacing.dart` → `AppSpacing` | 4/8-pt scale (`xs`…`xxxl`). |
| Buttons / inputs / app bar / nav | `lib/design_system/theme/app_theme.dart` (`ThemeData`) + `widgets/` | Component themes centralize most styling. |
| Icons (custom) | `assets/illustrations/*.svg` via `JzSvgAsset` | Figma icon exports as SVG. |
| Illustrations (onboarding, empty/success) | `assets/illustrations/*.svg` | Reference through `JzSvgAsset`. |
| Raster images | `assets/images/` (re-add to `pubspec` assets) | PNG/JPG/WebP. |

## Integration plan (when the Figma arrives)

**D1 — Tokens (one focused PR, highest leverage).** Read the Figma color/text
styles, radii, spacing and shadows; update `JzColors` (both themes),
`AppTypography`, `AppSpacing`/`AppRadius`, and the component themes in
`app_theme.dart`. The change propagates app-wide automatically.

**D2 — Assets.** Export icons/illustrations as SVG and images as WebP/PNG into
`assets/`. Add an `AppAssets` constants holder and swap placeholder icons /
empty-state visuals to the real artwork via `JzSvgAsset`.

**D3 — Screen-by-screen matching.** Walk each Figma frame and align layout,
spacing, and component anatomy (JobCard, CompanyCard, ChatBubble, app bars,
bottom nav, tab bars, chips). Most deltas are token-driven after D1.

**D4 — Motion & QA.** Add transitions/animations per the prototype; final sweep
across **3 locales × light/dark × small/large screens**.

## Adding the Figma font

1. Drop the font files into `assets/fonts/` (e.g. `Inter-Regular.ttf`, `-Medium`, `-SemiBold`, `-Bold`).
2. Declare them in `pubspec.yaml`:
   ```yaml
   flutter:
     fonts:
       - family: Inter
         fonts:
           - asset: assets/fonts/Inter-Regular.ttf
           - asset: assets/fonts/Inter-Medium.ttf
             weight: 500
           - asset: assets/fonts/Inter-SemiBold.ttf
             weight: 600
           - asset: assets/fonts/Inter-Bold.ttf
             weight: 700
   ```
3. Set `fontFamily: 'Inter'` in `AppTheme` (and/or per text style in
   `app_typography.dart`). Keep Cyrillic + Latin coverage for uz/ru/en.

## What's most useful to share from Figma

- A **Dev Mode** view link (lets values be read exactly), **or**
- exported **color styles + text styles + spacing/radius**, the **assets**
  (SVG/PNG), and any **font files**.

## Already in place (this prep PR)

- `flutter_svg` + `JzSvgAsset` wrapper (`lib/design_system/widgets/media/jz_svg.dart`).
- `assets/` structure (`icon/`, `illustrations/`, `images/`) declared in `pubspec`.
- This guide.
