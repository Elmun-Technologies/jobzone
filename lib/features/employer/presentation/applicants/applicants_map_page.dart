import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/geo.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/jz_map/jz_map.dart';
import '../../data/applicants_repository.dart';
import '../../domain/applicant.dart';

/// Applicants plotted on a map so an employer can see who lives near the job
/// (solving the commute problem). Yandex (official SDK) on mobile, OSM on
/// web (via [JzMapView]). [jobId] null → the cross-job inbox; otherwise one
/// job, whose
/// location is the origin pin and map center.
class ApplicantsMapPage extends ConsumerWidget {
  const ApplicantsMapPage({super.key, this.jobId});

  final String? jobId;

  static const _tashkent = LatLng(41.3111, 69.2797);

  void _showApplicant(BuildContext context, Applicant a) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.name,
              style: sheetCtx.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (a.distanceKm != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.kmAway(formatKm(a.distanceKm!)),
                style: sheetCtx.text.bodyMedium?.copyWith(
                  color: sheetCtx.colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: JzPrimaryButton(
                label: l.viewProfile,
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  context.push(Routes.employerApplicant(a.id), extra: a);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final topPad = MediaQuery.of(context).padding.top;
    final async = jobId == null
        ? ref.watch(allApplicantsProvider)
        : ref.watch(jobApplicantsProvider(jobId!));

    final applicants = async.value ?? const <Applicant>[];
    final located = [
      for (final a in applicants)
        if (a.lat != null && a.lng != null) a,
    ];
    LatLng? origin;
    if (jobId != null) {
      for (final a in applicants) {
        if (a.jobLat != null && a.jobLng != null) {
          origin = LatLng(a.jobLat!, a.jobLng!);
          break;
        }
      }
    }
    final originPin = origin;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: JzMapView(
              initialCenter: originPin ?? _tashkent,
              initialZoom: originPin == null ? 11 : 12,
              markers: [
                if (originPin != null)
                  JzMapMarker(id: 'job-origin', point: originPin),
                for (final a in located)
                  JzMapMarker(
                    id: 'a-${a.id}',
                    point: LatLng(a.lat!, a.lng!),
                    kind: JzMarkerKind.applicant,
                    onTap: () => _showApplicant(context, a),
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
                JzCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
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
                    child: Text(
                      l.applicantsMapTitle,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (async.isLoading)
            const Positioned.fill(child: Center(child: JzLoader())),
          if (!async.isLoading && located.isEmpty)
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: AppSpacing.xxl,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  l.mapNoLocations,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
