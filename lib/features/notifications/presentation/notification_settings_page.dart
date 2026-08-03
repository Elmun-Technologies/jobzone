import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../application/notifications_providers.dart';
import '../data/notifications_repository.dart';
import '../data/telegram_repository.dart';
import '../domain/notification.dart';

/// Toggle notification preferences: which categories reach the phone (push /
/// Telegram) and which reach the inbox. Each switch maps to one
/// [NotificationSettings] column, and the two channels are independent — the
/// backend reads `push_*` and `email_*` separately (0084).
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  // Optimistic overlay on top of the provider value, reconciled with the
  // reloaded server value after every save (or reverted on failure) — never
  // left stuck on a stale local copy, unlike the previous `_settings ??=`
  // pattern which cached the first load forever and ignored later reloads.
  NotificationSettings? _settings;

  Future<void> _update(NotificationSettings next) async {
    final previous = _settings;
    setState(() => _settings = next);
    try {
      await ref.read(notificationsRepositoryProvider).saveSettings(next);
      ref.invalidate(notificationSettingsProvider);
      final reloaded = await ref.read(notificationSettingsProvider.future);
      if (mounted) setState(() => _settings = reloaded);
    } catch (e) {
      if (mounted) {
        setState(() => _settings = previous);
        showErrorSnack(context, localizedError(context, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(notificationSettingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.notificationSettings),
            ),
            Expanded(
              child: async.when(
                loading: () => const JzLoader(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(notificationSettingsProvider),
                ),
                data: (loaded) {
                  final s = _settings ?? loaded;
                  // Two independent channels, grouped by the category the user
                  // actually thinks in: the same "new jobs" row appears under
                  // both, because switching push off must not silence the
                  // email digest (and vice versa) — that's how the backend
                  // reads them too.
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    children: [
                      _SectionHeader(title: l.pushNotifications),
                      _Toggle(
                        title: l.notifJobMatches,
                        value: s.pushJobMatch,
                        onChanged: (v) => _update(s.copyWith(pushJobMatch: v)),
                      ),
                      _Toggle(
                        title: l.notifApplications,
                        value: s.pushApplication,
                        onChanged: (v) =>
                            _update(s.copyWith(pushApplication: v)),
                      ),
                      _Toggle(
                        title: l.notifMessages,
                        value: s.pushMessages,
                        onChanged: (v) => _update(s.copyWith(pushMessages: v)),
                      ),
                      _Toggle(
                        title: l.notifReviews,
                        value: s.pushReviews,
                        onChanged: (v) => _update(s.copyWith(pushReviews: v)),
                      ),
                      const Divider(height: AppSpacing.xl),
                      _SectionHeader(title: l.emailNotifications),
                      _Toggle(
                        title: l.notifJobMatches,
                        subtitle: l.notifEmailDigestHint,
                        value: s.emailJobMatch,
                        onChanged: (v) => _update(s.copyWith(emailJobMatch: v)),
                      ),
                      _Toggle(
                        title: l.notifApplications,
                        value: s.emailApplication,
                        onChanged: (v) =>
                            _update(s.copyWith(emailApplication: v)),
                      ),
                      _Toggle(
                        title: l.notifMessages,
                        value: s.emailMessages,
                        onChanged: (v) => _update(s.copyWith(emailMessages: v)),
                      ),
                      _Toggle(
                        title: l.notifReviews,
                        value: s.emailReviews,
                        onChanged: (v) => _update(s.copyWith(emailReviews: v)),
                      ),
                      _Toggle(
                        title: l.notifEmailMarketing,
                        subtitle: l.notifEmailMarketingHint,
                        value: s.emailMarketing,
                        onChanged: (v) =>
                            _update(s.copyWith(emailMarketing: v)),
                      ),
                      const Divider(height: AppSpacing.xl),
                      const _TelegramTile(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Groups the switches by delivery channel (push vs email).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.bodyLarge),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Connect/disconnect Telegram so notifications can also be delivered there.
class _TelegramTile extends ConsumerWidget {
  const _TelegramTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final status = ref.watch(telegramStatusProvider).value;
    final linked = status?.linked ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.send_rounded, color: colors.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.connectTelegram, style: context.text.bodyLarge),
                Text(
                  linked
                      ? (status?.username != null
                            ? '@${status!.username}'
                            : l.telegramConnected)
                      : l.telegramHint,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (linked)
            TextButton(
              onPressed: () async {
                await ref.read(telegramRepositoryProvider).unlink();
                ref.invalidate(telegramStatusProvider);
              },
              child: Text(l.telegramDisconnect),
            )
          else
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final token = await ref
                    .read(telegramRepositoryProvider)
                    .startLink();
                ref.invalidate(telegramStatusProvider);
                // With a bot username configured this is a one-tap t.me deep
                // link; otherwise the raw /start command. Copied so the user
                // can paste it straight into the bot chat.
                final bot = Env.telegramBot;
                final link = bot.isEmpty
                    ? '/start $token'
                    : 'https://t.me/$bot?start=$token';
                await Clipboard.setData(ClipboardData(text: link));
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l.telegramSendToken}: $link  (${l.copied})',
                    ),
                  ),
                );
              },
              child: Text(l.telegramConnectCta),
            ),
        ],
      ),
    );
  }
}
