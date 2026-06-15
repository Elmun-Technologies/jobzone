import '../../../shared/enums/enums.dart';

/// Single source of truth for the signed-out (offline) demo profile's scalar
/// fields. Both `ProfileRepository` (read) and `CvRepository` (write) reference
/// it so edits made in offline mode show up in the read-only "Your Profile"
/// view. CV list sections (experiences, skills, …) live in the CV store.
class OfflineProfile {
  String? fullName = 'Aziz Karimov';
  String? headline = 'Senior Flutter Engineer';
  String? bio =
      'Mobile engineer focused on clean architecture and delightful UX.';
  String? avatarUrl;
  String? email = 'aziz@example.com';
  String? phone = '+998 90 123 45 67';
  String? city = 'Tashkent';
  String? country = 'UZ';
  bool isOpenToWork = true;
  SeekingStatus seekingStatus = SeekingStatus.activelyLooking;
}

/// Process-wide offline profile instance.
final offlineProfile = OfflineProfile();
