import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../data/reviews_repository.dart';
import '../domain/review.dart';

/// Write a review for a company. Reached from a job's or company's Reviews tab;
/// [companyName] is passed via `extra` for the header.
class WriteReviewPage extends ConsumerStatefulWidget {
  const WriteReviewPage({super.key, required this.companyId, this.companyName});

  final String companyId;
  final String? companyName;

  @override
  ConsumerState<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends ConsumerState<WriteReviewPage> {
  final _body = TextEditingController();
  int _rating = 5;
  int _photos = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final imgs = await ImagePicker().pickMultiImage();
    if (imgs.isNotEmpty) setState(() => _photos += imgs.length);
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_rating == 0) {
      showErrorSnack(context, l.ratingRequired);
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(reviewsRepositoryProvider)
          .submit(
            CompanyReview(
              companyId: widget.companyId,
              rating: _rating,
              body: _body.text.trim().isEmpty ? null : _body.text.trim(),
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
    final name = widget.companyName ?? '';
    final letter = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.writeReviewTitle),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: colors.primary,
                          child: Text(
                            letter,
                            style: context.text.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (name.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            name,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(color: colors.border),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l.rateThisCompany,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          onPressed: () => setState(() => _rating = i),
                          icon: Icon(
                            Icons.star_rounded,
                            size: 40,
                            color: i <= _rating
                                ? const Color(0xFFFFC629)
                                : colors.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(color: colors.border),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l.addDetailedReview, style: context.text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  JzTextField(
                    controller: _body,
                    hint: l.reviewBodyHint,
                    maxLines: 5,
                    minLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _pickPhotos,
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: colors.primary,
                        size: 20,
                      ),
                      label: Text(
                        _photos == 0 ? l.addPhoto : '$_photos',
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzPrimaryButton(
                label: l.submit,
                loading: _submitting,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
