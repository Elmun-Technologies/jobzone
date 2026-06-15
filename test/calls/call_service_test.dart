import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/calls/data/simulated_call_service.dart';
import 'package:jobzone/features/calls/domain/call_service.dart';

void main() {
  test(
    'SimulatedCallService: connecting → connected → ticks → ended',
    () async {
      final service = SimulatedCallService(
        connectDelay: const Duration(milliseconds: 20),
        tick: const Duration(milliseconds: 10),
      );
      addTearDown(service.dispose);

      final phases = <CallPhase>[];
      final sub = service.sessions.listen((s) => phases.add(s.phase));

      await service.join(channelId: 'conv-1', type: CallType.voice);
      expect(service.current.phase, CallPhase.connecting);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(phases.first, CallPhase.connecting);
      expect(phases.contains(CallPhase.connected), isTrue);
      expect(
        service.current.duration.inMilliseconds,
        greaterThan(0),
        reason: 'ticker should advance once connected',
      );

      await service.leave();
      expect(service.current.phase, CallPhase.ended);
      await sub.cancel();
    },
  );

  test('SimulatedCallService: control toggles update the session', () async {
    final service = SimulatedCallService();
    addTearDown(service.dispose);

    await service.setMuted(true);
    expect(service.current.muted, isTrue);

    await service.setVideoEnabled(false);
    expect(service.current.videoEnabled, isFalse);

    await service.setSpeaker(false);
    expect(service.current.speakerOn, isFalse);

    // Smoke: switchCamera is a no-op in the simulation, must not throw.
    await service.switchCamera();
  });
}
