import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Circular radio indicator matching the Figma design: an outline ring with a
/// filled brand dot when selected.
class JzRadio extends StatelessWidget {
  const JzRadio({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.primary : colors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
