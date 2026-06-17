import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../applications/application/applications_controller.dart';

/// Activity dashboard. Profile-view metrics and viewers are sample data (not
/// tracked client-side); Applied Jobs reflects the real application count.
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  static const _bars = <(String, int)>[
    ('SUN', 12),
    ('MON', 16),
    ('TUE', 32),
    ('WED', 20),
    ('THU', 14),
    ('FRI', 36),
    ('SAT', 10),
  ];
  static const _viewers = <(String, String, String)>[
    ('Leslie Alexander', 'HR - ByteCraft Solutions', '1h ago'),
    ('Dianne Russell', 'HR - QuantumLogic Tec', '7d ago'),
    ('Theresa Webb', 'HR - CodeVortex Systems', '1m ago'),
    ('Arlene McCoy', 'HR - DataWave Solutions', '2m ago'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final applied =
        ref.watch(applicationsControllerProvider).value?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.analytics),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.profileView,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l.last7Days,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ChartCard(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '40',
                          label: l.searchAppearances,
                          trend: '32%',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          value: '$applied',
                          label: l.appliedJobs,
                          trend: '52%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l.profileViewers,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final v in _viewers)
                    _ViewerTile(name: v.$1, role: v.$2, time: v.$3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxV = AnalyticsPage._bars
        .map((b) => b.$2)
        .reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '64 ',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    context.l10n.profileViewers,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '23%',
                    style: context.text.labelLarge?.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.trending_up_rounded,
                    size: 16,
                    color: colors.success,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final b in AnalyticsPage._bars)
                  Expanded(
                    child: _Bar(
                      label: b.$1,
                      value: b.$2,
                      maxValue: maxV,
                      highlight: b.$1 == 'TUE',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.highlight,
  });
  final String label;
  final int value;
  final int maxValue;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (highlight)
          Text(
            '$value',
            style: context.text.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: 18,
          height: (value / maxValue) * 110,
          decoration: BoxDecoration(
            color: highlight ? colors.primary : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: highlight ? colors.primary : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.trend,
  });
  final String value;
  final String label;
  final String trend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                value,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                trend,
                style: context.text.labelSmall?.copyWith(
                  color: colors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.trending_up_rounded, size: 14, color: colors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerTile extends StatelessWidget {
  const _ViewerTile({
    required this.name,
    required this.role,
    required this.time,
  });
  final String name;
  final String role;
  final String time;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colors.surfaceVariant,
            child: Icon(Icons.person_rounded, color: colors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  role,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: context.text.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
