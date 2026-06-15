import 'dart:async';

import '../domain/call_service.dart';

/// Agora implementation **template** (Phase 8).
///
/// This file intentionally does NOT import `agora_rtc_engine` so the project
/// builds without the dependency. To go live:
///
/// 1. `flutter pub add agora_rtc_engine permission_handler`
/// 2. Uncomment the SDK calls below (marked `// AGORA:`), add your App ID, and
///    wire [CallTokenProvider] to the `agora-token` Edge Function.
/// 3. Bind `callServiceFactoryProvider` to `AgoraCallService.new` in
///    `call_providers.dart`.
/// 4. Add platform permissions (mic/camera) per the Agora quick-start.
///
/// The method bodies show the exact engine calls each control maps to.
class AgoraCallService implements CallService {
  AgoraCallService({required this.appId, required this.tokenProvider});

  final String appId;
  final CallTokenProvider tokenProvider;

  final _controller = StreamController<CallSession>.broadcast();
  // Reassigned by the Agora event handlers once wired (see join()).
  // ignore: prefer_final_fields
  CallSession _session = const CallSession();
  // AGORA: late final RtcEngine _engine;

  @override
  Stream<CallSession> get sessions => _controller.stream;

  @override
  CallSession get current => _session;

  @override
  Future<void> join({required String channelId, required CallType type}) async {
    // AGORA:
    // _engine = createAgoraRtcEngine();
    // await _engine.initialize(RtcEngineContext(appId: appId));
    // _engine.registerEventHandler(RtcEngineEventHandler(
    //   onJoinChannelSuccess: (conn, elapsed) =>
    //       _emit(_session.copyWith(phase: CallPhase.connected)),
    //   onUserJoined: (conn, uid, elapsed) =>
    //       _emit(_session.copyWith(remoteVideoAvailable: type == CallType.video)),
    //   onUserOffline: (conn, uid, reason) => leave(),
    //   onError: (err, msg) => _emit(_session.copyWith(phase: CallPhase.failed)),
    // ));
    // if (type == CallType.video) {
    //   await _engine.enableVideo();
    //   await _engine.startPreview();
    // }
    // final token = await tokenProvider.tokenForChannel(channelId);
    // await _engine.joinChannel(
    //   token: token ?? '',
    //   channelId: channelId,
    //   uid: 0,
    //   options: const ChannelMediaOptions(),
    // );
    throw UnimplementedError(
      'AgoraCallService is a template. See docs/phase-8-realtime-and-push.md.',
    );
  }

  @override
  Future<void> setMuted(bool muted) async {
    // AGORA: await _engine.muteLocalAudioStream(muted);
    throw UnimplementedError();
  }

  @override
  Future<void> setSpeaker(bool on) async {
    // AGORA: await _engine.setEnableSpeakerphone(on);
    throw UnimplementedError();
  }

  @override
  Future<void> setVideoEnabled(bool enabled) async {
    // AGORA: await _engine.muteLocalVideoStream(!enabled);
    throw UnimplementedError();
  }

  @override
  Future<void> switchCamera() async {
    // AGORA: await _engine.switchCamera();
    throw UnimplementedError();
  }

  @override
  Future<void> leave() async {
    // AGORA: await _engine.leaveChannel();
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() async {
    // AGORA: await _engine.release();
    await _controller.close();
  }
}
