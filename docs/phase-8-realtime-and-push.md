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

### Architecture
- `features/notifications/domain/push_service.dart` — `PushService` interface +
  `PushMessage`.
- `features/notifications/data/noop_push_service.dart` — **default**, no-op.
- `features/notifications/data/fcm_push_service.dart` — **template**; documents
  the `firebase_messaging` calls and upserts tokens into `devices`.
- `features/notifications/application/push_providers.dart` — **the seam**:
  `pushServiceProvider`.
- DB: migration `0008_devices_push.sql` (`devices` table, owner-scoped RLS).
- Server: `push-dispatch` Edge Function (fan-out to a recipient's tokens);
  pair it with the existing `send-notification` (in-app row).

### Steps
1. `flutter pub add firebase_core firebase_messaging` then
   `flutterfire configure`.
2. `await Firebase.initializeApp()` at the top of `bootstrap()`.
3. Uncomment the `// FCM:` blocks in `fcm_push_service.dart`.
4. Flip the seam in `push_providers.dart`:
   ```dart
   final pushServiceProvider =
       Provider<PushService>((ref) => FcmPushService(ref));
   ```
5. Call it after sign-in (e.g. in `AppShell.initState` or right after a
   successful auth action):
   ```dart
   await ref.read(pushServiceProvider).initialize();
   ```
   and on logout: `await ref.read(pushServiceProvider).unregister();`
6. Apply the migration and deploy the dispatcher:
   ```bash
   supabase db push            # applies 0008_devices_push.sql
   supabase functions deploy push-dispatch
   supabase secrets set FCM_PROJECT_ID=... FCM_SERVICE_ACCOUNT='{...}'
   ```
7. Have the notification triggers (migration 0005) also call `push-dispatch`
   (via `pg_net`) so application-status / new-message events deliver a push in
   addition to the in-app row.

---

## Verification when wired
- Two physical devices: place a voice and a video call; toggle mute / camera /
  speaker; confirm join/leave on both ends and token expiry handling.
- Push: background the app, trigger an application-status change, confirm the
  system notification and that tapping it deep-links to the right screen.
- RLS: a user can only read/write their own `devices` rows.
