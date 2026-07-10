import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';

/// Row of five tappable stars for selecting a 1–5 rating.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 40,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: context.l10n.ratingStar(i),
            onPressed: () => onChanged(i),
            iconSize: size,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            constraints: const BoxConstraints(),
            icon: Icon(
              i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i <= rating ? colors.warning : colors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// Compact read-only star row for displaying an average/individual rating.
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating.round()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: colors.warning,
          ),
      ],
    );
  }
}
