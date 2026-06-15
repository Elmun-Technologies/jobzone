# Brand & content assets

Figma-exported assets live here and are referenced via `JzSvgAsset` (see
`lib/design_system/widgets/media/jz_svg.dart`).

- `icon/`          — app launcher icon sources (icon.png, icon_foreground.png)
- `illustrations/` — SVG illustrations (onboarding, empty/success states)
- `images/`        — raster images (PNG/JPG/WebP)

Naming: snake_case, descriptive (e.g. `onboarding_discover.svg`,
`empty_bookmarks.svg`). Prefer SVG for icons/illustrations so they scale and
can be tinted. Add new constants to a centralized `AppAssets` map as you wire
real screens to the assets.
