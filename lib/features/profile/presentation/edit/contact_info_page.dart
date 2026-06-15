import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/cv_providers.dart';
import '../../data/cv_repository.dart';
import '../../domain/cv_models.dart';
import 'widgets/edit_form_scaffold.dart';

class ContactInfoPage extends ConsumerStatefulWidget {
  const ContactInfoPage({super.key});

  @override
  ConsumerState<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends ConsumerState<ContactInfoPage> {
  final _website = TextEditingController();
  final _linkedin = TextEditingController();
  final _github = TextEditingController();
  final _telegram = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _website.dispose();
    _linkedin.dispose();
    _github.dispose();
    _telegram.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(cvRepositoryProvider)
          .saveContactInfo(
            ContactInfo(
              website: _nullable(_website.text),
              linkedin: _nullable(_linkedin.text),
              github: _nullable(_github.text),
              telegram: _nullable(_telegram.text),
              address: _nullable(_address.text),
            ),
          );
      ref.invalidate(contactInfoProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(contactInfoProvider);

    return async.when(
      loading: () =>
          JzScaffold(title: l.sectionContact, body: const JzLoader()),
      error: (_, _) => JzScaffold(
        title: l.sectionContact,
        body: Center(child: Text(l.errUnknown)),
      ),
      data: (info) {
        if (!_initialized) {
          _website.text = info.website ?? '';
          _linkedin.text = info.linkedin ?? '';
          _github.text = info.github ?? '';
          _telegram.text = info.telegram ?? '';
          _address.text = info.address ?? '';
          _initialized = true;
        }
        return EditFormScaffold(
          title: l.sectionContact,
          saving: _saving,
          onSave: _save,
          children: [
            JzTextField(
              label: l.websiteLabel,
              controller: _website,
              keyboardType: TextInputType.url,
              prefixIcon: Icons.language_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.linkedinLabel,
              controller: _linkedin,
              prefixIcon: Icons.work_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.githubLabel,
              controller: _github,
              prefixIcon: Icons.code_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.telegramLabel,
              controller: _telegram,
              prefixIcon: Icons.send_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.addressLabel,
              controller: _address,
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
            ),
          ],
        );
      },
    );
  }
}

String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();
