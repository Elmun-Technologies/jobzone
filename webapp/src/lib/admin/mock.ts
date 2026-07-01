import type { DashboardStats, SeriesPoint } from "./types";

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
