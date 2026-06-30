import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';

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
            Image.asset('assets/icon/splash_logo.png', width: 120, height: 120),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'yolla',
              style: context.text.displayMedium?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
