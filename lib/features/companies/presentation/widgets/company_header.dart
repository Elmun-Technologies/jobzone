import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../data/company_follow_repository.dart';
import '../../domain/company.dart';

/// Company Details header (Figma): a soft grey bar with back + "Company
/// Details", an overlapping centered logo, the name, industry and website.
class CompanyHeader extends StatelessWidget {
  const CompanyHeader({super.key, required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final topPad = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: colors.surfaceVariant,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            topPad + AppSpacing.md,
            AppSpacing.lg,
            48,
          ),
          child: Row(
            children: [
              JzCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    l.companyDetailsTitle,
                    style: context.text.titleLarge,
                  ),
                ),
              ),
              // Follow / subscribe toggle — a filled bell means "following", so
              // this company's new jobs show up under Подписки.
              _FollowButton(companyId: company.id),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -36),
          child: Column(
            children: [
              _LogoCircle(name: company.name, url: company.logoUrl),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      company.name,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (company.isVerified) ...[
                    const SizedBox(width: AppSpacing.xs),
                    JzTrustBadge(
                      kind: company.verificationMethod == 'licensed_agency'
                          ? JzTrustKind.agency
                          : JzTrustKind.employer,
                    ),
                  ],
                ],
              ),
              if (company.industry != null && company.industry!.isNotEmpty)
                Text(
                  company.industry!,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              if (company.website != null && company.website!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                // Tapping copies the URL (no in-app browser wired) — previously
                // the link-styled row did nothing on tap.
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: company.website!),
                    );
                    if (context.mounted) {
                      showInfoSnack(context, context.l10n.copied);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          company.website!,
                          style: context.text.bodyMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.name, this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final letter = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    return Container(
      height: 84,
      width: 84,
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 4),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (url == null || url!.isEmpty)
          ? Text(
              letter,
              style: context.text.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            )
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              width: 84,
              height: 84,
              errorWidget: (_, _, _) =>
                  const Icon(Icons.business_rounded, color: Colors.white),
            ),
    );
  }
}

/// Bell toggle in the header: subscribes the seeker to a company so its new
/// vacancies surface under Подписки. Filled (volt) while following.
class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final following =
        ref.watch(isFollowingCompanyProvider(companyId)).value ?? false;
    return JzCircleButton(
      icon: following
          ? Icons.notifications_active_rounded
          : Icons.notifications_none_rounded,
      filled: following,
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final message = following
            ? l.companyUnfollowedToast
            : l.companyFollowedToast;
        await ref.read(companyFollowRepositoryProvider).toggle(companyId);
        ref.invalidate(isFollowingCompanyProvider(companyId));
        ref.invalidate(followedCompaniesProvider);
        ref.invalidate(followedCompanyJobsProvider);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }
}
