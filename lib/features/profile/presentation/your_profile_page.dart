import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../application/cv_providers.dart';
import '../data/profile_repository.dart';
import '../domain/cv_models.dart';
import '../domain/user_profile.dart';
import 'widgets/worker_card.dart';

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
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(currentProfileProvider),
                ),
                data: (profile) => _ProfileCards(profile: profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _period(DateTime? start, DateTime? end, {bool current = false}) {
  String f(DateTime d) => DateFormat.yMMM().format(d);
  final from = start == null ? '' : f(start);
  final to = current ? 'Present' : (end == null ? '' : f(end));
  if (from.isEmpty && to.isEmpty) return '';
  return '$from - $to';
}

class _ProfileCards extends ConsumerWidget {
  const _ProfileCards({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final p = profile;
    final experiences =
        ref.watch(experiencesControllerProvider).value ?? const [];
    final educations =
        ref.watch(educationsControllerProvider).value ?? const [];
    final projects = ref.watch(projectsControllerProvider).value ?? const [];
    final certs = ref.watch(certificationsControllerProvider).value ?? const [];
    final vols = ref.watch(volunteerControllerProvider).value ?? const [];
    final awards = ref.watch(awardsControllerProvider).value ?? const [];
    final skills =
        ref.watch(skillsControllerProvider).value ?? const <String>[];
    final resumes = ref.watch(resumesControllerProvider).value ?? const [];

    final contactFilled =
        (p?.email?.isNotEmpty ?? false) || (p?.phone?.isNotEmpty ?? false);
    final filled = [
      contactFilled,
      p?.bio?.isNotEmpty ?? false,
      experiences.isNotEmpty,
      educations.isNotEmpty,
      projects.isNotEmpty,
      certs.isNotEmpty,
      vols.isNotEmpty,
      awards.isNotEmpty,
      skills.isNotEmpty,
      resumes.isNotEmpty,
    ].where((b) => b).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        if (p != null) ...[
          WorkerCard(
            profile: p,
            skills: skills,
            onVerifyPhone: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(profileRepositoryProvider).confirmPhone();
                ref.invalidate(currentProfileProvider);
              } catch (_) {
                messenger.showSnackBar(SnackBar(content: Text(l.errUnknown)));
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: filled / 10,
                  minHeight: 6,
                  backgroundColor: colors.surfaceVariant,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '$filled/10',
              style: context.text.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        _SectionCard(
          icon: Icons.person_outline_rounded,
          title: l.sectionContact,
          onEdit: () => context.push(Routes.profileContactInfo),
          child: contactFilled || p?.locationText.isNotEmpty == true
              ? Column(
                  children: [
                    if (p?.locationText.isNotEmpty ?? false)
                      _MetaRow(Icons.location_on_outlined, p!.locationText),
                    if (p?.phone?.isNotEmpty ?? false)
                      _MetaRow(Icons.call_outlined, p!.phone!),
                    if (p?.email?.isNotEmpty ?? false)
                      _MetaRow(Icons.mail_outline_rounded, p!.email!),
                  ],
                )
              : null,
        ),

        _SectionCard(
          icon: Icons.description_outlined,
          title: l.sectionAbout,
          onEdit: () => context.push(Routes.profileAbout),
          child: (p?.bio?.isNotEmpty ?? false)
              ? Text(
                  p!.bio!,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                )
              : null,
        ),

        _SectionCard(
          icon: Icons.work_outline_rounded,
          title: l.sectionExperience,
          onAdd: () => context.push(Routes.profileExperience),
          child: experiences.isEmpty
              ? null
              : _EntryTile(
                  logoText: experiences.first.companyName,
                  title: experiences.first.title,
                  subtitle: experiences.first.companyName,
                  meta: _period(
                    experiences.first.startDate,
                    experiences.first.endDate,
                    current: experiences.first.isCurrent,
                  ),
                  onEdit: () => context.push(Routes.profileExperience),
                ),
        ),

        _SectionCard(
          icon: Icons.school_outlined,
          title: l.sectionEducation,
          onAdd: () => context.push(Routes.profileEducation),
          child: educations.isEmpty
              ? null
              : _EntryTile(
                  logoText: educations.first.school,
                  title: educations.first.degree ?? educations.first.school,
                  subtitle: educations.first.school,
                  meta: _period(
                    educations.first.startDate,
                    educations.first.endDate,
                  ),
                  extra: educations.first.grade == null
                      ? null
                      : '${l.gradeLabel}: ${educations.first.grade}',
                  onEdit: () => context.push(Routes.profileEducation),
                ),
        ),

        _SectionCard(
          icon: Icons.insights_rounded,
          title: l.sectionProjects,
          onAdd: () => context.push(Routes.profileProjects),
          child: projects.isEmpty
              ? null
              : _EntryTile(
                  icon: Icons.work_outline_rounded,
                  title: projects.first.name,
                  subtitle: projects.first.role,
                  meta: _period(
                    projects.first.startDate,
                    projects.first.endDate,
                  ),
                  onEdit: () => context.push(Routes.profileProjects),
                ),
        ),

        _SectionCard(
          icon: Icons.verified_outlined,
          title: l.sectionCertifications,
          onAdd: () => context.push(Routes.profileCertifications),
          child: certs.isEmpty
              ? null
              : _EntryTile(
                  icon: Icons.verified_outlined,
                  title: certs.first.name,
                  subtitle: certs.first.issuer,
                  meta: certs.first.issuedDate == null
                      ? ''
                      : DateFormat.yMMM().format(certs.first.issuedDate!),
                  onEdit: () => context.push(Routes.profileCertifications),
                ),
        ),

        _SectionCard(
          icon: Icons.volunteer_activism_outlined,
          title: l.sectionVolunteer,
          onAdd: () => context.push(Routes.profileVolunteer),
          child: vols.isEmpty
              ? null
              : _EntryTile(
                  icon: Icons.volunteer_activism_outlined,
                  title: vols.first.organization,
                  subtitle: vols.first.role,
                  meta: _period(vols.first.startDate, vols.first.endDate),
                  onEdit: () => context.push(Routes.profileVolunteer),
                ),
        ),

        _SectionCard(
          icon: Icons.emoji_events_outlined,
          title: l.sectionAwards,
          onAdd: () => context.push(Routes.profileAwards),
          child: awards.isEmpty
              ? null
              : _EntryTile(
                  icon: Icons.emoji_events_outlined,
                  title: awards.first.title,
                  subtitle: awards.first.issuer,
                  meta: awards.first.date == null
                      ? ''
                      : DateFormat.yMMM().format(awards.first.date!),
                  onEdit: () => context.push(Routes.profileAwards),
                ),
        ),

        _SectionCard(
          icon: Icons.donut_small_rounded,
          title: l.sectionSkills,
          onEdit: () => context.push(Routes.profileSkills),
          child: skills.isEmpty
              ? null
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final s in skills) _SkillChip(s)],
                ),
        ),

        _SectionCard(
          icon: Icons.description_rounded,
          title: l.sectionResume,
          onChevron: () => context.push(Routes.profileResume),
          child: resumes.isEmpty ? null : _ResumeRow(resume: resumes.first),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    this.child,
    this.onEdit,
    this.onAdd,
    this.onChevron,
  });

  final IconData icon;
  final String title;
  final Widget? child;
  final VoidCallback? onEdit;
  final VoidCallback? onAdd;
  final VoidCallback? onChevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final VoidCallback? action = onEdit ?? onAdd ?? onChevron;
    final IconData actionIcon = onAdd != null
        ? Icons.add_rounded
        : (onChevron != null
              ? Icons.chevron_right_rounded
              : Icons.edit_outlined);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
              Icon(icon, color: colors.primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (action != null)
                GestureDetector(
                  onTap: action,
                  child: Icon(actionIcon, color: colors.primary, size: 20),
                ),
            ],
          ),
          if (child != null) ...[const Divider(height: AppSpacing.lg), child!],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.title,
    this.subtitle,
    this.meta,
    this.extra,
    this.logoText,
    this.icon,
    required this.onEdit,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final String? extra;
  final String? logoText;
  final IconData? icon;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget leading;
    if (logoText != null && logoText!.isNotEmpty) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 44,
          height: 44,
          color: colors.primary,
          alignment: Alignment.center,
          child: Text(
            logoText!.substring(0, 1).toUpperCase(),
            style: context.text.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    } else {
      leading = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.chipBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon ?? Icons.work_outline_rounded, color: colors.primary),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              if (meta != null && meta!.isNotEmpty)
                Text(
                  meta!,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              if (extra != null && extra!.isNotEmpty)
                Text(
                  extra!,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Icon(Icons.edit_outlined, color: colors.primary, size: 18),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);
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

class _ResumeRow extends StatelessWidget {
  const _ResumeRow({required this.resume});
  final Resume resume;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: colors.danger, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume.title,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (resume.sizeText != null)
                  Text(
                    resume.sizeText!,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
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
