import { describe, expect, it } from "vitest";

import { canAffordJobPost, willChargeForJobPost } from "@/lib/job-post-pricing";

describe("willChargeForJobPost", () => {
  it("is free for a first-time poster", () => {
    expect(willChargeForJobPost(false, 99_000)).toBe(false);
  });

  it("charges once the employer has published before", () => {
    expect(willChargeForJobPost(true, 99_000)).toBe(true);
  });

  it("is free regardless of history when the price is zero (e.g. a promo)", () => {
    expect(willChargeForJobPost(true, 0)).toBe(false);
  });
});

describe("canAffordJobPost", () => {
  it("affords an exact-balance match", () => {
    expect(canAffordJobPost(99_000, 99_000)).toBe(true);
  });

  it("affords more than the price", () => {
    expect(canAffordJobPost(150_000, 99_000)).toBe(true);
  });

  it("cannot afford less than the price", () => {
    expect(canAffordJobPost(50_000, 99_000)).toBe(false);
  });

  it("cannot afford a zero balance against a positive price", () => {
    expect(canAffordJobPost(0, 99_000)).toBe(false);
  });
});
