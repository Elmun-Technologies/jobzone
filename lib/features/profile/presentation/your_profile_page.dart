import 'package:cached_network_image/cached_network_image.dart';
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
    return JzScaffold(
      title: l.yourProfile,
      body: profileAsync.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
        data: (profile) => profile == null
            ? JzEmptyState(
                icon: Icons.person_outline_rounded,
                title: l.completeProfileTitle,
              )
            : _ProfileView(profile: profile),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            ClipOval(
              child: Container(
                height: 72,
                width: 72,
                color: colors.chipBackground,
                child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                    ? Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: colors.primary,
                      )
                    : CachedNetworkImage(
                        imageUrl: profile.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: colors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.fullName ?? '—', style: context.text.titleLarge),
                  if (profile.headline != null && profile.headline!.isNotEmpty)
                    Text(
                      profile.headline!,
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
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
        if (profile.isOpenToWork) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: colors.success,
              ),
              label: Text(l.openToWork),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (profile.bio != null && profile.bio!.isNotEmpty)
          _Section(
            title: l.sectionAbout,
            onEdit: () => context.push(Routes.profileAbout),
            child: Text(
              profile.bio!,
              style: context.text.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        _Section(
          title: l.sectionExperience,
          onEdit: () => context.push(Routes.profileExperience),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in profile.experiences) _ExperienceTile(entry: e),
              if (profile.experiences.isEmpty)
                _emptyHint(context, l.noEntriesYet),
            ],
          ),
        ),
        _Section(
          title: l.sectionEducation,
          onEdit: () => context.push(Routes.profileEducation),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in profile.educations)
                _LineTile(
                  title: e.school,
                  subtitle: [
                    e.degree,
                    e.period,
                  ].whereType<String>().join(' • '),
                ),
              if (profile.educations.isEmpty)
                _emptyHint(context, l.noEntriesYet),
            ],
          ),
        ),
        _Section(
          title: l.sectionSkills,
          onEdit: () => context.push(Routes.profileSkills),
          child: profile.skills.isEmpty
              ? _emptyHint(context, l.noEntriesYet)
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final s in profile.skills) Chip(label: Text(s)),
                  ],
                ),
        ),
        _Section(
          title: l.sectionContact,
          onEdit: () => context.push(Routes.profileContactInfo),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.email != null)
                _LineTile(title: l.email, subtitle: profile.email!),
              if (profile.phone != null)
                _LineTile(title: l.phone, subtitle: profile.phone!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyHint(BuildContext context, String text) => Text(
    text,
    style: context.text.bodySmall?.copyWith(
      color: context.colors.textSecondary,
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.onEdit});
  final String title;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: context.text.titleMedium),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  const _ExperienceTile({required this.entry});
  final ExperienceEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.title, style: context.text.titleSmall),
          Text(
            [entry.companyName, entry.period].whereType<String>().join(' • '),
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (entry.description != null && entry.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                entry.description!,
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

class _LineTile extends StatelessWidget {
  const _LineTile({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleSmall),
          Text(
            subtitle,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
