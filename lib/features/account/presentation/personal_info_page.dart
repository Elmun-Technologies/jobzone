import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/options/option_lists.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../profile/data/cv_repository.dart';
import '../../profile/data/profile_repository.dart';

class PersonalInfoPage extends ConsumerStatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  ConsumerState<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends ConsumerState<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String? _gender;
  String? _position;
  Uint8List? _avatar;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _avatar = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(cvRepositoryProvider)
          .savePersonalInfo(
            fullName: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          );
      ref.invalidate(currentProfileProvider);
      if (mounted) context.pop();
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
    final async = ref.watch(currentProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.personalInformation),
            ),
            Expanded(
              child: async.when(
                loading: () => const JzLoader(),
                error: (_, _) => Center(child: Text(l.errUnknown)),
                data: (profile) {
                  if (!_initialized) {
                    _name.text = profile?.fullName ?? '';
                    _phone.text = profile?.phone ?? '';
                    _email.text = profile?.email ?? '';
                    _initialized = true;
                  }
                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: colors.surfaceVariant,
                                  backgroundImage: _avatar == null
                                      ? null
                                      : MemoryImage(_avatar!),
                                  child: _avatar != null
                                      ? null
                                      : Icon(
                                          Icons.person_rounded,
                                          size: 48,
                                          color: colors.textSecondary,
                                        ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: colors.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        JzTextField(
                          label: l.fullName,
                          controller: _name,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l.valRequired
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l.phoneNumber,
                                  style: context.text.labelLarge,
                                ),
                                GestureDetector(
                                  onTap: () => ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(content: Text(l.comingSoon)),
                                    ),
                                  child: Text(
                                    l.changeLabel,
                                    style: context.text.labelLarge?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            JzTextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Read-only: the sign-in email isn't editable here (and
                        // was previously backed by a controller rebuilt on every
                        // setState, so edits were lost and controllers leaked).
                        JzTextField(
                          label: l.email,
                          hint: context.l10n.emailHint,
                          controller: _email,
                          readOnly: true,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _Dropdown(
                          label: l.gender,
                          value: _gender,
                          items: {
                            'Male': l.genderMale,
                            'Female': l.genderFemale,
                            'Other': l.genderOther,
                          },
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _Dropdown(
                          label: l.currentPosition,
                          value: _position,
                          items: jobTitleOptions(l),
                          onChanged: (v) => setState(() => _position = v),
                        ),
                      ],
                    ),
                  );
                },
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
                  label: l.updateLabel,
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

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String? value;

  /// Stable wire value → localized display label.
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(context.l10n.selectOption),
          items: [
            for (final e in items.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
