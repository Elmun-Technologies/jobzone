import { describe, expect, it } from "vitest";

import { LISTING_TIERS } from "@/lib/listing-tiers";

describe("LISTING_TIERS", () => {
  it("has the three per-listing tiers at the agreed prices", () => {
    expect(LISTING_TIERS.map((t) => [t.code, t.priceUzs])).toEqual([
      ["standard", 39_900],
      ["brand", 79_900],
      ["premium", 99_900],
    ]);
  });

  it("marks exactly one tier as the featured nudge target", () => {
    const featured = LISTING_TIERS.filter((t) => t.featured);
    expect(featured).toHaveLength(1);
    expect(featured[0].code).toBe("brand");
  });
});
