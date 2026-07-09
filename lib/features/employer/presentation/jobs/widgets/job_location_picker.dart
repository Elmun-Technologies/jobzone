import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../../localization/l10n_extension.dart';
import '../../../../../shared/widgets/jz_map/jz_map.dart';

/// Full-screen map picker for a job's work location. Tap the map to drop the
/// pin; the chosen [LatLng] is returned via `Navigator.pop`. Renders
/// OpenStreetMap on every platform (via [JzMapView]).
class JobLocationPicker extends StatefulWidget {
  const JobLocationPicker({super.key, this.initial});

  final LatLng? initial;

  @override
  State<JobLocationPicker> createState() => _JobLocationPickerState();
}

class _JobLocationPickerState extends State<JobLocationPicker> {
  static const _tashkent = LatLng(41.3111, 69.2797);
  late LatLng? _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final center = _picked ?? widget.initial ?? _tashkent;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.fieldWorkAddress),
            ),
            Expanded(
              child: JzMapView(
                initialCenter: center,
                initialZoom: 13,
                onMapTap: (point) => setState(() => _picked = point),
                markers: _picked == null
                    ? const []
                    : [
                        JzMapMarker(
                          id: 'picked',
                          point: _picked!,
                          kind: JzMarkerKind.picked,
                        ),
                      ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: JzPrimaryButton(
                  label: l.useThisLocation,
                  onPressed: () => Navigator.of(context).pop(_picked ?? center),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
