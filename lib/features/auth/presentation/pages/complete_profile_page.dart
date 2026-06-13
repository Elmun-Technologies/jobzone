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
import '../../../../shared/widgets/snackbars.dart';

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
  Uint8List? _avatar;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
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
                if (_headline.text.trim().isNotEmpty)
                  'headline': _headline.text.trim(),
                'avatar_url': ?avatarUrl,
              })
              .eq('id', uid);
        }
      }
      if (!mounted) return;
      context.push(Routes.setupJobType);
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return JzScaffold(
      title: l.completeProfileTitle,
      showBack: false,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              l.completeProfileSubtitle,
              style: context.text.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: colors.chipBackground,
                  backgroundImage: _avatar == null
                      ? null
                      : MemoryImage(_avatar!),
                  child: _avatar != null
                      ? null
                      : Icon(Icons.add_a_photo_outlined, color: colors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            JzTextField(
              label: l.fullName,
              controller: _name,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => Validators.isNotBlank(v) ? null : l.valRequired,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.headline,
              hint: 'Flutter Developer',
              controller: _headline,
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            JzPrimaryButton(
              label: l.continueLabel,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
