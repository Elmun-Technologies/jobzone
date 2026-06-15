import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../application/applications_controller.dart';
import '../domain/application.dart';
import 'my_applications_page.dart' show StatusPill, formatDate;
import 'util/status_label.dart';

class ApplicationStatusPage extends ConsumerWidget {
  const ApplicationStatusPage({super.key, required this.application});
  final Application? application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final app = application;
    if (app == null) {
      return JzScaffold(
        title: l.applicationStatusTitle,
        body: JzEmptyState(
          icon: Icons.description_outlined,
          title: l.noApplicationsTitle,
        ),
      );
    }

    final historyAsync = ref.watch(statusHistoryProvider(app.id));
    return JzScaffold(
      title: l.applicationStatusTitle,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(app.job.title, style: context.text.titleLarge),
          Text(
            app.job.companyName,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusPill(status: app.status),
          ),
          const SizedBox(height: AppSpacing.xl),
          historyAsync.when(
            loading: () => const JzLoader(),
            error: (_, _) => Text(l.errUnknown),
            data: (events) => Column(
              children: [
                for (var i = 0; i < events.length; i++)
                  _TimelineTile(
                    event: events[i],
                    isLast: i == events.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});
  final StatusEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = applicationStatusColor(context, event.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 14,
                width: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: colors.border)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    applicationStatusLabel(context, event.status),
                    style: context.text.titleSmall,
                  ),
                  Text(
                    formatDate(event.changedAt),
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (event.note != null && event.note!.isNotEmpty)
                    Text(
                      event.note!,
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
