import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../companies/domain/company.dart';
import '../../data/company_admin_repository.dart';

/// The employer's own company profile, with an entry to edit it.
class CompanyManagePage extends ConsumerWidget {
  const CompanyManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(myCompanyProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(l.navCompany, style: context.text.titleLarge),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const JzLoader(),
                error: (_, _) => Center(child: Text(l.errUnknown)),
                data: (company) => company == null
                    ? JzEmptyState(
                        icon: Icons.business_outlined,
                        title: l.noCompanyTitle,
                        message: l.noCompanyBody,
                        action: JzPrimaryButton(
                          label: l.createCompanyTitle,
                          onPressed: () => context.push(Routes.employerOnboard),
                        ),
                      )
                    : _CompanyView(company: company),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyView extends StatelessWidget {
  const _CompanyView({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Row(
          children: [
            _Logo(name: company.name, url: company.logoUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                      ],
                    ],
                  ),
                  if ([
                    company.industry,
                    company.size,
                  ].any((e) => e != null && e.isNotEmpty))
                    Text(
                      [
                        company.industry,
                        company.size,
                      ].where((e) => e != null && e.isNotEmpty).join(' · '),
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () =>
              context.push(Routes.employerCompanyEdit, extra: company),
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            side: BorderSide(color: colors.border),
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(l.editCompanyCta),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ManageRow(
          icon: Icons.people_outline_rounded,
          label: l.managePeopleTitle,
          onTap: () => context.push(Routes.employerCompanyPeople),
        ),
        _ManageRow(
          icon: Icons.photo_library_outlined,
          label: l.manageGalleryTitle,
          onTap: () => context.push(Routes.employerCompanyGallery),
        ),
        if (company.about != null && company.about!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(l.companyAboutLabel, style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            company.about!,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (company.website != null && company.website!.isNotEmpty)
          _InfoRow(icon: Icons.language_rounded, value: company.website!),
        if (company.headquarters != null && company.headquarters!.isNotEmpty)
          _InfoRow(
            icon: Icons.location_on_outlined,
            value: company.headquarters!,
          ),
      ],
    );
  }
}

class _ManageRow extends StatelessWidget {
  const _ManageRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: context.text.bodyLarge)),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(value, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.name, this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final letter = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        letter,
        style: context.text.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
