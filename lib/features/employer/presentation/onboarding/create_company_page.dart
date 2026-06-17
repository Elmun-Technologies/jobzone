import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/providers/app_flags.dart';

/// Employer onboarding: create the company. This is the employer's equivalent
/// of the seeker preference chain — finishing it marks the profile complete and
/// enters the employer shell. The full company form lands in a later phase; for
/// now it's a single confirmation step so the flow is end-to-end navigable.
class CreateCompanyPage extends ConsumerStatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  ConsumerState<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends ConsumerState<CreateCompanyPage> {
  bool _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(appFlagsProvider.notifier).setProfileComplete(true);
    if (mounted) context.go(Routes.employerDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.chipBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business_center_outlined,
                    size: 40,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l.createCompanyTitle,
                textAlign: TextAlign.center,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.createCompanyBody,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              JzPrimaryButton(
                label: l.continueLabel,
                loading: _saving,
                onPressed: _finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
