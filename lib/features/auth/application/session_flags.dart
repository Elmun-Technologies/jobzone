import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/enums/enums.dart';
import '../../../shared/providers/app_flags.dart';

/// The two halves of cross-device onboarding state. The router reads locally
/// persisted flags (synchronously), but the durable source of truth is the
/// `profiles` row — [completeProfileSetup] writes it and [hydrateSessionFlags]
/// reads it back on the next sign-in, so a returning account (Google, email or
/// phone, on any device) is never marched through choose-role/setup again.

/// Marks profile setup finished: locally and on `profiles.onboarding_complete`.
/// The server write is best-effort — a transient failure must not block
/// entering the app (the flag hydrates from a later completed pass instead).
Future<void> completeProfileSetup(WidgetRef ref) async {
  await ref.read(appFlagsProvider.notifier).setProfileComplete(true);
  if (!Env.hasSupabase) return;
  final client = ref.read(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  if (uid == null) return;
  try {
    await client
        .from('profiles')
        .update({'onboarding_complete': true})
        .eq('id', uid);
  } catch (_) {}
}

/// Restores the router flags from the server profile of the signed-in user.
/// Only a profile that already finished onboarding hydrates (role +
/// profileComplete together); new or mid-setup accounts are left to the
/// guard's normal choose-role → setup chain. No-op offline, signed out, or
/// when the local flags are already complete.
Future<void> hydrateSessionFlags(WidgetRef ref) async {
  if (!Env.hasSupabase) return;
  if (ref.read(appFlagsProvider).profileComplete) return;
  final client = ref.read(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  if (uid == null) return;
  try {
    final row = await client
        .from('profiles')
        .select('role, onboarding_complete')
        .eq('id', uid)
        .maybeSingle();
    if (row == null || row['onboarding_complete'] != true) return;
    final flags = ref.read(appFlagsProvider.notifier);
    await flags.setRole(
      UserRole.fromWire(row['role'] as String?) ?? UserRole.jobSeeker,
    );
    await flags.setProfileComplete(true);
  } catch (_) {
    // Best-effort: on failure the user just walks setup again locally.
  }
}
