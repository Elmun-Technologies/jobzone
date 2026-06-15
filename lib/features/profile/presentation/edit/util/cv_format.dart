import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../../localization/l10n_extension.dart';

/// "Jan 2022 – Present" / "2019 – 2022" style range for CV cards.
String periodText(
  BuildContext context,
  DateTime? start,
  DateTime? end, {
  bool current = false,
}) {
  final fmt = DateFormat.yMMM();
  final s = start == null ? null : fmt.format(start);
  final e = current
      ? context.l10n.present
      : (end == null ? null : fmt.format(end));
  if (s == null && e == null) return '';
  return [s, e].where((x) => x != null).join(' – ');
}
