/// Aggregate hiring metrics shown on the employer dashboard.
class EmployerStats {
  const EmployerStats({
    this.totalJobs = 0,
    this.openJobs = 0,
    this.totalApplicants = 0,
    this.newApplicants = 0,
    this.interviews = 0,
    this.hired = 0,
  });

  final int totalJobs;
  final int openJobs;
  final int totalApplicants;

  /// Applicants still in the `submitted` stage (not yet reviewed).
  final int newApplicants;
  final int interviews;
  final int hired;
}
