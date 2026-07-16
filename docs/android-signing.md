# Android release signing

Google Play only accepts uploads signed with a real upload keystore. The
project's `android/app/build.gradle.kts` reads its release-signing values from
`android/key.properties`, which is **gitignored and must never be committed**.

## One-time setup

1. **Generate the upload keystore** (do this on the machine that will
   produce release builds; back the file up separately in a password
   manager):

   ```
   keytool -genkey -v \
     -keystore ~/keystores/yolla-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

   Answer the prompts and pick a strong password. You will be asked for
   both a **store password** and a **key password** — using the same value
   for both is simplest.

2. **Create `android/key.properties`** in this repo (the file is
   `.gitignore`d):

   ```
   storeFile=/absolute/path/to/yolla-upload.jks
   storePassword=YOUR_STORE_PASSWORD
   keyAlias=upload
   keyPassword=YOUR_KEY_PASSWORD
   ```

3. **Verify** the wiring picks it up:

   ```
   flutter build appbundle --release
   jarsigner -verify -verbose -certs \
     build/app/outputs/bundle/release/app-release.aab
   ```

   The certificate CN should match what you entered in step 1, NOT
   `Android Debug`. If it shows `Android Debug`, the file wasn't loaded
   — check the absolute path in `storeFile`.

4. **Capture the SHA-256 fingerprint** — needed for
   `webapp/public/.well-known/assetlinks.json` (Android App Links) and
   for Firebase Console (Google Sign-In):

   ```
   keytool -list -v -keystore ~/keystores/yolla-upload.jks -alias upload
   ```

   Copy the `SHA-256:` line and paste it into Vercel as
   `ANDROID_APP_SHA256_FINGERPRINT` (Production + Preview scope) — the
   `/.well-known/assetlinks.json` route reads that env.

## Play App Signing

On the first upload to Play Console, opt into **Play App Signing**. Play
holds the app-signing key on Google's side; your `yolla-upload.jks` is
only an *upload* key. If the upload key is ever compromised, Play lets
you rotate it without invalidating the app's identity.

Play App Signing changes the runtime signature the app is verified
against — after enrollment, download the *App signing certificate* from
Play Console → App integrity → App signing, extract its SHA-256, and use
**that** value in the assetlinks.json / Firebase console. The upload
key's fingerprint alone is not enough once Play resigns.

## Bumping the build number

Every Play upload must increase `versionCode`. It's read from
`pubspec.yaml`'s `version: 1.0.0+N` — bump `N` each time, or pass
`--build-number=N` on the CLI:

```
flutter build appbundle --release --build-number=$(git rev-list --count HEAD)
```

## What must NEVER be committed

- `android/key.properties` (gitignored)
- Any `.jks` / `.keystore` file (gitignored)
- Keystore passwords in CI env vars — use GitHub Actions **secrets**, not
  environment variables in the workflow YAML

If you accidentally commit any of the above, generate a new upload
keystore and rotate the compromised one in Play Console.
