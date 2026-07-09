import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../applications/application/applications_controller.dart';
import '../../../profile/data/profile_repository.dart';
import '../../domain/job.dart';

/// One-tap "apply with my profile" action for a job card — no cover letter, no
/// screening form. Mirrors the web QuickApplyButton's gating exactly, so both
/// clients behave the same:
///  - a job with a REQUIRED screening question or that wants a cover letter
///    can't skip the form — routes to the full apply page instead;
///  - an incomplete profile is useless to an employer — routes to Profile;
///  - otherwise applies immediately and flips to a ✓ state (idempotent: a
///    duplicate-apply error is treated as success, not shown as a failure).
class QuickApplyButton extends ConsumerStatefulWidget {
  const QuickApplyButton({super.key, required this.job});

  final Job job;

  @override
  ConsumerState<QuickApplyButton> createState() => _QuickApplyButtonState();
}

class _QuickApplyButtonState extends ConsumerState<QuickApplyButton> {
  bool _pending = false;

  bool get _needsForm =>
      widget.job.requireCoverLetter ||
      widget.job.screeningQuestions.any((q) => q.required);

  Future<void> _onTap() async {
    final l = context.l10n;
    if (_needsForm) {
      context.push(Routes.applyJob(widget.job.id));
      return;
    }
    setState(() => _pending = true);
    try {
      final profile = await ref.read(currentProfileProvider.future);
      final hasResume = (profile?.fullName ?? '').trim().isNotEmpty;
      if (!mounted) return;
      if (!hasResume) {
        setState(() => _pending = false);
        context.push(Routes.profile);
        return;
      }
      await ref
          .read(applicationsControllerProvider.notifier)
          .apply(job: widget.job);
    } on PostgrestException catch (e) {
      // 23505 = unique(job_id, applicant_id) — already applied is a success
      // state here, not an error.
      if (e.code != '23505' && mounted) showErrorSnack(context, l.errUnknown);
    } catch (_) {
      if (mounted) showErrorSnack(context, l.errUnknown);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final applied =
        ref
            .watch(applicationsControllerProvider)
            .value
            ?.any((a) => a.job.id == widget.job.id) ??
        false;

    if (applied) {
      return Semantics(
        label: l.quickApplied,
        child: Icon(Icons.check_circle_rounded, color: colors.primary),
      );
    }

    return Semantics(
      button: true,
      label: l.quickApply,
      child: InkResponse(
        onTap: _pending ? null : _onTap,
        child: _pending
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            : Icon(Icons.bolt_rounded, color: colors.primary),
      ),
    );
  }
}
