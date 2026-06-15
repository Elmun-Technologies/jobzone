import 'dart:async';

import '../domain/call_service.dart';

/// Default [CallService]: no real media transport. Simulates connecting →
/// connected and ticks an elapsed timer, while control toggles update the
/// streamed [CallSession]. Keeps the call UI fully functional without Agora.
class SimulatedCallService implements CallService {
  SimulatedCallService({
    this.connectDelay = const Duration(seconds: 2),
    this.tick = const Duration(seconds: 1),
  });

  final Duration connectDelay;
  final Duration tick;

  final _controller = StreamController<CallSession>.broadcast();
  CallSession _session = const CallSession();
  Timer? _connectTimer;
  Timer? _ticker;
  bool _disposed = false;

  @override
  Stream<CallSession> get sessions => _controller.stream;

  @override
  CallSession get current => _session;

  void _emit(CallSession next) {
    _session = next;
    if (!_disposed && !_controller.isClosed) _controller.add(next);
  }

  @override
  Future<void> join({required String channelId, required CallType type}) async {
    _emit(
      CallSession(
        phase: CallPhase.connecting,
        videoEnabled: type == CallType.video,
        speakerOn: type == CallType.video,
      ),
    );
    _connectTimer = Timer(connectDelay, () {
      _emit(_session.copyWith(phase: CallPhase.connected));
      _ticker = Timer.periodic(tick, (_) {
        if (_session.phase == CallPhase.connected) {
          _emit(_session.copyWith(duration: _session.duration + tick));
        }
      });
    });
  }

  @override
  Future<void> setMuted(bool muted) async =>
      _emit(_session.copyWith(muted: muted));

  @override
  Future<void> setSpeaker(bool on) async =>
      _emit(_session.copyWith(speakerOn: on));

  @override
  Future<void> setVideoEnabled(bool enabled) async =>
      _emit(_session.copyWith(videoEnabled: enabled));

  @override
  Future<void> switchCamera() async {
    // No-op in the simulation; a real engine swaps the capture device.
  }

  @override
  Future<void> leave() async {
    _connectTimer?.cancel();
    _ticker?.cancel();
    _emit(_session.copyWith(phase: CallPhase.ended));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _connectTimer?.cancel();
    _ticker?.cancel();
    await _controller.close();
  }
}
