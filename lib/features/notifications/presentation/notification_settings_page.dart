import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../application/notifications_providers.dart';
import '../data/notifications_repository.dart';
import '../data/telegram_repository.dart';
import '../domain/notification.dart';

/// Toggle notification preferences. The design's five switches map onto the
/// existing [NotificationSettings] channels.
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  NotificationSettings? _settings;

  Future<void> _update(NotificationSettings next) async {
    setState(() => _settings = next);
    try {
      await ref.read(notificationsRepositoryProvider).saveSettings(next);
      ref.invalidate(notificationSettingsProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
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
                error: (_, _) => Center(child: Text(l.errUnknown)),
                data: (loaded) {
                  final s = _settings ??= loaded;
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    children: [
                      _Toggle(
                        title: l.notifGeneral,
                        value: s.pushMessages,
                        onChanged: (v) => _update(s.copyWith(pushMessages: v)),
                      ),
                      _Toggle(
                        title: l.notifJobAvailable,
                        value: s.pushJobMatch,
                        onChanged: (v) => _update(s.copyWith(pushJobMatch: v)),
                      ),
                      _Toggle(
                        title: l.notifJobInvitation,
                        value: s.pushApplication,
                        onChanged: (v) =>
                            _update(s.copyWith(pushApplication: v)),
                      ),
                      _Toggle(
                        title: l.notifAppUpdates,
                        value: s.pushReviews,
                        onChanged: (v) => _update(s.copyWith(pushReviews: v)),
                      ),
                      _Toggle(
                        title: l.notifJobStatus,
                        value: s.emailApplication,
                        onChanged: (v) =>
                            _update(s.copyWith(emailApplication: v)),
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

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.bodyLarge)),
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
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${l.telegramSendToken}: /start $token'),
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
