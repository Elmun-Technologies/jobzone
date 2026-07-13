import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/config/env.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/providers/app_flags.dart';
import '../../../companies/domain/company.dart';
import '../../../notifications/application/push_providers.dart';
import '../../data/company_admin_repository.dart';

/// The employer's own company profile, with an entry to edit it.
class CompanyManagePage extends ConsumerWidget {
  const CompanyManagePage({super.key});

  /// Confirms, then signs out — mirrors the seeker profile flow so employers
  /// have a logout too (the employer shell has no profile tab).
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l.logout,
              style: c.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.logoutConfirm,
              style: c.text.bodyMedium?.copyWith(color: c.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(c, false),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      side: BorderSide(color: c.colors.border),
                    ),
                    child: Text(l.cancel, style: c.text.titleSmall),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.colors.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    child: Text(
                      l.yesLogout,
                      style: c.text.titleSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (Env.hasSupabase) {
      await ref.read(pushServiceProvider).unregister();
      await ref.read(supabaseClientProvider).auth.signOut();
    }
    await ref.read(appFlagsProvider.notifier).reset();
    if (context.mounted) context.go(Routes.welcome);
  }

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
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Text(l.navCompany, style: context.text.titleLarge),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: l.logOut,
                    onPressed: () => _logout(context, ref),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const JzLoader(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(myCompanyProvider),
                ),
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
        _ManageRow(
          icon: Icons.sell_outlined,
          label: l.tiersTitle,
          onTap: () => context.push(Routes.employerTiers),
        ),
        _ManageRow(
          icon: Icons.bolt_outlined,
          label: l.promotionsTitle,
          onTap: () => context.push(Routes.employerPromotions),
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
