import type {
  AdminAuditRow,
  AdminCompanyRow,
  AdminJobRow,
  AdminList,
  AdminReviewRow,
  AdminUserRow,
  DashboardStats,
  SeriesPoint,
} from "./types";

/**
 * Believable demo data for the admin panel when Supabase env is absent
 * (product invariant: everything runs offline). Values are generated with a
 * seeded wave — deterministic for a given day index, no Math.random — so the
 * dashboard renders stable, plausible curves.
 */

function isoDaysAgo(daysAgo: number): string {
  const d = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
  return d.toISOString().slice(0, 10);
}

/** Smooth pseudo-random series: base + weekly wave + deterministic jitter. */
function wave(days: number, base: number, amp: number, seed: number): SeriesPoint[] {
  const points: SeriesPoint[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const weekly = Math.sin(((days - i) / 7) * Math.PI * 2 + seed) * amp * 0.4;
    const jitter = (Math.sin((days - i) * 12.9898 * (seed + 1)) + 1) * amp * 0.3;
    const growth = ((days - i) / days) * amp * 0.6;
    points.push({
      d: isoDaysAgo(i),
      n: Math.max(0, Math.round(base + weekly + jitter + growth)),
    });
  }
  return points;
}

function sum(points: SeriesPoint[]): number {
  return points.reduce((acc, p) => acc + p.n, 0);
}

export function mockDashboardStats(days: number): DashboardStats {
  const signups = wave(days, 38, 22, 1);
  const jobs = wave(days, 12, 9, 2);
  const applications = wave(days, 64, 40, 3);
  const revenue = wave(days, 240_000, 180_000, 4);
  const topups = wave(days, 350_000, 250_000, 5);

  const applied = sum(applications);
  return {
    totals: {
      seekers: 12_480,
      employers: 1_315,
      companies: 1_240,
      companiesVerified: 312,
      workersVerified: 1_876,
      jobsOpen: 934,
      jobsTotal: 2_611,
      applications: 48_902,
      devices: 9_744,
      telegramLinked: 5_120,
    },
    series: { signups, jobs, applications, revenue, topups },
    funnel: {
      submitted: applied,
      viewed: Math.round(applied * 0.72),
      shortlisted: Math.round(applied * 0.31),
      interview: Math.round(applied * 0.14),
      offer: Math.round(applied * 0.06),
      hired: Math.round(applied * 0.045),
      rejected: Math.round(applied * 0.38),
    },
    topCategories: [
      { name: "Quruvchi", n: 214 },
      { name: "Haydovchi", n: 187 },
      { name: "Oshpaz", n: 151 },
      { name: "Sotuvchi", n: 133 },
      { name: "Ofitsiant", n: 104 },
      { name: "Farrosh", n: 88 },
      { name: "Omborchi", n: 71 },
      { name: "Qo'riqchi", n: 64 },
      { name: "Chilangar", n: 52 },
      { name: "Kuryer", n: 47 },
    ],
    topCities: [
      { city: "Toshkent", n: 512 },
      { city: "Samarqand", n: 118 },
      { city: "Namangan", n: 84 },
      { city: "Andijon", n: 76 },
      { city: "Buxoro", n: 61 },
      { city: "Farg'ona", n: 55 },
      { city: "Qarshi", n: 38 },
      { city: "Nukus", n: 31 },
      { city: "Urganch", n: 27 },
      { city: "Jizzax", n: 22 },
    ],
    finance: {
      revenueTotal: 18_450_000,
      walletLiability: 6_280_000,
      pendingTopups: 7,
      pendingTopupSum: 1_150_000,
    },
  };
}

// ---------------------------------------------------------------------------
// List fixtures for the moderation screens (offline demo). Search filters the
// fixture in memory so the panel feels alive without a backend.
// ---------------------------------------------------------------------------

function filtered<T>(rows: T[], q: string, text: (row: T) => string): AdminList<T> {
  const needle = q.trim().toLowerCase();
  const hit = needle
    ? rows.filter((r) => text(r).toLowerCase().includes(needle))
    : rows;
  return { rows: hit, hasNext: false };
}

const MOCK_USERS: AdminUserRow[] = [
  { id: "u-01", fullName: "Aziz Karimov", phone: "+998901234501", email: null, city: "Toshkent", role: "job_seeker", createdAt: "2026-05-14T09:00:00Z", suspendedAt: null, workerVerifiedAt: "2026-06-01T10:00:00Z" },
  { id: "u-02", fullName: "Dilnoza Yusupova", phone: "+998901234502", email: "dilnoza@example.uz", city: "Samarqand", role: "job_seeker", createdAt: "2026-05-20T12:30:00Z", suspendedAt: null, workerVerifiedAt: null },
  { id: "u-03", fullName: "Rustam Qodirov", phone: "+998901234503", email: null, city: "Namangan", role: "employer", createdAt: "2026-06-02T08:15:00Z", suspendedAt: null, workerVerifiedAt: null },
  { id: "u-04", fullName: "Malika Tosheva", phone: null, email: "malika@example.uz", city: "Toshkent", role: "job_seeker", createdAt: "2026-06-10T16:45:00Z", suspendedAt: "2026-06-25T11:00:00Z", workerVerifiedAt: null },
  { id: "u-05", fullName: "Jasur Bekmurodov", phone: "+998901234505", email: null, city: "Buxoro", role: "employer", createdAt: "2026-06-18T14:20:00Z", suspendedAt: null, workerVerifiedAt: null },
];

