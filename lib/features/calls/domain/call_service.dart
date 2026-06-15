/// Call domain abstraction (Phase 8 seam).
///
/// The UI talks to [CallService] and renders [CallSession] snapshots. The
/// default binding is a [SimulatedCallService] (no real media transport), so
/// the call screens work today. To enable real calls, bind
/// `callServiceFactoryProvider` to an Agora/WebRTC implementation — no UI
/// changes required. See `docs/phase-8-realtime-and-push.md`.
library;

enum CallType { voice, video }

enum CallPhase { connecting, connected, ended, failed }

/// Immutable snapshot of an in-progress call, streamed by [CallService].
class CallSession {
  const CallSession({
    this.phase = CallPhase.connecting,
    this.muted = false,
    this.speakerOn = true,
    this.videoEnabled = true,
    this.remoteVideoAvailable = false,
    this.duration = Duration.zero,
  });

  final CallPhase phase;
  final bool muted;
  final bool speakerOn;
  final bool videoEnabled;
  final bool remoteVideoAvailable;
  final Duration duration;

  bool get isActive =>
      phase == CallPhase.connecting || phase == CallPhase.connected;

  CallSession copyWith({
    CallPhase? phase,
    bool? muted,
    bool? speakerOn,
    bool? videoEnabled,
    bool? remoteVideoAvailable,
    Duration? duration,
  }) => CallSession(
    phase: phase ?? this.phase,
    muted: muted ?? this.muted,
    speakerOn: speakerOn ?? this.speakerOn,
    videoEnabled: videoEnabled ?? this.videoEnabled,
    remoteVideoAvailable: remoteVideoAvailable ?? this.remoteVideoAvailable,
    duration: duration ?? this.duration,
  );
}

/// Transport-agnostic call controls. Implementations: [SimulatedCallService]
/// (default) and a future Agora/WebRTC service.
abstract interface class CallService {
  /// Live session state (phase, mute/video flags, elapsed duration).
  Stream<CallSession> get sessions;

  /// Current snapshot (for synchronous reads on first build).
  CallSession get current;

  /// Connect to [channelId] as a voice or video [type] call.
  Future<void> join({required String channelId, required CallType type});

  Future<void> setMuted(bool muted);
  Future<void> setSpeaker(bool on);
  Future<void> setVideoEnabled(bool enabled);
  Future<void> switchCamera();

  /// Leave the channel and end the call.
  Future<void> leave();

  /// Release engine/stream resources.
  Future<void> dispose();
}

/// Fetches a short-lived call token for a channel (e.g. an Agora RTC token
/// minted by a Supabase Edge Function). The simulated service ignores it.
abstract interface class CallTokenProvider {
  Future<String?> tokenForChannel(String channelId);
}
