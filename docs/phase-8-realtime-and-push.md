# Phase 8 — Real calls (WebRTC/Agora) & push notifications (FCM)

Phases 0–7 ship a complete app that runs offline and against Supabase +
Meilisearch. Phase 8 swaps two **seams** to enable real-time voice/video calls
and remote push. Everything below is scaffolded: interfaces, default no-op
implementations, provider seams, DB migration, and Edge Function stubs. No UI
changes are needed to go live — you bind a different implementation to one
provider each.

> Why scaffolded, not wired: both features require provisioned third-party
> services (Agora project, Firebase project) plus native iOS/Android config and
> real devices to test — none of which exist in CI. The app stays green today
> because the defaults are a **simulated** call service and a **no-op** push
> service.

---

## 1. Calls — Agora (or any WebRTC)

### Architecture
- `features/calls/domain/call_service.dart` — `CallService` interface +
  `CallSession` snapshot (phase, mute/speaker/video flags, duration) +
  `CallTokenProvider`.
- `features/calls/data/simulated_call_service.dart` — **default**. No media;
  drives connecting → connected + a duration ticker so the call UI works.
- `features/calls/data/agora_call_service.dart` — **template**. Implements
  `CallService`; every method documents the exact `agora_rtc_engine` call.
- `features/calls/data/call_token_provider.dart` — `SupabaseCallTokenProvider`
  calls the `agora-token` Edge Function.
- `features/calls/application/call_providers.dart` — **the seam**:
  `callServiceFactoryProvider`.
- `features/chat/presentation/call_page.dart` already renders purely from the
  `CallService` session stream — no changes needed.

### Steps
1. `flutter pub add agora_rtc_engine permission_handler`
2. Add your App ID via dart-define: `AGORA_APP_ID` (exposed as `Env.agoraAppId`).
3. Uncomment the `// AGORA:` blocks in `agora_call_service.dart`.
4. Flip the seam in `call_providers.dart`:
   ```dart
   final callServiceFactoryProvider = Provider<CallService Function()>((ref) {
     if (!Env.hasAgora) return SimulatedCallService.new; // fallback
     final tokens = ref.read(callTokenProvider);
     return () => AgoraCallService(appId: Env.agoraAppId, tokenProvider: tokens);
   });
   ```
5. Deploy the token function and set its secrets:
   ```bash
   supabase functions deploy agora-token
   supabase secrets set AGORA_APP_ID=... AGORA_APP_CERTIFICATE=...
   ```
6. Native permissions: add mic (voice) and mic+camera (video) usage strings to
   `Info.plist` and the `RECORD_AUDIO` / `CAMERA` permissions to
   `AndroidManifest.xml` per the Agora quick-start; request them before `join`.

### Signaling
Call invites/accept/decline ride on the existing chat: insert a `messages` row
with `type = 'call_event'` (already allowed by the schema) and react to it via
the realtime stream. The channel id is the `conversationId`.

---

## 2. Push — Firebase Cloud Messaging

**The client and server are now wired.** Push works end-to-end the moment the
host app ships a Firebase project config — no code change needed.

### What's in place
- `features/notifications/domain/push_service.dart` — `PushService` + `PushMessage`.
- `features/notifications/data/fcm_push_service.dart` — real `firebase_messaging`:
  requests permission, gets the token, listens for refreshes, exposes foreground
  messages on `messages`, and upserts the token into `devices`.
- `features/notifications/data/noop_push_service.dart` — fallback (push disabled).
- `features/notifications/application/push_providers.dart` — `pushServiceProvider`
  resolves to `FcmPushService` when **`firebaseReady`**, else `NoopPushService`.
- `bootstrap()` guards `Firebase.initializeApp()` (sets `firebaseReady`); it
  throws without native config (web/dev) and we catch it → push stays disabled,
  no regression.
- Lifecycle: `app.dart` calls `initialize()` on sign-in (`authStateChanges`);
  `profile_page` calls `unregister()` before sign-out (RLS needs the uid).
- DB: `0008_devices_push.sql` (`devices`, owner RLS).
- Server fan-out: `_shared/fcm.ts` sends FCM HTTP v1; `push-dispatch` exposes it;
  `notify-dispatch` (migration 0026 trigger) pushes every notification to the
  recipient's devices alongside Telegram, respecting `notification_settings`.

### To go live (host-app + ops only)
1. Create a Firebase project; add an **Android app** (`io.jobzone.jobzone`) and
   an **iOS app** (same bundle id).
2. **Android:** drop `google-services.json` into `android/app/`, then add the
   Gradle plugin (kept out of the repo so the build works without the file):
   - `android/settings.gradle.kts` → `plugins { … id("com.google.gms.google-services") version "4.4.2" apply false }`
   - `android/app/build.gradle.kts` → `plugins { … id("com.google.gms.google-services") }`
3. **iOS:** drop `GoogleService-Info.plist` into `ios/Runner/`, add the **Push
   Notifications** capability, and upload an **APNs auth key** in the Firebase
   console. (`flutterfire configure` automates steps 2–3.)
4. Server: from the service-account JSON,
   ```bash
   supabase db push            # applies 0008 + 0026 (+ the rest)
   supabase secrets set FCM_SERVICE_ACCOUNT='{...}'
   supabase functions deploy push-dispatch notify-dispatch
   ```
   (`project_id` is read from the JSON — no separate FCM_PROJECT_ID needed.)

Until step 1–3 are done, `Firebase.initializeApp()` throws → `firebaseReady`
stays false → `NoopPushService` → push silently disabled.

---

## Verification when wired
- Two physical devices: place a voice and a video call; toggle mute / camera /
  speaker; confirm join/leave on both ends and token expiry handling.
- Push: background the app, trigger an application-status change, confirm the
  system notification and that tapping it deep-links to the right screen.
- RLS: a user can only read/write their own `devices` rows.
