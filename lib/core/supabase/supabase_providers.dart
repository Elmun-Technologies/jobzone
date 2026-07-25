import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// The shared [SupabaseClient]. Only valid once Supabase has been initialized
/// in `bootstrap()` (i.e. when [Env.hasSupabase] is true).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Stream of auth state changes (sign in / out, token refresh).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  if (!Env.hasSupabase) return const Stream.empty();
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// The current session, or null when signed out / no backend configured.
final currentSessionProvider = Provider<Session?>((ref) {
  if (!Env.hasSupabase) return null;
  // Rebuild whenever auth state changes.
  ref.watch(authStateChangesProvider);
  return Supabase.instance.client.auth.currentSession;
});

/// Whether a user is currently signed in.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentSessionProvider) != null;
});

/// The signed-in user's id, or null. Unlike [currentSessionProvider] this
/// settles: a token refresh yields a new `Session` object but the same id
/// string, so dependents rebuild only when the identity actually changes.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.user.id;
});
