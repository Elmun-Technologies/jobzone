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
