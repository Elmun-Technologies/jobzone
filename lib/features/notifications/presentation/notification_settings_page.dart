import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../application/notifications_providers.dart';
import '../data/notifications_repository.dart';
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
