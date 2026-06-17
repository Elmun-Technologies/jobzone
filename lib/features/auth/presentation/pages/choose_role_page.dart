import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/enums/enums.dart';
import '../../application/role_controller.dart';
import '../widgets/auth_header.dart';

/// Sits between Verify and Complete Profile during signup: the user picks
/// whether they're a job seeker or an employer. The choice is persisted to
/// [AppFlags] (read synchronously by the router) and to `profiles.role` when a
/// backend is configured.
class ChooseRolePage extends ConsumerStatefulWidget {
  const ChooseRolePage({super.key});

  @override
  ConsumerState<ChooseRolePage> createState() => _ChooseRolePageState();
}

class _ChooseRolePageState extends ConsumerState<ChooseRolePage> {
  UserRole? _selected;
  bool _saving = false;

  Future<void> _continue() async {
    final role = _selected;
    if (role == null) return;
    setState(() => _saving = true);
    try {
      await applyRole(ref, role);
      if (mounted) context.push(Routes.completeProfile);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: l.roleChooseTitle,
                subtitle: l.roleChooseSubtitle,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _RoleCard(
                icon: Icons.work_outline_rounded,
                title: l.roleSeekerTitle,
                description: l.roleSeekerDesc,
                selected: _selected == UserRole.jobSeeker,
                onTap: () => setState(() => _selected = UserRole.jobSeeker),
              ),
              const SizedBox(height: AppSpacing.lg),
              _RoleCard(
                icon: Icons.business_center_outlined,
                title: l.roleEmployerTitle,
                description: l.roleEmployerDesc,
                selected: _selected == UserRole.employer,
                onTap: () => setState(() => _selected = UserRole.employer),
              ),
              const Spacer(),
              JzPrimaryButton(
                label: l.continueLabel,
                loading: _saving,
                onPressed: _selected == null ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.chipBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: colors.primary),
              ),
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
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              JzRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}
