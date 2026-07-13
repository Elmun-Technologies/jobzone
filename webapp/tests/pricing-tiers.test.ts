import { describe, expect, it } from "vitest";

import { PLAN_TIERS, tierForActiveJobs } from "@/lib/pricing-tiers";

describe("PLAN_TIERS", () => {
  it("has the four employer plan tiers at the agreed prices", () => {
    expect(PLAN_TIERS.map((t) => [t.code, t.maxJobs, t.priceUzs])).toEqual([
      ["free", 1, 0],
      ["standard", 10, 99_000],
      ["highlight", 50, 199_000],
      ["business", null, 499_000],
    ]);
  });

  it("marks exactly one tier as featured", () => {
    expect(PLAN_TIERS.filter((t) => t.featured)).toHaveLength(1);
  });
});

describe("tierForActiveJobs", () => {
  it("keeps a single vacancy on the free tier", () => {
    expect(tierForActiveJobs(1).code).toBe("free");
  });

  it("moves to standard from the second vacancy up to ten", () => {
    expect(tierForActiveJobs(2).code).toBe("standard");
    expect(tierForActiveJobs(10).code).toBe("standard");
  });

  it("moves to highlight past ten up to fifty", () => {
    expect(tierForActiveJobs(11).code).toBe("highlight");
    expect(tierForActiveJobs(50).code).toBe("highlight");
  });

  it("moves to business past fifty (unlimited)", () => {
    expect(tierForActiveJobs(51).code).toBe("business");
    expect(tierForActiveJobs(9999).code).toBe("business");
  });
});
