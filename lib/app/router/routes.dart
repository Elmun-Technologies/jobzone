/// Typed route paths + helpers. Prefer these over string literals when
/// navigating (`context.go(Routes.home)`, `context.push(Routes.jobDetails(id))`).
abstract final class Routes {
  // Pre-app
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';

  // Auth
  static const signIn = '/auth/sign-in';
  static const createAccount = '/auth/create-account';
  static const verifyCode = '/auth/verify-code';
  static const newPassword = '/auth/new-password';
  static const completeProfile = '/auth/complete-profile';

  // Preference setup
  static const setupJobType = '/setup/job-type';
  static const setupExperience = '/setup/experience';
  static const setupWorkingModel = '/setup/working-model';
  static const setupJobTitle = '/setup/job-title';

  // Permissions
  static const permLocation = '/permissions/location';
  static const permLocationManual = '/permissions/location-manual';
  static const permNotifications = '/permissions/notifications';

  // Shell tabs
  static const home = '/home';
  static const explore = '/explore';
  static const chat = '/chat';
  static const profile = '/profile';

  // Explore children
  static const search = '/explore/search';
  static const filter = '/explore/filter';

  // Jobs (static routes declared before the `:id` route to avoid capture)
  static const suggestedJobs = '/jobs/suggested';
  static const recentJobs = '/jobs/recent';
  static const bookmarks = '/bookmarks';
  static String jobDetails(String id) => '/jobs/$id';
  static String applyJob(String id) => '/jobs/$id/apply';
  static String applySuccess(String id) => '/jobs/$id/apply/success';
  static String writeReview(String id) => '/jobs/$id/review/new';

  // Companies
  static String companyDetails(String id) => '/companies/$id';
  static String companyIntroVideo(String id) => '/companies/$id/intro-video';
  static String companyGallery(String id) => '/companies/$id/gallery';

  // Chat
  static String chatDetail(String id) => '/chat/$id';
  static String videoCall(String id) => '/chat/$id/call/video';
  static String voiceCall(String id) => '/chat/$id/call/voice';

  // Misc
  static const notifications = '/notifications';

  // Profile (CV) subtree
  static const yourProfile = '/your-profile';
  static const profileContactInfo = '/profile/contact-info';
  static const profileAbout = '/profile/about';
  static const profileExperience = '/profile/experience';
  static const profileEducation = '/profile/education';
  static const profileProjects = '/profile/projects';
  static const profileCertifications = '/profile/certifications';
  static const profileVolunteer = '/profile/volunteer';
  static const profileAwards = '/profile/awards';
  static const profileSkills = '/profile/skills';
  static const profileResume = '/profile/resume';

  // Account subtree
  static const accountPersonalInfo = '/account/personal-info';
  static const accountAnalytics = '/account/analytics';
  static const accountApplications = '/account/my-applications';
  static String applicationStatus(String id) => '/account/my-applications/$id';
  static const accountSeekingStatus = '/account/seeking-status';
  static const accountSettings = '/account/settings';
  static const accountNotificationSettings = '/account/notification-settings';
  static const accountLanguage = '/account/language';
  static const accountPassword = '/account/password';
  static const accountHelp = '/account/help';
  static const accountPrivacy = '/account/privacy';
  static const accountInvite = '/account/invite';
}
