// Domain enums mirrored from the Postgres check constraints. `wire` is the
// value stored in the DB / sent to Meilisearch; `fromWire` parses it back.

enum JobType {
  fullTime('full_time'),
  partTime('part_time'),
  contract('contract'),
  internship('internship'),
  temporary('temporary'),
  rotational('rotational'); // Вахта — rotational shift work

  const JobType(this.wire);
  final String wire;
  static JobType? fromWire(String? w) => _byWire(values, w);
}

/// Work schedule pattern ("График работы"): days-on/days-off or custom.
enum SchedulePattern {
  sixOne('6_1'),
  fiveTwo('5_2'),
  fourFour('4_4'),
  twoTwo('2_2'),
  custom('custom');

  const SchedulePattern(this.wire);
  final String wire;
  static SchedulePattern? fromWire(String? w) => _byWire(values, w);
}

/// How a hire is formalized ("Оформление сотрудника").
enum Formalization {
  employmentContract('employment_contract'),
  gph('gph'),
  selfEmployed('self_employed'),
  none('none');

  const Formalization(this.wire);
  final String wire;
  static Formalization? fromWire(String? w) => _byWire(values, w);
}

enum ExperienceLevel {
  entry('entry'),
  mid('mid'),
  senior('senior'),
  lead('lead');

  const ExperienceLevel(this.wire);
  final String wire;
  static ExperienceLevel? fromWire(String? w) => _byWire(values, w);
}

enum WorkingModel {
  onsite('onsite'),
  remote('remote'),
  hybrid('hybrid');

  const WorkingModel(this.wire);
  final String wire;
  static WorkingModel? fromWire(String? w) => _byWire(values, w);
}

enum ApplicationStatus {
  submitted('submitted'),
  viewed('viewed'),
  shortlisted('shortlisted'),
  interview('interview'),
  offer('offer'),
  rejected('rejected'),
  hired('hired');

  const ApplicationStatus(this.wire);
  final String wire;
  static ApplicationStatus? fromWire(String? w) => _byWire(values, w);
}

enum SeekingStatus {
  activelyLooking('actively_looking'),
  openToOffers('open_to_offers'),
  notLooking('not_looking');

  const SeekingStatus(this.wire);
  final String wire;
  static SeekingStatus? fromWire(String? w) => _byWire(values, w);
}

enum NotificationType {
  applicationUpdate('application_update'),
  message('message'),
  jobMatch('job_match'),
  review('review'),
  system('system');

  const NotificationType(this.wire);
  final String wire;
  static NotificationType? fromWire(String? w) => _byWire(values, w);
}

/// Which in-app experience a signed-in user gets. `job_seeker` is the default
/// (today's app); `employer` unlocks the Jobzone Business / HR side.
enum UserRole {
  jobSeeker('job_seeker'),
  employer('employer');

  const UserRole(this.wire);
  final String wire;
  static UserRole? fromWire(String? w) => _byWire(values, w);
}

T? _byWire<T extends Enum>(List<T> values, String? wire) {
  if (wire == null) return null;
  for (final v in values) {
    if ((v as dynamic).wire == wire) return v;
  }
  return null;
}
