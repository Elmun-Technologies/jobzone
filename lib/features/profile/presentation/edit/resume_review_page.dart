import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/cv_providers.dart';
import '../../data/cv_repository.dart';
import '../../data/profile_repository.dart';
import '../../data/resume_ai_repository.dart';
import '../../domain/cv_models.dart';

/// Shows what the AI read from an uploaded résumé and, on confirm, writes it
/// into the profile (name/headline/bio, skills, experience, education). The
/// user reviews first — nothing is applied until they tap confirm — and every
/// section stays editable afterwards through the normal edit screens.
class ResumeReviewPage extends ConsumerStatefulWidget {
  const ResumeReviewPage({super.key, required this.parsed});

  final ParsedResume parsed;

  @override
  ConsumerState<ResumeReviewPage> createState() => _ResumeReviewPageState();
}

class _ResumeReviewPageState extends ConsumerState<ResumeReviewPage> {
  bool _saving = false;

  Future<void> _apply() async {
    final p = widget.parsed;
    final repo = ref.read(cvRepositoryProvider);
    setState(() => _saving = true);
    try {
      if ((p.fullName?.trim().isNotEmpty ?? false) ||
          (p.headline?.trim().isNotEmpty ?? false) ||
          (p.bio?.trim().isNotEmpty ?? false)) {
        await repo.saveAbout(
          fullName: p.fullName,
          headline: p.headline,
          bio: p.bio,
        );
      }
      if (p.skills.isNotEmpty) {
        final existing = await repo.skills();
        await repo.setSkills([...existing, ...p.skills]);
      }
      for (final e in p.experiences) {
        await repo.saveExperience(
          Experience(
            title: e.title,
            companyName: e.companyName,
            startDate: e.startYear == null ? null : DateTime(e.startYear!),
            endDate: e.endYear == null ? null : DateTime(e.endYear!),
            isCurrent: e.isCurrent,
            description: e.description,
          ),
        );
      }
      for (final ed in p.educations) {
        await repo.saveEducation(
          Education(
            school: ed.school,
            degree: ed.degree,
            field: ed.field,
            startDate: ed.startYear == null ? null : DateTime(ed.startYear!),
            endDate: ed.endYear == null ? null : DateTime(ed.endYear!),
          ),
        );
      }
      ref.invalidate(currentProfileProvider);
      ref.invalidate(skillsControllerProvider);
      ref.invalidate(experiencesControllerProvider);
      ref.invalidate(educationsControllerProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.resumeAutofillDone)),
        );
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final p = widget.parsed;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.resumeReviewTitle),
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
                  Text(
                    l.resumeReviewSubtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if ((p.fullName?.trim().isNotEmpty ?? false) ||
                      (p.headline?.trim().isNotEmpty ?? false))
                    _Card(
                      icon: Icons.badge_outlined,
                      title: l.sectionContact,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.fullName?.trim().isNotEmpty ?? false)
                            Text(
                              p.fullName!,
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (p.headline?.trim().isNotEmpty ?? false)
                            Text(
                              p.headline!,
                              style: context.text.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (p.bio?.trim().isNotEmpty ?? false)
                    _Card(
                      icon: Icons.description_outlined,
                      title: l.sectionAbout,
                      child: Text(
                        p.bio!,
                        style: context.text.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ),
                  if (p.skills.isNotEmpty)
                    _Card(
                      icon: Icons.bolt_outlined,
                      title: l.sectionSkills,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final s in p.skills)
                            Chip(
                              label: Text(s),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  if (p.experiences.isNotEmpty)
                    _Card(
                      icon: Icons.work_outline_rounded,
                      title: l.sectionExperience,
                      child: Column(
                        children: [
                          for (final e in p.experiences)
                            _Line(
                              title: e.title,
                              subtitle: [
                                if (e.companyName?.isNotEmpty ?? false)
                                  e.companyName,
                                _years(
                                  e.startYear,
                                  e.endYear,
                                  e.isCurrent,
                                  l.present,
                                ),
                              ].whereType<String>().join(' · '),
                            ),
                        ],
                      ),
                    ),
                  if (p.educations.isNotEmpty)
                    _Card(
                      icon: Icons.school_outlined,
                      title: l.sectionEducation,
                      child: Column(
                        children: [
                          for (final ed in p.educations)
                            _Line(
                              title: ed.school,
                              subtitle: [
                                if (ed.degree?.isNotEmpty ?? false) ed.degree,
                                if (ed.field?.isNotEmpty ?? false) ed.field,
                                _years(
                                  ed.startYear,
                                  ed.endYear,
                                  false,
                                  l.present,
                                ),
                              ].whereType<String>().join(' · '),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: JzPrimaryButton(
                  label: l.resumeReviewConfirm,
                  loading: _saving,
                  onPressed: _apply,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _years(int? start, int? end, bool current, String present) {
  if (start == null && end == null && !current) return null;
  final to = current ? present : (end?.toString() ?? '');
  final from = start?.toString() ?? '';
  if (from.isEmpty && to.isEmpty) return null;
  return '$from — $to';
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: context.text.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: context.text.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
