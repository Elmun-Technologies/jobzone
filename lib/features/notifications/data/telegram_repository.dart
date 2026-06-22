import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';

/// Whether the signed-in user's Telegram is linked (+ the linked username).
class TelegramLink {
  const TelegramLink({required this.linked, this.username});
  final bool linked;
  final String? username;
}

/// Links/unlinks the user's Telegram for notification delivery. The actual
/// link row is created by the `telegram-webhook` edge function after the user
/// sends the one-time token to the bot; this repo mints the token and reads
/// status. Offline, it simulates a link so the UI is demoable.
class TelegramRepository {
  TelegramRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;
  bool _offlineLinked = false;

  Future<TelegramLink> status() async {
    if (!_live) {
      return TelegramLink(
        linked: _offlineLinked,
        username: _offlineLinked ? 'demo' : null,
      );
    }
    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const TelegramLink(linked: false);
    final row = await client
        .from('telegram_links')
        .select('username')
        .eq('profile_id', uid)
        .maybeSingle();
    return TelegramLink(
      linked: row != null,
      username: row?['username'] as String?,
    );
  }

  /// Mints a one-time token to send to the bot as `/start <token>`. Offline
  /// simulates an immediate link and returns a demo token.
  Future<String> startLink() async {
    if (!_live) {
      _offlineLinked = true;
      return 'demo-token';
    }
    final res = await _ref
        .read(supabaseClientProvider)
        .rpc('start_telegram_link');
    return '$res';
  }

  Future<void> unlink() async {
    if (!_live) {
      _offlineLinked = false;
      return;
    }
    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    await client.from('telegram_links').delete().eq('profile_id', uid);
  }
}

final telegramRepositoryProvider = Provider<TelegramRepository>(
  (ref) => TelegramRepository(ref),
);

final telegramStatusProvider = FutureProvider<TelegramLink>(
  (ref) => ref.read(telegramRepositoryProvider).status(),
);
