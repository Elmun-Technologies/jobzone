import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/auth_controller.dart';
import '../util/auth_failure_message.dart';

/// "Or sign in with" divider + Apple / Google circular buttons.
/// Google is wired to Supabase OAuth; Apple sign-in is coming soon.
class AuthSocialRow extends ConsumerWidget {
  const AuthSocialRow({super.key, required this.label});

  final String label;

  Future<void> _google(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    // On web the page redirects on success; only surface failures.
    if (!ok && context.mounted) {
      final err = ref.read(authControllerProvider).error;
      showErrorSnack(
        context,
        err == null
            ? context.l10n.errUnknown
            : authFailureMessage(context, err),
      );
    }
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
            _SocialButton(
              onTap: () => _comingSoon(context),
              child: const Icon(
                Icons.apple,
                color: Color(0xFF1A1A1A),
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
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

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.comingSoon)));
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
