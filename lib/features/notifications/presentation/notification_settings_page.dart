import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../application/notifications_providers.dart';
import '../data/notifications_repository.dart';
import '../domain/notification.dart';

/// Toggle per-channel push / email notification preferences.
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

    return JzScaffold(
      title: l.notificationSettings,
      body: async.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
        data: (loaded) {
          final s = _settings ??= loaded;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: [
              _SectionLabel(l.pushNotifications),
              _Toggle(
                title: l.notifMessages,
                value: s.pushMessages,
                onChanged: (v) => _update(s.copyWith(pushMessages: v)),
              ),
              _Toggle(
                title: l.notifApplications,
                value: s.pushApplication,
                onChanged: (v) => _update(s.copyWith(pushApplication: v)),
              ),
              _Toggle(
                title: l.notifJobMatches,
                value: s.pushJobMatch,
                onChanged: (v) => _update(s.copyWith(pushJobMatch: v)),
              ),
              _Toggle(
                title: l.notifReviews,
                value: s.pushReviews,
                onChanged: (v) => _update(s.copyWith(pushReviews: v)),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionLabel(l.emailNotifications),
              _Toggle(
                title: l.notifMessages,
                value: s.emailMessages,
                onChanged: (v) => _update(s.copyWith(emailMessages: v)),
              ),
              _Toggle(
                title: l.notifApplications,
                value: s.emailApplication,
                onChanged: (v) => _update(s.copyWith(emailApplication: v)),
              ),
              _Toggle(
                title: l.notifJobMatches,
                value: s.emailJobMatch,
                onChanged: (v) => _update(s.copyWith(emailJobMatch: v)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: context.text.labelLarge?.copyWith(color: context.colors.primary),
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
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      title: Text(title, style: context.text.bodyLarge),
      value: value,
      onChanged: onChanged,
    );
  }
}
