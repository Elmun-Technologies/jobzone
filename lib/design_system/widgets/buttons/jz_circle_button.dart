import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Circular icon button used across the Figma design (back arrows, onboarding
/// nav, etc.). Outlined by default; [filled] paints it in the brand colour.
class JzCircleButton extends StatelessWidget {
  const JzCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: filled ? colors.primary : colors.surface,
      shape: CircleBorder(
        side: filled ? BorderSide.none : BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.42,
            color: filled ? colors.onPrimary : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
