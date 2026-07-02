/** Camel-cased shapes the admin data layer returns (mapped from RPC jsonb). */

/** One daily bucket of a time series: ISO date + value. */
export interface SeriesPoint {
  d: string;
  n: number;
}

export interface DashboardTotals {
  seekers: number;
  employers: number;
  companies: number;
  companiesVerified: number;
  workersVerified: number;
  jobsOpen: number;
  jobsTotal: number;
  applications: number;
  devices: number;
  telegramLinked: number;
}

export interface DashboardFinance {
  revenueTotal: number;
  walletLiability: number;
  pendingTopups: number;
  pendingTopupSum: number;
}

/** Return shape of the `admin_dashboard_stats` RPC (0037). */
export interface DashboardStats {
  totals: DashboardTotals;
  series: {
    signups: SeriesPoint[];
    jobs: SeriesPoint[];
    applications: SeriesPoint[];
    revenue: SeriesPoint[];
    topups: SeriesPoint[];
  };
  /** application_status_history status -> distinct applications reaching it. */
  funnel: Record<string, number>;
  topCategories: { name: string; n: number }[];
  topCities: { city: string; n: number }[];
  finance: DashboardFinance;
}

/** Ordered funnel stages (mirrors the applications status CHECK, 0003). */
export const FUNNEL_STAGES = [
  "submitted",
  "viewed",
  "shortlisted",
  "interview",
  "offer",
  "hired",
] as const;

/**
 * Paged admin list. `null` means the privileged read layer is unavailable
 * (SUPABASE_SERVICE_ROLE_KEY missing) — pages show a config hint, not an
 * empty list.
 */
export type AdminList<T> = { rows: T[]; hasNext: boolean } | null;

export interface AdminUserRow {
  id: string;
  fullName: string;
  phone: string | null;
  email: string | null;
  city: string | null;
  role: string;
  createdAt: string;
  suspendedAt: string | null;
  workerVerifiedAt: string | null;
}

export interface AdminCompanyRow {
  id: string;
  name: string;
  headquarters: string | null;
  isVerified: boolean;
  blockedAt: string | null;
  createdAt: string;
}

export interface AdminJobRow {
  id: string;
  title: string;
  companyName: string;
  city: string | null;
  status: string;
  applicantsCount: number;
  blockedAt: string | null;
  createdAt: string;
}

export interface AdminReviewRow {
  id: string;
  /** company_reviews -> company name; worker_reviews -> worker name. */
  subject: string;
  authorName: string;
  rating: number;
  body: string | null;
  hiddenAt: string | null;
  createdAt: string;
}

export interface AdminAuditRow {
  id: number;
  actorName: string;
  action: string;
  targetType: string | null;
  targetId: string | null;
  meta: Record<string, unknown>;
  createdAt: string;
}
