import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/auth_controller.dart';
import '../util/auth_failure_message.dart';

/// "Or sign in with" divider + Google (and, on Apple platforms, Apple).
///
/// Both providers dispatch through Supabase Auth: Google via browser OAuth,
/// Apple via native SIWA on iOS/macOS.
///
/// The Apple button is **iOS/macOS-only**. On Android it was pure noise — a
/// sign-in method most users there can't complete — so it's hidden. It must
/// keep rendering on Apple platforms for as long as any other social provider
/// is offered: App Store Review Guideline 4.8 makes Sign in with Apple
/// mandatory there, and dropping it is a rejection at review.
class AuthSocialRow extends ConsumerWidget {
  const AuthSocialRow({super.key, required this.label});

  final String label;

  /// Sign in with Apple only makes sense — and is only mandated — on Apple
  /// platforms. See the class doc for why it must NOT be dropped there.
  static bool get _showApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> _google(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    // The analyzer's use_build_context_synchronously lint can't see through
    // a helper — the mounted guard has to live at the same statement level
    // as the await for the check to satisfy it, so we inline it here.
    if (!context.mounted) return;
    _surfaceIfFailed(context, ref, ok);
  }

  Future<void> _apple(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithApple();
    if (!context.mounted) return;
    _surfaceIfFailed(context, ref, ok);
  }

  void _surfaceIfFailed(BuildContext context, WidgetRef ref, bool ok) {
    // On web the page redirects on success; only surface failures. Callers
    // above have already checked context.mounted at the await boundary.
    if (ok) return;
    final err = ref.read(authControllerProvider).error;
    showErrorSnack(
      context,
      err == null ? context.l10n.errUnknown : authFailureMessage(context, err),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: colors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                label,
                style: context.text.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: colors.border)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showApple) ...[
              _SocialButton(
                onTap: () => _apple(context, ref),
                child: const Icon(
                  Icons.apple,
                  color: Color(0xFF1A1A1A),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            _SocialButton(
              onTap: () => _google(context, ref),
              child: Text(
                'G',
                style: context.text.titleLarge?.copyWith(
                  color: const Color(0xFF4285F4),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: child,
      ),
    );
  }
}
