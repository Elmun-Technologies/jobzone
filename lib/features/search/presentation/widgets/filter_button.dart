import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Tune icon with an active-filter-count badge.
class FilterButton extends StatelessWidget {
  const FilterButton({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: onTap,
          icon: const Icon(Icons.tune_rounded),
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(
                  color: colors.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
