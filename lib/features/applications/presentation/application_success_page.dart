import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

class ApplicationSuccessPage extends StatelessWidget {
  const ApplicationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: JzCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.go(Routes.home),
                ),
              ),
              const Spacer(flex: 2),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 64,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l.applicationSentTitle,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.applicationSentBody,
                style: context.text.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              JzPrimaryButton(
                label: l.viewMyApplications,
                onPressed: () => context.go(Routes.accountApplications),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => context.go(Routes.home),
                child: Text(
                  l.cancel,
                  style: context.text.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
