import 'package:flutter/material.dart';

/// Centered progress indicator for full-screen / section loading.
class JzLoader extends StatelessWidget {
  const JzLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
