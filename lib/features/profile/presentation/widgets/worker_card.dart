import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../monetization/domain/promotion.dart';
import '../../domain/user_profile.dart';

/// Compact "how employers see you" card for a blue-collar worker: avatar, name,
/// trust badges, desired pay, availability, location and top skills. Distinct
/// from the full CV — no resume required.
class WorkerCard extends StatelessWidget {
  const WorkerCard({
    super.key,
    required this.profile,
    this.skills = const [],
    this.onVerifyPhone,
  });

  final UserProfile profile;
  final List<String> skills;
  final VoidCallback? onVerifyPhone;

  String? _pay() {
    final min = profile.desiredPayMin;
    final max = profile.desiredPayMax;
    if (min == null && max == null) return null;
    if (profile.desiredPayCurrency == 'UZS') {
      if (min != null && max != null) {
        return '${formatUzs(min)} – ${formatUzs(max)}';
      }
      final one = min ?? max;
      return one == null ? null : formatUzs(one);
    }
    String f(num v) => '\$${v.toStringAsFixed(0)}';
    if (min != null && max != null) return '${f(min)} – ${f(max)}';
    final one = min ?? max;
    return one == null ? null : f(one);
  }

  String? _availability(BuildContext c) => switch (profile.availability) {
    'immediate' => c.l10n.availImmediate,
    'two_weeks' => c.l10n.availTwoWeeks,
    'flexible' => c.l10n.availFlexible,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final name = profile.fullName ?? '';
    final letter = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final pay = _pay();
    final avail = _availability(context);

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
          Text(
            l.workerCardHint,
            style: context.text.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child:
                      (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                      ? ColoredBox(
                          color: colors.primary,
                          child: Center(
                            child: Text(
                              letter,
                              style: context.text.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: profile.avatarUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.workerVerified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const JzTrustBadge(kind: JzTrustKind.worker),
                        ],
                        if (profile.phoneVerified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const JzTrustBadge(kind: JzTrustKind.phone),
                        ],
                      ],
                    ),
                    if (profile.headline != null &&
                        profile.headline!.isNotEmpty)
                      Text(
                        profile.headline!,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (profile.locationText.isNotEmpty)
                      Text(
                        profile.locationText,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (pay != null || avail != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                if (pay != null)
                  _Fact(
                    icon: Icons.payments_outlined,
                    label: l.desiredPay,
                    value: pay,
                  ),
                if (avail != null)
                  _Fact(
                    icon: Icons.event_available_outlined,
                    label: l.availabilityLabel,
                    value: avail,
                  ),
              ],
            ),
          ],
          if (skills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final s in skills.take(6)) _Chip(s)],
            ),
          ],
          if (!profile.phoneVerified && onVerifyPhone != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onVerifyPhone,
                icon: const Icon(Icons.phone_iphone_rounded, size: 18),
                label: Text(l.verifyPhone),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.text.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            Text(
              value,
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label, style: context.text.labelMedium),
    );
  }
}
