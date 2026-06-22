import 'package:flutter/widgets.dart';

import '../../../localization/l10n_extension.dart';
import '../domain/job_collection.dart';

/// Localized label for a [JobCollection]. Kept out of the domain enum so the
/// model stays free of l10n/UI dependencies; both the Home cards and the
/// results page resolve labels through this single extension.
extension JobCollectionLabel on JobCollection {
  String label(BuildContext context) {
    final l = context.l10n;
    return switch (this) {
      JobCollection.freshers => l.collectionFreshers,
      JobCollection.remote => l.collectionRemote,
      JobCollection.partTime => l.collectionPartTime,
      JobCollection.fullTime => l.collectionFullTime,
      JobCollection.rotational => l.collectionRotational,
      JobCollection.women => l.collectionWomen,
      JobCollection.nightShift => l.collectionNightShift,
    };
  }
}
