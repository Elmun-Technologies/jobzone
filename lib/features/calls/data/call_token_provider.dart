import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/call_service.dart';

/// Fetches an Agora RTC token from the `agora-token` Edge Function (which holds
/// the Agora App Certificate server-side — never shipped to the client).
/// Returns null offline / when no backend is configured.
class SupabaseCallTokenProvider implements CallTokenProvider {
  SupabaseCallTokenProvider(this._ref);

  final Ref _ref;

  @override
  Future<String?> tokenForChannel(String channelId) async {
    if (!Env.hasSupabase) return null;
    final res = await _ref
        .read(supabaseClientProvider)
        .functions
        .invoke('agora-token', body: {'channel': channelId});
    final data = res.data;
    if (data is Map && data['token'] is String) return data['token'] as String;
    return null;
  }
}

final callTokenProvider = Provider<CallTokenProvider>(
  (ref) => SupabaseCallTokenProvider(ref),
);
