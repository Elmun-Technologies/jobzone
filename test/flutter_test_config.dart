import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs before the test suite. Disables google_fonts runtime fetching so the
/// theme (which applies Archivo) builds in the test harness without attempting
/// a network/asset font load — it falls back to the default font in tests,
/// while the real app still fetches/caches Archivo at runtime.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
