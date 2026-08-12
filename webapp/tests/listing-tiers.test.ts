import { describe, expect, it } from "vitest";

import { LISTING_TIERS, upgradeTiersFor } from "@/lib/listing-tiers";

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

describe("upgradeTiersFor", () => {
  const codes = (tier: string | null) =>
    upgradeTiersFor(tier).map((t) => t.code);

  it("offers a free / Standart listing both visual tiers", () => {
    // A free first vacancy and a paid Standart one both carry no boost_kind.
    expect(codes(null)).toEqual(["brand", "premium"]);
    expect(codes("standard")).toEqual(["brand", "premium"]);
  });

  it("offers a Brend listing only Premium", () => {
    expect(codes("brand")).toEqual(["premium"]);
  });

  it("offers a Premium listing nothing — it is already the top tier", () => {
    expect(codes("premium")).toEqual([]);
  });

  it("never offers Standart as an upgrade", () => {
    // Standart is a paid listing, not a visual treatment: selling it to a live
    // vacancy would charge for a change the seeker can't see.
    for (const current of [null, "standard", "brand", "premium"]) {
      expect(codes(current)).not.toContain("standard");
    }
  });
});
