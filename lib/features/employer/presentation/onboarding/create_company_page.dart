import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/providers/app_flags.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../data/company_admin_repository.dart';

/// Employer onboarding: create the company. Finishing it persists the company
/// (via [CompanyAdminRepository]), marks the profile complete and enters the
/// employer shell — the employer's equivalent of the seeker preference chain.
class CreateCompanyPage extends ConsumerStatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  ConsumerState<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends ConsumerState<CreateCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _industry = TextEditingController();
  final _about = TextEditingController();
  final _website = TextEditingController();
  final _hq = TextEditingController();
  String? _size;
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

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(companyAdminRepositoryProvider)
          .createCompany(
            name: _name.text.trim(),
            industry: _industry.text.trim(),
            size: _size,
            about: _about.text.trim(),
            website: _website.text.trim(),
            headquarters: _hq.text.trim(),
          );
      await ref.read(appFlagsProvider.notifier).setProfileComplete(true);
      ref.invalidate(myCompanyProvider);
      if (mounted) context.go(Routes.employerDashboard);
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.chipBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.business_center_outlined,
                          size: 34,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l.createCompanyTitle,
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l.createCompanyBody,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                          initialValue: _size,
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
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: JzPrimaryButton(
                  label: l.continueLabel,
                  loading: _saving,
                  onPressed: _finish,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
