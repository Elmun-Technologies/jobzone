import 'package:flutter/material.dart';

/// Thin Scaffold wrapper that standardizes app-bar handling and SafeArea.
class JzScaffold extends StatelessWidget {
  const JzScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBack = true,
  });

  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              automaticallyImplyLeading: showBack,
            ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
