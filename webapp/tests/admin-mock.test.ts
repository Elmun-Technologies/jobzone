import { describe, expect, it } from "vitest";

import { mockDashboardStats } from "@/lib/admin/mock";
import { FUNNEL_STAGES } from "@/lib/admin/types";

describe("mockDashboardStats", () => {
  const stats = mockDashboardStats(30);

  it("emits one point per day for every series", () => {
    for (const series of Object.values(stats.series)) {
      expect(series).toHaveLength(30);
      for (const p of series) {
        expect(p.d).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        expect(p.n).toBeGreaterThanOrEqual(0);
        expect(Number.isInteger(p.n)).toBe(true);
      }
    }
  });

  it("orders series oldest-first (chart input order)", () => {
    const dates = stats.series.signups.map((p) => p.d);
    expect([...dates].sort()).toEqual(dates);
  });

  it("covers every funnel stage the dashboard renders", () => {
    for (const stage of FUNNEL_STAGES) {
      expect(stats.funnel[stage]).toBeGreaterThan(0);
    }
    // Monotonic non-increasing down the funnel — believable demo data.
    for (let i = 1; i < FUNNEL_STAGES.length; i++) {
      expect(stats.funnel[FUNNEL_STAGES[i]]).toBeLessThanOrEqual(
        stats.funnel[FUNNEL_STAGES[i - 1]],
      );
    }
  });

  it("ships ten-item top lists and coherent finance tiles", () => {
    expect(stats.topCategories).toHaveLength(10);
    expect(stats.topCities).toHaveLength(10);
    expect(stats.finance.pendingTopupSum).toBeGreaterThan(0);
    expect(stats.finance.revenueTotal).toBeGreaterThan(0);
  });

  it("respects the requested range length", () => {
    expect(mockDashboardStats(90).series.jobs).toHaveLength(90);
  });
});
