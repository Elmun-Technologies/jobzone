import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/providers/app_flags.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../notifications/application/push_providers.dart';
import '../data/cv_repository.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// Profile tab — the account hub.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  double _completion(UserProfile? p) {
    if (p == null) return 0;
    final flags = [
      p.fullName?.isNotEmpty ?? false,
      p.bio?.isNotEmpty ?? false,
      p.phone?.isNotEmpty ?? false,
      p.email?.isNotEmpty ?? false,
      p.locationText.isNotEmpty,
      p.experiences.isNotEmpty,
      p.educations.isNotEmpty,
      p.skills.isNotEmpty,
    ];
    return flags.where((b) => b).length / flags.length;
  }

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
      // Drop this device's push token first — RLS needs the uid, which the
      // sign-out clears. No-op when push isn't configured.
      await ref.read(pushServiceProvider).unregister();
      await ref.read(supabaseClientProvider).auth.signOut();
    }
    // Clear per-account onboarding (role + profile-complete) so the next
    // account that signs in starts its own journey from role choice.
    await ref.read(appFlagsProvider.notifier).reset();
    if (context.mounted) context.go(Routes.welcome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(currentProfileProvider).value;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(child: Text(l.navProfile, style: context.text.titleLarge)),
            const SizedBox(height: AppSpacing.lg),
            _ProfileCard(
              name: profile?.fullName ?? '—',
              completion: _completion(profile),
              onTap: () => context.push(Routes.yourProfile),
            ),
            const SizedBox(height: AppSpacing.md),
            if (profile != null)
              _OpenToWorkTile(
                key: ValueKey(profile.isOpenToWork),
                value: profile.isOpenToWork,
              ),
            if (_completion(profile) < 1.0) ...[
              const SizedBox(height: AppSpacing.sm),
              _ProfileNudge(onTap: () => context.push(Routes.yourProfile)),
            ],
            const SizedBox(height: AppSpacing.lg),
            _MenuTile(
              icon: Icons.person_outline_rounded,
              label: l.personalInformation,
              onTap: () => context.push(Routes.accountPersonalInfo),
            ),
            _MenuTile(
              icon: Icons.description_outlined,
              label: l.sectionResume,
              onTap: () => context.push(Routes.resumeHome),
            ),
            _MenuTile(
              icon: Icons.insights_rounded,
              label: l.analytics,
              onTap: () => context.push(Routes.accountAnalytics),
            ),
            _MenuTile(
              icon: Icons.assignment_outlined,
              label: l.myApplications,
              onTap: () => context.push(Routes.accountApplications),
            ),
            _MenuTile(
              icon: Icons.remove_red_eye_outlined,
              label: l.jobSeekingStatus,
              onTap: () => context.push(Routes.accountSeekingStatus),
            ),
            _MenuTile(
              icon: Icons.notifications_none_rounded,
              label: l.subscriptions,
              onTap: () => context.push(Routes.subscriptions),
            ),
            _MenuTile(
              icon: Icons.bookmark_border_rounded,
              label: l.savedSearches,
              onTap: () => context.push(Routes.savedSearches),
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              label: l.settings,
              onTap: () => context.push(Routes.accountSettings),
            ),
            _MenuTile(
              icon: Icons.language_rounded,
              label: l.language,
              onTap: () => context.push(Routes.accountLanguage),
            ),
            _MenuTile(
              icon: Icons.help_outline_rounded,
              label: l.helpCenter,
              onTap: () => context.push(Routes.accountHelp),
            ),
            _MenuTile(
              icon: Icons.lock_outline_rounded,
              label: l.privacyPolicy,
              onTap: () => context.push(Routes.accountPrivacy),
            ),
            _MenuTile(
              icon: Icons.person_add_alt_1_outlined,
              label: l.inviteFriends,
              onTap: () => context.push(Routes.accountInvite),
            ),
            _MenuTile(
              icon: Icons.logout_rounded,
              label: l.logOut,
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.completion,
    required this.onTap,
  });
  final String name;
  final double completion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: context.text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      context.l10n.viewProfile,
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: completion,
                      strokeWidth: 4,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(colors.gold),
                    ),
                    Text(
                      '${(completion * 100).round()}%',
                      style: context.text.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prominent open-to-work visibility toggle (LinkedIn-style "hiring employers
/// can find you"). Persists `is_open_to_work` via cvRepository; optimistic with
/// rollback on failure. Keyed to the profile value so it resyncs on refresh.
class _OpenToWorkTile extends ConsumerStatefulWidget {
  const _OpenToWorkTile({super.key, required this.value});
  final bool value;

  @override
  ConsumerState<_OpenToWorkTile> createState() => _OpenToWorkTileState();
}

class _OpenToWorkTileState extends ConsumerState<_OpenToWorkTile> {
  late bool _on = widget.value;

  Future<void> _toggle(bool v) async {
    setState(() => _on = v);
    try {
      await ref.read(cvRepositoryProvider).setOpenToWork(v);
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _on = !v);
      showErrorSnack(context, localizedError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            _on ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: _on ? colors.primary : colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.openToWork,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l.openToWorkHint,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: _on, onChanged: _toggle),
        ],
      ),
    );
  }
}

/// Tappable "complete your profile" nudge shown while the profile is < 100%.
class _ProfileNudge extends StatelessWidget {
  const _ProfileNudge({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.chipBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: colors.primary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(l.profileNudge, style: context.text.bodySmall),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Text(label, style: context.text.bodyLarge)),
            Icon(Icons.chevron_right_rounded, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
