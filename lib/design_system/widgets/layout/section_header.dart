import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// "Section title  ……  See all" row used across Home and detail screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Expanded + ellipsis so a long localized title (uz/ru run longer than
        // en) can't overflow the row into RenderFlex stripes.
        Expanded(
          child: Text(
            title,
            style: context.text.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
