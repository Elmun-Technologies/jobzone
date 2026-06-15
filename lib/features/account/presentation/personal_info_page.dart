import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../profile/data/cv_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/edit/widgets/edit_form_scaffold.dart';

/// Edit core identity fields on the profile row (name, phone, location).
class PersonalInfoPage extends ConsumerStatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  ConsumerState<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends ConsumerState<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _city.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(cvRepositoryProvider)
          .savePersonalInfo(
            fullName: _fullName.text.trim(),
            phone: _nullable(_phone.text),
            city: _nullable(_city.text),
            country: _nullable(_country.text),
          );
      ref.invalidate(currentProfileProvider);
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
    final async = ref.watch(currentProfileProvider);

    return async.when(
      loading: () =>
          JzScaffold(title: l.personalInformation, body: const JzLoader()),
      error: (_, _) => JzScaffold(
        title: l.personalInformation,
        body: Center(child: Text(l.errUnknown)),
      ),
      data: (profile) {
        if (!_initialized) {
          _fullName.text = profile?.fullName ?? '';
          _phone.text = profile?.phone ?? '';
          _city.text = profile?.city ?? '';
          _country.text = profile?.country ?? '';
          _initialized = true;
        }
        return EditFormScaffold(
          title: l.personalInformation,
          formKey: _formKey,
          saving: _saving,
          onSave: _save,
          children: [
            JzTextField(
              label: l.fullName,
              controller: _fullName,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.valRequired : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (profile?.email != null) ...[
              JzTextField(
                label: l.email,
                controller: TextEditingController(text: profile!.email),
                prefixIcon: Icons.email_outlined,
                // Email is managed by auth, not editable here.
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            JzTextField(
              label: l.phone,
              controller: _phone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.city,
              controller: _city,
              prefixIcon: Icons.location_city_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.country,
              controller: _country,
              prefixIcon: Icons.public_outlined,
            ),
          ],
        );
      },
    );
  }
}

String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();
