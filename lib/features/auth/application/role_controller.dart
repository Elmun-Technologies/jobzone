import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/enums/enums.dart';
import '../../../shared/providers/app_flags.dart';

/// Persists a role change: locally (so the router reacts immediately) and to
/// `profiles.role` when a backend is configured. Shared by the choose-role
/// screen and the in-app "switch role" entries.
Future<void> applyRole(WidgetRef ref, UserRole role) async {
  await ref.read(appFlagsProvider.notifier).setRole(role);
  if (Env.hasSupabase) {
    final client = ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      // Best-effort: the local flag is the source of truth for routing, so a
      // transient backend write failure must not throw out of the UI callback.
      try {
        await client.from('profiles').update({'role': role.wire}).eq('id', uid);
      } catch (_) {}
    }
  }
}
