import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

/// Branded splash. In the Auth phase this will await the restored session and
/// route to welcome / onboarding / home accordingly.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) context.go(Routes.welcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.onPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconsaxPlusBold.briefcase,
                size: 48,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.appTitle,
              style: context.text.displayMedium?.copyWith(
                color: colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
