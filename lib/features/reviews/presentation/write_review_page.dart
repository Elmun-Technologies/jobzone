import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../data/reviews_repository.dart';
import '../domain/review.dart';
import 'widgets/star_rating_input.dart';

/// Write / update a review for a company. Reached from a job's or company's
/// Reviews tab; [companyName] is passed via `extra` for the header.
class WriteReviewPage extends ConsumerStatefulWidget {
  const WriteReviewPage({super.key, required this.companyId, this.companyName});

  final String companyId;
  final String? companyName;

  @override
  ConsumerState<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends ConsumerState<WriteReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _pros = TextEditingController();
  final _cons = TextEditingController();
  final _jobTitle = TextEditingController();
  int _rating = 0;
  bool _currentEmployee = false;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _pros.dispose();
    _cons.dispose();
    _jobTitle.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_rating == 0) {
      showErrorSnack(context, l.ratingRequired);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(reviewsRepositoryProvider)
          .submit(
            CompanyReview(
              companyId: widget.companyId,
              rating: _rating,
              title: _nullable(_title.text),
              body: _nullable(_body.text),
              pros: _nullable(_pros.text),
              cons: _nullable(_cons.text),
              isCurrentEmployee: _currentEmployee,
              jobTitle: _nullable(_jobTitle.text),
            ),
          );
      ref.invalidate(companyReviewsProvider(widget.companyId));
      if (mounted) {
        showInfoSnack(context, l.reviewSubmitted);
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return JzScaffold(
      title: l.writeReviewTitle,
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (widget.companyName != null)
                    Text(
                      widget.companyName!,
                      style: context.text.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l.rateThisCompany,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StarRatingInput(
                    rating: _rating,
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  JzTextField(
                    label: l.reviewTitleLabel,
                    controller: _title,
                    hint: l.reviewTitleHint,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  JzTextField(
                    label: l.reviewBodyLabel,
                    controller: _body,
                    hint: l.reviewBodyHint,
                    maxLines: 5,
                    minLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  JzTextField(
                    label: l.prosLabel,
                    controller: _pros,
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  JzTextField(
                    label: l.consLabel,
                    controller: _cons,
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  JzTextField(
                    label: l.yourJobTitleLabel,
                    controller: _jobTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.currentEmployee),
                    value: _currentEmployee,
                    onChanged: (v) => setState(() => _currentEmployee = v),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: JzPrimaryButton(
                label: l.submitReview,
                loading: _submitting,
                onPressed: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();
