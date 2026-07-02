import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../auth/application/session_flags.dart';

/// Branded splash. While the brand frame shows, the router flags are hydrated
/// from the restored session's profile, so the first hop lands right — a
/// returning account goes straight to its shell instead of re-onboarding.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([
      hydrateSessionFlags(ref), // no-op offline / signed out
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (mounted) context.go(Routes.welcome);
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
