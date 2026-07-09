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
  const QuickApplyButton({super.key, required this.job, this.pill = false});

  final Job job;

  /// When true, renders as a labelled volt "⚡ Apply" pill (used in the job
  /// card footer) instead of the bare bolt icon.
  final bool pill;

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
    final applied =
        ref
            .watch(applicationsControllerProvider)
            .value
            ?.any((a) => a.job.id == widget.job.id) ??
        false;

    final state = applied
        ? _ApplyState.applied
        : (_pending ? _ApplyState.pending : _ApplyState.idle);

    // A single AnimatedSwitcher so every state change (idle → pending →
    // applied) pops in with a scale + fade rather than snapping.
    final child = widget.pill
        ? _buildPill(context, state)
        : _buildIcon(context, state);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (c, a) => ScaleTransition(
        scale: a,
        child: FadeTransition(opacity: a, child: c),
      ),
      child: KeyedSubtree(key: ValueKey(state), child: child),
    );
  }

  Widget _buildIcon(BuildContext context, _ApplyState state) {
    final l = context.l10n;
    final colors = context.colors;
    switch (state) {
      case _ApplyState.applied:
        return Semantics(
          label: l.quickApplied,
          child: Icon(Icons.check_circle_rounded, color: colors.primary),
        );
      case _ApplyState.pending:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        );
      case _ApplyState.idle:
        return Semantics(
          button: true,
          label: l.quickApply,
          child: InkResponse(
            onTap: _onTap,
            child: Icon(Icons.bolt_rounded, color: colors.primary),
          ),
        );
    }
  }

  Widget _buildPill(BuildContext context, _ApplyState state) {
    final l = context.l10n;
    final colors = context.colors;
    const shape = StadiumBorder();

    if (state == _ApplyState.applied) {
      return Semantics(
        label: l.quickApplied,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: ShapeDecoration(
            color: colors.surfaceVariant,
            shape: shape,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 17, color: colors.success),
              const SizedBox(width: 6),
              Text(
                l.quickApplied,
                style: context.text.labelLarge?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pending = state == _ApplyState.pending;
    return Semantics(
      button: true,
      label: l.quickApply,
      child: Material(
        color: colors.gold,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: pending ? null : _onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: pending
                    ? [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onGold,
                          ),
                        ),
                      ]
                    : [
                        Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: colors.onGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l.applyShort,
                          style: context.text.labelLarge?.copyWith(
                            color: colors.onGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ApplyState { idle, pending, applied }
