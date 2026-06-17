import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

class YourProfilePage extends ConsumerWidget {
  const YourProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.yourProfile),
            ),
            Expanded(
              child: profileAsync.when(
                loading: () => const JzLoader(),
                error: (_, _) => Center(child: Text(l.errUnknown)),
                data: (profile) => _Hub(profile: profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  const _Section(this.icon, this.label, this.route, this.done);
  final IconData icon;
  final String label;
  final String route;
  final bool done;
}

class _Hub extends StatelessWidget {
  const _Hub({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final p = profile;
    final sections = <_Section>[
      _Section(
        Icons.person_outline_rounded,
        l.sectionContact,
        Routes.profileContactInfo,
        (p?.email?.isNotEmpty ?? false) || (p?.phone?.isNotEmpty ?? false),
      ),
      _Section(
        Icons.description_outlined,
        l.sectionAbout,
        Routes.profileAbout,
        p?.bio?.isNotEmpty ?? false,
      ),
      _Section(
        Icons.work_outline_rounded,
        l.sectionExperience,
        Routes.profileExperience,
        p?.experiences.isNotEmpty ?? false,
      ),
      _Section(
        Icons.school_outlined,
        l.sectionEducation,
        Routes.profileEducation,
        p?.educations.isNotEmpty ?? false,
      ),
      _Section(
        Icons.insights_rounded,
        l.sectionProjects,
        Routes.profileProjects,
        false,
      ),
      _Section(
        Icons.verified_outlined,
        l.sectionCertifications,
        Routes.profileCertifications,
        false,
      ),
      _Section(
        Icons.volunteer_activism_outlined,
        l.sectionVolunteer,
        Routes.profileVolunteer,
        false,
      ),
      _Section(
        Icons.emoji_events_outlined,
        l.sectionAwards,
        Routes.profileAwards,
        false,
      ),
      _Section(
        Icons.donut_small_rounded,
        l.sectionSkills,
        Routes.profileSkills,
        p?.skills.isNotEmpty ?? false,
      ),
      _Section(
        Icons.description_rounded,
        l.sectionResume,
        Routes.profileResume,
        false,
      ),
    ];
    final completed = sections.where((s) => s.done).length;

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
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: completed / sections.length,
                  minHeight: 6,
                  backgroundColor: colors.surfaceVariant,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '$completed/${sections.length}',
              style: context.text.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final s in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _SectionCard(section: s),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final _Section section;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(section.route),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(section.icon, color: colors.primary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  section.label,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (section.done)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: colors.onPrimary,
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
