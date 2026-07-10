import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/options/option_lists.dart';
import '../../../shared/widgets/snackbars.dart';
import '../data/permission_service.dart';

class ManualLocationPage extends ConsumerStatefulWidget {
  const ManualLocationPage({super.key});

  @override
  ConsumerState<ManualLocationPage> createState() => _ManualLocationPageState();
}

class _ManualLocationPageState extends ConsumerState<ManualLocationPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _useCurrent() async {
    await ref.read(permissionServiceProvider).requestLocation();
    if (mounted) context.push(Routes.permNotifications);
  }

  Future<void> _select(String city, String country) async {
    try {
      if (Env.hasSupabase) {
        final client = ref.read(supabaseClientProvider);
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          await client
              .from('profiles')
              .update({'city': city, 'country': country})
              .eq('id', uid);
        }
      }
      if (mounted) context.push(Routes.permNotifications);
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final q = _query.trim().toLowerCase();
    // (wire value, localized label) — real geocoding can replace this later.
    // The query matches BOTH forms, so "Toshkent" and "Tashkent" both hit.
    final suggestions = [
      for (final c in cityOptions(l).entries) (c.key, c.value),
    ];
    final results = q.isEmpty
        ? suggestions
        : suggestions
              .where(
                (s) =>
                    s.$1.toLowerCase().contains(q) ||
                    s.$2.toLowerCase().contains(q),
              )
              .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  JzCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l.permLocationManual,
                        style: context.text.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l.searchLocationHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.cancel, color: colors.primary),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: _useCurrent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(IconsaxPlusBold.location, color: colors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        l.useCurrentLocation,
                        style: context.text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(color: colors.border),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.searchResult,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (_, i) {
                    final r = results[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: () => _select(r.$1, 'Uzbekistan'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              IconsaxPlusBold.location,
                              color: colors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.$2,
                                    style: context.text.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    l.countryUzbekistan,
                                    style: context.text.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
