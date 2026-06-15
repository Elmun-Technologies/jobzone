import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';

class InviteFriendsPage extends StatelessWidget {
  const InviteFriendsPage({super.key});

  static const _code = 'JOBZONE-AZIZ';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;

    return JzScaffold(
      title: l.inviteFriends,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                size: 48,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l.inviteHeadline,
            style: context.text.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.inviteBody,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l.yourReferralCode,
            style: context.text.labelLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          DottedCodeBox(code: _code),
          const SizedBox(height: AppSpacing.xl),
          JzPrimaryButton(
            label: l.copyCode,
            icon: Icons.copy_rounded,
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: _code));
              if (context.mounted) showInfoSnack(context, l.codeCopied);
            },
          ),
        ],
      ),
    );
  }
}

class DottedCodeBox extends StatelessWidget {
  const DottedCodeBox({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.primary, width: 1.5),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: context.text.titleMedium?.copyWith(
          color: colors.primary,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
