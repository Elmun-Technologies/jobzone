import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';

class ManualLocationPage extends ConsumerStatefulWidget {
  const ManualLocationPage({super.key});

  @override
  ConsumerState<ManualLocationPage> createState() => _ManualLocationPageState();
}

class _ManualLocationPageState extends ConsumerState<ManualLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _city = TextEditingController();
  final _country = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _city.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (Env.hasSupabase) {
        final client = ref.read(supabaseClientProvider);
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          await client
              .from('profiles')
              .update({
                'city': _city.text.trim(),
                'country': _country.text.trim(),
              })
              .eq('id', uid);
        }
      }
      if (mounted) context.push(Routes.permNotifications);
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return JzScaffold(
      title: l.permLocationManual,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            JzTextField(
              label: l.city,
              controller: _city,
              prefixIcon: Icons.location_city_outlined,
              validator: (v) => Validators.isNotBlank(v) ? null : l.valRequired,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.country,
              controller: _country,
              prefixIcon: Icons.public_outlined,
              validator: (v) => Validators.isNotBlank(v) ? null : l.valRequired,
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
