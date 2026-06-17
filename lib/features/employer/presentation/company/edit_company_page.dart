import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../companies/domain/company.dart';
import '../../data/company_admin_repository.dart';

/// Edit the employer's company profile.
class EditCompanyPage extends ConsumerStatefulWidget {
  const EditCompanyPage({super.key, required this.company});

  final Company company;

  @override
  ConsumerState<EditCompanyPage> createState() => _EditCompanyPageState();
}

class _EditCompanyPageState extends ConsumerState<EditCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.company.name);
  late final _industry = TextEditingController(text: widget.company.industry);
  late final _about = TextEditingController(text: widget.company.about);
  late final _website = TextEditingController(text: widget.company.website);
  late final _hq = TextEditingController(text: widget.company.headquarters);
  late String? _size = widget.company.size;
  bool _saving = false;

  static const _sizes = ['1–10', '11–50', '51–200', '201–500', '500+'];

  @override
  void dispose() {
    _name.dispose();
    _industry.dispose();
    _about.dispose();
    _website.dispose();
    _hq.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(companyAdminRepositoryProvider)
          .updateCompany(
            widget.company.copyWith(
              name: _name.text.trim(),
              industry: _industry.text.trim(),
              size: _size,
              about: _about.text.trim(),
              website: _website.text.trim(),
              headquarters: _hq.text.trim(),
            ),
          );
      ref.invalidate(myCompanyProvider);
      if (mounted) {
        showInfoSnack(context, context.l10n.companySavedToast);
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.editCompanyCta),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  children: [
                    JzTextField(
                      label: l.companyNameLabel,
                      controller: _name,
                      validator: (v) =>
                          Validators.isNotBlank(v) ? null : l.valRequired,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(
                      label: l.companyIndustryLabel,
                      controller: _industry,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.companySizeLabel,
                          style: context.text.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          initialValue: _sizes.contains(_size) ? _size : null,
                          isExpanded: true,
                          hint: Text(l.selectOption),
                          items: [
                            for (final s in _sizes)
                              DropdownMenuItem(value: s, child: Text(s)),
                          ],
                          onChanged: (v) => setState(() => _size = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(
                      label: l.companyAboutLabel,
                      controller: _about,
                      maxLines: 4,
                      minLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(
                      label: l.websiteLabel,
                      controller: _website,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(label: l.companyHqLabel, controller: _hq),
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
                  label: l.saveChanges,
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
