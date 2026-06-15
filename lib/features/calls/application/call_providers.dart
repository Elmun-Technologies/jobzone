import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/simulated_call_service.dart';
import '../domain/call_service.dart';

/// **The Phase 8 seam.** Returns a factory that builds a fresh [CallService]
/// per call screen. Default = [SimulatedCallService] (no real transport).
///
/// To enable real calls, swap the body to build an `AgoraCallService`:
/// ```dart
/// final callServiceFactoryProvider = Provider<CallService Function()>((ref) {
///   final tokens = ref.read(callTokenProvider);
///   return () => AgoraCallService(appId: Env.agoraAppId, tokenProvider: tokens);
/// });
/// ```
final callServiceFactoryProvider = Provider<CallService Function()>(
  (ref) => SimulatedCallService.new,
);