const MOCK_COMPANIES: AdminCompanyRow[] = [
  { id: "c-01", name: "Qurilish Invest", headquarters: "Toshkent", isVerified: true, blockedAt: null, createdAt: "2026-04-02T09:00:00Z" },
  { id: "c-02", name: "Oqtepa Lavash", headquarters: "Toshkent", isVerified: true, blockedAt: null, createdAt: "2026-04-18T10:30:00Z" },
  { id: "c-03", name: "Trans Logistika", headquarters: "Samarqand", isVerified: false, blockedAt: null, createdAt: "2026-05-05T11:00:00Z" },
  { id: "c-04", name: "Shaffof Servis", headquarters: "Andijon", isVerified: false, blockedAt: "2026-06-20T13:00:00Z", createdAt: "2026-05-22T15:45:00Z" },
];

const MOCK_JOBS: AdminJobRow[] = [
  { id: "j-01", title: "G'isht teruvchi usta", companyName: "Qurilish Invest", city: "Toshkent", status: "open", applicantsCount: 34, blockedAt: null, createdAt: "2026-06-25T09:00:00Z" },
  { id: "j-02", title: "Oshpaz yordamchisi", companyName: "Oqtepa Lavash", city: "Toshkent", status: "open", applicantsCount: 18, blockedAt: null, createdAt: "2026-06-27T10:00:00Z" },
  { id: "j-03", title: "Yuk mashinasi haydovchisi (C)", companyName: "Trans Logistika", city: "Samarqand", status: "open", applicantsCount: 9, blockedAt: null, createdAt: "2026-06-28T08:30:00Z" },
  { id: "j-04", title: "Kechki farrosh", companyName: "Shaffof Servis", city: "Andijon", status: "open", applicantsCount: 4, blockedAt: "2026-06-29T12:00:00Z", createdAt: "2026-06-26T17:00:00Z" },
  { id: "j-05", title: "Omborchi", companyName: "Qurilish Invest", city: "Toshkent", status: "draft", applicantsCount: 0, blockedAt: null, createdAt: "2026-06-30T13:10:00Z" },
];

const MOCK_COMPANY_REVIEWS: AdminReviewRow[] = [
  { id: "r-01", subject: "Qurilish Invest", authorName: "Aziz Karimov", rating: 5, body: "Maosh o'z vaqtida, sharoit yaxshi.", hiddenAt: null, createdAt: "2026-06-15T09:00:00Z" },
  { id: "r-02", subject: "Trans Logistika", authorName: "Dilnoza Yusupova", rating: 2, body: "Ish vaqti kelishilgandan uzun.", hiddenAt: null, createdAt: "2026-06-21T10:00:00Z" },
  { id: "r-03", subject: "Shaffof Servis", authorName: "Malika Tosheva", rating: 1, body: "Reklama uchun yozilgan haqoratli matn…", hiddenAt: "2026-06-26T12:00:00Z", createdAt: "2026-06-24T18:00:00Z" },
];

const MOCK_WORKER_REVIEWS: AdminReviewRow[] = [
  { id: "w-01", subject: "Aziz Karimov", authorName: "Rustam Qodirov", rating: 5, body: "Mas'uliyatli, o'z vaqtida keladi.", hiddenAt: null, createdAt: "2026-06-18T09:00:00Z" },
  { id: "w-02", subject: "Dilnoza Yusupova", authorName: "Jasur Bekmurodov", rating: 4, body: null, hiddenAt: null, createdAt: "2026-06-22T14:00:00Z" },
];

const MOCK_AUDIT: AdminAuditRow[] = [
  { id: 4, actorName: "Admin (demo)", action: "job.block", targetType: "jobs", targetId: "j-04", meta: { reason: "Firibgarlik shubhasi" }, createdAt: "2026-06-29T12:00:00Z" },
  { id: 3, actorName: "Admin (demo)", action: "company.block", targetType: "companies", targetId: "c-04", meta: { reason: "Takroriy shikoyatlar" }, createdAt: "2026-06-20T13:00:00Z" },
  { id: 2, actorName: "Admin (demo)", action: "company_review.hide", targetType: "company_reviews", targetId: "r-03", meta: { reason: "Haqorat" }, createdAt: "2026-06-26T12:00:00Z" },
  { id: 1, actorName: "Admin (demo)", action: "profile.suspend", targetType: "profiles", targetId: "u-04", meta: { reason: "Spam arizalar" }, createdAt: "2026-06-25T11:00:00Z" },
];

export function mockAdminUsers(q: string): AdminList<AdminUserRow> {
  return filtered(MOCK_USERS, q, (r) => `${r.fullName} ${r.phone ?? ""} ${r.email ?? ""}`);
}
export function mockAdminCompanies(q: string): AdminList<AdminCompanyRow> {
  return filtered(MOCK_COMPANIES, q, (r) => r.name);
}
export function mockAdminJobs(q: string): AdminList<AdminJobRow> {
  return filtered(MOCK_JOBS, q, (r) => `${r.title} ${r.companyName}`);
}
export function mockAdminReviews(kind: "company" | "worker", q: string): AdminList<AdminReviewRow> {
  const rows = kind === "company" ? MOCK_COMPANY_REVIEWS : MOCK_WORKER_REVIEWS;
  return filtered(rows, q, (r) => `${r.subject} ${r.authorName} ${r.body ?? ""}`);
}
export function mockAdminAudit(): AdminList<AdminAuditRow> {
  return { rows: MOCK_AUDIT, hasNext: false };
}
