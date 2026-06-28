import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/config/env.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/enums/enums.dart';
import '../../../../shared/providers/app_flags.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../widgets/auth_header.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _headline = TextEditingController();
  final _phone = TextEditingController();
  String? _gender;
  Uint8List? _avatar;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
    _phone.dispose();
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
      if (Env.hasSupabase) {
        final client = ref.read(supabaseClientProvider);
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          String? avatarUrl;
          if (_avatar != null) {
            final path =
                '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
            await client.storage
                .from('avatars')
                .uploadBinary(
                  path,
                  _avatar!,
                  fileOptions: const FileOptions(
                    upsert: true,
                    contentType: 'image/jpeg',
                  ),
                );
            avatarUrl = client.storage.from('avatars').getPublicUrl(path);
          }
          await client
              .from('profiles')
              .update({
                'full_name': _name.text.trim(),
                'phone': '+998${_phone.text.replaceAll(RegExp(r'\D'), '')}',
                if (_headline.text.trim().isNotEmpty)
                  'headline': _headline.text.trim(),
                'avatar_url': ?avatarUrl,
              })
              .eq('id', uid);
        }
      }
      if (!mounted) return;
      final role = ref.read(appFlagsProvider).role;
      context.push(
        role == UserRole.employer
            ? Routes.employerOnboard
            : Routes.setupJobType,
      );
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: [
              AuthHeader(
                title: l.completeProfileTitle,
                subtitle: l.completeProfileSubtitle,
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: colors.chipBackground,
                        backgroundImage: _avatar == null
                            ? null
                            : MemoryImage(_avatar!),
                        child: _avatar != null
                            ? null
                            : Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: colors.primary,
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
                            border: Border.all(color: colors.surface, width: 2),
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
                hint: 'Ex. John Doe',
                controller: _name,
                validator: (v) =>
                    Validators.isNotBlank(v) ? null : l.valRequired,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PhoneField(
                label: l.phoneNumber,
                controller: _phone,
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  return digits.length >= 7 ? null : l.valPhoneRequired;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.gender, style: context.text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    isExpanded: true,
                    hint: Text(l.selectOption),
                    items: [
                      DropdownMenuItem(
                        value: 'male',
                        child: Text(l.genderMale),
                      ),
                      DropdownMenuItem(
                        value: 'female',
                        child: Text(l.genderFemale),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text(l.genderOther),
                      ),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              JzPrimaryButton(
                label: l.completeProfileCta,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phone field with a country-code prefix, styled like the design.
class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.label,
    required this.controller,
    this.validator,
  });
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          validator: validator,
          decoration: InputDecoration(
            hintText: 'Enter Phone Number',
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+998', style: context.text.bodyLarge),
                  Icon(Icons.arrow_drop_down, color: colors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Container(width: 1, height: 24, color: colors.border),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
        ),
      ],
    );
  }
}
