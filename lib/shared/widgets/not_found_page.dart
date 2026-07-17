import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../design_system/design_system.dart';
import '../../localization/l10n_extension.dart';

/// Real 404 page shown by `GoRouter.errorBuilder` when a deep link, shared URL,
/// or push-notification tap resolves to a route the app doesn't know about.
/// Previously the router fell back to `PlaceholderPage` ("This screen is part
/// of an upcoming phase") — that read as an intentional stub, not a bad URL.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return JzScaffold(
      appBar: JzAppBar(title: l.notFoundTitle),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: context.colors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.notFoundTitle,
                style: context.text.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.notFoundBody,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              JzButton.primary(
                label: l.backToHome,
                onPressed: () => context.go(Routes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
