import "server-only";

import { isAdminUser } from "@/lib/auth/admin-role";
import { getCurrentUser } from "@/lib/auth/user";
import { hasSupabase } from "@/lib/data/supabase-env";
import { createClient } from "@/lib/supabase/server";

import { mockDashboardStats } from "../mock";
import type { DashboardStats, SeriesPoint } from "../types";

/** Raw jsonb shape returned by the `admin_dashboard_stats` RPC (0037). */
interface StatsRow {
  totals: Record<string, number>;
  series: Record<string, SeriesPoint[]>;
  funnel: Record<string, number>;
  top_categories: { name: string; n: number }[];
  top_cities: { city: string; n: number }[];
  finance: Record<string, number>;
}

function toStats(row: StatsRow): DashboardStats {
  const t = row.totals ?? {};
  const s = row.series ?? {};
  const f = row.finance ?? {};
  return {
    totals: {
      seekers: t.seekers ?? 0,
      employers: t.employers ?? 0,
      companies: t.companies ?? 0,
      companiesVerified: t.companies_verified ?? 0,
      workersVerified: t.workers_verified ?? 0,
      jobsOpen: t.jobs_open ?? 0,
      jobsTotal: t.jobs_total ?? 0,
      applications: t.applications ?? 0,
      devices: t.devices ?? 0,
      telegramLinked: t.telegram_linked ?? 0,
    },
    series: {
      signups: s.signups ?? [],
      jobs: s.jobs ?? [],
      applications: s.applications ?? [],
      revenue: s.revenue ?? [],
      topups: s.topups ?? [],
    },
    funnel: row.funnel ?? {},
    topCategories: row.top_categories ?? [],
    topCities: row.top_cities ?? [],
    finance: {
      revenueTotal: f.revenue_total ?? 0,
      walletLiability: f.wallet_liability ?? 0,
      pendingTopups: f.pending_topups ?? 0,
      pendingTopupSum: f.pending_topup_sum ?? 0,
    },
  };
}

/**
 * Dashboard aggregates for /admin. Uses the ANON cookie client — the RPC is a
 * security-definer function that re-checks `is_admin()` itself, so no service
 * key is needed for the dashboard. Returns null on failure (page shows an
 * error state); mock data without Supabase env. The `isAdminUser` re-check is
 * defense-in-depth on top of the page's `requireAdmin()`.
 */
export async function getDashboardStats(
  days: number,
): Promise<DashboardStats | null> {
  if (!hasSupabase()) return mockDashboardStats(days);
  const user = await getCurrentUser();
  if (!isAdminUser(user)) return null;
  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("admin_dashboard_stats", {
      p_days: days,
    });
    if (error || !data) return null;
    return toStats(data as StatsRow);
  } catch {
    return null;
  }
}
