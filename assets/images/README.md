# Onboarding photos

Drop three photographs here and the onboarding slides pick them up
automatically (see `_slidePhotos` in
`lib/features/onboarding/presentation/widgets/onboarding_art.dart`):

| File | Slide | What it should show |
|---|---|---|
| `onboarding_jobs.webp` | 1 | Someone browsing work on a phone |
| `onboarding_map.webp`  | 2 | A workplace or street scene in Uzbekistan |
| `onboarding_chat.webp` | 3 | A hiring conversation / handshake |

Requirements: WebP or JPEG, ~1080px wide, **licensed for commercial use**
(own photography, or a source whose licence permits it — keep the licence
record with the file). Until a file exists the slide falls back to the drawn
scene, so a missing photo is invisible rather than broken.
