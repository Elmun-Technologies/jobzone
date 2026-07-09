import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/jz_map/jz_map.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../../permissions/data/permission_service.dart';
import '../application/search_controller.dart';

/// Map-style Explore screen. Jobs are plotted from each job's lat/lng as
/// clustered salary markers; a search + filter bar and a Map/List toggle sit on
/// top, with a job carousel along the bottom of the map. The map is Yandex
/// (official SDK) on mobile and OpenStreetMap on web (via [JzMapView]).
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _map = JzMapController();

  // Default view: Tashkent. Replaced by the device location on "my location".
  static const _initialCenter = LatLng(41.3111, 69.2797);

  int _tab = 0; // 0 = map, 1 = list
  LatLng? _myLocation;

  /// A compact salary for the marker pill (e.g. "2.5 mln", "$1.5k"). Null when
  /// the job has no salary.
  String? _salaryLabel(Job j) {
    final v = j.salaryMin ?? j.salaryMax;
    if (v == null) return null;
    if (j.currency == 'UZS') {
      final mln = v / 1000000;
      if (mln >= 1) return '${mln.toStringAsFixed(mln % 1 == 0 ? 0 : 1)} mln';
      final k = v / 1000;
      if (k >= 1) return '${k.toStringAsFixed(0)}k';
      return v.toStringAsFixed(0);
    }
    return j.salaryText;
  }

  Future<void> _goToMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    final pos = await ref.read(permissionServiceProvider).currentPosition();
    if (!mounted) return;
    if (pos == null) {
      showInfoSnack(context, context.l10n.locationUnavailable);
      return;
    }
    final here = LatLng(pos.latitude, pos.longitude);
    setState(() => _myLocation = here);
    _map.moveTo(here, zoom: 13);
    messenger.clearSnackBars();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchControllerProvider);
    final jobs = results.value ?? const <Job>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  const _SearchBar(),
                  const SizedBox(height: AppSpacing.sm),
                  _MapListToggle(
                    value: _tab,
                    onChanged: (v) => setState(() => _tab = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _MapTab(
                    map: _map,
                    initialCenter: _initialCenter,
                    myLocation: _myLocation,
                    markers: [
                      for (final job in jobs)
                        if (job.lat != null && job.lng != null)
                          JzMapMarker(
                            id: job.id,
                            point: LatLng(job.lat!, job.lng!),
                            label: _salaryLabel(job),
                            imageUrl: job.companyLogoUrl,
                            onTap: () =>
                                context.push(Routes.jobDetails(job.id)),
                          ),
                    ],
                    carousel: jobs,
                    onMyLocation: _goToMyLocation,
                  ),
                  _ListTab(results: results),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({
    required this.map,
    required this.initialCenter,
    required this.myLocation,
    required this.markers,
    required this.carousel,
    required this.onMyLocation,
  });

  final JzMapController map;
  final LatLng initialCenter;
  final LatLng? myLocation;
  final List<JzMapMarker> markers;
  final List<Job> carousel;
  final VoidCallback onMyLocation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: JzMapView(
            controller: map,
            initialCenter: initialCenter,
            initialZoom: 11,
            cluster: true,
            myLocation: myLocation,
            markers: markers,
          ),
        ),
        Positioned(
          right: AppSpacing.lg,
          bottom: 230,
          child: _CircleFab(
            icon: Icons.my_location_rounded,
            onTap: onMyLocation,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.lg,
          child: SizedBox(
            height: 210,
            child: carousel.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: carousel.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (_, i) => SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.82,
                      child: JobCard(job: carousel[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ListTab extends StatelessWidget {
  const _ListTab({required this.results});

  final AsyncValue<List<Job>> results;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return results.when(
      loading: () => const JobListSkeleton(),
      error: (_, _) =>
          JzEmptyState(icon: Icons.error_outline_rounded, title: l.errUnknown),
      data: (jobs) => jobs.isEmpty
          ? JzEmptyState(icon: Icons.work_outline_rounded, title: l.noJobsTitle)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => JobCard(job: jobs[i]),
            ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(Routes.search),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                  Icon(Icons.search_rounded, color: colors.textSecondary),
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
              color: colors.gold,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.tune_rounded, color: colors.onGold),
          ),
        ),
      ],
    );
  }
}

class _MapListToggle extends StatelessWidget {
  const _MapListToggle({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(child: _seg(context, l.tabMap, 0)),
          Expanded(child: _seg(context, l.tabList, 1)),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, String label, int index) {
    final colors = context.colors;
    final selected = value == index;
    return GestureDetector(
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(
            color: selected ? colors.primary : colors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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
