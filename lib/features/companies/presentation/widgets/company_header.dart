import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/company.dart';

/// Cover + logo + name header shown atop the Company Details screen.
class CompanyHeader extends StatelessWidget {
  const CompanyHeader({super.key, required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          width: double.infinity,
          child: (company.coverUrl == null || company.coverUrl!.isEmpty)
              ? Container(color: colors.surfaceVariant)
              : CachedNetworkImage(
                  imageUrl: company.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) =>
                      Container(color: colors.surfaceVariant),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -24),
                child: _Logo(url: company.logoUrl),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      company.name,
                      style: context.text.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (company.isVerified) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.verified_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                  ],
                ],
              ),
              if (company.industry != null || company.headquarters != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    [
                      company.industry,
                      company.headquarters,
                    ].where((e) => e != null && e.isNotEmpty).join(' • '),
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fallback = Icon(Icons.business_rounded, color: colors.primary);
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md - 2),
        child: (url == null || url!.isEmpty)
            ? fallback
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
