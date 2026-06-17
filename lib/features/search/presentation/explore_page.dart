import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../application/search_controller.dart';

/// Map-style Explore screen backed by OpenStreetMap (via flutter_map — no API
/// key needed). Job pins are plotted from each job's lat/lng; a floating search
/// + filter sits on top and a job carousel along the bottom.
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _map = MapController();

  // Default view: Tashkent. Real device location lands with geolocator later.
  static const _initialCenter = LatLng(41.3111, 69.2797);

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final results = ref.watch(searchControllerProvider);
    final topPad = MediaQuery.of(context).padding.top;
    final jobs = results.value ?? const <Job>[];
    final located = [
      for (final j in jobs)
        if (j.lat != null && j.lng != null) j,
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: const MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 11,
                minZoom: 3,
                maxZoom: 18,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'io.jobzone.jobzone',
                ),
                MarkerLayer(
                  markers: [
                    for (final job in located)
                      Marker(
                        point: LatLng(job.lat!, job.lng!),
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: _JobPin(
                          onTap: () => context.push(Routes.jobDetails(job.id)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: topPad + AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(Routes.search),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l.search,
                            style: context.text.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: () => context.push(Routes.filter),
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC629),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: 250,
            child: _CircleFab(
              icon: Icons.my_location_rounded,
              onTap: () => _map.move(_initialCenter, 12),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.lg,
            child: SizedBox(
              height: 210,
              child: results.maybeWhen(
                data: (jobs) => jobs.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        itemCount: jobs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (_, i) => SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.82,
                          child: JobCard(job: jobs[i]),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobPin extends StatelessWidget {
  const _JobPin({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        Icons.location_on_rounded,
        color: colors.primary,
        size: 40,
        shadows: const [
          Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class _CircleFab extends StatelessWidget {
  const _CircleFab({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: colors.primary),
        ),
      ),
    );
  }
}
