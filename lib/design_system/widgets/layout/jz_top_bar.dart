import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../buttons/jz_circle_button.dart';

/// A lightweight top bar matching the Figma design: a circular back button on
/// the left, an optional centered title, and optional trailing [actions]
/// (e.g. bookmark / share circular buttons).
class JzTopBar extends StatelessWidget {
  const JzTopBar({super.key, this.title, this.actions = const []});

  final String? title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        JzCircleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Center(
            child: title == null
                ? const SizedBox.shrink()
                : Text(
                    title!,
                    style: context.text.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
        if (actions.isEmpty)
          const SizedBox(width: 48)
        else
          Row(mainAxisSize: MainAxisSize.min, children: actions),
      ],
    );
  }
}
