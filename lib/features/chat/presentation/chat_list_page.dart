import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return JzScaffold(
      title: l.navChat,
      showBack: false,
      body: JzEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: l.comingSoon,
        message: l.comingSoonBody,
      ),
    );
  }
}
