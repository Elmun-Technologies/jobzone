import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../../localization/l10n_extension.dart';

/// Full-screen OpenStreetMap picker for a job's work location. Tap the map to
/// drop the pin; the chosen [LatLng] is returned via `Navigator.pop`. Reuses
/// the keyless OSM tiles from the Explore screen — no API key needed.
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
    final colors = context.colors;
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
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onTap: (_, point) => setState(() => _picked = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'io.jobzone.jobzone',
                  ),
                  if (_picked != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _picked!,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_on_rounded,
                            color: colors.primary,
                            size: 40,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
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
